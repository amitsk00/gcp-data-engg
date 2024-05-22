# visitors who bought on a return visit (could have bought on first as well
WITH all_visitor_stats AS (
SELECT
  fullvisitorid, # 741,721 unique visitors
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

SELECT
  COUNT(DISTINCT fullvisitorid) AS total_visitors,
  will_buy_on_return_visit
FROM all_visitor_stats
GROUP BY will_buy_on_return_visit
;




SELECT
  * EXCEPT(fullVisitorId)
FROM

  # features
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1)
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
ORDER BY time_on_site DESC
LIMIT 10;

;

-- model
CREATE OR REPLACE MODEL `ecommerce.classification_model`
OPTIONS
(
model_type='logistic_reg',
labels = ['will_buy_on_return_visit']
)
AS

#standardSQL
SELECT
  * EXCEPT(fullVisitorId)
FROM

  # features
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430') # train on first 9 months
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
;

SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'decent'
    WHEN roc_auc > .6 THEN 'not great'
  ELSE 'poor' END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model,  (

SELECT
  * EXCEPT(fullVisitorId)
FROM

  # features
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630') # eval on 2 months
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)

));

-- feature engineered model
CREATE OR REPLACE MODEL `ecommerce.classification_model_2`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

# add in new features
SELECT * EXCEPT(unique_session_id) FROM (

  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory,

      # geographic
      IFNULL(geoNetwork.country, "") AS country

  FROM `data-to-insights.ecommerce.web_analytics`,
     UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE 1=1
    # only predict for new visits
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430' # train 9 months

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);


-- predict

