{{ config(materialized='table') }}

-- =============================================================================
-- slv_kaggle__team_history
-- =============================================================================
-- Nombres históricos de cada franquicia. Dos correcciones:
--   1. El nombre actual viene con year_to = último año del dataset (2019),
--      como si hubiera dejado de usarse. Se pone a null y se marca con
--      is_current_name.
--   2. En origen faltan 5 equipos (BOS, CLE, NOP, NYK, ORL). Su nombre actual
--      se deduce de la tabla de equipos y se marca con is_inferred.
--      Lo que no se puede deducir (p. ej. que NOP fue antes "Hornets") no se
--      inventa.
-- =============================================================================

with history as (
    select * from {{ ref('stg_kaggle__team_history') }}
),

teams as (
    select * from {{ ref('stg_kaggle__teams') }}
),

last_year as (
    select max(year_to) as max_year_to from history
),

history_corrected as (
    select
          h.team_id
        , h.team_city
        , h.team_nickname
        , h.year_from
        , case when h.year_to = l.max_year_to then null
               else h.year_to
          end                               as year_to
        , h.year_to = l.max_year_to         as is_current_name
        , false                             as is_inferred
        , h.loaded_at
    from history h
    cross join last_year l
),

missing_teams as (
    select
          t.team_id
        , t.team_city
        , t.team_nickname
        , t.year_founded                    as year_from
        , cast(null as integer)             as year_to
        , true                              as is_current_name
        , true                              as is_inferred
        , t.loaded_at
    from teams t
    where not exists (
        select 1 from history h where h.team_id = t.team_id
    )
)

select * from history_corrected
union all
select * from missing_teams