-- =============================================================================
-- PROJECT 4: YOUTUBE TRENDING VIDEOS - GLOBAL DAILY ANALYSIS
-- =============================================================================
-- Author   : Mochammad Amir Hamzah
-- Database : youtube_data
-- Tool     : MySQL Workbench / MySQL 8.0+
-- =============================================================================
--
-- PROJECT OBJECTIVES
-- =============================================================================
--
-- 1. Preserve and audit the original YouTube trending dataset.
-- 2. Clean and standardize text, numeric, and temporal values.
-- 3. Validate data quality and logical consistency.
-- 4. Remove invalid records that cannot satisfy the analytical grain.
-- 5. Remove duplicate video-date-country observations.
-- 6. Analyze global reach, category performance, engagement, and virality.
-- 7. Engineer analytical features for potential machine-learning use.
-- 8. Create an ML/export-ready dataset.
-- 9. Build a simple star schema for analytical reporting.
--
-- =============================================================================
-- DATA GRAIN
-- =============================================================================
--
-- One row represents:
--
--     One video × one trending date × one country
--
-- Natural key:
--
--     video_id
--     video_trending__date
--     video_trending_country
--
-- =============================================================================
-- DATA PIPELINE
-- =============================================================================
--
-- Original Imported Dataset
--          │
--          ▼
-- youtube_trending_raw
--          │
--          ▼
-- Data Quality Audit
--          │
--          ▼
-- youtube_trending_clean
--          │
--          ▼
-- Validation + Deduplication
--          │
--          ▼
-- youtube_trending
--          │
--          ├──────────────► Exploratory Data Analysis
--          │
--          ├──────────────► Advanced Analytics
--          │
--          ├──────────────► ML / Export Dataset
--          │
--          └──────────────► Star Schema
--
-- =============================================================================
-- IMPORTANT EXECUTION NOTE
-- =============================================================================
--
-- On the FIRST execution:
--
--     1. Import the original dataset as youtube_trending.
--     2. Run this script.
--     3. The script creates youtube_trending_raw as a permanent backup.
--
-- On SUBSEQUENT executions:
--
--     youtube_trending_raw is reused as the stable source.
--
-- Therefore, do NOT drop youtube_trending_raw unless you intentionally want
-- to recreate the raw backup from a new source dataset.
--
-- =============================================================================



-- =============================================================================
-- SECTION 1: DATABASE SETUP
-- =============================================================================

CREATE DATABASE IF NOT EXISTS youtube_data;

USE youtube_data;



-- =============================================================================
-- SECTION 2: PRESERVE ORIGINAL RAW DATA
-- =============================================================================
--
-- The raw table is intentionally preserved.
--
-- This provides a reproducible source for the entire cleaning pipeline.
--
-- =============================================================================


CREATE TABLE IF NOT EXISTS youtube_trending_raw AS
SELECT *
FROM youtube_trending;



-- =============================================================================
-- SECTION 3: RAW DATA PREVIEW AND STRUCTURE
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 3.1 Raw row count
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS total_raw_rows

FROM youtube_trending_raw;



-- -----------------------------------------------------------------------------
-- 3.2 Raw data preview
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_raw

LIMIT 10;



-- -----------------------------------------------------------------------------
-- 3.3 Raw table structure
-- -----------------------------------------------------------------------------

DESCRIBE youtube_trending_raw;



-- =============================================================================
-- SECTION 4: INITIAL DATA QUALITY AUDIT
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4.1 Missing values across important columns
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS total_rows,

    SUM(
        video_id IS NULL
        OR TRIM(video_id) = ''
    ) AS missing_video_id,

    SUM(
        video_title IS NULL
        OR TRIM(video_title) = ''
    ) AS missing_video_title,

    SUM(
        video_view_count IS NULL
        OR TRIM(video_view_count) = ''
        OR TRIM(video_view_count) = '\\N'
    ) AS missing_video_view_count,

    SUM(
        video_like_count IS NULL
        OR TRIM(video_like_count) = ''
        OR TRIM(video_like_count) = '\\N'
    ) AS missing_video_like_count,

    SUM(
        video_comment_count IS NULL
        OR TRIM(video_comment_count) = ''
        OR TRIM(video_comment_count) = '\\N'
    ) AS missing_video_comment_count,

    SUM(
        channel_view_count IS NULL
        OR TRIM(channel_view_count) = ''
        OR TRIM(channel_view_count) = '\\N'
    ) AS missing_channel_view_count,

    SUM(
        channel_subscriber_count IS NULL
        OR TRIM(channel_subscriber_count) = ''
        OR TRIM(channel_subscriber_count) = '\\N'
    ) AS missing_channel_subscriber_count,

    SUM(
        channel_video_count IS NULL
        OR TRIM(channel_video_count) = ''
        OR TRIM(channel_video_count) = '\\N'
    ) AS missing_channel_video_count,

    SUM(
        video_published_at IS NULL
        OR TRIM(video_published_at) = ''
    ) AS missing_video_published_at,

    SUM(
        channel_published_at IS NULL
        OR TRIM(channel_published_at) = ''
    ) AS missing_channel_published_at,

    SUM(
        video_trending__date IS NULL
        OR TRIM(video_trending__date) = ''
    ) AS missing_trending_date,

    SUM(
        video_trending_country IS NULL
        OR TRIM(video_trending_country) = ''
    ) AS missing_trending_country,

    SUM(
        channel_id IS NULL
        OR TRIM(channel_id) = ''
    ) AS missing_channel_id

FROM youtube_trending_raw;



-- -----------------------------------------------------------------------------
-- 4.2 Literal '\N' values
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS rows_with_literal_N_values

FROM youtube_trending_raw

WHERE video_view_count = '\\N'
   OR video_like_count = '\\N'
   OR video_comment_count = '\\N'
   OR channel_view_count = '\\N'
   OR channel_subscriber_count = '\\N'
   OR channel_video_count = '\\N';



-- =============================================================================
-- SECTION 5: CREATE CLEANING TABLE
-- =============================================================================
--
-- The raw table remains untouched.
--
-- All transformations are performed on youtube_trending_clean.
--
-- =============================================================================


DROP TABLE IF EXISTS youtube_trending_clean;

CREATE TABLE youtube_trending_clean AS

SELECT *

FROM youtube_trending_raw;



-- =============================================================================
-- SECTION 6: STANDARDIZE TEXT VALUES
-- =============================================================================


SET SQL_SAFE_UPDATES = 0;



