{{ config(materialized='table') }}

-- =============================================================================
-- slv_kaggle__teams
-- =============================================================================
-- Equipos limpios. Única corrección: en origen el estado de ATL es "Atlanta"
-- (la ciudad) en vez de "Georgia". Se corrige y se marca con un flag para
-- que quede trazado qué fila se ha tocado.
-- =============================================================================

with teams as (
    select * from {{ ref('stg_kaggle__teams') }}
),

corrected as (
    select
          team_id
        , team_full_name
        , team_abbreviation
        , team_nickname
        , team_city
        , case when team_state = 'Atlanta' then 'Georgia'
               else team_state
          end                              as team_state
        , team_state = 'Atlanta'           as is_state_corrected
        , year_founded
        , loaded_at
    from teams
)

select * from corrected