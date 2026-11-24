{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='game_id',
        on_schema_change='append_new_columns'
    )
}}

-- =============================================================================
-- slv_kaggle__line_scores
-- =============================================================================
-- Puntos por cuarto y prórroga, 1 fila por partido.
--   - Incremental: en cada ejecución solo procesa las filas cargadas en Bronze
--     después de la última carga ya procesada (loaded_at). El merge por
--     game_id evita duplicados si una fila se vuelve a procesar.
--   - Deduplicación: en origen hay 40 game_id repetidos (filas idénticas,
--     partidos All-Star). Se queda una.
--   - overtimes_played: nº de prórrogas jugadas. Una prórroga se jugó si
--     algún equipo anotó en ella (en las no jugadas viene 0 o vacío).
--     Sirve en slv_kaggle__games para reconstruir los minutos.
-- =============================================================================

with line_scores as (
    select * from {{ ref('stg_kaggle__line_scores') }}
    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}
),

deduplicated as (
    select *
    from line_scores
    qualify row_number() over (partition by game_id order by loaded_at desc) = 1
),

with_overtimes as (
    select
          *
        , 0
        {%- for i in range(1, 11) %}
          + iff(coalesce(pts_ot{{ i }}_home, 0) + coalesce(pts_ot{{ i }}_away, 0) > 0, 1, 0)
        {%- endfor %}                                       as overtimes_played
    from deduplicated
)

select * from with_overtimes