# 3.07 Activity 1

-- Keep working on the `bank` database.

USE bank;

-- Modify the previous query to obtain the percentage of variation in the number of users compared with previous month.

-- sql
-- the previous query:

create or replace view user_activity as
select account_id, convert(date, date) as Activity_date,
date_format(convert(date, date), '%M') as activity_month,
date_format(convert(date, date), '%m') as activity_month_number,
date_format(convert(date, date), '%Y') as activity_year
from bank.trans;

select * from user_activity;

create or replace view monthly_active_user AS
SELECT Activity_year, Activity_month_number, COUNT(Account_id) AS Active_users
FROM user_activity
GROUP BY Activity_year, Activity_month_number
ORDER BY COUNT(Account_id);

SELECT * FROM monthly_active_user;


with cte_activity as (
  select Active_users, lag(Active_users,1) over (partition by Activity_year) as last_month, Activity_year, Activity_month_number
  from monthly_active_user
)
select Activity_year, Activity_month_number, ROUND((((Active_users / last_month) -  1)*100), 2) AS porc_var  from cte_activity
where last_month is not null;


# 3.07 Activity 2

-- Modify the previous queries to list the customers lost last month.

with cte_activity_lost as (
  select Active_users, lag(Active_users,1) over (partition by Activity_year order by Activity_month_number) as last_month, Activity_year, Activity_month_number
  from monthly_active_user
)
select Activity_year, Activity_month_number, (Active_users - last_month) AS Var  
from cte_activity_lost
where (Active_users - last_month) <= 0;

# 3.07 Activity 3

-- Use a similar approach to get total monthly transaction per account and the difference with the previous month.

create or replace view trans_table as
select account_id, amount, convert(date, date) as Trans_date,
date_format(convert(date, date), '%M') as activity_month,
date_format(convert(date, date), '%m') as activity_month_number,
date_format(convert(date, date), '%Y') as activity_year
from bank.trans;

SELECT * FROM trans_table;

create or replace view monthly_trans AS
SELECT account_id, activity_month, activity_year, ROUND(SUM(amount), 2)
FROM trans_table
GROUP BY account_id, activity_month, activity_year
ORDER BY activity_year, activity_month;

SELECT * FROM monthly_trans;