-- -----------------------------------------------------------------------------
-- 6.1 Convert literal '\N' and empty numeric strings to NULL
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET

    video_view_count =
        NULLIF(
            NULLIF(TRIM(video_view_count), '\\N'),
            ''
        ),

    video_like_count =
        NULLIF(
            NULLIF(TRIM(video_like_count), '\\N'),
            ''
        ),

    video_comment_count =
        NULLIF(
            NULLIF(TRIM(video_comment_count), '\\N'),
            ''
        ),

    channel_view_count =
        NULLIF(
            NULLIF(TRIM(channel_view_count), '\\N'),
            ''
        ),

    channel_subscriber_count =
        NULLIF(
            NULLIF(TRIM(channel_subscriber_count), '\\N'),
            ''
        ),

    channel_video_count =
        NULLIF(
            NULLIF(TRIM(channel_video_count), '\\N'),
            ''
        );



-- -----------------------------------------------------------------------------
-- 6.2 Convert empty text values to NULL
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET

    video_id =
        NULLIF(TRIM(video_id), ''),

    video_title =
        NULLIF(TRIM(video_title), ''),

    video_description =
        NULLIF(TRIM(video_description), ''),

    video_default_thumbnail =
        NULLIF(TRIM(video_default_thumbnail), ''),

    video_tags =
        NULLIF(TRIM(video_tags), ''),

    video_trending_country =
        NULLIF(TRIM(video_trending_country), ''),

    channel_id =
        NULLIF(TRIM(channel_id), ''),

    channel_title =
        NULLIF(TRIM(channel_title), ''),

    channel_description =
        NULLIF(TRIM(channel_description), ''),

    video_category_id =
        NULLIF(TRIM(video_category_id), ''),

    channel_custom_url =
        NULLIF(TRIM(channel_custom_url), ''),

    channel_country =
        NULLIF(TRIM(channel_country), ''),

    video_licensed_content =
        NULLIF(TRIM(video_licensed_content), ''),

    video_duration =
        NULLIF(TRIM(video_duration), ''),

    video_definition =
        NULLIF(TRIM(video_definition), '');



-- -----------------------------------------------------------------------------
-- 6.3 Standardize country codes
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET

    video_trending_country =
        CASE
            WHEN video_trending_country IS NOT NULL
            THEN UPPER(TRIM(video_trending_country))
            ELSE NULL
        END,

    channel_country =
        CASE
            WHEN channel_country IS NOT NULL
            THEN UPPER(TRIM(channel_country))
            ELSE NULL
        END;



-- -----------------------------------------------------------------------------
-- 6.4 Standardize category names
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET

    video_category_id =
        CASE
            WHEN video_category_id IS NOT NULL
            THEN TRIM(video_category_id)
            ELSE NULL
        END;



-- -----------------------------------------------------------------------------
-- 6.5 Replace missing descriptive values
-- -----------------------------------------------------------------------------
--
-- These values are used only to distinguish missing descriptive information
-- from empty strings.
--
-- They do not represent actual source values.
--
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET

    video_description =
        COALESCE(
            video_description,
            'No description provided'
        ),

    video_tags =
        COALESCE(
            video_tags,
            'No tags'
        ),

    channel_description =
        COALESCE(
            channel_description,
            'No channel description'
        );


SET SQL_SAFE_UPDATES = 1;



-- =============================================================================
-- SECTION 7: NUMERIC DATA QUALITY AUDIT
-- =============================================================================
--
-- Numeric columns are validated BEFORE their data types are changed.
--
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 7.1 Invalid video views
-- -----------------------------------------------------------------------------

SELECT DISTINCT

    video_view_count

FROM youtube_trending_clean

WHERE video_view_count IS NOT NULL

  AND TRIM(video_view_count)
      NOT REGEXP '^[0-9]+$';



-- -----------------------------------------------------------------------------
-- 7.2 Invalid video likes
-- -----------------------------------------------------------------------------

SELECT DISTINCT

    video_like_count

FROM youtube_trending_clean

WHERE video_like_count IS NOT NULL

  AND TRIM(video_like_count)
      NOT REGEXP '^[0-9]+$';



-- -----------------------------------------------------------------------------
-- 7.3 Invalid video comments
-- -----------------------------------------------------------------------------

SELECT DISTINCT

    video_comment_count

FROM youtube_trending_clean

WHERE video_comment_count IS NOT NULL

  AND TRIM(video_comment_count)
      NOT REGEXP '^[0-9]+$';



-- -----------------------------------------------------------------------------
-- 7.4 Invalid channel views
-- -----------------------------------------------------------------------------

SELECT DISTINCT

    channel_view_count

FROM youtube_trending_clean

WHERE channel_view_count IS NOT NULL

  AND TRIM(channel_view_count)
      NOT REGEXP '^[0-9]+$';



-- -----------------------------------------------------------------------------
-- 7.5 Invalid channel subscribers
-- -----------------------------------------------------------------------------

SELECT DISTINCT

    channel_subscriber_count

FROM youtube_trending_clean

WHERE channel_subscriber_count IS NOT NULL

  AND TRIM(channel_subscriber_count)
      NOT REGEXP '^[0-9]+$';



-- -----------------------------------------------------------------------------
-- 7.6 Invalid channel video counts
-- -----------------------------------------------------------------------------

SELECT DISTINCT

    channel_video_count

FROM youtube_trending_clean

WHERE channel_video_count IS NOT NULL

  AND TRIM(channel_video_count)
      NOT REGEXP '^[0-9]+$';



-- =============================================================================
-- SECTION 8: CONVERT INVALID NUMERIC VALUES TO NULL
-- =============================================================================


SET SQL_SAFE_UPDATES = 0;


UPDATE youtube_trending_clean

SET

    video_view_count =
        CASE

            WHEN video_view_count IS NULL
                THEN NULL

            WHEN TRIM(video_view_count)
                 REGEXP '^[0-9]+$'
                THEN TRIM(video_view_count)

            ELSE NULL

        END,

    video_like_count =
        CASE

            WHEN video_like_count IS NULL
                THEN NULL

            WHEN TRIM(video_like_count)
                 REGEXP '^[0-9]+$'
                THEN TRIM(video_like_count)

            ELSE NULL

        END,

    video_comment_count =
        CASE

            WHEN video_comment_count IS NULL
                THEN NULL

            WHEN TRIM(video_comment_count)
                 REGEXP '^[0-9]+$'
                THEN TRIM(video_comment_count)

            ELSE NULL

        END,

    channel_view_count =
        CASE

            WHEN channel_view_count IS NULL
                THEN NULL

            WHEN TRIM(channel_view_count)
                 REGEXP '^[0-9]+$'
                THEN TRIM(channel_view_count)

            ELSE NULL

        END,

    channel_subscriber_count =
        CASE

            WHEN channel_subscriber_count IS NULL
                THEN NULL

            WHEN TRIM(channel_subscriber_count)
                 REGEXP '^[0-9]+$'
                THEN TRIM(channel_subscriber_count)

            ELSE NULL

        END,

    channel_video_count =
        CASE

            WHEN channel_video_count IS NULL
                THEN NULL

            WHEN TRIM(channel_video_count)
                 REGEXP '^[0-9]+$'
                THEN TRIM(channel_video_count)

            ELSE NULL

        END;


