/* ===========================================================================
BIKESTORE SALES & CUSTOMER BEHAVIOR ANALYSIS
Author: [Your Name]
Tools Used: MySQL, CTEs, Window Functions, Joins, Aggregations
===========================================================================
*/
use bikestore;
select * from order_items,orders,products
limit 2;

show tables;
SELECT * FROM INFORMATION_SCHEMA.TABLES;

select p.product_id, product_name, oi.list_price from order_items oi
join products p on oi.product_id = p.product_id
where oi.list_price > 3000;

select concat(first_name," ", last_name), 
email from staffs;
select first_name ||' ' || last_name as full_name,
 email from staffs;
 
 -- 2. Staff List (Standardized formatting)
SELECT 
    first_name || ' ' || last_name AS full_name, -- Standard SQL pipe concat
    email
FROM staffs;

select store_name, state from stores
where state != 'NY';

SELECT 
    product_name, 
    list_price
FROM products
WHERE list_price > 3000
ORDER BY list_price DESC;

SELECT order_id, sum((list_price*quantity)*(1-discount)) as total_revenue from order_items
group by order_id
order by total_revenue desc;

select count(distinct product_id) from products;

select max(list_price) as highest_price, min(list_price) as cheapest_price from products; 

select customer_id, count(distinct order_id) as total_order from orders
group by customer_id
having total_order >2;

select product_id, sum(quantity) as total_qty from stocks
group by product_id
having total_qty < 10;

select category_id, avg(list_price) as avg_price from products
group by category_id
having total_price > 2000;

select o.order_id,o.order_date,c.customer_id,c.first_name,c.last_name from orders o
join customers c on o.customer_id = c.customer_id;

select b.brand_name, p.product_name from products p
join brands b using (brand_id)
where b.brand_name = 'Trek';

select * from order_items oi
left join products p on p.product_id = oi.product_id;

select p.product_id, p.product_name from products p
left join order_items oi on p.product_id = oi.product_id
where oi.order_id is null;

select product_id, list_price from products
where list_price > (select avg(list_price) from products);

with StaffOrderCounts as (select staff_id,count(order_id) as order_count from orders
group by staff_id)
select st.staff_id,st.first_name, st.last_name, sto.order_count from staffs st
join StaffOrderCounts sto using (staff_id);

select * FROM stores
where store_id in(
select store_id from stocks
group by store_id
HAVING sum(quantity) > 4500);

with status as (select order_id, order_status,
case when order_status = '1' then "pending"
when order_status = '2' then "processing"
when order_status = '3' then "rejecting"
else "completed" 
end as "status_description"
from orders)
select status_description, count(*) from status
group by status_description ;


select order_id, order_status,
case when order_status = '1' then "pending"
when order_status = '2' then "processing"
when order_status = '3' then "rejecting"
else "completed" 
end as "status_description"
from orders;

select store_id,product_id, quantity,
case when quantity = 0 then "out of stock"
when quantity between 1 and 10 then "low stock"
else "in stock"
end as "stock_description"
from stocks;

select store_name, state,
case when state = "NY" THEN "EAST"
WHEN state = "CA" THEN "WEST"
ELSE "SOUTH" END AS "region" from stores;

select total_order from(
select count(order_id) as total_order from orders
where year(order_date) = 2017
) as tt;

select count(order_id) as total_order from orders
where year(order_date) = 2017;

select order_id, order_date,shipped_date,
datediff(shipped_Date, order_date) as day_to_ship
 from orders
 where datediff(shipped_Date, order_date) >=3;
 
 select year(order_date) as order_year, month(order_date) as order_month, count(*) as total_order from orders
 group by order_year, order_month;
 
select product_name, category_id, list_price,
rank() over (partition by category_id order by list_price) as rank_of_product
from products;

with rank_pro as ( select product_name, category_id, list_price,
rank() over (partition by category_id order by list_price) as rank_products
from products)
select product_name, category_id, list_price, rank_products from rank_pro
where rank_products in (1,2,3);

