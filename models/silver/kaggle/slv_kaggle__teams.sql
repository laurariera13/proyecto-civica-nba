{{ config(materialized='table') }}

with teams as (
    select
          team_id
        , team_abbreviation
        , year_founded
        , false                                as is_inferred
    from {{ ref('stg_kaggle__teams') }}
),

teams_in_games as (
    select team_id_home as team_id, team_abbreviation_home as team_abbreviation, game_date
    from {{ ref('stg_kaggle__games') }}
    union all
    select team_id_away, team_abbreviation_away, game_date
    from {{ ref('stg_kaggle__games') }}
),

missing_teams as (
    select
          team_id
        , team_abbreviation
        , cast(null as integer)                as year_founded
        , true                                 as is_inferred
    from teams_in_games g
    where not exists (
        select 1 from teams t where t.team_id = g.team_id
    )
    qualify row_number() over (partition by team_id order by game_date desc) = 1
)

select * from teams
union all
select * from missing_teams