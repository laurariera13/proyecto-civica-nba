with games as (
    select
          *
        , iff(is_home, 'Casa', 'Fuera')     as location
    from {{ ref('fct_team_games') }}
    where days_rest is not null      -- el 1er partido de la temporada no tiene descanso que medir
),

buckets as (
    select
          'Descanso'                                    as factor
        , location
        , case when days_rest = 0 then '1. Back-to-back'
               when days_rest = 1 then '2. 1 día'
               when days_rest = 2 then '3. 2 días'
               else '4. 3 o más días'
          end                                           as bucket
        , is_win, point_diff
    from games

    union all

    select
          'Distancia'
        , location
        , case when distance_km = 0 then '1. Sin viaje'
               when distance_km < 500 then '2. Menos de 500 km'
               when distance_km < {{ var('long_trip_km') }} then '3. De 500 a {{ var("long_trip_km") }} km'
               else '4. Más de {{ var("long_trip_km") }} km'
          end
        , is_win, point_diff
    from games

    union all

    select
          'Cambio de huso'
        , location
        , case travel_direction
              when 'none' then '1. Mismo huso'
              when 'west' then '2. Hacia el oeste'
              when 'east' then '3. Hacia el este'
          end
        , is_win, point_diff
    from games

    union all

    select
          'Gira fuera de casa'
        , location
        , case when road_trip_game_number = 1 then '1. 1er partido'
               when road_trip_game_number = 2 then '2. 2º partido'
               when road_trip_game_number = 3 then '3. 3er partido'
               else '4. 4º o más'
          end
        , is_win, point_diff
    from games
    where not is_home
)

select
      factor
    , location
    , bucket
    , count(*)                                  as n_games
    , round(avg(iff(is_win, 1, 0)) * 100, 1)    as win_pct
    , round(avg(point_diff), 2)                 as avg_point_diff
from buckets
group by factor, location, bucket