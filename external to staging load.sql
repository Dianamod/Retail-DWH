
CREATE SCHEMA IF NOT EXISTS sa_offline_sales;

CREATE extension if not exists file_fdw;


CREATE SERVER file_server FOREIGN DATA WRAPPER file_fdw;


create foreign table IF NOT EXISTS sa_offline_sales.ext_sales(
"Date" VARCHAR(1000),
"Customer ID" VARCHAR(1000),
"Customer AGE" VARCHAR(1000),
"Age Group" VARCHAR(1000),
"Customer Gender"  VARCHAR(1000),
Country VARCHAR(1000),
State VARCHAR(1000),
"Product Category" VARCHAR(1000),
"Product Subcategory" VARCHAR(1000),
Product VARCHAR(1000),
"Frame Size" VARCHAR(1000),
"Order Quantity" VARCHAR(1000),
"Unit Cost" VARCHAR(1000),
"Unit Price" VARCHAR(1000),
"Cost" VARCHAR(1000),
Revenue VARCHAR(1000),
Profit VARCHAR(1000),
sales_channel VARCHAR(1000),
"Store ID" VARCHAR(1000),
"Store Name" VARCHAR(1000),
"Salesperson ID" VARCHAR(1000),
"Store Addresses" VARCHAR(1000),
employee_first_name VARCHAR(1000),
employee_last_name VARCHAR(1000),
customer_first_name VARCHAR(1000),
customer_last_name VARCHAR(1000)
) SERVER  file_server

OPTIONS (filename 'C:/Program Files/PostgreSQL/17/data/new/updated_dataset_with_names.csv', format 'csv', header 'true',delimiter ';');




CREATE TABLE IF NOT EXISTS sa_offline_sales.src_offline_sales (
    Event_DT VARCHAR(1000),
    "Customer ID" VARCHAR(1000),
    "Customer AGE" VARCHAR(1000),
    "Age Group" VARCHAR(1000),
    "Customer Gender" VARCHAR(1000),
    Country VARCHAR(1000),
    State VARCHAR(1000),
    "Product Category" VARCHAR(1000),
    "Product Subcategory" VARCHAR(1000),
    Product VARCHAR(1000),
    "Frame Size" VARCHAR(1000),
    "Order Quantity" VARCHAR(1000),
    "Unit Cost" VARCHAR(1000),
    "Unit Price" VARCHAR(1000),
    "Cost" VARCHAR(1000),
    Revenue VARCHAR(1000),
    Profit VARCHAR(1000),
    sales_channel VARCHAR(1000),
    "Store ID" VARCHAR(1000),
    "Store Name" VARCHAR(1000),
    Employee_Id VARCHAR(1000),
    "Store Addresses" VARCHAR(1000),
    employee_first_name VARCHAR(1000),
    employee_last_name VARCHAR(1000),
    customer_first_name VARCHAR(1000),
    customer_last_name VARCHAR(1000)
);


BEGIN;
INSERT INTO sa_offline_sales.src_offline_sales (
    Event_DT, "Customer ID", "Customer AGE", "Age Group", "Customer Gender", Country, State, 
    "Product Category", "Product Subcategory", Product, "Frame Size", "Order Quantity", 
    "Unit Cost", "Unit Price", "Cost", Revenue, Profit, sales_channel, "Store ID", 
    "Store Name", Employee_Id, "Store Addresses", employee_first_name, 
    employee_last_name, customer_first_name, customer_last_name
)
SELECT *
FROM 
sa_offline_sales.ext_sales;

COMMIT;

--Create foreign table for online dataset

CREATE SCHEMA IF NOT EXISTS sa_online_sales;



CREATE FOREIGN TABLE IF NOT EXISTS sa_online_sales.ext_sales_online(
"Transaction Date" varchar(1000),
"Buyer ID" varchar(1000),
"Buyer age" varchar(1000),
"Age Group" varchar(1000),
"Customer Gender"  varchar(1000),
"Transaction Country" varchar(1000),
"Transaction State" varchar(1000),
"Product Category Name" varchar(1000),
"Subcategory" varchar(1000),
Product varchar(1000),
"Frame Size" varchar(1000),
"Order Quantity" varchar(1000),
"Unit Cost" varchar(1000),
"Unit Price" varchar(1000),
"Cost" varchar(1000),
Revenue varchar(1000),
Profit varchar(1000),
sales_channel varchar(1000),
"Shipping Carriers" varchar(1000),
"Shipping Methods" varchar(1000),
"Customer Addresses" varchar(1000),
customer_first_name varchar(1000),
customer_last_name varchar(1000)
) SERVER  file_server

OPTIONS (filename 'C:\Program Files\PostgreSQL\17\data\new\updated_online_dataset_with_names.csv', format 'csv', header 'true',delimiter ',');



CREATE TABLE IF NOT EXISTS sa_online_sales.src_online_sales (
"Transaction Date" varchar(1000),
"Buyer ID" varchar(1000),
"Buyer age" varchar(1000),
"Age Group" varchar(1000),
"Customer Gender"  varchar(1000),
"Transaction Country" varchar(1000),
"Transaction State" varchar(1000),
"Product Category Name" varchar(1000),
"Subcategory" varchar(1000),
Product varchar(1000),
"Frame Size" varchar(1000),
"Order Quantity" varchar(1000),
"Unit Cost" varchar(1000),
"Unit Price" varchar(1000),
"Cost" varchar(1000),
Revenue varchar(1000),
Profit varchar(1000),
sales_channel varchar(1000),
"Shipping Carriers" varchar(1000),
"Shipping Methods" varchar(1000),
"Customer Addresses" varchar(1000),
customer_first_name varchar(1000),
customer_last_name varchar(1000)
);

BEGIN;
INSERT INTO sa_online_sales.src_online_sales (
"Transaction Date",
"Buyer ID",
"Buyer age",
"Age Group",
"Customer Gender",
"Transaction Country",
"Transaction State",
"Product Category Name",
"Subcategory",
Product,
"Frame Size",
"Order Quantity",
"Unit Cost",
"Unit Price",
"Cost",
Revenue,
Profit,
sales_channel,
"Shipping Carriers",
"Shipping Methods",
"Customer Addresses",
customer_first_name,
customer_last_name 
)

SELECT *
FROM sa_online_sales.ext_sales_online;

COMMIT;



