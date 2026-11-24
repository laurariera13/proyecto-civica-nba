{{ config(materialized='view') }}
with source as (
    select * from {{ source('kaggle', 'game_info') }}
),

renamed as (
    select
          game_id
        , to_date(game_date, 'YYYY-MM-DD HH24:MI:SS')   as game_date
        , cast(attendance as integer)                   as attendance
        , trim(game_time)                               as game_duration_text
        , _loaded_at                                    as loaded_at
    from source
)

select * from renamed