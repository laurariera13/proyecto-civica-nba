with source as (
    select * from {{ source('nba', 'team') }}
),

renamed as (
    select
          cast(id as integer)              as team_id
        , trim(full_name)                  as team_full_name
        , trim(abbreviation)               as team_abbreviation
        , trim(nickname)                   as team_nickname
        , trim(city)                       as team_city
        , trim(state)                      as team_state
        , cast(year_founded as integer)    as year_founded
        , _loaded_at                       as loaded_at
    from source
)

select * from renamed