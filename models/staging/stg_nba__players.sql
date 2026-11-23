with source as (
    select * from {{ source('nba', 'common_player_info') }}
),

renamed as (
    select
          cast(person_id as integer)                    as player_id
        , trim(first_name)                              as first_name
        , trim(last_name)                               as last_name
        , trim(display_first_last)                      as player_name
        , to_date(birthdate, 'YYYY-MM-DD HH24:MI:SS')   as birth_date
        , trim(country)                                 as country
        , trim(height)                                  as height_ft_in
        , cast(weight as integer)                       as weight_lbs
        , trim(position)                                as position
        , trim(rosterstatus)                            as roster_status
        , cast(team_id as integer)                      as team_id
        , cast(from_year as integer)                    as first_season
        , cast(to_year as integer)                      as last_season
        , trim(draft_year)                              as draft_year_text
        , trim(draft_round)                             as draft_round_text
        , trim(draft_number)                            as draft_number_text
        , cast(greatest_75_flag as boolean)             as is_greatest_75
        , _loaded_at                                    as loaded_at
    from source
)

select * from renamed