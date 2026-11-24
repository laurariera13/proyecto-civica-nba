{{ config(materialized='table') }}

with details as (
    select * from {{ ref('stg_kaggle__team_details') }}
)

select
      team_id
    , {{ dbt_utils.generate_surrogate_key(['arena_name']) }}  as arena_id
    , owner_name
    , general_manager
    , head_coach
    , g_league_affiliate
from details