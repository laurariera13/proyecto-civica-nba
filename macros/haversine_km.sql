{#
  haversine_km: distancia en km entre dos puntos (latitud, longitud)
  sobre la Tierra (radio medio 6.371 km). Es la distancia en línea recta
  "por el aire": la que recorre un avión entre dos ciudades.
  Uso: {{ haversine_km('lat1', 'lon1', 'lat2', 'lon2') }}
#}
{% macro haversine_km(lat1, lon1, lat2, lon2) -%}
    2 * 6371 * asin(sqrt(
          power(sin(radians({{ lat2 }} - {{ lat1 }}) / 2), 2)
        + cos(radians({{ lat1 }})) * cos(radians({{ lat2 }}))
        * power(sin(radians({{ lon2 }} - {{ lon1 }}) / 2), 2)
    ))
{%- endmacro %}