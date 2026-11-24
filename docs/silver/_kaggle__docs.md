{% docs is_inferred %}
Indica si la fila se ha deducido de otra tabla porque faltaba en la suya.

| is_inferred | Significado |
|-------------|-------------|
| false | Viene en la tabla de origen |
| true  | No venía: se ha creado a partir de los partidos o de las bajas para que ningún id apunte a una fila inexistente |
{% enddocs %}

{% docs season_type %}
Tipo de temporada, sacado del primer dígito de season_id.

| Dígito | season_type |
|--------|-------------|
| 1 | Pre Season |
| 2 | Regular Season |
| 3 | All Star |
| 4 | Playoffs |
{% enddocs %}

{% docs period_number %}
Periodo del partido: 1 a 4 son los cuartos y 5 a 14 las prórrogas 1 a 10.
Las prórrogas que no se jugaron no tienen fila.
{% enddocs %}
