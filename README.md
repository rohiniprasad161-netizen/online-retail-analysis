# End-to-End Online Retail Analytics & Customer Intelligence Pipeline

## 📌 Project Overview
This project implements a production-grade data analytics pipeline designed to transform raw e-commerce transactional data into high-impact business intelligence. Utilizing **Python (Pandas)** for robust Extraction, Transformation, and Loading (ETL) and **MySQL** for relational warehousing, the system executes sophisticated data modeling. 

The core analytics framework evaluates revenue health, inventories via automated ABC classification, market basket configurations, and granular customer lifetime value (LTV) models—including advanced RFM segmentation and predictive churn tracking.

---

## 🛠️ Technical Architecture & Stack
* **Data Engineering & ETL:** Python 3, Pandas, NumPy
* **Database Connectivity & Database ORM:** SQLAlchemy, PyMySQL
* **Relational Database Engine:** MySQL Server / MySQL Workbench
* **Execution Environment:** Jupyter Notebook Ecosystem

---

## ⚙️ Data Engineering & ETL Pipeline (Python Engine)

The pipeline ingests raw transactional datasets through an automated cleaning and feature-driven preprocessing workflow inside `code.ipynb`:

### 1. Data Validation & Operational Auditing
* **Handling Missing Identifiers:** Records lacking critical dimensions are systematically purged using strict indexing criteria:
  ```python
  df.dropna(subset=['CustomerID'])
  ```
* **Deduplication:** Redundant multi-row logs across identical attributes are resolved via `df.drop_duplicates()`.
* **Outlier & Financial Filtering:** Transactions with negative or zero pricing and volumetric structures (e.g., cancellations/returns) are isolated to secure analytical consistency:
  ```python
  df = df[(df['Quantity'] > 0) & (df['UnitPrice'] > 0)]
  ```

### 2. Feature Engineering & Dimensional Scaling
* **Temporal Disaggregation:** Extracts `InvoiceHour` and `DayOfWeek` from native datetime values to isolate peak infrastructure loads and high-traffic purchasing windows.
* **Transactional Aggregations:** Computes dynamic metrics including `TotalAmount` (Quantity × UnitPrice) and invoice structural depth (`ItemsPerInvoice`).
* **Customer Behavior Baselines:** Implements vectorized calculations to produce analytical fields: `CustomerCohortYear`, `CustomerOrderCount`, and `CustomerLifetimeSpend`.
* **Dynamic Product Profiling:** Categorizes products into `Premium` and `Economy` segments by setting the structural price boundary at the median unit price.

### 3. High-Throughput Database Injection
Establishes a robust connection mapping layer to transform memory-optimized Pandas DataFrames directly into physical database relations:
```python
import urllib.parse
from sqlalchemy import create_engine

raw_password = "YOUR_DATABASE_PASSWORD"
safe_password = urllib.parse.quote_plus(raw_password)

engine = create_engine(f'mysql+pymysql://root:{safe_password}@localhost:3306/retail_db')
df.to_sql(name='online_retail_cleaned', con=engine, if_exists='replace', index=False)
```

---

## 📊 Relational Database Schema & Analytics Engine (SQL)

Once data is written into the database, highly optimized relational scripts are deployed to evaluate performance across three distinct operational layers: