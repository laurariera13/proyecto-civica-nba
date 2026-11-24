{{ config(materialized='table') }}

-- =============================================================================
-- slv_kaggle__players
-- =============================================================================
-- Ficha de cada jugador, limpia. Correcciones:
--   1. Fecha de nacimiento 1900-01-01: es un valor de relleno, no real.
--      Se pone a null y se marca con is_birth_date_invalid.
--   2. Altura "6-10" (pies-pulgadas) -> centímetros. Peso libras -> kg.
--      Se conservan las columnas originales.
--   3. Draft: "Undrafted" no es un año. Se separa en un flag (is_undrafted)
--      y en columnas numéricas (null si no fue drafteado).
-- =============================================================================

with players as (
    select * from {{ ref('stg_kaggle__players') }}
),

corrected as (
    select
          player_id
        , first_name
        , last_name
        , player_name

        -- 1. Fecha de relleno -> null + flag
        , case when birth_date = '1900-01-01' then null
               else birth_date
          end                                               as birth_date
        , coalesce(birth_date = '1900-01-01', false)        as is_birth_date_invalid

        , country
        , position
        , roster_status
        , team_id
        , first_season
        , last_season

        -- 2. Unidades: pies-pulgadas -> cm (1 pulgada = 2,54 cm), libras -> kg
        , height_ft_in
        , cast(round((
              try_cast(split_part(height_ft_in, '-', 1) as integer) * 12
            + try_cast(split_part(height_ft_in, '-', 2) as integer)
          ) * 2.54) as integer)                             as height_cm
        , weight_lbs
        , round(weight_lbs * 0.453592, 1)                   as weight_kg

        -- 3. Draft: texto -> flag + números
        , draft_year_text = 'Undrafted'                     as is_undrafted
        , try_cast(draft_year_text as integer)              as draft_year
        , try_cast(draft_round_text as integer)             as draft_round
        , try_cast(draft_number_text as integer)            as draft_number

        , is_greatest_75
        , loaded_at
    from players
)

select * from corrected