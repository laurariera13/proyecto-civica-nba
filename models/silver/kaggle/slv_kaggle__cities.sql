{{ config(materialized='table') }}

with team_cities as (
    select distinct
          team_city                                   as city_name
        , case when team_state = 'Atlanta' then 'Georgia'
               else team_state
          end                                         as state_name
        , team_state = 'Atlanta'                      as is_state_corrected
    from {{ ref('stg_kaggle__teams') }}
),

history_cities as (
    select distinct team_city as city_name
    from {{ ref('stg_kaggle__team_history') }}
),

old_cities as (
    select
          city_name
        , cast(null as varchar)                       as state_name
        , false                                       as is_state_corrected
    from history_cities h
    where not exists (
        select 1 from team_cities t where t.city_name = h.city_name
    )
),

all_cities as (
    select * from team_cities
    union all
    select * from old_cities
)

select
      {{ dbt_utils.generate_surrogate_key(['city_name']) }}  as city_id
    , city_name
    , state_name
    , is_state_corrected
from all_cities