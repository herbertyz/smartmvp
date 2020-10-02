
INCONSISTENCIES & EDGE CASES
-----------------------------------------------

### Illegal Session ID in Responses data file

Some 5 rows in the `lead_user_responses.csv` file has non-integer session ID. Manual clean up was done on the original file. The results was saved to `lead_user_responses_v2.csv` file and used subsequently for importing into database. 

```
$ diff lead_user_responses.csv solution/lead_user_responses_v2.csv
36448,36452c36448,36452
< a1414121,"location","95f7a95efa2808697894eeb4ce20eddc",19
< z1414122,"currentSavings","3",23
< z1414122,"location","6398796f364ce2e7005f31bbd08ba210",20
< z1414123,"currentSavings","3",22
< a1414123,"location","560a6a01a9fce179d1d3a1d8d56758a3",19
---
> 1414121,"location","95f7a95efa2808697894eeb4ce20eddc",19
> 1414122,"currentSavings","3",23
> 1414122,"location","6398796f364ce2e7005f31bbd08ba210",20
> 1414123,"currentSavings","3",22
> 1414123,"location","560a6a01a9fce179d1d3a1d8d56758a3",19
```

Without such clean up, MySQL batch importing `LOAD DATA INFILE 'filename' INTO TABLE ...` command would fail on the file and preventing loading even those good rows.

### Corrupted question_key string in Responses data file

It seems that sometimes `currentSavings` was misspelled as ~~crrentSavings~~ and `location` as ~~lcation~~

```
mysql> select count(1), question_key from lead_user_responses group by question_key;
+----------+----------------+
| count(1) | question_key   |
+----------+----------------+
|    18214 | currentSavings |
|    18226 | location       |
|        9 | lcation        |
|        9 | crrentSavings  |
+----------+----------------+
```

### Potential duplicated answer 

If we convert `lcation` to correct spelling `location`, we might have duplicated rows

```
mysql> select session_id  from lead_user_responses group by session_id having count(1) > 2;
+------------+
| session_id |
+------------+
|    1396393 |
+------------+

mysql> select * from lead_user_responses where session_id in (1396393);
+------------+----------------+----------------------------------+--------------+
| session_id | question_key   | answer_value                     | answer_order |
+------------+----------------+----------------------------------+--------------+
|    1396393 | currentSavings | 2                                |           23 |
|    1396393 | lcation        | 8bd045c0275185605e58d7fec40ecae6 |           20 |
|    1396393 | location       | 8ed045c0275185605e58d7fec40ecae6 |           20 |
+------------+----------------+----------------------------------+--------------+
```

In this example, we would have two rows for location answer. Though they would be the same here, the question lingers what if those rows has different answers.

### Possible invalid or missing session_id 

There are some `session_id` in `lead_user_responses` table which are not defined in `lead_user_sessions` dataset.

```
mysql> select * from lead_user_responses where session_id not in ( select id from lead_user_sessions );
+------------+----------------+----------------------------------+--------------+
| session_id | question_key   | answer_value                     | answer_order |
+------------+----------------+----------------------------------+--------------+
|    1396892 | currentSavings | 0                                |           22 |
|    1396892 | location       | 4ee3f0492290c6f29384ec280a7bd715 |           19 |
|    1396906 | currentSavings | 3                                |           25 |
|    1396906 | location       | 99fc32e3c05e03597a692c4fd9a9d162 |           22 |
|    1396907 | currentSavings | 1                                |           24 |
|    1396907 | location       | 2a384b15e8016b260de6ef70a54dbd22 |           21 |
|    1396923 | currentSavings | 4                                |           24 |
|    1396923 | location       | 3dc5cc06467053d6dfc1e4003741d47c |           21 |
|    1396924 | currentSavings | 3                                |           23 |
|    1396924 | location       | d4636a49d4ce00d4cc3a5392795e7ca6 |           20 |
|   11396893 | location       | 86ecf8e4e588ec1eee86940ebbb300fa |           19 |
|   11396894 | location       | bbd4e463fe0ad675dcb2493d8abd6b0b |           20 |
|   11396895 | location       | 7609cb245858fd9cdafcb5f5e1de6602 |           20 |
|   11396896 | location       | 975ff777e4f3c121942a6b8f51e26e9c |           20 |
|   11396897 | location       | 0e0dd1a59be523f40d48a805d14f1800 |           18 |
+------------+----------------+----------------------------------+--------------+
15 rows in set
```

Some possible causes include:
1. missing data from lead_user_sessions table
1. application error when creating / storing lead_user_responses data



DATA VALIDATION
-----------------------------------------------

With our sample data set, there are at least three broad categories of data validation can be incorporated based on insertion point (i) Raw data at edge device / user entry (ii) Individual record ingestion (iii) Batch processing

### Raw data / user entry 

At the point of data entry (mobile app or web portal), data should be either checked for legality or chosen from a given list. This will avoid illegal date string or type (e.g. misspell "location" as "lcation" ).

Common data wrapper type/library can be developed and share within whole organization, in order to perform data validation and conversion.

In frontend or mobile codebase, common components can be designed and shared by entire team. For example, CurrentSaving seems to be a field defined as several ranges. A common dropdown list or multiple choice list can be defined for such predetermined ranges, and then used wherever needed. This will avoid potential confusion and mistake. 

### Individual record ingestion

When we send data record from web portal or mobile app to backend server / data storage, validation should be done by either backend code or database constraints. 

With database constraints, various data errors could be rejected with corresponding message returned to frontend or mobile app:
1. incorrectly formed data - for example, if we define session id as an integer column in funnel_data database, then 'a1414121' or 'z1414122' will not be accepted
1. any violation of primary key or unique constraint. For instance, we could put a constraint of `UNIQUE(session_id, question_key)` on `lead_user_responses` table
1. any violation of foreign key relationship. For instance, foreign key constrain could be use to avoid previously mentioned invalid or missing session_id in the `lead_user_responses` table.

Alternatively, we could use backend code to validate data, especially when the validation logic is more complex than typical DB level constraints. For example, we can implement in backend code for flagging or rejecting outlier data record, where we can define an outlier as sitting outside of certain multiples of standard deviation.

Backend data validation is typically implemented as part of the data model code. In object oriented paradigm, it could be implemented inside classes (as base class), or mixins (as helper)

### Batch Processing

In an ideal world (i.e. all data are clean and perfect), one might incline to treat batch data merely as a collection of individual records. Batch processing then involves just ingesting records one after another. However, this is usually undesirable for a couple of reasons:
* Data for batch processing are often not perfect. Data error, corruption, duplication, and omission are all possible. Data engineer needs to think ahead of time how to handle such conditions. Rejecting the entire batch due to some errors is usually unacceptable.
* Ingesting one record at a time is also not efficient for disk drive, network and database connection. Relational data might be stored in different files (as in our example, which has pertinent data records spread across 3 CSV files).

Therefore, data engineer often needs to develop additional code for batch ingestion and optimize it for performance. Moreover, it might be desirable to keep track all data associated with a batch job and build capability to reverse a batch ingestion if called, i.e., to remove all data ingested during one batch job.

Batch processing sometimes involves temporarily disabling constraints. A check should be run when all the data is in place and constraints re-enabled.

For data validation, a data engineer might need to develop additional code to detect inconsistency / edge cases, if specific conditions are not already covered by aforementioned data type or data model classes. Such conditions usually describe complex constraints or relationship. One normally implement this type of validation in functions.



