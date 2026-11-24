with games as (
    select * from {{ ref('fct_team_games') }}
),

teams as (
    select * from {{ ref('dim_teams') }}
),

seasons as (
    select * from {{ ref('dim_seasons') }}
)

select
      g.team_id
    , t.team_name
    , g.season_id
    , s.season_label

    -- Balance
    , count(*)                                                          as n_games
    , count_if(g.is_win)                                                as n_wins
    , count(*) - count_if(g.is_win)                                     as n_losses
    , round(avg(iff(g.is_win, 1, 0)) * 100, 1)                          as win_pct

    -- Dónde y cuándo gana
    , round(avg(iff(g.is_home,      iff(g.is_win, 1, 0), null)) * 100, 1) as home_win_pct
    , round(avg(iff(not g.is_home,  iff(g.is_win, 1, 0), null)) * 100, 1) as away_win_pct
    , round(avg(iff(g.is_back_to_back, iff(g.is_win, 1, 0), null)) * 100, 1) as back_to_back_win_pct
    , round(avg(iff(g.is_home, g.attendance, null)), 0)                 as avg_home_attendance

    -- Ataque y defensa
    , round(avg(g.pts), 1)                                              as avg_pts
    , round(avg(g.opponent_pts), 1)                                     as avg_opponent_pts
    , round(avg(g.point_diff), 1)                                       as avg_point_diff

    -- Tiro y juego
    , round(sum(g.fgm)  / nullif(sum(g.fga), 0)  * 100, 1)              as fg_pct
    , round(sum(g.fg3m) / nullif(sum(g.fg3a), 0) * 100, 1)              as fg3_pct
    , round(sum(g.ftm)  / nullif(sum(g.fta), 0)  * 100, 1)              as ft_pct
    , round(avg(g.reb), 1)                                              as avg_reb
    , round(avg(g.ast), 1)                                              as avg_ast
    , round(avg(g.tov), 1)                                              as avg_tov
from games g
inner join teams t   on g.team_id = t.team_id
inner join seasons s on g.season_id = s.season_id
group by g.team_id, t.team_name, g.season_id, s.season_label