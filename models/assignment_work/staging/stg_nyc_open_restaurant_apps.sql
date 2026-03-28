-- Clean and standardize NYC Open Restaurant Applications data
-- One row per restaurant application

WITH source AS (
    SELECT * FROM {{ source('raw_restaurants', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            objectid,
            zip,
            borough,
            latitude,
            longitude,
            time_of_submission
        ),

        -- Identifier
        CAST(objectid AS STRING) AS application_id,

        -- Location cleaning
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip,

        -- Standardize borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE objectid IS NOT NULL

    -- Deduplicate on objectid
    QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned