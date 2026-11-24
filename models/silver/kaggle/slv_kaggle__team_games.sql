{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['game_id', 'team_id'],
        on_schema_change='append_new_columns'
    )
}}

-- =============================================================================
-- slv_kaggle__team_games
-- =============================================================================
-- Lo que hizo cada equipo en cada partido (tabla EQUIPO_PARTIDO).
-- Origen: 1 fila por partido con todo repetido en _home y _away.
-- Aquí (1FN): 2 filas por partido, una por equipo, con is_home.
--   - Incremental por loaded_at + merge por (game_id, team_id).
--   - Deduplicación: 56 partidos repetidos (solo cambiaba "All-Star" /
--     "All Star"); se deduplica por game_id antes de separar.
--   - W/L: se recalcula desde los puntos (2 venían mal y 2 vacíos;
--     no hay empates). is_wl_corrected marca las filas cambiadas.
--   - 3FN: fuera nombre, abreviatura y matchup del equipo (dependen del
--     equipo, no del partido) y los porcentajes (= anotados / intentados).
--   - reb se queda aunque sea oreb + dreb: en temporadas antiguas no hay
--     oreb/dreb, así que no siempre se puede calcular.
-- =============================================================================

{% set stats = ['pts', 'fgm', 'fga', 'fg3m', 'fg3a', 'ftm', 'fta', 'oreb', 'dreb',
                'reb', 'ast', 'stl', 'blk', 'tov', 'pf', 'plus_minus'] %}

with games as (
    select * from {{ ref('stg_kaggle__games') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
),

deduplicated as (
    select *
    from games
    qualify row_number() over (partition by game_id order by loaded_at desc) = 1
),

-- Columnas _home/_away -> 2 filas por partido
unpivoted as (
    {%- for lado, rival in [('home', 'away'), ('away', 'home')] %}
    select
          game_id
        , team_id_{{ lado }}                as team_id
        , {{ 'true' if lado == 'home' else 'false' }}  as is_home
        , wl_{{ lado }}                     as wl_original
        , pts_{{ rival }}                   as pts_opponent
        {%- for stat in stats %}
        , {{ stat }}_{{ lado }}             as {{ stat }}
        {%- endfor %}
        , is_video_available_{{ lado }}     as is_video_available
        , loaded_at
    from deduplicated
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
)

select
      game_id
    , team_id
    , is_home
    , iff(pts > pts_opponent, 'W', 'L')                             as wl
    , coalesce(wl_original <> iff(pts > pts_opponent, 'W', 'L'), true) as is_wl_corrected
    {%- for stat in stats %}
    , {{ stat }}
    {%- endfor %}
    , is_video_available
    , loaded_at
from unpivoted