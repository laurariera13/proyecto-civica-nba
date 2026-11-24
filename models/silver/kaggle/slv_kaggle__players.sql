{{ config(materialized='table') }}

-- =============================================================================
-- slv_kaggle__players
-- =============================================================================
-- Un jugador por fila (3FN). Correcciones:
--   1. Fecha de nacimiento 1900-01-01 es un relleno -> null + flag.
--   2. Altura "6-10" -> cm y libras -> kg. Solo se guarda la versión
--      convertida (la original sigue en staging): guardar las dos sería
--      repetir el mismo dato.
--   3. Draft: "Undrafted" no es un año -> flag + columnas numéricas.
--   4. team_id = 0 significa "sin equipo" -> null.
-- Se quita player_name: es nombre + apellido (dato calculado).
-- Se añaden los 338 jugadores que solo aparecen en inactive_players
-- (is_inferred = true), para que ninguna baja apunte a un jugador inexistente.
-- =============================================================================

with players as (
    select * from {{ ref('stg_kaggle__players') }}
),

inactive_players as (
    select * from {{ ref('stg_kaggle__inactive_players') }}
),

-- 1. Jugadores de la ficha oficial
corrected as (
    select
          player_id
        , first_name
        , last_name
        , case when birth_date = '1900-01-01' then null
               else birth_date
          end                                               as birth_date
        , country
        , cast(round((
              try_cast(split_part(height_ft_in, '-', 1) as integer) * 12
            + try_cast(split_part(height_ft_in, '-', 2) as integer)
          ) * 2.54) as integer)                             as height_cm
        , round(weight_lbs * 0.453592, 1)                   as weight_kg
        , position
        , roster_status
        , nullif(team_id, 0)                                as team_id
        , first_season
        , last_season
        , try_cast(draft_year_text as integer)              as draft_year
        , try_cast(draft_round_text as integer)             as draft_round
        , try_cast(draft_number_text as integer)            as draft_number
        , draft_year_text = 'Undrafted'                     as is_undrafted
        , is_greatest_75
        , coalesce(birth_date = '1900-01-01', false)        as is_birth_date_invalid
        , false                                             as is_inferred
    from players
),

-- 2. Jugadores que solo aparecen en las bajas
missing_players as (
    select
          player_id
        , first_name
        , last_name
        , cast(null as date)                                as birth_date
        , cast(null as varchar)                             as country
        , cast(null as integer)                             as height_cm
        , cast(null as number(5, 1))                        as weight_kg
        , cast(null as varchar)                             as position
        , cast(null as varchar)                             as roster_status
        , cast(null as integer)                             as team_id
        , cast(null as integer)                             as first_season
        , cast(null as integer)                             as last_season
        , cast(null as integer)                             as draft_year
        , cast(null as integer)                             as draft_round
        , cast(null as integer)                             as draft_number
        , cast(null as boolean)                             as is_undrafted
        , cast(null as boolean)                             as is_greatest_75
        , false                                             as is_birth_date_invalid
        , true                                              as is_inferred
    from inactive_players i
    where not exists (
        select 1 from players p where p.player_id = i.player_id
    )
    qualify row_number() over (partition by player_id order by loaded_at desc) = 1
)

select * from corrected
union all
select * from missing_players