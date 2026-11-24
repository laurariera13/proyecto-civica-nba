{#
  generate_schema_name: el schema de la carpeta (+schema) se usa tal cual
  en todos los entornos. Lo que separa DEV de PRO es la base de datos
  (DEV_SILVER_DB / PRO_SILVER_DB), que viene de las variables de entorno.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}