SET SQL_SAFE_UPDATES = 1;



-- =============================================================================
-- SECTION 9: CONVERT NUMERIC DATA TYPES
-- =============================================================================


ALTER TABLE youtube_trending_clean

    MODIFY COLUMN video_view_count BIGINT NULL,

    MODIFY COLUMN video_like_count BIGINT NULL,

    MODIFY COLUMN video_comment_count BIGINT NULL,

    MODIFY COLUMN channel_view_count BIGINT NULL,

    MODIFY COLUMN channel_subscriber_count BIGINT NULL,

    MODIFY COLUMN channel_video_count INT NULL;



-- -----------------------------------------------------------------------------
-- Verify numeric data types
-- -----------------------------------------------------------------------------

DESCRIBE youtube_trending_clean;



-- =============================================================================
-- SECTION 10: NEGATIVE VALUE VALIDATION
-- =============================================================================


SELECT *

FROM youtube_trending_clean

WHERE video_view_count < 0
   OR video_like_count < 0
   OR video_comment_count < 0
   OR channel_view_count < 0
   OR channel_subscriber_count < 0
   OR channel_video_count < 0;



-- -----------------------------------------------------------------------------
-- Convert negative values to NULL
-- -----------------------------------------------------------------------------

SET SQL_SAFE_UPDATES = 0;


UPDATE youtube_trending_clean

SET

    video_view_count =
        CASE
            WHEN video_view_count < 0 THEN NULL
            ELSE video_view_count
        END,

    video_like_count =
        CASE
            WHEN video_like_count < 0 THEN NULL
            ELSE video_like_count
        END,

    video_comment_count =
        CASE
            WHEN video_comment_count < 0 THEN NULL
            ELSE video_comment_count
        END,

    channel_view_count =
        CASE
            WHEN channel_view_count < 0 THEN NULL
            ELSE channel_view_count
        END,

    channel_subscriber_count =
        CASE
            WHEN channel_subscriber_count < 0 THEN NULL
            ELSE channel_subscriber_count
        END,

    channel_video_count =
        CASE
            WHEN channel_video_count < 0 THEN NULL
            ELSE channel_video_count
        END;


SET SQL_SAFE_UPDATES = 1;



-- =============================================================================
-- SECTION 11: DATE/TIME STANDARDIZATION
-- =============================================================================
--
-- Supported source formats:
--
--     YYYY.MM.DD
--     YYYY-MM-DD
--     YYYY-MM-DD HH:MM:SS
--     YYYY-MM-DDTHH:MM:SSZ
--
-- =============================================================================


SET SQL_SAFE_UPDATES = 0;



-- -----------------------------------------------------------------------------
-- 11.1 Standardize trending date
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET video_trending__date =

    CASE

        WHEN video_trending__date IS NULL
            THEN NULL

        WHEN TRIM(video_trending__date) = ''
            THEN NULL

        WHEN TRIM(video_trending__date)
             LIKE '%.%.%'

            THEN STR_TO_DATE(
                TRIM(video_trending__date),
                '%Y.%m.%d'
            )

        WHEN TRIM(video_trending__date)
             LIKE '%T%'

            THEN DATE(
                STR_TO_DATE(
                    LEFT(
                        TRIM(video_trending__date),
                        19
                    ),
                    '%Y-%m-%dT%H:%i:%s'
                )
            )

        ELSE

            STR_TO_DATE(
                LEFT(
                    TRIM(video_trending__date),
                    10
                ),
                '%Y-%m-%d'
            )

    END;



-- -----------------------------------------------------------------------------
-- 11.2 Standardize video publication timestamp
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET video_published_at =

    CASE

        WHEN video_published_at IS NULL
            THEN NULL

        WHEN TRIM(video_published_at) = ''
            THEN NULL

        WHEN TRIM(video_published_at)
             LIKE '%T%'

            THEN STR_TO_DATE(
                LEFT(
                    TRIM(video_published_at),
                    19
                ),
                '%Y-%m-%dT%H:%i:%s'
            )

        ELSE

            STR_TO_DATE(
                LEFT(
                    TRIM(video_published_at),
                    19
                ),
                '%Y-%m-%d %H:%i:%s'
            )

    END;



-- -----------------------------------------------------------------------------
-- 11.3 Standardize channel publication timestamp
-- -----------------------------------------------------------------------------

UPDATE youtube_trending_clean

SET channel_published_at =

    CASE

        WHEN channel_published_at IS NULL
            THEN NULL

        WHEN TRIM(channel_published_at) = ''
            THEN NULL

        WHEN TRIM(channel_published_at)
             LIKE '%T%'

            THEN STR_TO_DATE(
                LEFT(
                    TRIM(channel_published_at),
                    19
                ),
                '%Y-%m-%dT%H:%i:%s'
            )

        ELSE

            STR_TO_DATE(
                LEFT(
                    TRIM(channel_published_at),
                    19
                ),
                '%Y-%m-%d %H:%i:%s'
            )

    END;


SET SQL_SAFE_UPDATES = 1;



-- =============================================================================
-- SECTION 12: CONVERT TEMPORAL DATA TYPES
-- =============================================================================


ALTER TABLE youtube_trending_clean

    MODIFY COLUMN video_trending__date DATE NULL,

    MODIFY COLUMN video_published_at DATETIME NULL,

    MODIFY COLUMN channel_published_at DATETIME NULL;



-- -----------------------------------------------------------------------------
-- Verify temporal data types
-- -----------------------------------------------------------------------------

DESCRIBE youtube_trending_clean;



-- =============================================================================
-- SECTION 13: TEMPORAL VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 13.1 Future video publication dates
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE video_published_at > CURRENT_TIMESTAMP;



-- -----------------------------------------------------------------------------
-- 13.2 Future channel publication dates
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE channel_published_at > CURRENT_TIMESTAMP;



-- -----------------------------------------------------------------------------
-- 13.3 Video published after trending date
-- -----------------------------------------------------------------------------
--
-- These records are audited rather than automatically deleted.
--
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE video_published_at IS NOT NULL

  AND video_trending__date IS NOT NULL

  AND DATE(video_published_at) >
      video_trending__date;



-- -----------------------------------------------------------------------------
-- 13.4 Channel published after video publication
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE channel_published_at IS NOT NULL

  AND video_published_at IS NOT NULL

  AND channel_published_at >
      video_published_at;



-- =============================================================================
-- SECTION 14: YOUTUBE-SPECIFIC LOGICAL VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 14.1 Likes greater than views
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE video_like_count IS NOT NULL

  AND video_view_count IS NOT NULL

  AND video_like_count > video_view_count;



