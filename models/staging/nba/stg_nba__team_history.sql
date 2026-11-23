with source as (
    select * from {{ source('nba', 'team_history') }}
),

renamed as (
    select
          cast(team_id as integer)             as team_id
        , trim(city)                           as team_city
        , trim(nickname)                       as team_nickname
        , cast(year_founded as integer)        as year_from
        , cast(year_active_till as integer)    as year_to
        , _loaded_at                           as loaded_at
    from source
)

select * from renamed