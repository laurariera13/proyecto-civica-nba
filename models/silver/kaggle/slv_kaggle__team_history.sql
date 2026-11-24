{{ config(materialized='table') }}

with history as (
    select * from {{ ref('stg_kaggle__team_history') }}
),

teams as (
    select * from {{ ref('stg_kaggle__teams') }}
),

games as (
    select * from {{ ref('stg_kaggle__games') }}
),

last_year as (
    select max(year_to) as max_year_to from history
),

-- 1. Los nombres que vienen en el histórico
history_corrected as (
    select
          h.team_id
        , h.year_from
        , case when h.year_to = l.max_year_to then null
               else h.year_to
          end                                           as year_to
        , h.team_city
        , h.team_nickname
        , false                                         as is_inferred
    from history h
    cross join last_year l
),

-- 2. Los 5 equipos actuales que faltan en el histórico
missing_nba_teams as (
    select
          t.team_id
        , t.year_founded                                as year_from
        , cast(null as integer)                         as year_to
        , t.team_city
        , t.team_nickname
        , true                                          as is_inferred
    from teams t
    where not exists (
        select 1 from history h where h.team_id = t.team_id
    )
),

-- 3. Los equipos que solo salen en los partidos
names_in_games as (
    select team_id_home as team_id, team_name_home as team_name, season_id from games
    union all
    select team_id_away, team_name_away, season_id from games
),

games_only_teams as (
    select
          team_id
        , min(cast(substr(season_id, 2) as integer))    as year_from
        , max(cast(substr(season_id, 2) as integer))    as year_to
        , cast(null as varchar)                         as team_city
        , team_name                                     as team_nickname
        , true                                          as is_inferred
    from names_in_games n
    where not exists (
        select 1 from teams t where t.team_id = n.team_id
    )
    group by team_id, team_name
),
all_names as (
    select * from history_corrected
    union all
    select * from missing_nba_teams
    union all
    select * from games_only_teams
)

select
      team_id
    , year_from
    , year_to
    , case when team_city is not null
           then {{ dbt_utils.generate_surrogate_key(['team_city']) }}
      end                                               as city_id
    , team_nickname
    , is_inferred
from all_names