-- -----------------------------------------------------------------------------
-- 14.2 Comments greater than views
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE video_comment_count IS NOT NULL

  AND video_view_count IS NOT NULL

  AND video_comment_count > video_view_count;



-- =============================================================================
-- SECTION 15: ANALYTICAL GRAIN VALIDATION
-- =============================================================================
--
-- Required natural key:
--
--     video_id
--     video_trending__date
--     video_trending_country
--
-- Records missing one of these fields cannot reliably satisfy the intended
-- analytical grain and are excluded from the final analytical table.
--
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 15.1 Count invalid-grain records
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS invalid_grain_rows

FROM youtube_trending_clean

WHERE video_id IS NULL
   OR video_trending__date IS NULL
   OR video_trending_country IS NULL;



-- -----------------------------------------------------------------------------
-- 15.2 Preview invalid-grain records
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_clean

WHERE video_id IS NULL
   OR video_trending__date IS NULL
   OR video_trending_country IS NULL

LIMIT 50;



-- =============================================================================
-- SECTION 16: DUPLICATE DETECTION
-- =============================================================================


WITH ranked_records AS (

    SELECT

        video_id,

        video_trending__date,

        video_trending_country,

        ROW_NUMBER() OVER (

            PARTITION BY

                video_id,
                video_trending__date,
                video_trending_country

            ORDER BY

                (
                    video_view_count IS NOT NULL
                    AND video_like_count IS NOT NULL
                    AND video_comment_count IS NOT NULL
                    AND channel_id IS NOT NULL
                ) DESC,

                video_view_count DESC,

                video_like_count DESC,

                video_comment_count DESC,

                channel_view_count DESC,

                channel_subscriber_count DESC,

                channel_video_count DESC,

                video_published_at DESC,

                channel_published_at DESC

        ) AS row_num

    FROM youtube_trending_clean

    WHERE video_id IS NOT NULL

      AND video_trending__date IS NOT NULL

      AND video_trending_country IS NOT NULL

)

SELECT

    video_id,

    video_trending__date,

    video_trending_country,

    COUNT(*) AS duplicate_count

FROM ranked_records

GROUP BY

    video_id,

    video_trending__date,

    video_trending_country

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;



-- -----------------------------------------------------------------------------
-- 16.1 Total duplicate rows
-- -----------------------------------------------------------------------------

WITH ranked_records AS (

    SELECT

        ROW_NUMBER() OVER (

            PARTITION BY

                video_id,
                video_trending__date,
                video_trending_country

            ORDER BY

                (
                    video_view_count IS NOT NULL
                    AND video_like_count IS NOT NULL
                    AND video_comment_count IS NOT NULL
                    AND channel_id IS NOT NULL
                ) DESC,

                video_view_count DESC,

                video_like_count DESC,

                video_comment_count DESC,

                channel_view_count DESC,

                channel_subscriber_count DESC,

                channel_video_count DESC,

                video_published_at DESC,

                channel_published_at DESC

        ) AS row_num

    FROM youtube_trending_clean

    WHERE video_id IS NOT NULL

      AND video_trending__date IS NOT NULL

      AND video_trending_country IS NOT NULL

)

SELECT

    COUNT(*) AS duplicate_rows

FROM ranked_records

WHERE row_num > 1;



-- =============================================================================
-- SECTION 17: CREATE FINAL DEDUPLICATED DATASET
-- =============================================================================

DROP TABLE IF EXISTS youtube_trending_deduplicated;

CREATE TABLE youtube_trending_deduplicated AS
SELECT
    video_id,
    
    video_published_at,
    
    video_trending__date,
    
    video_trending_country,
    
    channel_id,
    
    video_title,
    
    video_description,
    
    video_default_thumbnail,
    
    video_tags,
    
    channel_title,
    
    channel_description,
    
    channel_published_at,
    
    video_category_id,
    
	video_view_count,
    
    video_like_count,
    
    video_comment_count,
    
    channel_view_count,
    
    channel_subscriber_count,
    
    channel_video_count,
    
    video_licensed_content,
    
    video_duration,
    
    video_definition,
    
    channel_custom_url,
    
    channel_country
    
FROM (
    SELECT

        youtube_trending_clean.*,
        
        ROW_NUMBER() OVER (
            PARTITION BY
                video_id,
                
                video_trending__date,
                
                video_trending_country
                
            ORDER BY
                (
                    video_view_count IS NOT NULL
                    
                    AND video_like_count IS NOT NULL
                    
                    AND video_comment_count IS NOT NULL
                    
                    AND channel_id IS NOT NULL
                    
                ) DESC,
                
                video_view_count DESC,
                
                video_like_count DESC,
                
                video_comment_count DESC,
                
                channel_view_count DESC,
                
                channel_subscriber_count DESC,
                
                channel_video_count DESC,
                
                video_published_at DESC,
                
                channel_published_at DESC
                
        ) AS dedup_rank
        
    FROM youtube_trending_clean
    
    WHERE video_id IS NOT NULL
    
      AND video_trending__date IS NOT NULL
      
      AND video_trending_country IS NOT NULL
      
) AS ranked_records

WHERE dedup_rank = 1;



-- =============================================================================
-- SECTION 18: CREATE FINAL youtube_trending TABLE
-- =============================================================================


DROP TABLE IF EXISTS youtube_trending;


CREATE TABLE youtube_trending AS

SELECT *

FROM youtube_trending_deduplicated;



DROP TABLE youtube_trending_deduplicated;



-- =============================================================================
-- SECTION 19: FINAL TABLE STRUCTURE
-- =============================================================================


DESCRIBE youtube_trending;



-- =============================================================================
-- SECTION 20: FINAL DATA QUALITY SCORECARD
-- =============================================================================


SELECT

    COUNT(*) AS total_rows,

    COUNT(DISTINCT video_id)
        AS unique_videos,

    COUNT(DISTINCT channel_id)
        AS unique_channels,

    COUNT(DISTINCT video_trending_country)
        AS unique_countries,

    COUNT(DISTINCT video_category_id)
        AS unique_categories,

    MIN(video_trending__date)
        AS earliest_trending_date,

    MAX(video_trending__date)
        AS latest_trending_date,

    SUM(video_id IS NULL)
        AS missing_video_id,

    SUM(channel_id IS NULL)
        AS missing_channel_id,

    SUM(video_trending__date IS NULL)
        AS missing_trending_date,

    SUM(video_trending_country IS NULL)
        AS missing_trending_country,

    SUM(video_view_count IS NULL)
        AS missing_views,

    SUM(video_like_count IS NULL)
        AS missing_likes,

    SUM(video_comment_count IS NULL)
        AS missing_comments,

    SUM(channel_view_count IS NULL)
        AS missing_channel_views,

    SUM(channel_subscriber_count IS NULL)
        AS missing_subscribers,

    SUM(channel_video_count IS NULL)
        AS missing_channel_videos

