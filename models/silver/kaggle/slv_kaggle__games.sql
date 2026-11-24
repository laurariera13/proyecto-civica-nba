{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='game_id',
        on_schema_change='append_new_columns'
    )
}}

-- =============================================================================
-- slv_kaggle__games
-- =============================================================================
-- Solo lo que es del PARTIDO, 1 fila por partido (3FN):
--   - season_type sale a seasons (depende de season_id, no del partido).
--   - Todo lo de cada equipo (_home/_away) sale a team_games.
--   - Incremental por loaded_at + merge por game_id.
--   - Deduplicación: 56 partidos repetidos (solo cambiaba "All-Star").
--   - Minutos: 5.613 partidos traen 0. Si hay puntos por cuarto, se
--     reconstruyen: 240 + 25 por prórroga (regla que cumple el 99,98% de
--     los partidos con minutos). Si no, null. Se marca con
--     is_minutes_reconstructed.
-- =============================================================================

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

-- Por partido: ¿hay puntos por cuarto? ¿cuántas prórrogas?
periods as (
    select
          game_id
        , count(distinct iff(period_number > 4, period_number, null))  as overtimes_played
    from {{ ref('slv_kaggle__period_scores') }}
    group by game_id
)

select
      g.game_id
    , g.season_id
    , g.game_date
    , case when g.game_minutes > 0 then g.game_minutes
           when p.game_id is not null then 240 + 25 * p.overtimes_played
      end                                                           as game_minutes
    , coalesce(g.game_minutes = 0 and p.game_id is not null, false) as is_minutes_reconstructed
    , g.loaded_at
from deduplicated g
left join periods p on g.game_id = p.game_id