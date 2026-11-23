use role sysadmin;
create or replace database PRO_BRONZE_DB clone DEV_BRONZE_DB;

use role securityadmin;

--solo puede leer en bronze
grant usage  on database PRO_BRONZE_DB                    to role PRO_TRANSFORM_ROLE;
grant usage  on schema   PRO_BRONZE_DB.nba                to role PRO_TRANSFORM_ROLE;
grant select on all    tables in schema PRO_BRONZE_DB.nba to role PRO_TRANSFORM_ROLE;
grant select on future tables in schema PRO_BRONZE_DB.nba to role PRO_TRANSFORM_ROLE;

grant usage  on database PRO_BRONZE_DB                    to role PRO_TRANSFORM_ROLE;
grant usage  on schema   PRO_BRONZE_DB.nba                to role PRO_TRANSFORM_ROLE;
grant select on all    tables in schema PRO_BRONZE_DB.nba to role PRO_TRANSFORM_ROLE;

-- Comprobación: mismas filas que en DEV
use role sysadmin;
select 'DEV' as entorno, count(*) as filas_game from DEV_BRONZE_DB.nba.game
union all
select 'PRO', count(*) from PRO_BRONZE_DB.nba.game;