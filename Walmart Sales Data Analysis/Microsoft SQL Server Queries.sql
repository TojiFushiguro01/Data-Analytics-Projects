USE [Data Analysis Database]
GO

SELECT *
FROM [Walmart Clean] 

-- Check Total Record
SELECT COUNT(*) 
FROM [Walmart Clean]

-- Distinct Payment Type
SELECT 
	[Walmart Clean].payment_method,
	COUNT(*) AS total	
FROM [Walmart Clean]
GROUP BY [Walmart Clean].payment_method

-- Maximum Quantity
SELECT MAX([Walmart Clean].quantity) AS max_quantity
FROM [Walmart Clean]

-- Minimum Quantity
SELECT MIN([Walmart Clean].quantity) AS min_quantity
FROM [Walmart Clean]



-- Business Problems
-- Question 1: Find the different payment method, number of transactions and number of qty sold

SELECT 
	[Walmart Clean].payment_method,
	COUNT(*) AS total_payments,
	SUM([Walmart Clean].quantity) AS qty_sold
FROM [Walmart Clean]
GROUP BY [Walmart Clean].payment_method



-- Question 2: Identify the Highest-rated category in each branch. displaying the branch, category, AVG rating

SELECT *
FROM
(SELECT 
		[Walmart Clean].branch,
		[Walmart Clean].category,
		AVG([Walmart Clean].rating) AS avg_rating,
		RANK() OVER(PARTITION BY [Walmart Clean].branch ORDER BY AVG([Walmart Clean].rating) DESC) AS ranks
	FROM [Walmart Clean]
	GROUP BY [Walmart Clean].branch, [Walmart Clean].category
) AS ranked_data
WHERE ranks = 1


-- Question 3: Identify the busiest day for each branch based on the number of transactions

-- Convert the string object to date object
SELECT
	date,
	CONVERT(DATE, date, 3) as converted_date
FROM [Walmart Clean]

-- main query
SELECT *
FROM
(
	SELECT
		branch,
		FORMAT(date, 'dddd') as day_of_month,
		COUNT(*) as no_transactions,
		RANK() OVER(PARTITION BY [Walmart Clean].branch ORDER BY COUNT(*) DESC) AS ranks
	FROM [Walmart Clean]
	GROUP BY branch, FORMAT(date, 'dddd')
) AS Ranked_data
WHERE ranks = 1


-- Question 4: Calculate the total quantity of items sold per payment method. list payment_method and total_quantity

SELECT 
	[Walmart Clean].payment_method,
	SUM([Walmart Clean].quantity) AS qty_sold
FROM [Walmart Clean]
GROUP BY [Walmart Clean].payment_method
ORDER BY 2 DESC


-- Question 5: Determine the average, minimum, and maximum rating of category for each city. list the city, avg_rating, min_rating and max_rating

SELECT 
	city,
	category,
	AVG(rating) AS avg_rating,
	MIN(rating) AS min_rating,
	MAX(rating) AS max_rating
FROM [Walmart Clean]
GROUP BY city, category


-- Question 6: Calculate the Total profit for each category by considering total_profit as (unit_price * quantity * profit_margin). List category and total_profit, ordered from highest to lowest profit.

SELECT
	category,
	SUM(total) AS total_revenue,
	SUM(total * (DATEDIFF(SECOND, 0, profit_margin) / 3600.0)) As total_profit
FROM [Walmart Clean]
GROUP BY category


-- Question 7: Determine the most common payment method for each branch. Display branch and the preferred payment method

WITH cte AS (
	SELECT 
		branch,
		payment_method, 
		COUNT(*) AS total_transactions,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as ranks 
	FROM [Walmart Clean]
	GROUP BY branch, payment_method
) 
SELECT *
FROM cte
WHERE ranks = 1


-- Question 8: Categorize sales into 3 group MORNING, AFTERNOON, EVENING. Find out which of the shift and number of invoices

-- Convert time in the right format
SELECT	
	branch,
	CONVERT(VARCHAR(8), CAST(time AS TIME), 108) AS trimmed_time,
	CASE 
		WHEN DATEPART(HOUR, time) < 12 THEN 'Morning'
		WHEN DATEPART(HOUR, time) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END day_time,
	COUNT(*)
FROM [Walmart Clean]
GROUP BY 1, 2
ORDER BY 1, 3 DESC


-- Question 9: Identify 5 branch with highest decrease rate in revenue compare to last year (current year 2023 and last year 2022)

-- rdr == last_rev - curr_rev/ last_rev * 100

-- 2022 sales
WITH 
revenue_2022
AS 
(
SELECT 
	branch,
	SUM(total) as revenue
FROM [Walmart Clean]
WHERE YEAR(date) = 2022
GROUP BY branch
),

-- 2023 sales
revenue_2023
AS 
(
SELECT 
	branch,
	SUM(total) as revenue
FROM [Walmart Clean]
WHERE YEAR(date) = 2023
GROUP BY branch
)

SELECT TOP 5
	ls.branch,
	ls.revenue as revenue_2022,
	cs.revenue as revenue_2023,
	((ls.revenue - cs.revenue) * 100.0) / ls.revenue AS rev_dec_ratio 
FROM revenue_2022 as ls
JOIN 
revenue_2023 as cs
ON ls.branch = cs.branch
WHERE ls.revenue > cs.revenue
ORDER BY 4 DESC
