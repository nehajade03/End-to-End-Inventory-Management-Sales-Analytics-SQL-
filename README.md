# Supply Chain & Inventory SQL Analysis

## 📑 Project Index

- [Introduction](#introduction)
- [Business Problem Statement](#business-problem-statement)
- [Database Schema Overview](#database-schema-overview)
- [Table Structure (DDL)](#table-structure-ddl)
- [Data Cleaning & Preprocessing](#data-cleaning--preprocessing)
- [Data Transformation](#data-transformation)
- [Exploratory Data Analysis (EDA)](#exploratory-data-analysis-eda)
- [Business Queries & KPI Analysis](#business-queries--kpi-analysis)
- [Inventory Analysis](#inventory-analysis)
- [Sales & Revenue Analysis](#sales--revenue-analysis)
- [Customer Analysis](#customer-analysis)
- [Supplier Analysis](#supplier-analysis)
- [Advanced SQL Concepts Used](#advanced-sql-concepts-used)
- [Key Insights](#key-insights)
- [Business Recommendations](#business-recommendations)
- [Conclusion](#conclusion)

---

# Introduction 

This project focuses on analyzing supply chain operations using SQL.  
The analysis includes inventory tracking, supplier performance, sales analysis, customer behavior, and operational KPIs using a relational database structure.

The project simulates a real-world inventory management system used by businesses to optimize stock levels, monitor suppliers, and improve operational efficiency.

---

# Business Problem Statement

Companies often face challenges such as:

- Overstocking and understocking inventory
- Poor visibility into supplier performance
- Inefficient order tracking
- Difficulty identifying top-selling products
- Delayed reorder planning

This project solves these challenges through SQL-based analytical queries and relational database modeling.

---

# Database Schema Overview

The database consists of the following tables:

- `products`
- `orders`
- `inventory`
- `suppliers`

### Table Structure (DDL)

```text
suppliers
    ↓
products
   /    \
orders  inventory
```

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/b1dca8b8-6083-4064-b81e-d00399def478" />

---

# Table Structure (DDL)

## Suppliers Table

```sql
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100),
    contact_name VARCHAR(100),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50)
);
```

## Products Table

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    description TEXT,
    reorder_level INT,
    supplier_id INT,
    FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
);
```

---

# Data Cleaning & Preprocessing

## Handle Null Values

```sql
UPDATE products
SET price = 0
WHERE price IS NULL;
```

## Remove Duplicate Products

```sql
DELETE FROM products
WHERE product_id NOT IN (
    SELECT product_id
    FROM (
        SELECT product_id,
        ROW_NUMBER() OVER (
            PARTITION BY product_name, category
            ORDER BY product_id
        ) AS rn
        FROM products
    ) AS sub
    WHERE rn = 1
);
```

---

# Exploratory Data Analysis (EDA)

## Total Products Per Category

```sql
SELECT
    category,
    COUNT(*) AS total_products
FROM products
GROUP BY category;
```

<img width="281" height="170" alt="image" src="https://github.com/user-attachments/assets/8d856bd5-7d83-49d8-9026-e82c3568b8ea" />

---

```sql
-- Total Suppliers by Country
Select (country) , count(*) As Total_Suppliers from suppliers
Group by country;
```

<img width="430" height="607" alt="image" src="https://github.com/user-attachments/assets/2a46867b-f1c7-4b74-9628-65b9203d0b16" />

---

# Business KPI Analysis

## Revenue Generated Per Product

```sql
select 
p.product_name, 
count(o.order_id) As Total_Orders
from products p
left join orders o on  p.product_id = o.product_id
Group by p.product_name;
```

<img width="277" height="408" alt="image" src="https://github.com/user-attachments/assets/dcc53d68-922e-4d59-b47b-1ad20cd122ef" />

---

```sql
SELECT
    p.product_name,
    ROUND(SUM(o.quantity_ordered * p.price),2) AS total_revenue
FROM orders o
LEFT JOIN products p
ON o.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.product_name
ORDER BY total_revenue DESC;
```

---

# Inventory Analysis

## Low Stock Alert

```sql
SELECT
    p.product_name,
    i.quantity_in_stock,
    p.reorder_level,
    CASE
        WHEN COALESCE(i.quantity_in_stock,0) < p.reorder_level
        THEN 'Reorder Needed'
        ELSE 'Sufficient'
    END AS stock_status
FROM inventory i
RIGHT JOIN products p
ON i.product_id = p.product_id;
```

<img width="578" height="602" alt="image" src="https://github.com/user-attachments/assets/8b9d28d6-0c98-4c24-9ba3-354c628924d1" />

---

```sql
-- 3. Monthly sales trend
select Month(order_date) As order_month, sum(quantity_ordered) AS total_quantity
from orders 
Group by month(order_date)
order by order_month;
```

<img width="281" height="291" alt="image" src="https://github.com/user-attachments/assets/c8ce7021-0228-49c5-b5c9-e1cb4b49a9c9" />

---

# Customer Analysis

## Top 5 Customers by Spending

```sql
SELECT
    customer_id,
    SUM(quantity_ordered * p.price) AS total_spent
FROM orders o
LEFT JOIN products p
ON o.product_id = p.product_id
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 5;
```

<img width="225" height="137" alt="image" src="https://github.com/user-attachments/assets/e71cfe79-409f-4981-b2eb-29bc79041777" />

---

## Product Performance Summary

```sql
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
```

<img width="865" height="641" alt="image" src="https://github.com/user-attachments/assets/1360f452-b7d3-4ffd-a9ae-69938030d468" />

---

# Step 7: Additional Insights

## Out of Stock Products

```sql
select p.product_name
from products p
left join inventory i on p.product_id = i.product_id
where i.quantity_in_stock = 0 or i.quantity_in_stock is Null;
```

<img width="167" height="217" alt="image" src="https://github.com/user-attachments/assets/bcf7d914-a62c-474f-afbd-62e10bde13c5" />

---

## Daily Order Summary

```sql
Select order_date , Count(*) as total_orders, sum(quantity_ordered) As Total_items
from orders
Group by order_date
order by order_date desc;
```

<img width="362" height="592" alt="image" src="https://github.com/user-attachments/assets/493ff637-e3a4-4829-a68b-06221b3ecefc" />

---

## Most Ordered Products (Top 5)

```sql
select p.product_name, sum(o.quantity_ordered) As total_quantity
from orders o
Join products p on o.product_id = p.product_id
group by p.product_name
order by total_quantity desc
limit 5;
```

<img width="292" height="206" alt="image" src="https://github.com/user-attachments/assets/31e5ef77-872f-4de1-bb23-2eb26559601b" />

---

## Average Monthly Orders

```sql
Select Month(order_date) As Month, Round(Avg(quantity_ordered),0) As avg_order_quantity
from orders
Group by month(order_date)
order by month;
```

<img width="253" height="292" alt="image" src="https://github.com/user-attachments/assets/e54fe64e-e1f8-4f07-9621-6b505211af1f" />

---

## Highest Revenue Products (Top 5)

```sql
Select p.product_name, Round(Sum(o.quantity_ordered*p.price),2) As Total_Revenue
From products p
Join orders o On o.product_id = p.product_id
Group By p.product_name
Order By Total_Revenue Desc
Limit 5;
```

<img width="306" height="148" alt="image" src="https://github.com/user-attachments/assets/c91ea1b9-8a40-4918-af44-d8fb641b41f1" />

---

## Long Time Since Last Stock Update

```sql
Select p.product_name, Datediff(Curdate(), i.last_stocked) AS Days_Since_Stocked
from inventory i
right Join products p ON i.product_id = p.product_id
Order By Days_Since_Stocked Desc;
```

---

## Products with No Orders

```sql
Select p.product_name
from products p
left Join orders o on p.product_id = o.product_id
where o.order_id is Null;
```

<img width="195" height="141" alt="image" src="https://github.com/user-attachments/assets/ce256386-7cbe-421e-9ddb-067013a59354" />

---

## Customers with Frequent Orders (more than 5)

```sql
Select customer_id, Count(*) As Total_Orders
From orders
Group By customer_id
Having Total_Orders > 5
Order By Total_Orders Desc;
```

---

## Category-wise Revenue

```sql
SELECT category, Round(SUM(o.quantity_ordered * p.price),2) AS category_revenue
FROM orders o
left JOIN products p ON o.product_id = p.product_id
GROUP BY category
ORDER BY category_revenue DESC;
```

<img width="300" height="156" alt="image" src="https://github.com/user-attachments/assets/69beb906-3451-4eed-9649-787eeff4517d" />

---

# Supplier Analysis

## Supplier-wise Product Count

```sql
SELECT
    s.supplier_name,
    COUNT(p.product_id) AS total_products
FROM suppliers s
LEFT JOIN products p
ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_name
ORDER BY total_products DESC;
```

---

# Advanced SQL Concepts Used

- JOINs
- GROUP BY
- Aggregate Functions
- Window Functions
- CASE Statements
- Foreign Keys
- Relational Modeling
- Data Cleaning
- KPI Analysis

---

# Key Insights

- Electronics products generated highest revenue
- Several products were below reorder level
- Some suppliers contributed higher inventory stock
- Customer purchasing trends were identified

---

# Business Recommendations

- Improve inventory replenishment planning
- Monitor low-stock products regularly
- Strengthen supplier management
- Focus on high-performing product categories

---

# Technologies Used

- SQL
- MySQL
- Relational Database Design
- Supply Chain Analytics
- GitHub

---

# Conclusion

This project demonstrates real-world supply chain and inventory analysis using SQL and relational database concepts. It highlights business intelligence reporting, data cleaning, KPI analysis, and operational insights generation.
