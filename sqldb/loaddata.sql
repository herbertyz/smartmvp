-- LOAD DATA LOCAL INFILE 'lead_users.csv' 

LOAD DATA INFILE '/docker-entrypoint-initdb.d/lead_users.csv' 
INTO TABLE lead_users 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/docker-entrypoint-initdb.d/lead_user_sessions.csv' 
INTO TABLE lead_user_sessions 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- NOTE: lead_user_responses_v2.csv is a copy of lead_user_responses.csv 
--       with 5 record changed to fix some error in ID field, see detail below
LOAD DATA INFILE '/docker-entrypoint-initdb.d/lead_user_responses_v2.csv' 
INTO TABLE lead_user_responses
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- $ diff lead_user_responses.csv solution/lead_user_responses_v2.csv
-- 36448,36452c36448,36452
-- < a1414121,"location","95f7a95efa2808697894eeb4ce20eddc",19
-- < z1414122,"currentSavings","3",23
-- < z1414122,"location","6398796f364ce2e7005f31bbd08ba210",20
-- < z1414123,"currentSavings","3",22
-- < a1414123,"location","560a6a01a9fce179d1d3a1d8d56758a3",19
-- ---
-- > 1414121,"location","95f7a95efa2808697894eeb4ce20eddc",19
-- > 1414122,"currentSavings","3",23
-- > 1414122,"location","6398796f364ce2e7005f31bbd08ba210",20
-- > 1414123,"currentSavings","3",22
-- > 1414123,"location","560a6a01a9fce179d1d3a1d8d56758a3",19