FROM youtube_trending;



-- =============================================================================
-- SECTION 21: FINAL DUPLICATE VALIDATION
-- =============================================================================


SELECT

    video_id,

    video_trending__date,

    video_trending_country,

    COUNT(*) AS duplicate_count

FROM youtube_trending

GROUP BY

    video_id,

    video_trending__date,

    video_trending_country

HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 22: FINAL LOGICAL VALIDATION
-- =============================================================================


SELECT

    SUM(
        video_like_count > video_view_count
    ) AS likes_greater_than_views,

    SUM(
        video_comment_count > video_view_count
    ) AS comments_greater_than_views,

    SUM(
        video_published_at > CURRENT_TIMESTAMP
    ) AS future_video_publications,

    SUM(
        channel_published_at > CURRENT_TIMESTAMP
    ) AS future_channel_publications,

    SUM(

        video_published_at IS NOT NULL

        AND video_trending__date IS NOT NULL

        AND DATE(video_published_at) >
            video_trending__date

    ) AS video_published_after_trending_date,

    SUM(

        channel_published_at IS NOT NULL

        AND video_published_at IS NOT NULL

        AND channel_published_at >
            video_published_at

    ) AS channel_published_after_video

FROM youtube_trending;



-- =============================================================================
-- SECTION 23: FINAL NUMERIC VALIDATION
-- =============================================================================


SELECT

    SUM(video_view_count < 0)
        AS negative_views,

    SUM(video_like_count < 0)
        AS negative_likes,

    SUM(video_comment_count < 0)
        AS negative_comments,

    SUM(channel_view_count < 0)
        AS negative_channel_views,

    SUM(channel_subscriber_count < 0)
        AS negative_subscribers,

    SUM(channel_video_count < 0)
        AS negative_channel_videos

FROM youtube_trending;



-- =============================================================================
-- SECTION 24: FINAL DATA PREVIEW
-- =============================================================================


SELECT

    video_id,

    channel_id,

    video_trending__date,

    video_trending_country,

    video_category_id,

    video_title,

    video_view_count,

    video_like_count,

    video_comment_count,

    channel_view_count,

    channel_subscriber_count,

    channel_video_count,

    video_published_at,

    channel_published_at,

    channel_country

FROM youtube_trending

LIMIT 20;



-- =============================================================================
-- PART B: EXPLORATORY DATA ANALYSIS
-- =============================================================================



-- =============================================================================
-- QUERY 1: GLOBAL VIDEO REACH
-- =============================================================================
--
-- Identifies videos appearing in the largest number of countries.
--
-- =============================================================================


SELECT

    video_id,

    MAX(video_title) AS video_title,

    MAX(channel_title) AS channel_title,

    COUNT(DISTINCT video_trending_country)
        AS countries_trending,

    MAX(video_view_count)
        AS peak_views,

    MAX(video_like_count)
        AS peak_likes

FROM youtube_trending

GROUP BY video_id

ORDER BY

    countries_trending DESC,

    peak_views DESC

LIMIT 10;



-- =============================================================================
-- QUERY 2: CATEGORY PERFORMANCE
-- =============================================================================


SELECT

    video_category_id,

    COUNT(*) AS trending_entries,

    COUNT(DISTINCT video_id)
        AS unique_videos,

    ROUND(
        AVG(video_view_count),
        2
    ) AS average_views,

    ROUND(
        AVG(video_like_count),
        2
    ) AS average_likes,

    ROUND(
        AVG(video_comment_count),
        2
    ) AS average_comments

FROM youtube_trending

GROUP BY video_category_id

ORDER BY average_views DESC;



-- =============================================================================
-- QUERY 3: CATEGORY TRENDING SHARE
-- =============================================================================
--
-- This dataset does not contain revenue.
-- Therefore, category contribution is measured using trending entries.
--
-- =============================================================================


WITH category_stats AS (

    SELECT

        video_category_id,

        COUNT(*) AS trending_entries

    FROM youtube_trending

    GROUP BY video_category_id

)

SELECT

    video_category_id,

    trending_entries,

    ROUND(

        trending_entries
        / NULLIF(
            SUM(trending_entries) OVER (),
            0
        )
        * 100,

        2

    ) AS trending_share_percentage

FROM category_stats

ORDER BY trending_entries DESC;



-- =============================================================================
-- QUERY 4: CATEGORY VIEW DISTRIBUTION
-- =============================================================================


WITH ranked_views AS (

    SELECT

        video_category_id,

        video_view_count,

        ROW_NUMBER() OVER (

            PARTITION BY video_category_id

            ORDER BY video_view_count

        ) AS row_num,

        COUNT(*) OVER (

            PARTITION BY video_category_id

        ) AS category_count

    FROM youtube_trending

    WHERE video_view_count IS NOT NULL

),

category_median AS (

    SELECT

        video_category_id,

        AVG(video_view_count)
            AS median_views

    FROM ranked_views

    WHERE row_num IN (

        FLOOR((category_count + 1) / 2),

        FLOOR((category_count + 2) / 2)

    )

    GROUP BY video_category_id

)

SELECT

    c.video_category_id,

    COUNT(*) AS trending_entries,

    COUNT(DISTINCT c.video_id)
        AS unique_videos,

    ROUND(
        AVG(c.video_view_count),
        2
    ) AS average_views,

    ROUND(
        m.median_views,
        2
    ) AS median_views

FROM youtube_trending AS c

LEFT JOIN category_median AS m

    ON c.video_category_id =
       m.video_category_id

GROUP BY

    c.video_category_id,

    m.median_views

ORDER BY average_views DESC;



-- =============================================================================
-- QUERY 5: ENGAGEMENT PERFORMANCE BY CATEGORY
-- =============================================================================


SELECT

    video_category_id,

    COUNT(DISTINCT video_id)
        AS unique_videos,

    ROUND(

        AVG(

            video_like_count
            / NULLIF(video_view_count, 0)

        ) * 100,

        2

    ) AS average_like_ratio_pct,

    ROUND(

        AVG(

            video_comment_count
            / NULLIF(video_view_count, 0)

        ) * 100,

        2

    ) AS average_comment_ratio_pct,

    ROUND(

        SUM(video_like_count)
        / NULLIF(SUM(video_view_count), 0)
        * 100,

        2

    ) AS weighted_like_ratio_pct,

    ROUND(

        SUM(video_comment_count)
        / NULLIF(SUM(video_view_count), 0)
        * 100,

        2

    ) AS weighted_comment_ratio_pct

FROM youtube_trending

WHERE video_view_count > 0

GROUP BY video_category_id

ORDER BY weighted_like_ratio_pct DESC;



