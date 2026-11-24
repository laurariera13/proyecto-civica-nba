{{ config(materialized='table') }}

with details as (
    select distinct
          arena_name
        , arena_capacity
    from {{ ref('stg_kaggle__team_details') }}
    where arena_name is not null
)

select
      {{ dbt_utils.generate_surrogate_key(['arena_name']) }}  as arena_id
    , arena_name
    , arena_capacity
from details