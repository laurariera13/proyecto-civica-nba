{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['game_id', 'team_id'],
        on_schema_change='fail'
    )
}}

with travel as (
    select * from {{ ref('int_team_games__travel') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
)

select
    -- claves: enlazan con las dimensiones
      game_id
    , team_id
    , opponent_team_id
    , season_id
    , {{ dbt_utils.generate_surrogate_key(['arena_name']) }}   as arena_id
    , game_date

    -- resultado
    , is_home
    , is_win
    , pts
    , opponent_pts
    , pts - opponent_pts                                        as point_diff
    , fgm, fga, fg3m, fg3a, ftm, fta, reb, ast, tov

    -- caso 1: viajes
    , cast(distance_km as number(10, 1))                        as distance_km
    , days_rest
    , days_rest = 0                                             as is_back_to_back
    , timezone_shift_hours
    , case
          when timezone_shift_hours > 0 then 'east'
          when timezone_shift_hours < 0 then 'west'
          else 'none'
      end                                                       as travel_direction
    , road_trip_game_number
    , is_from_home_base

    -- caso 2: contexto del partido (casa, público)
    , is_neutral_venue
    , case
          when is_neutral_venue                                   then 'bubble'
          when season_year = {{ var('restricted_fans_season') }} then 'restricted'
          else 'normal'
      end                                                       as fan_context
    , attendance
    , n_inactive_players

    , loaded_at
from travel