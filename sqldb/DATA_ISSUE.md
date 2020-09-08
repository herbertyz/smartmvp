
INCONSISTENCIES & EDGE CASES
-----------------------------------------------

### Illegal Session ID in Responses data file

Soe5 rows in the `lead_user_responses.csv` file has non-integer session ID. Manual clean up was done on the orignal file. The results was saved to `lead_user_responses_v2.csv` file and used subsequently for importing into database. 

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

Without such clean up, MySQL batch importing `LOAD DATA INFILE 'filename' INTO TABLE ...` command would fail on the file and preventing loading even the good rows.

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

If we convert `lcation` to correct spelling `location`, we might have duplciated rows

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

