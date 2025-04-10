create database WalMart


-- data imported from the excel into table called walmart
-- call the table
select * from walmart

/*Feature Engineering: This will help use generate some new columns from existing ones.
Add a new column named time_of_day to give insight of sales in the Morning, 
Afternoon and Evening. This will help answer the question on which part of the day most sales are made.
Add a new column named day_name that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri). 
This will help answer the question on which week of the day each branch is busiest.
Add a new column named month_name that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar). 
Help determine which month of the year has the most sales and profit.
*/


-- Performing futures of data
-- Add the time_of_day column
-- Add a new column
ALTER TABLE walmart ADD time_of_day VARCHAR(20);

-- Update the new column based on the time
UPDATE walmart
SET time_of_day = 
    CASE
        WHEN CAST([time] AS TIME) BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN CAST([time] AS TIME) BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END;

-- Optional: To view the result
SELECT [time], time_of_day
FROM walmart;


-- Adding day_name column

alter table walmart add day_name varchar(30);

UPDATE walmart 
SET day_name = DATENAME(WEEKDAY, [Date]);



-- Adding month_name

alter table walmart add month_name varchar(30)

update walmart
set month_name = datename(mm,date)



/*     Generic Question
1) How many unique cities does the data have?
*/
select 
	distinct city
from walmart

--2) In which city is each branch?
select distinct
	city,
	branch
from walmart



/*               Product Analysis          */ 

--How many unique product lines does the data have?
select 
	Product_line,
	count(*) as no_of_productlines
from walmart
group by Product_line


--What is the most common payment method?
WITH payment_rank AS (
    SELECT 
        Payment,
        COUNT(*) AS no_payments,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS payment_rank
    FROM walmart
    GROUP BY Payment
)
SELECT 
		Payment,
		no_payments
FROM payment_rank
WHERE payment_rank = 1;


--What is the most selling product line?
with rankingproductline as (
	select 
		Product_line,
		Count(*) as countofproductline,
		rank() over(order by count(*) desc) as product_rank
	from walmart
	group by Product_line
) 
select	*
from rankingproductline
where product_rank = 1;

--What is the total revenue by month? 
select 
	month_name as month,
	sum(total) as total_revenue
from walmart
group by month_name

--What month had the largest COGS?
select top 1
	month_name as month,
	sum(cogs) as total_cogs
from walmart
group by month_name
order by sum(cogs) desc


--What product line had the largest revenue?
SELECT top 1
    product_line,
    SUM(total) AS total_revenue
FROM walmart
GROUP BY product_line
ORDER BY total_revenue DESC;


--What is the city with the largest revenue?
with cityranking as (

	select 
		city,
		sum(total) as total_revenue,
		rank() over(order by sum(total) desc) as revenue_ranking
	from walmart
	group by city
)
select *
from cityranking
where revenue_ranking = 1;


--What product line had the largest VAT?
with total_vat_ranking as (

	select 
		Product_line,
		sum(total * tax_5 / 100.0) as total_vat,
		rank() over(order by sum(total * tax_5 / 100.0) desc) as vat_ranking
	from walmart
	group by Product_line
)
select *
from total_vat_ranking
where vat_ranking = 1;


--Fetch each product line and add a column to those product line showing "Good", "Bad". 
--Good if its greater than average sales
-- Step: Get overall average quantity and compare per product line
alter table walmart add remark varchar(20)

-- Step 1: Create a CTE with average quantity per product line
WITH avg_quantity_per_line AS (
    SELECT 
        Product_line,
        AVG(Quantity) AS avg_qty
    FROM walmart
    GROUP BY Product_line
),
overall_avg AS (
    SELECT AVG(Quantity) AS overall_avg_qty FROM walmart
)

-- Step 2: Update the remark column based on comparison
UPDATE w
SET w.remark = 
    CASE 
        WHEN a.avg_qty > o.overall_avg_qty THEN 'Good'
        ELSE 'Bad'
    END
FROM walmart w
JOIN avg_quantity_per_line a ON w.Product_line = a.Product_line
CROSS JOIN overall_avg o;


--Which branch sold more products than average product sold?
SELECT 
	branch, 
    SUM(quantity) AS qnty
FROM walmart
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM walmart);


--What is the most common product line by gender?
SELECT
	gender,
    product_line,
    COUNT(gender) AS total_cnt
FROM walmart
GROUP BY gender, product_line
ORDER BY total_cnt DESC;


--What is the average rating of each product line?
select 
	Product_line,
	avg(rating) as avg_rating
from walmart
group by Product_line
order by avg(rating) desc




/*          Sales        */

--Number of sales made in each time of the day per weekday
select 
	time_of_day,
	count(*) as time_of_day_sales
from walmart
group by time_of_day


--Which of the customer types brings the most revenue?
with most_revenue as (

	select 
		customer_type,
		round(sum(total),2) as customer_wise_revenue,
		rank() over(order by sum(total) desc) as revenue_ranking
	from walmart
	group by Customer_type
)
select *
from most_revenue
where revenue_ranking = 1;



--Which city has the largest tax percent/ VAT (Value Added Tax)?
select
	city,
	round(avg(tax_5),2) as avg_tax_vat
from walmart
group by city


--Which customer type pays the most in VAT?
select top 1
	Customer_type,
	round(sum(tax_5),2) as total_tax_added
from walmart
group by Customer_type
order by round(sum(tax_5),2) desc;




/*            Customer       */
--How many unique customer types does the data have?
select distinct
	customer_type
from walmart


--How many unique payment methods does the data have?
select distinct
	payment
from walmart


--What is the most common customer type?
select top 1
	customer_type,
	count(*) as common_cust_type
from walmart
group by Customer_type
order by count(*) desc


--Which customer type buys the most?
select top 1
	customer_type,
	count(*) as most_buy_customer_type
from walmart
group by Customer_type
order by count(*) desc


--What is the gender of most of the customers?
select top 1
	gender,
	count(*) as gender_customers
from walmart
group by gender
order by gender desc


--What is the gender distribution per branch?
select 
	branch,
	gender,
	count(*) branch_wise_gender
from walmart
where branch = 'c'
group by branch, gender
order by count(*) desc

--Which time of the day do customers give most ratings?
select 
	time_of_day,
	avg(rating) as most_rating
from walmart
group by time_of_day
order by avg(rating) desc


--Which time of the day do customers give most ratings per branch?
select
	time_of_day,
	avg(rating) as most_rating
from walmart
where branch ='B'
group by time_of_day

	
SELECT
	day_name,
	AVG(rating) AS avg_rating
FROM walmart
GROUP BY day_name 
ORDER BY avg_rating DESC;


--Which day of the week has the best average ratings per branch?
SELECT 
	day_name,
	COUNT(day_name) total_sales
FROM walmart
WHERE branch = 'C'
GROUP BY day_name
ORDER BY total_sales DESC;