use bank;
-- -------------------------------
-- 	    CORRELATED SUBQUERIES
-- -------------------------------

-- We extracted the results only for those customers whose loan amount was greater than the average. 
-- Here is the self-contained subquery:

select * from bank.loan
where amount > (
  select avg(amount)
  from bank.loan
)
order by amount desc
limit 10;

-- Now we want to find those customers whose loan amounts are greater than the average 
-- but only within the same status group; 
-- ie. we want to find those averages by each group and 
-- simultaneously compare the loan amount of that customer with its status group's average.

select * from bank.loan l1
where amount > (
  select avg(amount)
  from bank.loan l2
  where l1.status = l2.status
)
order by amount desc;

-- --------------------------------
-- 	 			LAG
-- --------------------------------

-- Write a query to find the month on month monthly active users (MAU)
-- Use lag() function to get the active users in the previous month
-- To get this information we will proceed step by step.

-- Step 1: Get the account_id, date, year, month and month_number for every transaction.

create or replace view user_activity as
select account_id, convert(date, date) as Activity_date,
date_format(convert(date,date), '%M') as Activity_Month,
date_format(convert(date,date), '%m') as Activity_Month_number,
date_format(convert(date,date), '%Y') as Activity_year
from bank.trans;

-- Checking the results
select * from bank.user_activity;

-- Step 2: Computing the total number of active users by Year and Month with group by 
-- and sorting according to year and month NUMBER.

select Activity_year, Activity_Month_number, count(account_id) as Active_users from bank.user_activity
group by Activity_year, Activity_Month_number
order by Activity_year asc, Activity_Month_number asc;

-- Step 3: Storing the results on a view for later use.

drop view bank.monthly_active_users;
create view bank.monthly_active_users as
select 
   Activity_year, 
   Activity_Month_number, 
   count(account_id) as Active_users 
from bank.user_activity
group by Activity_year, Activity_Month_number
order by Activity_year asc, Activity_Month_number asc;

-- Checking results
select * from monthly_active_users;

-- Step 4: Compute the difference of active_users between one month and the previous one 
-- for each year using the lag function with lag = 1 (as we want the lag from one previous record)

select 
   Activity_year, 
   Activity_Month_number,
   Active_users, 
   lag(Active_users,1) over (order by Activity_year, Activity_Month_number) as Last_month
from monthly_active_users;

-- Final step: Refining the query. Getting the difference of monthly active_users month to month.

with cte_view as (select 
   Activity_year, 
   Activity_Month_number,
   Active_users, 
   lag(Active_users,1) over (order by Activity_year, Activity_Month_number) as Last_month
from monthly_active_users)
select 
   Activity_year, 
   Activity_Month_number, 
   Active_users, 
   Last_month, 
   (Active_users - Last_month) as Difference 
from cte_view;


-- --------------------------------
-- 			SELF JOINS
-- --------------------------------

-- Number of retained users per month
-- So far we computed the total number of customers, 
-- but we are interested in the UNIQUE customer variation month to month. 
-- In other words, how many which unique customers keep renting from month to month? 
-- (customer_id present in one month and in the next one).


-- Step1: Getting the total number of UNIQUE active customers for each year-month.

select 
   distinct account_id as Active_id, 
   Activity_year, 
   Activity_month, 
   Activity_month_number 
from bank.user_activity;

-- Step 2: Create a view with the previous information

drop view bank.distinct_users;
create view bank.distinct_users as
select 
   distinct account_id as Active_id, 
   Activity_year, 
   Activity_month, 
   Activity_month_number 
from bank.user_activity;

-- Check results
select * from bank.distinct_users;

-- Final step: Do a cross join for the previous view but with the following restrictions:

-- The Active_id MUST exist in the second table
-- The Activity_month should be shifted by one.

select 
   d1.Activity_year,
   d1.Activity_month_number,
   count(distinct d1.Active_id) as Retained_customers
   from bank.distinct_users as d1
join bank.distinct_users as d2
on d1.Active_id = d2.Active_id 
and d2.Activity_month_number = d1.Activity_month_number + 1 
group by d1.Activity_year, d1.Activity_month_number
order by d1.Activity_year, d1.Activity_month_number;

-- Creating a view to store the results of the previous query

drop view if exists bank.retained_customers;
create view bank.retained_customers as 
select 
   d1.Activity_year,
   d1.Activity_month_number,
   count(distinct d1.Active_id) as Retained_customers
   from bank.distinct_users as d1
join bank.distinct_users as d2
on d1.Active_id = d2.Active_id 
and d2.Activity_month_number = d1.Activity_month_number + 1 
group by d1.Activity_year, d1.Activity_month_number
order by d1.Activity_year, d1.Activity_month_number;

-- Checking the final results
select * from bank.retained_customers;


-- SECOND EXAMPLE


-- Compute the change in retained customers from month to month. Again, let's go step by step.

-- Step 1: Checking what we have.

select * from retained_customers;

-- Step 2. Computing the differences between each month and restarted every year.
select 
   Activity_year,
   Activity_month_number,
   Retained_customers, 
   lag(Retained_customers, 1) over(partition by Activity_year) as Lagged
from retained_customers;

-- Final Step: Computing column differrences.
select
	Activity_year,
    Activity_month_number, 
    (Retained_customers-lag(Retained_customers, 1) over(partition by Activity_year)) as Diff
from retained_customers;




