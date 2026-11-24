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
--   - Deduplicación: en origen hay 7 parejas (partido, jugador) repetidas,
--     filas idénticas. Se queda una.
--   - Dorsal: 43 filas lo traen vacío; el texto vacío ('') pasa a null,
--     que es como se representa "no hay dato".
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
),

corrected as (
    select
          game_id
        , player_id
        , first_name
        , last_name
        , nullif(jersey_number, '')     as jersey_number
        , team_id
        , team_abbreviation
        , loaded_at
    from deduplicated
)

select * from corrected