SELECT
*
FROM
  ml.PREDICT(MODEL `ecommerce.classification_model_2`,
   (

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

  SELECT
      CONCAT(fullvisitorid, '-',CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory,

      # geographic
      IFNULL(geoNetwork.country, "") AS country

  FROM `data-to-insights.ecommerce.web_analytics`,
     UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE
    # only predict for new visits
    totals.newVisits = 1
    AND date BETWEEN '20170701' AND '20170801' # test 1 month

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
)

)

ORDER BY
  predicted_will_buy_on_return_visit DESC;



-- challenge lab


create or replace table  `qwiklabs-gcp-03-88daf24a97ef.taxirides.taxi_training_data_640` 
as

SELECT pickup_datetime, pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude, dropoff_datetime, passenger_count, 
(fare_amount + tolls_amount ) AS fare_amount_873

FROM `qwiklabs-gcp-03-88daf24a97ef.taxirides.historical_taxi_rides_raw` 
where 
trip_distance > 4 
and  fare_amount < 3
and  passenger_count > 4

LIMIT 1000000

;

CREATE OR REPLACE MODEL taxirides.fare_model_948

TRANSFORM(
 * EXCEPT pickup_datetime 
 ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean 
 EXTRACT(DAYOFWEEK FROM pickup_datetime ) as dayOfWeek 
 EXTRACT(HOUR FROM pickup_datetime ) as hourOfDay 

)

OPTIONS(
    input_label_cols=['fare_amount_873'] ,
    model_type = 'linear_reg'
)
AS
select * from  `qwiklabs-gcp-03-88daf24a97ef.taxirides.taxi_training_data_640` ;


SELECT
  SQRT(mean_squared_error) AS rmse
FROM
  ML.EVALUATE(MODEL taxirides.fare_model_948,
    (
    WITH
      taxitrips AS (
      SELECT
        *,
        ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean
      FROM
        `taxirides.taxi_training_data_640` )
      SELECT
        *
      FROM
        taxitrips ))
;



CREATE OR REPLACE TABLE taxirides.2015_fare_amount_predictions
  AS
SELECT * FROM ML.PREDICT(MODEL taxirides.fare_model,(
  SELECT * FROM taxirides.report_prediction_data)
)​
;


-- from web
create or replace table  `qwiklabs-gcp-03-88daf24a97ef.taxirides.taxi_training_data_640` 
as

Select
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
  ( tolls_amount + fare_amount ) AS fare_amount_873                                                                                                                         
FROM
  `taxirides.historical_taxi_rides_raw`
WHERE
  trip_distance > 1
  AND fare_amount >= 2
  AND pickup_longitude > -75
  AND pickup_longitude < -73
  AND dropoff_longitude > -75
  AND dropoff_longitude < -73
  AND pickup_latitude > 40
  AND pickup_latitude < 42
  AND dropoff_latitude > 40
  AND dropoff_latitude < 42
  AND passenger_count > 1
  AND RAND() < 999999 / 1031673361
;

CREATE or REPLACE MODEL
  taxirides.fare_model_948  OPTIONS (model_type='linear_reg',
    labels=['fare_amount_873']) AS
WITH
  taxitrips AS (
  SELECT
    *,
    ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean
  FROM
    `taxirides.taxi_training_data_640` )
  SELECT
    *
  FROM
    taxitrips
;

SELECT
  SQRT(mean_squared_error) AS rmse
FROM
  ML.EVALUATE(MODEL taxirides.fare_model_948,
    (
    WITH
      taxitrips AS (
      SELECT
        *,
        ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean
      FROM
        `taxirides.taxi_training_data_640` )
      SELECT
        *
      FROM
        taxitrips ))
;


create or replace table  `qwiklabs-gcp-03-88daf24a97ef.taxirides.2015_fare_amount_predictions` 
as

SELECT
  *
FROM
  ML.PREDICT(MODEL `taxirides.fare_model_948`,
    (
    WITH
      taxitrips AS (
      SELECT
        *,
        ST_Distance(ST_GeogPoint(pickuplon, pickuplat)   , ST_GeogPoint(dropofflon, dropofflat)) AS    euclidean
      FROM
        `taxirides.report_prediction_data` )
    SELECT
      *
    FROM
      taxitrips ))

    ;





-- Challenge BQ 2

select
sum(cumulative_confirmed) as total_cases_worldwide

from `bigquery-public-data.covid19_open_data.covid19_open_data`
where
  date = '2020-06-10'

;


with deaths_by_states as (
    SELECT subregion1_name as state, sum(cumulative_deceased) as death_count
    FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
    where country_name="United States of America" and date='2020-06-10' and subregion1_name is NOT NULL
    group by subregion1_name
)

select count(*) as count_of_states
from deaths_by_states
where death_count > 250 

;



select
subregion1_name as state ,
sum(cumulative_confirmed) as total_confirmed_cases

from `bigquery-public-data.covid19_open_data.covid19_open_data`
where
  date = '2020-06-10'
  and country_name = 'United States of America'
  -- and cumulative_confirmed > 2500
  and cumulative_confirmed is not null 
  and subregion1_name is not null 

group by  subregion1_name 
having total_confirmed_cases > 2500 
order by total_confirmed_cases desc 


;



select
sum(cumulative_confirmed) as total_confirmed_cases, 
sum(cumulative_deceased) as total_deaths, 
 (sum(cumulative_deceased) / sum(cumulative_confirmed)) * 100 as  case_fatality_ratio

from `bigquery-public-data.covid19_open_data.covid19_open_data`
where
  date between '2020-06-01' and '2020-06-30'
  and country_name = 'Italy'

;



select
date 

from `bigquery-public-data.covid19_open_data.covid19_open_data`
where
  country_name = 'Italy'
  and cumulative_deceased  > 12000

order by date asc 
LIMIT 1 

;


WITH india_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="United States of America"
    AND date between '2020-03-22' and '2020-04-20'
  GROUP BY
    date
  ORDER BY
    date ASC
 )

, india_previous_day_comparison AS
(SELECT
  date as Date ,
  cases as Confirmed_Cases_On_Day ,
  LAG(cases) OVER(ORDER BY date) AS Confirmed_Cases_Previous_Day ,
  ((cases - LAG(cases) OVER(ORDER BY date))/LAG(cases) OVER(ORDER BY date)) AS Percentage_Increase_In_Cases
FROM india_cases_by_date
)

select 
Date , 
Confirmed_Cases_On_Day , 
Confirmed_Cases_Previous_Day , 
Percentage_Increase_In_Cases
from india_previous_day_comparison
-- where  Percentage_Increase_In_Cases = 0.15

;





