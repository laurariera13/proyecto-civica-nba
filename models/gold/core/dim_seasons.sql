select
      season_id
    , season_year
    , season_year || '-' || right(season_year + 1, 2)     as season_label
from {{ ref('slv_kaggle__seasons') }}
where season_type = 'Regular Season'
  and season_year between {{ var('season_start') }} and {{ var('season_end') }}