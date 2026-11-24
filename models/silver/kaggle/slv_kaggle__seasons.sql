{{ config(materialized='table') }}

with games as (
    select distinct season_id
    from {{ ref('stg_kaggle__games') }}
),

final as (
    select
          season_id
        , cast(substr(season_id, 2) as integer)    as season_year
        , case left(season_id, 1)
              when '1' then 'Pre Season'
              when '2' then 'Regular Season'
              when '3' then 'All Star'
              when '4' then 'Playoffs'
          end                                       as season_type
    from games
)

select * from final