-- =============================================================================
-- QUERY 6: SUBSCRIBER LEVERAGE
-- =============================================================================
--
-- Measures peak video views relative to channel subscriber count.
--
-- =============================================================================


SELECT

    video_id,

    MAX(video_title)
        AS video_title,

    MAX(channel_title)
        AS channel_title,

    channel_subscriber_count
        AS subscribers,

    MAX(video_view_count)
        AS peak_views,

    ROUND(

        MAX(video_view_count)
        / NULLIF(
            channel_subscriber_count,
            0
        ),

        2

    ) AS view_to_subscriber_ratio

FROM youtube_trending

WHERE channel_subscriber_count > 0

GROUP BY

    video_id,

    channel_subscriber_count

HAVING MAX(video_view_count) > 500000

ORDER BY view_to_subscriber_ratio DESC

LIMIT 15;



-- =============================================================================
-- QUERY 7: TITLE LENGTH AND TAG ANALYSIS
-- =============================================================================


SELECT

    video_category_id,

    ROUND(
        AVG(LENGTH(video_title)),
        2
    ) AS average_title_length,

    ROUND(

        AVG(

            CASE

                WHEN video_tags IS NULL
                  OR video_tags = ''
                  OR video_tags = 'No tags'

                THEN 0

                ELSE

                    LENGTH(video_tags)
                    -
                    LENGTH(
                        REPLACE(
                            video_tags,
                            ',',
                            ''
                        )
                    )
                    + 1

            END

        ),

        2

    ) AS average_tag_count,

    ROUND(
        AVG(video_view_count),
        2
    ) AS average_views

FROM youtube_trending

GROUP BY video_category_id

ORDER BY average_views DESC;



-- =============================================================================
-- PART C: ADVANCED ANALYTICS
-- =============================================================================



-- =============================================================================
-- QUERY 8: APPROXIMATE TIME TO FIRST OBSERVED TRENDING
-- =============================================================================
--
-- The dataset records trending dates rather than exact entry timestamps.
-- Therefore, this metric is an approximation.
--
-- =============================================================================


WITH first_trending AS (

    SELECT

        video_id,

        MIN(video_trending__date)
            AS first_trending_date

    FROM youtube_trending

    GROUP BY video_id

),

video_latency AS (

    SELECT

        v.video_id,

        MAX(v.channel_subscriber_count)
            AS channel_subscriber_count,

        DATEDIFF(

            ft.first_trending_date,

            DATE(MIN(v.video_published_at))

        ) AS days_to_first_trending

    FROM youtube_trending AS v

    INNER JOIN first_trending AS ft

        ON v.video_id = ft.video_id

    WHERE v.video_published_at IS NOT NULL

    GROUP BY

        v.video_id,

        ft.first_trending_date

),

channel_tier AS (

    SELECT

        video_id,

        days_to_first_trending,

        CASE

            WHEN channel_subscriber_count >= 1000000
                THEN '1M+ Subscribers'

            WHEN channel_subscriber_count >= 100000
                THEN '100K-1M Subscribers'

            ELSE '<100K Subscribers'

        END AS subscriber_tier

    FROM video_latency

    WHERE days_to_first_trending >= 0

),

ranked_latency AS (

    SELECT

        subscriber_tier,

        video_id,

        days_to_first_trending,

        ROW_NUMBER() OVER (

            PARTITION BY subscriber_tier

            ORDER BY days_to_first_trending

        ) AS row_num,

        COUNT(*) OVER (

            PARTITION BY subscriber_tier

        ) AS total_count

    FROM channel_tier

),

median_latency AS (

    SELECT

        subscriber_tier,

        AVG(days_to_first_trending)
            AS median_days

    FROM ranked_latency

    WHERE row_num IN (

        FLOOR((total_count + 1) / 2),

        FLOOR((total_count + 2) / 2)

    )

    GROUP BY subscriber_tier

)

SELECT

    r.subscriber_tier,

    COUNT(DISTINCT r.video_id)
        AS video_count,

    ROUND(
        AVG(r.days_to_first_trending),
        2
    ) AS average_days_to_trend,

    ROUND(
        m.median_days,
        2
    ) AS median_days_to_trend

FROM ranked_latency AS r

LEFT JOIN median_latency AS m

    ON r.subscriber_tier =
       m.subscriber_tier

GROUP BY

    r.subscriber_tier,

    m.median_days

ORDER BY average_days_to_trend;



-- =============================================================================
-- QUERY 9: GLOBAL VIRALITY FEATURE ENGINEERING
-- =============================================================================
--
-- Target:
--
--     is_global_viral = 1
--     when a video trends in more than 10 countries.
--
-- IMPORTANT:
--
-- country_count is used to construct the target.
-- It must NOT be used as a predictor because doing so would cause
-- target leakage.
--
-- =============================================================================


WITH global_reach AS (

    SELECT

        video_id,

        COUNT(
            DISTINCT video_trending_country
        ) AS country_count

    FROM youtube_trending

    GROUP BY video_id

),

video_features AS (

    SELECT

        video_id,

        MAX(video_category_id)
            AS video_category_id,

        MAX(video_duration)
            AS video_duration,

        MAX(channel_subscriber_count)
            AS channel_subscribers,

        MAX(channel_video_count)
            AS channel_total_videos,

        MAX(video_published_at)
            AS video_published_at

    FROM youtube_trending

    GROUP BY video_id

)

SELECT

    v.video_id,

    v.video_category_id,

    v.video_duration,

    v.channel_subscribers,

    v.channel_total_videos,

    HOUR(v.video_published_at)
        AS publish_hour,

    DAYOFWEEK(v.video_published_at)
        AS publish_day_of_week,

    CASE

        WHEN g.country_count > 10
            THEN 1

        ELSE 0

    END AS is_global_viral

FROM video_features AS v

INNER JOIN global_reach AS g

    ON v.video_id = g.video_id;



-- =============================================================================
-- QUERY 10: ENGAGEMENT ANOMALY DETECTION
-- =============================================================================
--
-- Threshold:
--
--     Views > 100,000
--     Like ratio < 0.1%
--
-- =============================================================================


SELECT

    video_id,

    video_title,

    channel_title,

    video_view_count
        AS views,

    video_like_count
        AS likes,

    video_comment_count
        AS comments,

    ROUND(

        video_like_count
        / NULLIF(video_view_count, 0)
        * 100,

        4

    ) AS like_ratio_percentage,

    'High Views - Very Low Like Ratio'
        AS anomaly_type

FROM youtube_trending

WHERE video_view_count > 100000

  AND video_like_count IS NOT NULL

  AND video_view_count > 0

  AND video_like_count
      / video_view_count < 0.001

ORDER BY video_view_count DESC;



