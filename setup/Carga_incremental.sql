use role sysadmin;
use warehouse WH_CURSO;
use database DEV_BRONZE_DB;

list @DEV_BRONZE_DB.public.carga_bronze pattern = '.*_historico.csv';

-- 2. Vaciar las 4 tablas. TRUNCATE borra las filas pero mantiene la tabla,
--    sus columnas y sus permisos (el grant "future" ya se aplicó al crearla).
truncate table DEV_BRONZE_DB.nba.game;
truncate table DEV_BRONZE_DB.nba.line_score;
truncate table DEV_BRONZE_DB.nba.game_info;
truncate table DEV_BRONZE_DB.nba.inactive_players;

-- 3. Cargar el histórico

copy into DEV_BRONZE_DB.nba.game (
    season_id, team_id_home, team_abbreviation_home, team_name_home, game_id, game_date, matchup_home, wl_home, min, fgm_home, fga_home, fg_pct_home, fg3m_home, fg3a_home, fg3_pct_home, ftm_home, fta_home, ft_pct_home, oreb_home, dreb_home, reb_home, ast_home, stl_home, blk_home, tov_home, pf_home, pts_home, plus_minus_home, video_available_home, team_id_away, team_abbreviation_away, team_name_away, matchup_away, wl_away, fgm_away, fga_away, fg_pct_away, fg3m_away, fg3a_away, fg3_pct_away, ftm_away, fta_away, ft_pct_away, oreb_away, dreb_away, reb_away, ast_away, stl_away, blk_away, tov_away, pf_away, pts_away, plus_minus_away, video_available_away, season_type,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('game_historico.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.line_score (
    game_date_est, game_sequence, game_id, team_id_home, team_abbreviation_home, team_city_name_home, team_nickname_home, team_wins_losses_home, pts_qtr1_home, pts_qtr2_home, pts_qtr3_home, pts_qtr4_home, pts_ot1_home, pts_ot2_home, pts_ot3_home, pts_ot4_home, pts_ot5_home, pts_ot6_home, pts_ot7_home, pts_ot8_home, pts_ot9_home, pts_ot10_home, pts_home, team_id_away, team_abbreviation_away, team_city_name_away, team_nickname_away, team_wins_losses_away, pts_qtr1_away, pts_qtr2_away, pts_qtr3_away, pts_qtr4_away, pts_ot1_away, pts_ot2_away, pts_ot3_away, pts_ot4_away, pts_ot5_away, pts_ot6_away, pts_ot7_away, pts_ot8_away, pts_ot9_away, pts_ot10_away, pts_away,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('line_score_historico.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.game_info (
    game_id, game_date, attendance, game_time,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('game_info_historico.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.inactive_players (
    game_id, player_id, first_name, last_name, jersey_num, team_id, team_city, team_name, team_abbreviation,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('inactive_players_historico.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

-- 4. Comprobación: filas = esperadas
select 'game' as tabla, count(*) as filas, 64312 as esperadas from DEV_BRONZE_DB.nba.game
union all
select 'line_score' as tabla, count(*) as filas, 56800 as esperadas from DEV_BRONZE_DB.nba.line_score
union all
select 'game_info' as tabla, count(*) as filas, 56800 as esperadas from DEV_BRONZE_DB.nba.game_info
union all
select 'inactive_players' as tabla, count(*) as filas, 101462 as esperadas from DEV_BRONZE_DB.nba.inactive_players
order by tabla;

list @DEV_BRONZE_DB.public.carga_bronze pattern = '.*game_info.*';