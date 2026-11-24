with source as (
    select * from {{ source('kaggle', 'team_details') }}
),

renamed as (
    select
          cast(team_id as integer)          as team_id
        , trim(abbreviation)                as team_abbreviation
        , trim(arena)                       as arena_name
        , cast(arenacapacity as integer)    as arena_capacity
        , trim(owner)                       as owner_name
        , trim(generalmanager)              as general_manager
        , trim(headcoach)                   as head_coach
        , trim(dleagueaffiliation)          as g_league_affiliate
        , _loaded_at                        as loaded_at
    from source
)

select * from renamed