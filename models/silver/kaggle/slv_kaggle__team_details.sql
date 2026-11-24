{{ config(materialized='table') }}

-- =============================================================================
-- slv_kaggle__team_details
-- =============================================================================
-- Sin correcciones: el aforo vacío no se puede deducir y queda null; el
-- pabellón y su ubicación saldrán del seed nba_arenas. Existe para que Gold
-- lea siempre de Silver. En origen faltan 5 equipos (ver team_history).
-- =============================================================================

with details as (
    select * from {{ ref('stg_kaggle__team_details') }}
)

select
      team_id
    , team_abbreviation
    , arena_name
    , arena_capacity
    , owner_name
    , general_manager
    , head_coach
    , g_league_affiliate
    , loaded_at
from details