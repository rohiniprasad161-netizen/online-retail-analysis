-- ============================================================================
-- ONLINE RETAIL DATA ANALYSIS - MASTER SQL SCRIPT (20 BUSINESS INSIGHTS)
-- ============================================================================

USE retail_db;

-- ==========================================
-- SECTION 1: SALES & REVENUE INSIGHTS
-- ==========================================

-- 1. Total Global Revenue, Orders, and Customers

SELECT 
    ROUND(SUM(TotalAmount), 2) AS Global_Total_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Global_Total_Orders,
    COUNT(DISTINCT CustomerID) AS Global_Total_Customers
FROM online_retail_cleaned;

-- 2. Monthly Revenue, Orders, and Average Order Value (AOV)

SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
    ROUND(SUM(TotalAmount), 2) AS Monthly_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT InvoiceNo), 2) AS Average_Order_Value_AOV
FROM online_retail_cleaned
GROUP BY Month
ORDER BY Month;

-- 3. Month-on-Month (MoM) Revenue Growth Percentage

WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
        SUM(TotalAmount) AS Current_Month_Revenue
    FROM online_retail_cleaned
    GROUP BY Month
)
SELECT 
    Month,
    ROUND(Current_Month_Revenue, 2) AS Revenue,
    ROUND(LAG(Current_Month_Revenue) OVER (ORDER BY Month), 2) AS Previous_Month_Revenue,
    ROUND(((Current_Month_Revenue - LAG(Current_Month_Revenue) OVER (ORDER BY Month)) / LAG(Current_Month_Revenue) OVER (ORDER BY Month)) * 100, 2) AS Growth_Percentage
FROM MonthlySales;

-- 4. Top Countries by Revenue (Highest to Lowest)
SELECT 
    Country,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    COUNT(DISTINCT CustomerID) AS Unique_Customers
FROM online_retail_cleaned
GROUP BY Country
ORDER BY Total_Revenue DESC;

-- 5. Bottom 5 Countries by Revenue (Lowest Contributing Markets)

SELECT 
    Country,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue
FROM online_retail_cleaned
GROUP BY Country
ORDER BY Total_Revenue ASC
LIMIT 5;

-- 6. Cumulative Daily Running Total of Revenue
SELECT 
    DATE(InvoiceDate) AS Order_Date,
    ROUND(SUM(TotalAmount), 2) AS Daily_Sales,
    ROUND(SUM(SUM(TotalAmount)) OVER (ORDER BY DATE(InvoiceDate)), 2) AS Cumulative_Running_Total
FROM online_retail_cleaned
GROUP BY Order_Date
ORDER BY Order_Date;


-- ==========================================
-- SECTION 2: PRODUCT PERFORMANCE (क्या बिक रहा है, क्या फंसा है)
-- ==========================================

-- 7. Top 10 Best Selling Products by Revenue Generated

SELECT 
    Description,
    SUM(Quantity) AS Total_Quantity_Sold,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue
FROM online_retail_cleaned
GROUP BY Description
ORDER BY Total_Revenue DESC
LIMIT 10;

-- 8. Top 10 Best Selling Products by Volume (Quantity)

SELECT 
    Description,
    SUM(Quantity) AS Total_Quantity_Sold,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue
FROM online_retail_cleaned
GROUP BY Description
ORDER BY Total_Quantity_Sold DESC
LIMIT 10;

-- 9. Premium vs Economy Product Segment Performance

SELECT 
    PriceCategory,
    COUNT(DISTINCT Description) AS Total_Unique_Products,
    SUM(Quantity) AS Total_Items_Sold,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue,
    ROUND((SUM(TotalAmount) / (SELECT SUM(TotalAmount) FROM online_retail_cleaned)) * 100, 2) AS Revenue_Share_Percentage
FROM online_retail_cleaned
GROUP BY PriceCategory;

-- 10. Top 10 Dead/Lowest Performing Products (By Quantity Sold)

SELECT 
    Description,
    SUM(Quantity) AS Total_Quantity_Sold,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue
FROM online_retail_cleaned
GROUP BY Description
ORDER BY Total_Quantity_Sold ASC
LIMIT 10;

-- 11. ABC Inventory Classification (80/20 Rule)

WITH ProductRevenue AS (
    SELECT 
        Description,
        SUM(TotalAmount) AS Pro_Rev,
        SUM(SUM(TotalAmount)) OVER () AS Total_Global_Rev
    FROM online_retail_cleaned
    GROUP BY Description
),
RunningPercent AS (
    SELECT 
        Description,
        Pro_Rev,
        SUM(Pro_Rev) OVER (ORDER BY Pro_Rev DESC) / Total_Global_Rev * 100 AS Cum_Percentage
    FROM ProductRevenue
)
SELECT 
    Description,
    ROUND(Pro_Rev, 2) AS Product_Revenue,
    CASE 
        WHEN Cum_Percentage <= 70 THEN 'A (Top Contributor)'
        WHEN Cum_Percentage <= 90 THEN 'B (Medium Contributor)'
        ELSE 'C (Low Contributor / Dead Stock)'
    END AS ABC_Category
FROM RunningPercent;

