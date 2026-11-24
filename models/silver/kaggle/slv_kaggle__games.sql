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
-- Partidos limpios, 1 fila por partido (local y visitante en columnas).
--   - Incremental por loaded_at + merge por game_id.
--   - season_type: "All-Star" y "All Star" son lo mismo -> "All Star".
--   - Duplicados: los 56 game_id repetidos eran el mismo partido con las dos
--     grafías. Tras normalizar son idénticos y se queda uno.
--   - season_year: año de inicio de la temporada, sacado de season_id
--     ('22013' -> 2013). Sirve para filtrar el alcance en Gold.
--   - Minutos: 5.613 partidos traen min = 0. Se reconstruyen con
--     line_scores: 240 (5 jugadores x 48 min) + 25 por prórroga
--     (5 x 5 min). Regla verificada en los partidos con minutos conocidos
--     (31.989 de 31.996 coinciden). Solo se reconstruye si el partido tiene
--     los puntos por cuarto; si no, queda null. Flag: is_minutes_reconstructed.
--   - W/L: se recalcula siempre desde los puntos (no hay empates en
--     baloncesto). En origen hay 2 incoherentes y 2 vacíos. Flag:
--     is_wl_corrected.
-- =============================================================================

with games as (
    select * from {{ ref('stg_kaggle__games') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
),

normalized as (
    select
          * exclude (season_type)
        , replace(season_type, 'All-Star', 'All Star')     as season_type
    from games
),

deduplicated as (
    select *
    from normalized
    qualify row_number() over (partition by game_id order by loaded_at desc) = 1
),

line_scores as (
    select
          game_id
        , overtimes_played
        , pts_qtr1_home is not null                         as has_quarter_scores
    from {{ ref('slv_kaggle__line_scores') }}
),

corrected as (
    select
          g.* exclude (game_minutes, wl_home, wl_away)
        , cast(substr(g.season_id, 2) as integer)           as season_year

        -- Minutos: originales si son > 0; si no, reconstruidos con las prórrogas
        , g.game_minutes                                    as game_minutes_original
        , case
              when g.game_minutes > 0 then g.game_minutes
              when ls.has_quarter_scores then 240 + 25 * ls.overtimes_played
          end                                               as game_minutes
        , g.game_minutes = 0
          and coalesce(ls.has_quarter_scores, false)        as is_minutes_reconstructed

        -- W/L: siempre desde los puntos
        , iff(g.pts_home > g.pts_away, 'W', 'L')            as wl_home
        , iff(g.pts_home > g.pts_away, 'L', 'W')            as wl_away
        , coalesce(
              g.wl_home <> iff(g.pts_home > g.pts_away, 'W', 'L'),
              true
          )                                                 as is_wl_corrected
    from deduplicated g
    left join line_scores ls
        on g.game_id = ls.game_id
)

select * from corrected