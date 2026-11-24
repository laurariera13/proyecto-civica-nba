{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['game_id', 'player_id'],
        on_schema_change='append_new_columns'
    )
}}

-- =============================================================================
-- slv_kaggle__inactive_players
-- =============================================================================
-- Jugadores de baja en cada partido, 1 fila por partido y jugador.
--   - Incremental por loaded_at + merge por la clave compuesta
--     (game_id, player_id): un jugador solo puede estar de baja una vez en
--     cada partido.
--   - Deduplicación: 7 parejas (partido, jugador) repetidas en origen.
--   - Dorsal vacío ('') -> null.
--   - 3FN: se quitan nombre, apellido (están en players) y abreviatura del
--     equipo (está en teams). Solo quedan los ids que enlazan.
-- =============================================================================

with inactive_players as (
    select * from {{ ref('stg_kaggle__inactive_players') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
),

deduplicated as (
    select *
    from inactive_players
    qualify row_number() over (
        partition by game_id, player_id
        order by loaded_at desc
    ) = 1
)

select
      game_id
    , player_id
    , team_id
    , nullif(jersey_number, '')     as jersey_number
    , loaded_at
from deduplicated