-- 12. Product Market Basket Analysis (Frequently Bought Together)

SELECT 
    p1.Description AS Product_A,
    p2.Description AS Product_B,
    COUNT(*) AS Times_Bought_Together
FROM online_retail_cleaned p1
JOIN online_retail_cleaned p2 
    ON p1.InvoiceNo = p2.InvoiceNo AND p1.StockCode < p2.StockCode
GROUP BY Product_A, Product_B
ORDER BY Times_Bought_Together DESC
LIMIT 10;


-- ==========================================
-- SECTION 3: CUSTOMER BEHAVIOR & SEGMENTATION 
-- ==========================================

-- 13. Top 10 VIP/Highest Spending Customers

SELECT 
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders_Placed,
    ROUND(SUM(TotalAmount), 2) AS Lifetime_Value_LTV
FROM online_retail_cleaned
GROUP BY CustomerID, Country
ORDER BY Lifetime_Value_LTV DESC
LIMIT 10;

-- 14. RFM Customer Segmentation Logic
WITH CustomerSummary AS (
    SELECT 
        CustomerID,
        MAX(InvoiceDate) AS Last_Purchase_Date,
        DATEDIFF((SELECT MAX(InvoiceDate) FROM online_retail_cleaned), MAX(InvoiceDate)) AS Days_Since_Last_Purchase,
        COUNT(DISTINCT InvoiceNo) AS Total_Orders,
        SUM(TotalAmount) AS Lifetime_Spend
    FROM online_retail_cleaned
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    Days_Since_Last_Purchase AS Recency_Days,
    Total_Orders AS Frequency_Count,
    ROUND(Lifetime_Spend, 2) AS Monetary_Value,
    CASE 
        WHEN Days_Since_Last_Purchase <= 30 AND Total_Orders >= 8 AND Lifetime_Spend > 5000 THEN 'VIP / Champions'
        WHEN Days_Since_Last_Purchase <= 60 AND Total_Orders >= 3 THEN 'Loyal Customers'
        WHEN Days_Since_Last_Purchase <= 30 AND Total_Orders = 1 THEN 'New Customers'
        WHEN Days_Since_Last_Purchase > 120 THEN 'Lost / At Risk'
        ELSE 'Regular / Standard'
    END AS Customer_Segment
FROM CustomerSummary
ORDER BY Monetary_Value DESC;

-- 15. New Customers vs Repeat Customers Revenue Share

WITH CustomerFirstOrder AS (
    SELECT 
        CustomerID,
        MIN(InvoiceNo) AS First_Invoice
    FROM online_retail_cleaned
    GROUP BY CustomerID
)
SELECT 
    CASE 
        WHEN o.InvoiceNo = f.First_Invoice THEN 'New Customer Order'
        ELSE 'Repeat Customer Order'
    END AS Order_Type,
    COUNT(DISTINCT o.InvoiceNo) AS Total_Orders,
    ROUND(SUM(o.TotalAmount), 2) AS Total_Revenue
FROM online_retail_cleaned o
LEFT JOIN CustomerFirstOrder f ON o.CustomerID = f.CustomerID
GROUP BY Order_Type;

-- 16. Customer Repurchase Pace (Average Days Between Purchases)

WITH NextOrderDifs AS (
    SELECT 
        CustomerID,
        InvoiceDate,
        LEAD(InvoiceDate) OVER (PARTITION BY CustomerID ORDER BY InvoiceDate) AS Next_Invoice_Date
    FROM (SELECT DISTINCT CustomerID, InvoiceNo, InvoiceDate FROM online_retail_cleaned) t
)
SELECT 
    CustomerID,
    ROUND(AVG(DATEDIFF(Next_Invoice_Date, InvoiceDate)), 1) AS Avg_Days_Between_Purchases
FROM NextOrderDifs
WHERE Next_Invoice_Date IS NOT NULL
GROUP BY CustomerID
ORDER BY Avg_Days_Between_Purchases ASC;

-- 17. Churn Risk Warning for High-Value Customers
SELECT 
    CustomerID,
    MAX(InvoiceDate) AS Last_Purchase_Date,
    DATEDIFF((SELECT MAX(InvoiceDate) FROM online_retail_cleaned), MAX(InvoiceDate)) AS Days_Since_Last_Purchase,
    ROUND(SUM(TotalAmount), 2) AS Lifetime_Value
FROM online_retail_cleaned
GROUP BY CustomerID
HAVING Days_Since_Last_Purchase > 90 AND Lifetime_Value > 5000
ORDER BY Days_Since_Last_Purchase DESC;

-- 18. Wholesaler / B2B vs Retailer / B2C Detection
SELECT 
    CASE 
        WHEN AVG(Quantity) > 100 OR SUM(TotalAmount) > 15000 THEN 'Wholesaler / B2B'
        ELSE 'Retail Customer / B2C'
    END AS Customer_Type,
    COUNT(DISTINCT CustomerID) AS Total_Customers,
    ROUND(SUM(TotalAmount), 2) AS Total_Revenue,
    ROUND(AVG(TotalAmount), 2) AS Avg_Order_Value
FROM online_retail_cleaned
GROUP BY Customer_Type;