WITH us_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="United States of America"
    AND date between '2020-03-22' and '2020-04-20'
  GROUP BY
    date
  ORDER BY
    date ASC
 )

, us_previous_day_comparison AS
(SELECT
  date as Date ,
  cases as Confirmed_Cases_On_Day ,
  LAG(cases) OVER(ORDER BY date) AS Confirmed_Cases_Previous_Day ,
  ( (cases - LAG(cases) OVER(ORDER BY date)) / (LAG(cases) OVER(ORDER BY date)) )*100 AS Percentage_Increase_In_Cases
FROM us_cases_by_date
)

select 
Date , 
Confirmed_Cases_On_Day , 
Confirmed_Cases_Previous_Day , 
Percentage_Increase_In_Cases
from us_previous_day_comparison
where  Percentage_Increase_In_Cases > 15

;



with cases_by_country as (
select
country_name as country, 
sum(cumulative_recovered) as recovered_cases, 
sum(cumulative_confirmed) as confirmed_cases
from `bigquery-public-data.covid19_open_data.covid19_open_data`
where
  date = '2020-05-10'
group by country_name
)

, recovery_rate_data as (

select 
country , 
recovered_cases , 
confirmed_cases , 
(recovered_cases * 100)/confirmed_cases as recovery_rate 

from cases_by_country 

)

select 
country , 
recovered_cases , 
confirmed_cases , 
recovery_rate
from recovery_rate_data 
where confirmed_cases > 50000
order by recovery_rate desc 
limit 15 

;





WITH
  france_cases AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS total_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="France"
    AND date IN ('2020-01-24',
      '2020-06-10')
  GROUP BY
    date
  ORDER BY
    date asc )
, summary as (
SELECT
  total_cases AS first_day_cases,
  LEAD(total_cases) over(order by date  ) AS last_day_cases,
  DATE_DIFF(LEAD(date) OVER(ORDER BY date ),date, day) AS days_diff
FROM
  france_cases
LIMIT 1
)


select first_day_cases, last_day_cases, days_diff, power((last_day_cases/first_day_cases),(1/days_diff))-1 as cdgr
from summary

;









-- BQ challenge lab

create or replace table `covid.oxford_policy_tracker`
PARTITION BY date
OPTIONS (
    partition_expiration_days = 1080 )
as 

select * from `bigquery-public-data.covid19_govt_response.oxford_policy_tracker`
where alpha_3_code not in ('GBR','CAN','USA','BRA') 

; 


update `qwiklabs-gcp-01-83cf247f99e0.covid_data.consolidate_covid_tracker_data` S
set 
   S.mobility.avg_retail      = T.avg_retail,
   S.mobility.avg_grocery     = T.avg_grocery,
   S.mobility.avg_parks       = T.avg_parks,
   S.mobility.avg_transit     = T.avg_transit,
   S.mobility.avg_workplace   = T.avg_workplace,
   S.mobility.avg_residential = T.avg_residential
FROM
   ( SELECT country_region, date,
      AVG(retail_and_recreation_percent_change_from_baseline) as avg_retail,
      AVG(grocery_and_pharmacy_percent_change_from_baseline) as avg_grocery,
      AVG(parks_percent_change_from_baseline) as avg_parks,
      AVG(transit_stations_percent_change_from_baseline) as avg_transit,
      AVG( workplaces_percent_change_from_baseline ) as avg_workplace,
      AVG( residential_percent_change_from_baseline) as avg_residential
      FROM `bigquery-public-data.covid19_google_mobility.mobility_report`
      GROUP BY country_region, date
   ) AS T
WHERE
   CONCAT(S.country_name, S.date) = CONCAT(T.country_region, T.date)
   

;


select country_name from `qwiklabs-gcp-01-83cf247f99e0.covid_data.oxford_policy_tracker_worldwide`
where population is null  
UNION ALL
select country_name from `qwiklabs-gcp-01-83cf247f99e0.covid_data.oxford_policy_tracker_worldwide`
where country_area is null  

;



create or replace table covid_data.pop_data_2019
as

select 
country_territory_code ,
pop_data_2019

from `bigquery-public-data.covid19_ecdc.covid_19_geographic_distribution_worldwide`

;



