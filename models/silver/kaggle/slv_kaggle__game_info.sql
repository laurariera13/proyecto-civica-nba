{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='game_id',
        on_schema_change='append_new_columns'
    )
}}

-- =============================================================================
-- slv_kaggle__game_info
-- =============================================================================
-- Asistencia y duración de cada partido, 1 fila por partido.
--   - Incremental por loaded_at + merge por game_id.
--   - Deduplicación: 40 game_id repetidos en origen (All-Star).
--   - Duración "h:mm" -> minutos. Fuera de 60-240 min es un error de origen:
--     null + is_duration_invalid. Vacía -> null sin marcar (falta el dato).
--   - 3FN: se quitan game_date (ya está en games) y el texto original de la
--     duración (ya está en staging).
-- =============================================================================

with game_info as (
    select * from {{ ref('stg_kaggle__game_info') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
),

deduplicated as (
    select *
    from game_info
    qualify row_number() over (partition by game_id order by loaded_at desc) = 1
),

parsed as (
    select
          *
        , try_cast(split_part(game_duration_text, ':', 1) as integer) * 60
        + try_cast(split_part(game_duration_text, ':', 2) as integer)   as duration_minutes_raw
    from deduplicated
),

corrected as (
    select
          game_id
        , attendance
        , case when duration_minutes_raw between 60 and 240
               then duration_minutes_raw
          end                                                           as game_duration_minutes
        , coalesce(duration_minutes_raw not between 60 and 240, false)  as is_duration_invalid
        , loaded_at
    from parsed
)

select * from corrected