-- =============================================================================
-- QUERY 11: MOST CONSISTENTLY TRENDING VIDEOS
-- =============================================================================


SELECT

    video_id,

    MAX(video_title)
        AS video_title,

    MAX(channel_title)
        AS channel_title,

    COUNT(
        DISTINCT video_trending__date
    ) AS trending_days,

    COUNT(
        DISTINCT video_trending_country
    ) AS countries_reached,

    MAX(video_view_count)
        AS peak_views

FROM youtube_trending

GROUP BY video_id

ORDER BY

    trending_days DESC,

    countries_reached DESC

LIMIT 15;



-- =============================================================================
-- QUERY 12: COUNTRY-LEVEL TRENDING PERFORMANCE
-- =============================================================================


SELECT

    video_trending_country,

    COUNT(*) AS trending_entries,

    COUNT(DISTINCT video_id)
        AS unique_videos,

    COUNT(DISTINCT channel_id)
        AS unique_channels,

    ROUND(
        AVG(video_view_count),
        2
    ) AS average_views,

    ROUND(
        AVG(video_like_count),
        2
    ) AS average_likes

FROM youtube_trending

GROUP BY video_trending_country

ORDER BY trending_entries DESC;



-- =============================================================================
-- PART D: ML / EXPORT-READY DATASET
-- =============================================================================



-- =============================================================================
-- SECTION 25: CREATE youtube_trending_ml
-- =============================================================================
--
-- This table is designed for:
--
--     Python
--     Machine Learning
--     Tableau
--     Power BI
--     CSV export
--
-- Original YouTube IDs are retained.
-- Numeric IDs are provided as additional surrogate identifiers.
--
-- =============================================================================


DROP TABLE IF EXISTS youtube_trending_ml;


CREATE TABLE youtube_trending_ml AS

SELECT

    -- -------------------------------------------------------------------------
    -- Numeric video identifier
    -- -------------------------------------------------------------------------

    DENSE_RANK() OVER (

        ORDER BY video_id

    ) AS video_id_numeric,


    -- -------------------------------------------------------------------------
    -- Numeric channel identifier
    -- -------------------------------------------------------------------------

    CASE

        WHEN channel_id IS NOT NULL

        THEN DENSE_RANK() OVER (
            ORDER BY channel_id
        )

        ELSE NULL

    END AS channel_id_numeric,


    -- -------------------------------------------------------------------------
    -- Original identifiers
    -- -------------------------------------------------------------------------

    video_id,

    channel_id,


    -- -------------------------------------------------------------------------
    -- Trending information
    -- -------------------------------------------------------------------------

    video_trending__date,

    video_trending_country,


    -- -------------------------------------------------------------------------
    -- Category
    -- -------------------------------------------------------------------------

    video_category_id,

 
     -- -------------------------------------------------------------------------
    -- Engagement metrics
    -- -------------------------------------------------------------------------

    video_view_count,

    video_like_count,

    video_comment_count,


    -- -------------------------------------------------------------------------
    -- Channel metrics
    -- -------------------------------------------------------------------------

    channel_view_count,

    channel_subscriber_count,

    channel_video_count,


    -- -------------------------------------------------------------------------
    -- Publication information
    -- -------------------------------------------------------------------------

    video_published_at,

    channel_published_at,

    channel_country,


    -- -------------------------------------------------------------------------
    -- Sanitized video title
    -- -------------------------------------------------------------------------
    --
    -- Double quotes → single quotes
    -- Commas        → spaces
    -- Line breaks   → spaces
    --
    -- Useful for CSV/export workflows.
    --
    -- -------------------------------------------------------------------------

    TRIM(

        REPLACE(

            REPLACE(

                REPLACE(

                    REPLACE(

                        COALESCE(
                            video_title,
                            ''
                        ),

                        '"',
                        "'"

                    ),

                    ',',
                    ' '

                ),

                CHAR(10),
                ' '

            ),

            CHAR(13),
            ' '

        )

    ) AS video_title

FROM youtube_trending;



-- =============================================================================
-- SECTION 26: ML DATASET VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 26.1 Preview ML dataset
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending_ml

LIMIT 20;



-- -----------------------------------------------------------------------------
-- 26.2 Compare row counts
-- -----------------------------------------------------------------------------

SELECT

    (
        SELECT COUNT(*)
        FROM youtube_trending
    ) AS clean_rows,

    (
        SELECT COUNT(*)
        FROM youtube_trending_ml
    ) AS ml_rows;



-- -----------------------------------------------------------------------------
-- 26.3 Validate numeric ID mapping
-- -----------------------------------------------------------------------------

SELECT

    COUNT(DISTINCT video_id)
        AS unique_videos,

    COUNT(DISTINCT video_id_numeric)
        AS unique_video_numeric_ids,

    COUNT(DISTINCT channel_id)
        AS unique_channels,

    COUNT(DISTINCT channel_id_numeric)
        AS unique_channel_numeric_ids

FROM youtube_trending_ml;



-- -----------------------------------------------------------------------------
-- 26.4 Inspect video ID mapping
-- -----------------------------------------------------------------------------

SELECT

    video_id,

    video_id_numeric

FROM youtube_trending_ml

GROUP BY

    video_id,

    video_id_numeric

ORDER BY video_id_numeric

LIMIT 20;



-- -----------------------------------------------------------------------------
-- 26.5 Inspect channel ID mapping
-- -----------------------------------------------------------------------------

SELECT

    channel_id,

    channel_id_numeric

FROM youtube_trending_ml

GROUP BY

    channel_id,

    channel_id_numeric

ORDER BY channel_id_numeric

LIMIT 20;



-- =============================================================================
-- PART E: STAR SCHEMA / DATA WAREHOUSE
-- =============================================================================



-- =============================================================================
-- SECTION 27: RESET ANALYTICAL WAREHOUSE TABLES
-- =============================================================================
--
-- Raw and cleaned datasets are NOT dropped.
--
-- Only analytical warehouse tables are recreated.
--
-- =============================================================================


DROP TABLE IF EXISTS fact_trending_daily;

DROP TABLE IF EXISTS dim_video;

DROP TABLE IF EXISTS dim_channel;

DROP TABLE IF EXISTS dim_date;



-- =============================================================================
-- SECTION 28: DIMENSION - CHANNEL
-- =============================================================================


CREATE TABLE dim_channel AS

WITH ranked_channels AS (

    SELECT

        channel_id,

        channel_title,

        channel_custom_url,

        channel_country,

        channel_published_at,

        channel_subscriber_count
            AS subscriber_count,

        channel_video_count
            AS video_count,

        ROW_NUMBER() OVER (

            PARTITION BY channel_id

            ORDER BY

                video_trending__date DESC,

                channel_subscriber_count DESC,

                channel_video_count DESC

        ) AS row_num

    FROM youtube_trending

    WHERE channel_id IS NOT NULL

)

