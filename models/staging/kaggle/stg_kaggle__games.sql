-- =============================================================================
-- stg_nba__games
-- =============================================================================
-- Staging: 1:1 con Bronze. Solo casteo y renombrado: NO filtra ni corrige.
-- Bronze es todo VARCHAR; aquí cada columna pasa a su tipo real.
-- game_id se queda como texto: '0024600001' perdería los ceros si fuera número.
-- =============================================================================

{% set stats_enteras = ['fgm', 'fga', 'fg3m', 'fg3a', 'ftm', 'fta', 'oreb', 'dreb',
                         'reb', 'ast', 'stl', 'blk', 'tov', 'pf', 'pts', 'plus_minus'] %}
{% set stats_porcentaje = ['fg_pct', 'fg3_pct', 'ft_pct'] %}

{{ config(materialized='view') }}
with source as (
    select * from {{ source('kaggle', 'game') }}
),

renamed as (
    select
          game_id
        , season_id
        , trim(season_type)                                 as season_type
        , to_date(game_date, 'YYYY-MM-DD HH24:MI:SS')       as game_date
        , cast(min as integer)                              as game_minutes
        {%- for lado in ['home', 'away'] %}
        , cast(team_id_{{ lado }} as integer)               as team_id_{{ lado }}
        , trim(team_abbreviation_{{ lado }})                as team_abbreviation_{{ lado }}
        , trim(team_name_{{ lado }})                        as team_name_{{ lado }}
        , trim(matchup_{{ lado }})                          as matchup_{{ lado }}
        , trim(wl_{{ lado }})                               as wl_{{ lado }}
        {%- for stat in stats_enteras %}
        , cast({{ stat }}_{{ lado }} as integer)            as {{ stat }}_{{ lado }}
        {%- endfor %}
        {%- for stat in stats_porcentaje %}
        , cast({{ stat }}_{{ lado }} as number(5, 3))       as {{ stat }}_{{ lado }}
        {%- endfor %}
        , cast(video_available_{{ lado }} as boolean)       as is_video_available_{{ lado }}
        {%- endfor %}
        , _loaded_at                                        as loaded_at
    from source
)

select * from renamed