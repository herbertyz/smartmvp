
-- ---------------------------------------------------------------------------------------------------------
-- Note: it is possible to create the requested view without intermediate table (as in following statement)
--       However, each query in such view is expensive in execution time (about 2 minutes on my Dev iMac)
-- ---------------------------------------------------------------------------------------------------------
-- CREATE OR REPLACE VIEW lead_view AS
--     SELECT u.id as user_id, u.email, u.phone,
--         s.time_completed, s.ab_version, s.utm_campaign, s.utm_source, 
--         MAX(IF(r.question_key = 'currentSavings', r.answer_value, NULL)) AS current_savings,
--         MAX(IF(r.question_key = 'location', r.answer_value, NULL)) AS location
--     FROM  lead_users AS u 
--         JOIN lead_user_sessions AS s ON s.user_id = u.id
--         JOIN lead_user_responses as r on r.session_id = s.id 
--     GROUP BY r.session_id;


-- ---------------------------------------------------------------------------------------------------------
-- Note: as a result of above experient, following pivoted table is created in lieu of original response table
-- ---------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS `temp_pivoted_answers`;

CREATE TABLE `temp_pivoted_answers` (
  `session_id` bigint(20) unsigned NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `current_savings` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- these INSERT or UPDATE statements are 100 times faster than abovementioned GROUP BY aggregate
--     they takes less than 1 second each on my Dev iMac
INSERT INTO temp_pivoted_answers (session_id, location) 
    SELECT session_id, CONVERT(answer_value, CHAR)
    FROM lead_user_responses WHERE question_key = 'location'
    ON DUPLICATE KEY UPDATE location= CONVERT(answer_value, CHAR);

INSERT INTO temp_pivoted_answers (session_id, current_savings) 
    SELECT session_id, CONVERT(answer_value, SIGNED INTEGER)
    FROM lead_user_responses WHERE question_key = 'currentSavings'
    ON DUPLICATE KEY UPDATE current_savings= CONVERT(answer_value, SIGNED INTEGER);

-- query on the VIEW is also lightening fast
CREATE OR REPLACE VIEW lead_view AS
    SELECT IFNULL(u.id, -1) as user_id, 
        IFNULL(u.email,'') as user_email, 
        IFNULL(u.phone,'') as user_phone,
        s.time_completed as time_completed, 
        IFNULL(s.ab_version,'') as ab_version,
        IFNULL(s.utm_campaign,'') as utm_campaign,
        IFNULL(s.utm_source,'') as utm_source,
        IFNULL(resp.current_savings, -999999999) as current_savings,
        IFNULL(resp.location, '') as location
    FROM  lead_users AS u 
        RIGHT JOIN lead_user_sessions AS s ON s.user_id = u.id
        LEFT JOIN temp_pivoted_answers as resp on resp.session_id = s.id;

-- ---------------------------------------------------------------------------------------------------------
-- following are just some examples to query on the `lead_view`
-- ---------------------------------------------------------------------------------------------------------
-- mysql> select min(time_completed ) from lead_view;
-- mysql> select max(time_completed ) from lead_view;
-- mysql> select * from lead_view where DATE(time_completed ) = '2019-02-03' limit 20;