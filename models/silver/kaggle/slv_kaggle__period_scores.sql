{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['game_id', 'team_id', 'period_number'],
        on_schema_change='append_new_columns'
    )
}}

-- =============================================================================
-- slv_kaggle__period_scores
-- =============================================================================
-- Puntos de cada equipo en cada periodo. Sustituye a line_scores.
-- Origen: 1 fila por partido con 28 columnas que se repiten
--   (4 cuartos + 10 prórrogas) x (local + visitante).
-- Aquí (1FN): 1 fila por partido, equipo y periodo.
--   period_number 1-4 = cuartos, 5-14 = prórrogas 1-10.
--   - Incremental por loaded_at + merge por la clave de 3 columnas.
--   - Deduplicación: 40 partidos repetidos en origen (filas idénticas).
--   - Cuartos: se guardan si traen dato.
--   - Prórrogas: las no jugadas vienen a 0. Una prórroga se jugó si entre
--     los dos equipos sumaron más de 0 puntos; si no, la fila no se guarda.
--   - El total (pts) no se guarda: es la suma de los periodos y además ya
--     está en team_games.
-- =============================================================================

with line_scores as (
    select * from {{ ref('stg_kaggle__line_scores') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
),

deduplicated as (
    select *
    from line_scores
    qualify row_number() over (partition by game_id order by loaded_at desc) = 1
),

-- Columnas -> filas: un select por cada lado y periodo, unidos con union all
unpivoted as (
    {%- for lado in ['home', 'away'] %}
    {%- for periodo in range(1, 15) %}
    {%- set columna = 'pts_qtr' ~ periodo if periodo <= 4 else 'pts_ot' ~ (periodo - 4) %}
    select
          game_id
        , team_id_{{ lado }}                as team_id
        , {{ periodo }}                     as period_number
        , {{ columna }}_{{ lado }}          as points
        , loaded_at
    from deduplicated
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
),

with_period_total as (
    select
          *
        , sum(coalesce(points, 0)) over (partition by game_id, period_number) as period_total
    from unpivoted
)

select
      game_id
    , team_id
    , period_number
    , points
    , loaded_at
from with_period_total
where (period_number <= 4 and points is not null)
   or (period_number >  4 and period_total > 0)