SELECT

    channel_id,

    channel_title,

    channel_custom_url,

    channel_country,

    channel_published_at,

    subscriber_count,

    video_count

FROM ranked_channels

WHERE row_num = 1;



ALTER TABLE dim_channel

ADD PRIMARY KEY (channel_id);



-- =============================================================================
-- SECTION 29: DIMENSION - VIDEO
-- =============================================================================


CREATE TABLE dim_video AS

WITH ranked_videos AS (

    SELECT

        video_id,

        channel_id,

        video_title,

        video_category_id,

        video_duration,

        video_definition,

        video_licensed_content,

        video_published_at
            AS published_at,

        ROW_NUMBER() OVER (

            PARTITION BY video_id

            ORDER BY

                video_trending__date DESC,

                video_view_count DESC

        ) AS row_num

    FROM youtube_trending

    WHERE video_id IS NOT NULL

)

SELECT

    video_id,

    channel_id,

    video_title,

    video_category_id,

    video_duration,

    video_definition,

    video_licensed_content,

    published_at

FROM ranked_videos

WHERE row_num = 1;



ALTER TABLE dim_video

ADD PRIMARY KEY (video_id);



-- =============================================================================
-- SECTION 30: DIMENSION - DATE
-- =============================================================================


CREATE TABLE dim_date AS

SELECT DISTINCT

    video_trending__date
        AS date_key,

    YEAR(video_trending__date)
        AS year,

    MONTH(video_trending__date)
        AS month,

    MONTHNAME(video_trending__date)
        AS month_name,

    QUARTER(video_trending__date)
        AS quarter,

    DAY(video_trending__date)
        AS day,

    DAYOFWEEK(video_trending__date)
        AS day_of_week,

    DAYNAME(video_trending__date)
        AS day_name,

    WEEK(
        video_trending__date,
        1
    ) AS week_number

FROM youtube_trending

WHERE video_trending__date IS NOT NULL;



ALTER TABLE dim_date

ADD PRIMARY KEY (date_key);



-- =============================================================================
-- SECTION 31: FACT TABLE - DAILY TRENDING METRICS
-- =============================================================================
--
-- FACT TABLE GRAIN:
--
--     One video × one trending date × one country
--
-- =============================================================================


CREATE TABLE fact_trending_daily (

    trending_key BIGINT NOT NULL AUTO_INCREMENT,

    video_id VARCHAR(255) NOT NULL,

    trending_date DATE NOT NULL,

    trending_country VARCHAR(100) NOT NULL,

    view_count BIGINT,

    like_count BIGINT,

    comment_count BIGINT,

    PRIMARY KEY (trending_key),

    UNIQUE KEY uq_video_date_country (

        video_id,

        trending_date,

        trending_country

    )

);



-- -----------------------------------------------------------------------------
-- Populate fact table
-- -----------------------------------------------------------------------------

INSERT INTO fact_trending_daily (

    video_id,

    trending_date,

    trending_country,

    view_count,

    like_count,

    comment_count

)

SELECT

    video_id,

    video_trending__date,

    video_trending_country,

    video_view_count,

    video_like_count,

    video_comment_count

FROM youtube_trending;



-- =============================================================================
-- SECTION 32: FACT TABLE INDEXES
-- =============================================================================


CREATE INDEX idx_fact_video

ON fact_trending_daily(video_id);



CREATE INDEX idx_fact_date

ON fact_trending_daily(trending_date);



CREATE INDEX idx_fact_country

ON fact_trending_daily(trending_country);



-- =============================================================================
-- SECTION 33: STAR SCHEMA VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 33.1 Channel dimension count
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS channel_dimension_rows

FROM dim_channel;



-- -----------------------------------------------------------------------------
-- 33.2 Video dimension count
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS video_dimension_rows

FROM dim_video;



-- -----------------------------------------------------------------------------
-- 33.3 Date dimension count
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS date_dimension_rows

FROM dim_date;



-- -----------------------------------------------------------------------------
-- 33.4 Fact table count
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS fact_table_rows

FROM fact_trending_daily;



-- -----------------------------------------------------------------------------
-- 33.5 Orphan video records
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS orphan_video_records

FROM fact_trending_daily AS f

LEFT JOIN dim_video AS v

    ON f.video_id = v.video_id

WHERE v.video_id IS NULL;



-- -----------------------------------------------------------------------------
-- 33.6 Orphan channel records
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS orphan_channel_records

FROM dim_video AS v

LEFT JOIN dim_channel AS c

    ON v.channel_id = c.channel_id

WHERE v.channel_id IS NOT NULL

  AND c.channel_id IS NULL;



-- -----------------------------------------------------------------------------
-- 33.7 Orphan date records
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS orphan_date_records

FROM fact_trending_daily AS f

LEFT JOIN dim_date AS d

    ON f.trending_date = d.date_key

WHERE d.date_key IS NULL;



-- =============================================================================
-- SECTION 34: FINAL PROJECT REVIEW
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 34.1 Final cleaned dataset preview
-- -----------------------------------------------------------------------------

SELECT *

FROM youtube_trending

LIMIT 20;



-- -----------------------------------------------------------------------------
-- 34.2 Final cleaned dataset structure
-- -----------------------------------------------------------------------------

DESCRIBE youtube_trending;



-- -----------------------------------------------------------------------------
-- 34.3 Final cleaned dataset summary
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS final_rows,

    COUNT(DISTINCT video_id)
        AS unique_videos,

    COUNT(DISTINCT channel_id)
        AS unique_channels,

    COUNT(DISTINCT video_trending_country)
        AS unique_countries,

    COUNT(DISTINCT video_category_id)
        AS unique_categories,

    MIN(video_trending__date)
        AS earliest_trending_date,

    MAX(video_trending__date)
        AS latest_trending_date

FROM youtube_trending;



-- -----------------------------------------------------------------------------
-- 34.4 Final natural-key validation
-- -----------------------------------------------------------------------------

SELECT

    video_id,

    video_trending__date,

    video_trending_country,

    COUNT(*) AS duplicate_count

FROM youtube_trending

GROUP BY

    video_id,

    video_trending__date,

    video_trending_country

HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 35: FINAL TABLE INVENTORY
-- =============================================================================


SELECT

    TABLE_NAME,

    TABLE_ROWS

FROM information_schema.TABLES

WHERE TABLE_SCHEMA = DATABASE()

  AND TABLE_NAME IN (

      'youtube_trending_raw',

      'youtube_trending_clean',

      'youtube_trending',

      'youtube_trending_ml',

      'dim_channel',

      'dim_video',

      'dim_date',

      'fact_trending_daily'

  )

ORDER BY TABLE_NAME;



-- =============================================================================
-- END OF PROJECT 4
-- =============================================================================