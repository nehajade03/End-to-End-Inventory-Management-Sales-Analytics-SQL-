CREATE DATABASE inventory_management;
USE inventory_management;

-- ✅ Step 2: Create Tables

-- 1. Suppliers Table

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100),
    contact_name VARCHAR(100),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50)
);

-- 2. Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    description TEXT,
    reorder_level INT,
    supplier_id INT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

-- 3. Inventory Table
CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT,
    quantity_in_stock INT,
    last_stocked DATE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 4. Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    product_id INT,
    quantity_ordered INT,
    order_date DATE,
    status VARCHAR(20),
    customer_id INT,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);



UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%Y-%m-%d');



-- 🔸 Remove Duplicate Products ---
 
 Delete from orders
Where product_id Not In(
select product_id 
from(select product_id,
row_number() over (partition by product_name, category order by product_id)
As rn
From products
) as sub
 where rn=1);
 
 Delete  from products
 where product_id Not in(
 select product_id 
 from(select product_id,
 row_number() over (partition by product_name, category order by product_id)
 As rn
 From products
 )
 as sub
 where rn=1);
 
 
Delete  from inventory
 where inventory_id  Not in(
 select inventory_id 
 from(select inventory_id ,
 row_number() over (partition by inventory_id order by inventory_id)
 As rn
 From inventory)
 as sub
 where rn=1);
 
 
 Delete from suppliers
 where supplier_id  Not in(
 select supplier_id 
 from(select supplier_id  ,
 row_number() over (partition by supplier_name order by supplier_id )
 As rn
 From suppliers)
 as sub
 where rn=1);
 
 
 ----- Handle Nulls - Update with Default Values -----
 UPDATE products SET price = 0 WHERE price IS NULL;
 UPDATE products SET reorder_level = 10 WHERE reorder_level IS NULL;
UPDATE suppliers SET contact_name = 'Unknown' WHERE contact_name IS NULL;
UPDATE suppliers SET phone = 'N/A' WHERE phone IS NULL;


-- ✅ Step 5: Exploratory Data Analysis (EDA)
--- summary of product per category
select category,
count(*) as Total_Products from
products
group by category;

-- Total Suppliers by Country
Select (country) , count(*) As Total_Suppliers from suppliers
Group by country;

-- ✅ Step 6: Business Queries / KPI Analysis
-- 1. Total Orders Per Product

select 
p.product_name, 
count(o.order_id) As Total_Orders
from products p
left join orders o on  p.product_id = o.product_id
Group by p.product_name;

-- 2. Inventory status (low stock alert)
select p.product_name, i.quantity_in_stock, p.reorder_level,
case when COALESCE(i.quantity_in_stock,0) < p.reorder_level then 'Reorder Needed'
else 'Sufficient'
End As Stock_Status
from inventory i
Right join products p on i.product_id = p.product_id ;


-- 3. Monthly sales trend
select Month(order_date) As order_month, sum(quantity_ordered) AS total_quantity
from orders 
Group by month(order_date)
 order by order_month;

-- 4. Revenue generated per product
select p.product_name, Round(sum(o.quantity_ordered* p.price),2) As Total_Revenue
From orders o
left Join Products p on o.product_id = p.product_id
where o.status = 'Delivered'
Group By p.product_name
Order by Total_Revenue Desc ;

-- 6. Top 5 customers by spending
select customer_id, Sum(quantity_ordered*p.price) As total_Spent
from orders o
left Join products p on o.product_id = p.product_id
Group by customer_id
order by Total_Spent Desc
Limit 5;

-- 7. Product performance summary
SELECT
    p.product_name,
    COUNT(DISTINCT o.order_id) AS total_orders,           
    SUM(o.quantity_ordered) AS total_ordered,
    ROUND(SUM(o.quantity_ordered * p.price), 2) AS revenue, 
    COALESCE(i.total_stock, 0) AS quantity_in_stock,       
    p.reorder_level,
    CASE 
        WHEN COALESCE(i.total_stock, 0) < p.reorder_level THEN 'Reorder Needed'
        ELSE 'Stock Sufficient'
    END AS stock_status
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
LEFT JOIN (
    SELECT product_id, SUM(quantity_in_stock) AS total_stock
    FROM inventory
    GROUP BY product_id
) i ON p.product_id = i.product_id
GROUP BY p.product_name, i.total_stock, p.reorder_level
ORDER BY p.product_name;

-- ✅ Step 7: Additional Insights
-- 8. Out of Stock Products
select p.product_name
from products p
left join inventory i on p.product_id = i.product_id
where i.quantity_in_stock = 0 or i.quantity_in_stock is Null ;


-- 9. Daily Order Summary
Select order_date , Count(*) as total_orders, sum(quantity_ordered) As Total_items
from orders
Group by order_date
order by order_date desc;

-- 10. Most Ordered Products (Top 5)
select p.product_name, sum(o.quantity_ordered) As total_quantity
from orders o
Join products p on o.product_id = p.product_id
group by p.product_name
order by total_quantity desc
limit 5 ;

-- 11. Average Monthly Orders

Select Month(order_date) As Month, Round(Avg(quantity_ordered),0) As avg_order_quantity
from orders
Group by month(order_date)
order by month;

-- 12. Highest Revenue Products (Top 5)
Select p.product_name, Round(Sum(o.quantity_ordered*p.price),2) As Total_Revenue
From products p
Join orders o On o.product_id = p.product_id
Group By p.product_name
Order By Total_Revenue Desc
Limit 5 ; 

-- 13. Long Time Since Last Stock Update
Select p.product_name, Datediff(Curdate(), i.last_stocked) AS Days_Since_Stocked
from inventory i
right Join products p ON i.product_id = p.product_id
Order By Days_Since_Stocked Desc;

-- 14. Products with No Orders
Select p.product_name
from products p
left Join orders o on p.product_id = o.product_id
where o.order_id is Null;

-- 15. Customers with Frequent Orders (more than 5)
Select customer_id, Count(*) As Total_Orders
From orders
Group By customer_id
Having Total_Orders > 5
Order By Total_Orders Desc;

-- 16. Category-wise Revenue
SELECT category, Round(SUM(o.quantity_ordered * p.price),2) AS category_revenue
FROM orders o
left JOIN products p ON o.product_id = p.product_id
GROUP BY category
ORDER BY category_revenue DESC;


