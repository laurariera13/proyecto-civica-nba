with days as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('season_start') ~ "-10-01' as date)",
        end_date="cast('" ~ (var('season_end') + 1) ~ "-07-01' as date)"
    ) }}
)

select
      cast(date_day as date)                  as date_day
    , year(date_day)                          as year
    , quarter(date_day)                       as quarter
    , month(date_day)                         as month
    , monthname(date_day)                     as month_name
    , dayofweekiso(date_day)                  as day_of_week
    , dayname(date_day)                       as day_name
    , dayofweekiso(date_day) in (6, 7)        as is_weekend
from days