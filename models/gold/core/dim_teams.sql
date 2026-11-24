with teams as (
    select * from {{ ref('slv_kaggle__teams') }}
    where not is_inferred
),

current_names as (
    select * from {{ ref('slv_kaggle__team_history') }}
    where year_to is null
),

cities as (
    select * from {{ ref('slv_kaggle__cities') }}
)

select
      t.team_id
    , t.team_abbreviation
    , c.city_name || ' ' || n.team_nickname    as team_name
    , n.team_nickname
    , c.city_name                              as team_city
    , c.state_name                             as team_state
from teams t
inner join current_names n on t.team_id = n.team_id
inner join cities c        on n.city_id = c.city_id