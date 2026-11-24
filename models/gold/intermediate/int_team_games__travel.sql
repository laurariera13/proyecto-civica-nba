with venues as (
    select * from {{ ref('int_team_games__venues') }}
),

-- 1. Para cada partido, cómo fue el partido ANTERIOR del mismo equipo
with_previous as (
    select
          *
        , lag(game_date) over (partition by team_id, season_year order by game_date) as prev_game_date
        , lag(latitude)  over (partition by team_id, season_year order by game_date) as prev_latitude
        , lag(longitude) over (partition by team_id, season_year order by game_date) as prev_longitude
        , lag(timezone)  over (partition by team_id, season_year order by game_date) as prev_timezone
        -- Partidos en casa jugados hasta hoy: cambia cada vez que vuelven a casa
        , count_if(is_home) over (
              partition by team_id, season_year
              order by game_date
              rows between unbounded preceding and current row
          )                                                                          as home_games_so_far
    from venues
),

-- 2. Desde dónde sale el viaje
with_origin as (
    select
          *
        , datediff('day', prev_game_date, game_date)                    as days_since_prev_game
        -- Sale de casa si es el 1er partido de la temporada o si pasaron
        -- más de return_home_min_days días (supuesto: volvieron a casa)
        , prev_game_date is null
          or datediff('day', prev_game_date, game_date) > {{ var('return_home_min_days') }}
                                                                        as is_from_home_base
    from with_previous
),

with_origin_point as (
    select
          *
        , iff(is_from_home_base, home_base_latitude,  prev_latitude)   as origin_latitude
        , iff(is_from_home_base, home_base_longitude, prev_longitude)  as origin_longitude
        , iff(is_from_home_base, home_base_timezone,  prev_timezone)   as origin_timezone
    from with_origin
)

-- 3. Los cálculos de viaje y descanso
select
      game_id
    , team_id
    , opponent_team_id
    , season_id
    , season_year
    , game_date
    , is_home
    , is_win
    , pts, fgm, fga, fg3m, fg3a, ftm, fta, reb, ast, tov
    , opponent_pts
    , attendance
    , n_inactive_players
    , is_neutral_venue
    , arena_name
    , is_from_home_base
    , round({{ haversine_km('origin_latitude', 'origin_longitude', 'latitude', 'longitude') }}, 1)
                                                                        as distance_km
    , days_since_prev_game - 1                                          as days_rest
    -- Horas de diferencia con UTC de cada sitio ese día; la resta es el cambio de huso
    , datediff('hour', convert_timezone(timezone, 'UTC', game_date::timestamp_ntz), game_date::timestamp_ntz)
    - datediff('hour', convert_timezone(origin_timezone, 'UTC', game_date::timestamp_ntz), game_date::timestamp_ntz)
                                                                        as timezone_shift_hours
    , iff(is_home, 0, row_number() over (
          partition by team_id, season_year, home_games_so_far, is_home
          order by game_date
      ))                                                                as road_trip_game_number
    , loaded_at
from with_origin_point