select order_id, customer_id, order_date,
lag(order_date) over(partition by customer_id order by customer_id) as previous_order
 from orders;
 
 -- 1. Contact List with Aliasing and Schema
SELECT 
    first_name, 
    last_name, 
    COALESCE(phone, 'Unknown') AS phone_contact -- Using single quotes
FROM sales.customers;

-- 2. Handling the "Not Shipped Yet" logic
-- We swap NULL shipped_date for CURRENT_DATE to calculate current delay
SELECT 
    order_id, 
    required_date, 
    COALESCE(shipped_date, CURRENT_DATE) AS effective_shipped_date,
    DATEDIFF(COALESCE(shipped_date, CURRENT_DATE), required_date) AS days_late
FROM orders
WHERE DATEDIFF(COALESCE(shipped_date, CURRENT_DATE), required_date) > 0;

-- 3. Division Safety (Advanced Logic)
-- Calculating "Average Price Paid" but ensuring we don't divide by zero quantity
SELECT 
    order_id, 
    (list_price * quantity) / NULLIF(quantity, 0) AS safe_unit_price
FROM order_items;
 
 with storiesmetrics as (select s.store_name, c,
 count(distinct order_id) as total_order from orders o
 join order_items oi using (order_id)
 join stores s using (store_id)
 where order_date between '2017-01-01' and '2017-12-31'
 group by s.store_name)
 select store_name, total_price, total_order,
 rank()over(order by total_price desc) as rank_value
 from storiesmetrics
 where total_order > 10
 order by rank_value ;
 
 with brandmetrics as (select b.brand_id,b.brand_name,p.category_id, p.product_name, sum(list_price) as total_price
 from products p
 join brands b on b.brand_id = p.brand_id
 group by b.brand_id,b.brand_name,p.category_id,p.product_name)
 select * from (
 select brand_name, category_id, product_name,total_price,
 rank() over( partition by category_id order by total_price desc) as rank_brand from brandmetrics
 where brand_name in ('Trek' , 'Surly') 
 ) as tt
 where rank_brand <=2
 order by brand_name, rank_brand;
 
 WITH ProductRankings AS (
    SELECT 
        c.category_name,
        p.product_name,
        p.list_price,
        b.brand_name,
        -- We partition by category to get the top items in each group
        row_number() OVER (
            PARTITION BY c.category_name 
            ORDER BY p.list_price DESC
        ) AS price_rank
    FROM products p
    JOIN brands b ON p.brand_id = b.brand_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE b.brand_name IN ('Trek', 'Surly')
)
SELECT 
    category_name, 
    product_name, 
    brand_name,
    list_price
FROM ProductRankings
WHERE price_rank <= 2
ORDER BY category_name, price_rank;
 
 WITH ProductRankings AS (
    SELECT 
        c.category_name,
        p.product_name,
        p.list_price,
        b.brand_name,
        -- ROW_NUMBER forces a unique rank even if prices are tied
        ROW_NUMBER() OVER (
            PARTITION BY c.category_name ,b.brand_name
            ORDER BY p.list_price DESC, p.product_name ASC -- Tie-breaker
        ) AS unique_rank
    FROM products p
    JOIN brands b ON p.brand_id = b.brand_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE b.brand_name IN ('Trek', 'Surly')
)
SELECT 
    category_name, 
    product_name, 
    brand_name,
    list_price,
    unique_rank
FROM ProductRankings
WHERE unique_rank <= 2
ORDER BY category_name, brand_name,unique_rank;


with staff_rank as (select st.store_name, concat(sta.first_name," ", sta.last_name) as full_name,
sum((list_price*quantity)*(1-discount)) as total_revenue,
count(distinct o.order_id) as total_orders from stores st
join staffs sta using(store_id)
join orders o using (staff_id)
join order_items oi using (order_id)
group by st.store_name,full_name)
select * from (select store_name, full_name, total_revenue,total_orders,
dense_rank() over(partition by store_name order by total_revenue desc, total_orders desc) rank_staff from staff_rank) tt
where rank_staff=1
order by store_name asc;

