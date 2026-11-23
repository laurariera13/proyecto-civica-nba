--Warehouse
use role sysadmin;

create warehouse if not exists WH_CURSO
    warehouse_size = 'XSMALL'     
    auto_suspend   = 60           
    auto_resume    = true         
    initially_suspended = true;

--Creamos database, clonaremos bronze de pre y pro 
create database if not exists DEV_BRONZE_DB;
create database if not exists DEV_SILVER_DB;
create database if not exists DEV_GOLD_DB;

create database if not exists PRO_SILVER_DB;
create database if not exists PRO_GOLD_DB;

create schema if not exists DEV_BRONZE_DB.nba;

--roles
use role securityadmin;

create role if not exists DEV_TRANSFORM_ROLE;     
create role if not exists PRO_TRANSFORM_ROLE;   
create role if not exists REPORTING_ROLE;

    --el administrador puede modificar y ver cualquier cosa
grant role DEV_TRANSFORM_ROLE to role sysadmin;
grant role PRO_TRANSFORM_ROLE to role sysadmin;
grant role REPORTING_ROLE     to role sysadmin;

--asignamos el rol de dev a dev
grant usage on warehouse WH_CURSO to role DEV_TRANSFORM_ROLE;
--en bronze solo lectura
grant usage on database DEV_BRONZE_DB to role DEV_TRANSFORM_ROLE;
grant usage on schema DEV_BRONZE_DB.nba to role DEV_TRANSFORM_ROLE;
grant select on future tables in schema DEV_BRONZE_DB.nba to role DEV_TRANSFORM_ROLE;

grant usage, create schema on database DEV_SILVER_DB to role DEV_TRANSFORM_ROLE;
grant usage, create schema on database DEV_GOLD_DB   to role DEV_TRANSFORM_ROLE;

grant usage on warehouse WH_CURSO to role PRO_TRANSFORM_ROLE;
grant usage, create schema on database PRO_SILVER_DB to role PRO_TRANSFORM_ROLE;
grant usage, create schema on database PRO_GOLD_DB   to role PRO_TRANSFORM_ROLE;

grant usage on warehouse WH_CURSO   to role REPORTING_ROLE;
grant usage on database PRO_GOLD_DB to role REPORTING_ROLE;
grant usage on future schemas in database PRO_GOLD_DB to role REPORTING_ROLE;

grant role DEV_TRANSFORM_ROLE to user "e.laurariera";
grant role PRO_TRANSFORM_ROLE to user "e.laurariera";
grant role REPORTING_ROLE     to user "e.laurariera";

--desactivas lo que pone por defecto snow para no tener permisos de otros roles
use role accountadmin;
alter user "e.laurariera" set default_secondary_roles = ();

