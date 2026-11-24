{% set cuartos = ['qtr1', 'qtr2', 'qtr3', 'qtr4'] %}

with source as (
    select * from {{ source('kaggle', 'line_score') }}
),

renamed as (
    select
          game_id
        , to_date(game_date_est, 'YYYY-MM-DD HH24:MI:SS')        as game_date
        , cast(game_sequence as integer)                        as game_sequence
        {%- for lado in ['home', 'away'] %}
        , cast(team_id_{{ lado }} as integer)                   as team_id_{{ lado }}
        , trim(team_abbreviation_{{ lado }})                    as team_abbreviation_{{ lado }}
        , nullif(trim(team_wins_losses_{{ lado }}), '-')        as team_wins_losses_{{ lado }}
        {%- for cuarto in cuartos %}
        , cast(pts_{{ cuarto }}_{{ lado }} as integer)          as pts_{{ cuarto }}_{{ lado }}
        {%- endfor %}
        {%- for i in range(1, 11) %}
        , cast(pts_ot{{ i }}_{{ lado }} as integer)             as pts_ot{{ i }}_{{ lado }}
        {%- endfor %}
        , cast(pts_{{ lado }} as integer)                       as pts_{{ lado }}
        {%- endfor %}
        , _loaded_at                                            as loaded_at
    from source
)

select * from renamed