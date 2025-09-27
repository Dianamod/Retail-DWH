# Retail-DWH
Sales Shop Data Warehouse Project
📌 Project Overview
The Sales Shop is a retail business specializing in accessories, bikes, and clothes, serving customers through both online and offline channels across multiple regions. Over time, the company has accumulated large amounts of sales data, but due to fragmented storage across different systems, it struggled to gain unified insights.
This project demonstrates how a Data Warehouse (DWH) can address these challenges by consolidating data from multiple sources, applying proper data modeling, and enabling advanced analytics through a dimensional schema.

🔎 Business Challenges
•	Fragmented data: Online and offline sales data stored separately, limiting a holistic view.
•	Customer segmentation issues: Hard to analyze demographics for targeted marketing.
•	Poor product tracking: No clear performance view across categories and regions, leading to stock imbalances.
•	Slow decisions: Lack of real-time reporting for pricing, promotions, and stocking.
•	Limited profitability analysis: Difficult to identify high-margin products and categories.

✅ Benefits of the Data Warehouse
•	Centralized sales data across online and offline channels.
•	Rich customer insights (age, gender, location, buying behavior).
•	Optimized inventory management by tracking product/category performance.
•	Faster decision-making with real-time dashboards and reports.
•	Scalable design to support future data growth.

🏗️ Data Modeling Approach
I implemented both a 3NF layer and a Dimensional Model (DM) for analytics.
Grain
•	One row per individual product sold in a specific sales transaction.
•	Enables detailed analysis at product, customer, and region levels.

Dimensions
•	Customer Dimension: Demographics and addresses.
•	Product Dimension: Categories, subcategories, product details.
•	Date Dimension: Day, month, year for trend analysis.
•	Store Dimension: Store details, employees, and locations.
•	Shipping Dimension: Carrier and shipping type (online only).
•	Sales Channel Dimension: Online vs. offline.

Fact Table
Measures: Unit Price, Unit Cost, Total Cost, Order Quantity, Revenue, Profit.

Special Implementation
SCD Type 2 applied to the Employee Dimension to track historical changes.

⚙️ Project Highlights
•	Staging Layer:
	Raw data from online and offline Kaggle sales datasets loaded “as-is”.
  Serves as a temporary landing zone without heavy transformations.
•	3NF Layer:
  Data cleaned, standardized, and integrated from staging.
  Entities such as Customers, Products, Stores, Employees, and Sales modeled in normalized form.
  Ensures consistency and provides a trusted source for building the data mart.
  
•	Dimensional Model (DM Layer):
  Star Schema design for analytics.
  Fact Table: Captures detailed sales transactions (one row per product sold).
  Dimension Tables: Customer, Product, Date, Store, Shipping, and Sales Channel.
  SCD Type 2 applied to the Employee Dimension for tracking historical changes.
  
•	Optimization Features:
  Partitioning strategy for fact tables.
  
