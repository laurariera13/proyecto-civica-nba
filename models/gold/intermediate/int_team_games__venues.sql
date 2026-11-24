{% set stats = ['pts', 'fgm', 'fga', 'fg3m', 'fg3a', 'ftm', 'fta', 'reb', 'ast', 'tov'] %}

with team_games as (
    select * from {{ ref('slv_kaggle__team_games') }}
),

games as (
    select * from {{ ref('slv_kaggle__games') }}
),

seasons as (
    select * from {{ ref('slv_kaggle__seasons') }}
),

arenas as (
    select * from {{ ref('nba_arenas') }}
),

-- 1. Solo temporada regular y solo las temporadas del análisis
in_scope as (
    select
          tg.*
        , g.season_id
        , s.season_year
        , g.game_date
    from team_games tg
    inner join games g   on tg.game_id = g.game_id
    inner join seasons s on g.season_id = s.season_id
    where s.season_type = 'Regular Season'
      and s.season_year between {{ var('season_start') }} and {{ var('season_end') }}
),

-- 2. Quién era el local de cada partido
home_teams as (
    select game_id, team_id as home_team_id
    from in_scope
    where is_home
),

-- 3. Cuántos jugadores de baja tuvo cada equipo en cada partido
inactive_counts as (
    select game_id, team_id, count(*) as n_inactive_players
    from {{ ref('slv_kaggle__inactive_players') }}
    group by game_id, team_id
)

select
      t.game_id
    , t.team_id
    , o.team_id                                             as opponent_team_id
    , t.season_id
    , t.season_year
    , t.game_date
    , t.is_home
    , t.wl = 'W'                                            as is_win
    {%- for stat in stats %}
    , t.{{ stat }}
    {%- endfor %}
    , o.pts                                                 as opponent_pts
    , i.attendance
    , coalesce(ic.n_inactive_players, 0)                    as n_inactive_players

    -- Dónde se jugó: sede neutral si la hay; si no, el pabellón del local
    , neutral.arena_name is not null                        as is_neutral_venue
    , coalesce(neutral.arena_name, home_arena.arena_name)   as arena_name
    , coalesce(neutral.latitude,   home_arena.latitude)     as latitude
    , coalesce(neutral.longitude,  home_arena.longitude)    as longitude
    , coalesce(neutral.timezone,   home_arena.timezone)     as timezone

    -- La "casa" de este equipo ese día (para la regla de volver a casa)
    , own_arena.latitude                                    as home_base_latitude
    , own_arena.longitude                                   as home_base_longitude
    , own_arena.timezone                                    as home_base_timezone

    , t.loaded_at
from in_scope t
-- el rival: la otra fila del mismo partido
inner join in_scope o
    on  t.game_id = o.game_id
    and t.team_id <> o.team_id
inner join home_teams h
    on t.game_id = h.game_id
-- 4a. Sede neutral: la fila del seed sin equipo (burbuja)
left join arenas neutral
    on  neutral.team_id is null
    and t.game_date between neutral.date_from and neutral.date_to
-- 4b. Pabellón del equipo local en la fecha del partido
left join arenas home_arena
    on  home_arena.team_id = h.home_team_id
    and t.game_date between home_arena.date_from and coalesce(home_arena.date_to, '9999-12-31')
-- 4c. Pabellón de ESTE equipo en la fecha del partido (su casa)
left join arenas own_arena
    on  own_arena.team_id = t.team_id
    and t.game_date between own_arena.date_from and coalesce(own_arena.date_to, '9999-12-31')
left join {{ ref('slv_kaggle__game_info') }} i
    on t.game_id = i.game_id
left join inactive_counts ic
    on  t.game_id = ic.game_id
    and t.team_id = ic.team_id