-- =============================================================================
-- Cada partido tiene exactamente 2 equipos en team_games: uno gana y otro pierde.
-- Devuelve los partidos que no lo cumplen. 0 filas = PASS.
-- =============================================================================

select
      game_id
    , count(*)              as n_equipos
    , count_if(wl = 'W')    as n_ganadores
from {{ ref('slv_kaggle__team_games') }}
group by game_id
having count(*) <> 2
    or count_if(wl = 'W') <> 1
