with source as (
    select * from {{ source('kaggle', 'inactive_players') }}
),

renamed as (
    select
          game_id
        , cast(player_id as integer)    as player_id
        , trim(first_name)              as first_name
        , trim(last_name)               as last_name
        , trim(jersey_num)              as jersey_number
        , cast(team_id as integer)      as team_id
        , trim(team_abbreviation)       as team_abbreviation
        , _loaded_at                    as loaded_at
    from source
)

select * from renamed