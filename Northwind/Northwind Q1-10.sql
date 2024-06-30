/*
Q1. What is the total revenue amount for the second half of 1997 (January 1st 1997 to June 30th 1997)? 
(Discount is on a percentage basis, e.g. 0.15 means 15% off)
*/
SELECT SUM(unit_price*quantity*(1-discount)) AS total_revenue
FROM order_details od
LEFT JOIN orders o ON od.order_id = o.order_id 
WHERE order_date Between '1997-01-01' AND '1997-06-30';

/*
Q2. What are the top 5 product that got ordered the most in the Beverages category? 
Show the product name and the number of orders.
*/
SELECT p.product_name,p.product_id,COUNT(DISTINCT od.order_id)AS num_orders
FROM products p 
LEFT JOIN order_details od ON p.product_id=od.product_id
LEFT JOIN categories c ON p.category_id=c.category_id
WHERE c.category_name='Beverages'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

/*
Q3. What are the top 5 product category that are sold with the highest discount on average? 
(Using simple average would be fine)
*/
SELECT c.category_name,c.category_id,ROUND(CAST(AVG(discount)AS NUMERIC),3) AS avg_discount 
FROM categories c
LEFT JOIN products p ON c.category_id= p.category_id
LEFT JOIN order_details od ON p.product_id=od.product_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

/*
Q4. Northwind wants to learn a bit more about how popular each supplier's goods are. 
They plan to learn about how much volume each supplier's goods were sold to determine the future negotiations with them about pricing. 
They have classified the popularity of the supplier's goods as such:

-If the total order quantity of the supplier's goods is more than or equal to 3000, the supplier would be classified as 'Highly Popular'
-If the total order quantity of the supplier's goods is more than 1500 but less than 3000, the supplier would be classified as 'Adequately Popular'
-If the total order quantity of the supplier's goods is less than or equal to 1500, the supplier would be classified as 'Not Popular'

Please create a view that shows the average sales revenue for each popularity classification.
*/
-- NEED: JOIN THREE TABLES SUPPLIERS, PRODUCTS AND ORDER _DETAILS
--CASE WHEN NEEDED IN SEGENTATION
-- SELECT SEGMENTATION,AVG(REV)FROM THOSE TRHEE JOINED TABLE

WITH CTE AS(
SELECT s.supplier_id,s.company_name,SUM(od.quantity)AS total_quantities,
	CASE WHEN SUM (od.quantity)>3000 THEN 'Highly Popular'
		 WHEN SUM (od.quantity)>1500 AND SUM(od.quantity)<3000 THEN 'Adequately Popular'
		 ELSE 'Not Popluar'
		 END AS poplularity
	,SUM(od.unit_price*od.quantity*(1-od.discount)) AS total_revenue
FROM order_details od
LEFT JOIN products p ON od.product_id=p.product_id
LEFT JOIN suppliers s ON p.supplier_id=s.supplier_id
GROUP BY 1,2
)
SELECT poplularity,ROUND(CAST(AVG(total_revenue) AS NUMERIC),3)AS avg_total_revenue
FROM CTE
GROUP BY 1
ORDER BY 2;



/*
Q5. What is the top 3 most popular product category 
in the country that contributes to the most amount of revenue?
*/
--caculate level: order details
--aggregation level: product category
--condition level: country
--ranking level: top 3 from product catgeory

WITH CountryRevenue AS (
    SELECT cust.country,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM order_details od
    LEFT JOIN products p ON od.product_id = p.product_id
    LEFT JOIN orders o ON od.order_id = o.order_id
    LEFT JOIN customers cust ON o.customer_id = cust.customer_id
    GROUP BY cust.country
    ORDER BY 2 DESC
    LIMIT 1
),RankedCategories AS (
    SELECT cr.country,c.category_name,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS category_revenue,
        RANK() OVER (ORDER BY SUM(od.unit_price * od.quantity * (1 - od.discount)) DESC) AS category_revenue_ranking
    FROM CountryRevenue cr
    LEFT JOIN customers cust ON cr.country = cust.country
    LEFT JOIN orders o ON cust.customer_id = o.customer_id
    LEFT JOIN order_details od ON o.order_id = od.order_id
    LEFT JOIN products p ON od.product_id = p.product_id
    LEFT JOIN categories c ON p.category_id = c.category_id
    GROUP BY cr.country, c.category_name
)
SELECT *
FROM RankedCategories
WHERE category_revenue_ranking <= 3;

