-- =============================================================================
-- Cada equipo NBA tiene exactamente un pabellón en cada temporada del
-- análisis. Si falta o sobra alguno, la distancia de viaje saldría mal.
-- Devuelve las parejas (equipo, temporada) que no lo cumplen. 0 filas = PASS.
-- =============================================================================

with seasons as (
    select distinct season_year
    from {{ ref('slv_kaggle__seasons') }}
    where season_year between {{ var('season_start') }} and {{ var('season_end') }}
),

teams as (
    select team_id
    from {{ ref('slv_kaggle__teams') }}
    where not is_inferred
)

select
      t.team_id
    , s.season_year
    , count(a.arena_name)   as n_pabellones
from teams t
cross join seasons s
left join {{ ref('team_home_arenas') }} a
    on  a.team_id = t.team_id
    and s.season_year >= a.season_from
    and s.season_year <= coalesce(a.season_to, 9999)
group by t.team_id, s.season_year
having count(a.arena_name) <> 1
