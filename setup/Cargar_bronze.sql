use role sysadmin;
use warehouse WH_CURSO;
use database DEV_BRONZE_DB;

--como leer csv
create or replace file format DEV_BRONZE_DB.public.csv_bronze
    type = 'csv'
    field_delimiter = ','
    skip_header = 1                       -- la primera línea es la cabecera
    field_optionally_enclosed_by = '"'    -- hay textos con comas: "Abdelnaby, Alaa"
    empty_field_as_null = true            -- campo vacío -> NULL
    error_on_column_count_mismatch = true -- si una fila no tiene las columnas esperadas, falla
    encoding = 'UTF8';

--creamos carpeta donde vamos a subir los ficheros antes de cargarlos a las tablas
create stage if not exists DEV_BRONZE_DB.public.carga_bronze
    file_format = DEV_BRONZE_DB.public.csv_bronze
    comment = 'CSV del dataset NBA';

--game: un partido por fila
create or replace table DEV_BRONZE_DB.nba.game (
      season_id                           varchar
    , team_id_home                        varchar
    , team_abbreviation_home              varchar
    , team_name_home                      varchar
    , game_id                             varchar
    , game_date                           varchar
    , matchup_home                        varchar
    , wl_home                             varchar
    , min                                 varchar
    , fgm_home                            varchar
    , fga_home                            varchar
    , fg_pct_home                         varchar
    , fg3m_home                           varchar
    , fg3a_home                           varchar
    , fg3_pct_home                        varchar
    , ftm_home                            varchar
    , fta_home                            varchar
    , ft_pct_home                         varchar
    , oreb_home                           varchar
    , dreb_home                           varchar
    , reb_home                            varchar
    , ast_home                            varchar
    , stl_home                            varchar
    , blk_home                            varchar
    , tov_home                            varchar
    , pf_home                             varchar
    , pts_home                            varchar
    , plus_minus_home                     varchar
    , video_available_home                varchar
    , team_id_away                        varchar
    , team_abbreviation_away              varchar
    , team_name_away                      varchar
    , matchup_away                        varchar
    , wl_away                             varchar
    , fgm_away                            varchar
    , fga_away                            varchar
    , fg_pct_away                         varchar
    , fg3m_away                           varchar
    , fg3a_away                           varchar
    , fg3_pct_away                        varchar
    , ftm_away                            varchar
    , fta_away                            varchar
    , ft_pct_away                         varchar
    , oreb_away                           varchar
    , dreb_away                           varchar
    , reb_away                            varchar
    , ast_away                            varchar
    , stl_away                            varchar
    , blk_away                            varchar
    , tov_away                            varchar
    , pf_away                             varchar
    , pts_away                            varchar
    , plus_minus_away                     varchar
    , video_available_away                varchar
    , season_type                         varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

--line_score: puntos por cuarto
create or replace table DEV_BRONZE_DB.nba.line_score (
      game_date_est                       varchar
    , game_sequence                       varchar
    , game_id                             varchar
    , team_id_home                        varchar
    , team_abbreviation_home              varchar
    , team_city_name_home                 varchar
    , team_nickname_home                  varchar
    , team_wins_losses_home               varchar
    , pts_qtr1_home                       varchar
    , pts_qtr2_home                       varchar
    , pts_qtr3_home                       varchar
    , pts_qtr4_home                       varchar
    , pts_ot1_home                        varchar
    , pts_ot2_home                        varchar
    , pts_ot3_home                        varchar
    , pts_ot4_home                        varchar
    , pts_ot5_home                        varchar
    , pts_ot6_home                        varchar
    , pts_ot7_home                        varchar
    , pts_ot8_home                        varchar
    , pts_ot9_home                        varchar
    , pts_ot10_home                       varchar
    , pts_home                            varchar
    , team_id_away                        varchar
    , team_abbreviation_away              varchar
    , team_city_name_away                 varchar
    , team_nickname_away                  varchar
    , team_wins_losses_away               varchar
    , pts_qtr1_away                       varchar
    , pts_qtr2_away                       varchar
    , pts_qtr3_away                       varchar
    , pts_qtr4_away                       varchar
    , pts_ot1_away                        varchar
    , pts_ot2_away                        varchar
    , pts_ot3_away                        varchar
    , pts_ot4_away                        varchar
    , pts_ot5_away                        varchar
    , pts_ot6_away                        varchar
    , pts_ot7_away                        varchar
    , pts_ot8_away                        varchar
    , pts_ot9_away                        varchar
    , pts_ot10_away                       varchar
    , pts_away                            varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

--game_info: asistencia y duracion
create or replace table DEV_BRONZE_DB.nba.game_info (
      game_id                             varchar
    , game_date                           varchar
    , attendance                          varchar
    , game_time                           varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

--game_summary: estado del partido y cadena TV
create or replace table DEV_BRONZE_DB.nba.game_summary (
      game_date_est                       varchar
    , game_sequence                       varchar
    , game_id                             varchar
    , game_status_id                      varchar
    , game_status_text                    varchar
    , gamecode                            varchar
    , home_team_id                        varchar
    , visitor_team_id                     varchar
    , season                              varchar
    , live_period                         varchar
    , live_pc_time                        varchar
    , natl_tv_broadcaster_abbreviation    varchar
    , live_period_time_bcast              varchar
    , wh_status                           varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

--team: los 30 equipos actuales
create or replace table DEV_BRONZE_DB.nba.team (
      id                                  varchar
    , full_name                           varchar
    , abbreviation                        varchar
    , nickname                            varchar
    , city                                varchar
    , state                               varchar
    , year_founded                        varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

---- team_details: Pabellón, aforo y datos de cada equipo (faltan 5 equipos en origen)
create or replace table DEV_BRONZE_DB.nba.team_details (
      team_id                             varchar
    , abbreviation                        varchar
    , nickname                            varchar
    , yearfounded                         varchar
    , city                                varchar
    , arena                               varchar
    , arenacapacity                       varchar
    , owner                               varchar
    , generalmanager                      varchar
    , headcoach                           varchar
    , dleagueaffiliation                  varchar
    , facebook                            varchar
    , instagram                           varchar
    , twitter                             varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

---- team_history: Ciudades y nombres históricos de cada equipo
create or replace table DEV_BRONZE_DB.nba.team_history (
      team_id                             varchar
    , city                                varchar
    , nickname                            varchar
    , year_founded                        varchar
    , year_active_till                    varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

---- inactive_players: Jugadores inactivos (de baja) en cada partido.
create or replace table DEV_BRONZE_DB.nba.inactive_players (
      game_id                             varchar
    , player_id                           varchar
    , first_name                          varchar
    , last_name                           varchar
    , jersey_num                          varchar
    , team_id                             varchar
    , team_city                           varchar
    , team_name                           varchar
    , team_abbreviation                   varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

---- common_player_info: Ficha de cada jugador
create or replace table DEV_BRONZE_DB.nba.common_player_info (
      person_id                           varchar
    , first_name                          varchar
    , last_name                           varchar
    , display_first_last                  varchar
    , display_last_comma_first            varchar
    , display_fi_last                     varchar
    , player_slug                         varchar
    , birthdate                           varchar
    , school                              varchar
    , country                             varchar
    , last_affiliation                    varchar
    , height                              varchar
    , weight                              varchar
    , season_exp                          varchar
    , jersey                              varchar
    , position                            varchar
    , rosterstatus                        varchar
    , games_played_current_season_flag    varchar
    , team_id                             varchar
    , team_name                           varchar
    , team_abbreviation                   varchar
    , team_code                           varchar
    , team_city                           varchar
    , playercode                          varchar
    , from_year                           varchar
    , to_year                             varchar
    , dleague_flag                        varchar
    , nba_flag                            varchar
    , games_played_flag                   varchar
    , draft_year                          varchar
    , draft_round                         varchar
    , draft_number                        varchar
    , greatest_75_flag                    varchar
    , _source_file                        varchar
    , _source_row                         number
    , _loaded_at                          timestamp_ltz default current_timestamp()
);

list @DEV_BRONZE_DB.public.carga_bronze;

-- Ahora las cargamos
copy into DEV_BRONZE_DB.nba.game (
    season_id, team_id_home, team_abbreviation_home, team_name_home, game_id, game_date, matchup_home, wl_home, min, fgm_home, fga_home, fg_pct_home, fg3m_home, fg3a_home, fg3_pct_home, ftm_home, fta_home, ft_pct_home, oreb_home, dreb_home, reb_home, ast_home, stl_home, blk_home, tov_home, pf_home, pts_home, plus_minus_home, video_available_home, team_id_away, team_abbreviation_away, team_name_away, matchup_away, wl_away, fgm_away, fga_away, fg_pct_away, fg3m_away, fg3a_away, fg3_pct_away, ftm_away, fta_away, ft_pct_away, oreb_away, dreb_away, reb_away, ast_away, stl_away, blk_away, tov_away, pf_away, pts_away, plus_minus_away, video_available_away, season_type,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('game.csv')
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
files = ('line_score.csv')
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
files = ('game_info.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.game_summary (
    game_date_est, game_sequence, game_id, game_status_id, game_status_text, gamecode, home_team_id, visitor_team_id, season, live_period, live_pc_time, natl_tv_broadcaster_abbreviation, live_period_time_bcast, wh_status,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('game_summary.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.team (
    id, full_name, abbreviation, nickname, city, state, year_founded,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('team.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');


copy into DEV_BRONZE_DB.nba.team_details (
    team_id, abbreviation, nickname, yearfounded, city, arena, arenacapacity, owner, generalmanager, headcoach, dleagueaffiliation, facebook, instagram, twitter,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('team_details.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.team_history (
    team_id, city, nickname, year_founded, year_active_till,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('team_history.csv')
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
files = ('inactive_players.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.nba.common_player_info (
    person_id, first_name, last_name, display_first_last, display_last_comma_first, display_fi_last, player_slug, birthdate, school, country, last_affiliation, height, weight, season_exp, jersey, position, rosterstatus, games_played_current_season_flag, team_id, team_name, team_abbreviation, team_code, team_city, playercode, from_year, to_year, dleague_flag, nba_flag, games_played_flag, draft_year, draft_round, draft_number, greatest_75_flag,
    _source_file, _source_row
)
from (
    select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33,
           metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.public.carga_bronze
)
files = ('common_player_info.csv')
file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

select 'game' as tabla, count(*) as filas, 65698 as esperadas from DEV_BRONZE_DB.nba.game
union all
select 'line_score' as tabla, count(*) as filas, 58053 as esperadas from DEV_BRONZE_DB.nba.line_score
union all
select 'game_info' as tabla, count(*) as filas, 58053 as esperadas from DEV_BRONZE_DB.nba.game_info
union all
select 'game_summary' as tabla, count(*) as filas, 58110 as esperadas from DEV_BRONZE_DB.nba.game_summary
union all
select 'team' as tabla, count(*) as filas, 30 as esperadas from DEV_BRONZE_DB.nba.team
union all
select 'team_details' as tabla, count(*) as filas, 25 as esperadas from DEV_BRONZE_DB.nba.team_details
union all
select 'team_history' as tabla, count(*) as filas, 52 as esperadas from DEV_BRONZE_DB.nba.team_history
union all
select 'inactive_players' as tabla, count(*) as filas, 110191 as esperadas from DEV_BRONZE_DB.nba.inactive_players
union all
select 'common_player_info' as tabla, count(*) as filas, 4171 as esperadas from DEV_BRONZE_DB.nba.common_player_info
order by tabla;



