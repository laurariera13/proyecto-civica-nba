with arenas as (
    select distinct
          arena_name
        , latitude
        , longitude
        , timezone
    from {{ ref('nba_arenas') }}
),

capacities as (
    select * from {{ ref('slv_kaggle__arenas') }}
)

select
      {{ dbt_utils.generate_surrogate_key(['a.arena_name']) }}  as arena_id
    , a.arena_name
    , a.latitude
    , a.longitude
    , a.timezone
    , c.arena_capacity
from arenas a
left join capacities c on a.arena_name = c.arena_name