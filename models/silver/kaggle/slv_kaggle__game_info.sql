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
--   - Incremental por loaded_at + merge por game_id (igual que line_scores).
--   - Deduplicación: 40 game_id repetidos en origen (All-Star).
--   - Duración: viene como texto "h:mm". Se pasa a minutos. Un partido de la
--     NBA dura entre 1 y 4 horas; fuera de ese rango (negativos, "0:00",
--     "513:35"...) es un error de origen: se pone a null y se marca con
--     is_duration_invalid. Si viene vacía, queda null pero no se marca:
--     falta el dato, no está mal.
--   - Asistencia: se deja como viene (vacía en partidos antiguos).
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
        , game_date
        , attendance
        , game_duration_text
        , case when duration_minutes_raw between 60 and 240
               then duration_minutes_raw
          end                                                           as game_duration_minutes
        , coalesce(duration_minutes_raw not between 60 and 240, false)  as is_duration_invalid
        , loaded_at
    from parsed
)

select * from corrected