/*
Q6. Who is the customer that orders the most from Northwind? How much revenue they contributed?
*/
--***
SELECT o.customer_id 
	,ROUND(CAST(SUM(od.unit_price*od.quantity*(1-od.discount))AS NUMERIC),3) AS total_revenue
	, RANK() OVER(ORDER BY SUM((1 - od.discount) * od.unit_price * od.quantity) DESC) AS ranking
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


/*
Q7. For the same customer from the last question, 
create a view that shows the 3-month 
moving average total amount under each product category.
*/

--caculate level: NA
--aggregation level: category
--condition level: 3 month 
--ranking level: NA
CREATE VIEW QUICK_3_month_moving_avg AS
WITH CTE AS(--total amount
SELECT o.customer_id,c.category_name, DATE_TRUNC('month', o.order_date) AS order_month,
	SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_amount
FROM orders o 
LEFT JOIN order_details od ON o.order_id = od.order_id
LEFT JOIN products p ON od.product_id = p.product_id
LEFT JOIN categories c ON p.category_id = c.category_id
WHERE o.customer_id = 'QUICK'-- answer from Q6
GROUP BY 1,2,3	
)
SELECT customer_id,order_month,total_amount,category_name,
	 AVG(total_amount) OVER (PARTITION BY customer_id,category_name ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_amount
FROM CTE
ORDER BY 2 DESC;


/*
Q8. For the same customer, 
what proportion of revenue does the customer 
contribute to the total revenue in each product category?
*/
--caculate level: total_revenue
--aggregation level: category
--condition level: country
--ranking level: top 3 from product catgeory
WITH TotalCategoryRevenue AS (
    SELECT p.category_id,c.category_name,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM order_details od
    LEFT JOIN products p ON od.product_id = p.product_id
    LEFT JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.category_id, c.category_name
)
SELECT customer_id,p.category_id,c.category_name,total_revenue,
	SUM(od.unit_price * od.quantity * (1 - od.discount)) AS customer_revenue,
	ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount))/total_revenue * 100 AS NUMERIC),2)AS porportion_of_total_sales
FROM order_details od
	LEFT JOIN orders o ON od.order_id= o.order_id
    LEFT JOIN products p ON od.product_id = p.product_id
    LEFT JOIN categories c ON p.category_id = c.category_id
	LEFT JOIN TotalCategoryRevenue tcr ON c.category_id = tcr.category_id
WHERE o.customer_id ='QUICK'
GROUP BY 1,2,3,4
ORDER BY 6 DESC;

/*
Q9.Find the employee who has processed the most orders in Northwind. 
For this employee, 
1. list the total number of orders they processed
2. the total revenue generated from those orders.
*/

WITH EmployeeOrderCount AS (
    SELECT o.employee_id,e.first_name,e.last_name,
        COUNT(o.order_id) AS total_orders,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN employees e ON o.employee_id = e.employee_id
    GROUP BY o.employee_id, e.first_name, e.last_name
)
SELECT *
FROM EmployeeOrderCount
ORDER BY total_orders DESC
LIMIT 1;

/*
Q10. Determine the average number of orders per customer for each country. 
For each country, also find the total revenue generated from those orders.
*/
WITH CustomerOrderCount AS (
    SELECT 
        cust.country,cust.customer_id,
        COUNT(o.order_id) AS num_orders,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM customers cust
    JOIN orders o ON cust.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY cust.country, cust.customer_id
)
SELECT country,
        ROUND(AVG(num_orders),3) AS avg_orders_per_customer,
        ROUND(SUM(total_revenue)) AS total_revenue
    FROM CustomerOrderCount
    GROUP BY country
ORDER BY avg_orders_per_customer DESC;