WITH total_spend as (SELECT c.customer_id, concat(c.first_name,'  ', c.last_name) as full_name, 
sum((list_price*quantity)*(1-discount)) as total_spend
from customers c 
join orders o on o.customer_id = c.customer_id
join order_items oi on oi.order_id = o.order_id
group by c.customer_id, full_name 
having sum((list_price*quantity)*(1-discount)) > 5000),
order_date as (
SELECT customer_id,order_id,order_date, 
lag(order_date) over (partition by customer_id order by order_date) as previous_order_date,
row_number()over(partition by customer_id order by order_date desc) as rn from orders )
select t.customer_id, o.order_id,t.total_spend,o.order_date as lates_orderdate,
o.previous_order_date,
datediff( order_date,previous_order_date) as diffrence from total_spend t
join order_date o on o.customer_id = t.customer_id
where rn=1;

select o.order_date, s.store_id, count(distinct o.order_id) as total_order,
sum((oi.list_price*oi.quantity)*(1-discount)) as total_revenue,
sum(
   sum((oi.list_price*oi.quantity)*(1-discount))) 
   over(order by order_date) as running_total,
sum(
    count(distinct o.order_id)) over(order by order_date) as running_total_order from order_items oi 
join orders o on o.order_id = oi.order_id
join stores s on s.store_id = o.store_id
where s.store_id =1
GROUP BY o.order_date, s.store_id
order by order_date;


with daily_sales as (select o.order_date, s.store_id, count(distinct o.order_id) as total_order,
sum((oi.list_price*oi.quantity)*(1-discount)) as total_revenue
 from order_items oi 
join orders o on o.order_id = oi.order_id
join stores s on s.store_id = o.store_id
where s.store_id =1
GROUP BY o.order_date, s.store_id)
select *, 
sum(total_revenue) over(order by order_date) as running_total_revenue,
sum(total_order) over (order by order_date) as running_total_order
from daily_sales
order by order_date;


with daily_sales as (select o.order_date, s.store_id, count(distinct o.order_id) as total_order,
sum((oi.list_price*oi.quantity)*(1-discount)) as total_revenue
 from order_items oi 
join orders o on o.order_id = oi.order_id
join stores s on s.store_id = o.store_id
where s.store_id =1
GROUP BY o.order_date, s.store_id)
select *,
sum(total_revenue) over ( partition by year(order_date), month(order_date) order by order_date) as running_total_order_month,
sum(total_revenue) over (partition by year(order_date), quarter(order_date) order by order_date) as running_total_quoter,
sum(total_revenue) over (partition by year(order_Date) order by order_date) as running_total_year,
sum(total_order) over (order by order_date) as running_total_order
from daily_sales;

WITH Customer_Jan as (select distinct customer_id from orders
where order_date >= '2017-01-01' AND order_date < '2017-02-01'),
Customer_Feb as ( select distinct customer_id from orders
where order_date >= '2017-02-01' AND order_date < '2017-03-01')
select cj.customer_id from Customer_Jan cj
join Customer_Feb cf on cf.customer_id = cj.customer_id;

WITH CustomerBirth AS (
    -- Step 1: Find the "Birth Date" (First Order) for every customer
    SELECT 
        customer_id, 
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
)
SELECT 
    o.customer_id,
    o.order_id,
    cb.first_order_date,
    o.order_date,
    -- MySQL Month Difference Logic:
    -- (Year diff * 12) + Month diff
    ((YEAR(o.order_date) - YEAR(cb.first_order_date)) * 12) + 
    (MONTH(o.order_date) - MONTH(cb.first_order_date)) AS month_number,
    
    -- Step 3: Get the revenue for this specific order
    SUM(oi.list_price * oi.quantity * (1 - oi.discount)) AS order_revenue
FROM orders o
JOIN CustomerBirth cb ON o.customer_id = cb.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 
    o.customer_id, 
    o.order_id, 
    cb.first_order_date, 
    o.order_date
ORDER BY o.customer_id, o.order_date;

