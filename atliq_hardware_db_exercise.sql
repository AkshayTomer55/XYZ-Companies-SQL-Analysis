SELECT * FROM gdb023.dim_customer;
SELECT * FROM gdb023.dim_product;


1.) Select Distinct(market) MKT from dim_customer
where customer = 'Atliq Exclusive' AND region = "APAC";

2.) 
WITH unique_products AS (
    SELECT
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_product_count
    FROM fact_sales_monthly
    WHERE fiscal_year IN (2020, 2021)
    GROUP BY fiscal_year
)
SELECT
    MAX(CASE WHEN fiscal_year = 2020 THEN unique_product_count END) AS unique_products_2020,
    MAX(CASE WHEN fiscal_year = 2021 THEN unique_product_count END) AS unique_products_2021,
    ROUND(
        (MAX(CASE WHEN fiscal_year = 2021 THEN unique_product_count END) - 
         MAX(CASE WHEN fiscal_year = 2020 THEN unique_product_count END)
        ) * 100.0 / MAX(CASE WHEN fiscal_year = 2020 THEN unique_product_count END), 2
    ) AS percentage_chg
FROM unique_products;
    
3.) Select 
          Segment, 
          Count(distinct product) prod_count 
	 from dim_product
     group by segment
     order by prod_count desc
     
4.) WITH product_counts AS (
    SELECT
        dp.segment,
        COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2020 THEN dp.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2021 THEN dp.product_code END) AS product_count_2021
    FROM dim_product dp
    JOIN fact_sales_monthly fsm ON dp.product_code = fsm.product_code
    WHERE fsm.fiscal_year IN (2020, 2021)
    GROUP BY dp.segment
)
SELECT
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM product_counts
ORDER BY difference DESC;

5.) WITH manufacturing_costs AS (
    SELECT
        dp.product_code,
        dp.product,
        fmc.manufacturing_cost
    FROM dim_product dp
    JOIN fact_manufacturing_cost fmc ON dp.product_code = fmc.product_code
)
SELECT
    product_code,
    product,
    manufacturing_cost
FROM manufacturing_costs
WHERE manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM manufacturing_costs)
UNION ALL
SELECT
    product_code,
    product,
    manufacturing_cost
FROM manufacturing_costs
WHERE manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM manufacturing_costs);

6.) SELECT
    dc.customer_code,
    dc.customer,
    ROUND(AVG(fpid.pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM dim_customer dc
JOIN fact_pre_invoice_deductions fpid ON dc.customer_code = fpid.customer_code
WHERE fpid.fiscal_year = 2021 AND dc.market = 'India'
GROUP BY dc.customer_code, dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

7.) SELECT
    MONTH(fsm.date) AS Month,
    YEAR(fsm.date) AS Year,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price), 2) AS Gross_sales_Amount
FROM fact_sales_monthly fsm
JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY MONTH(fsm.date), YEAR(fsm.date)
ORDER BY Year, Month;

8.) SELECT
    QUARTER(fsm.date) AS Quarter,
    SUM(fsm.sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly fsm
WHERE fsm.fiscal_year = 2020
GROUP BY QUARTER(fsm.date)
ORDER BY total_sold_quantity DESC
LIMIT 1;

9.) WITH gross_sales AS (
    SELECT
        dc.channel,
        ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / 1000000, 2) AS gross_sales_mln
    FROM fact_sales_monthly fsm
    JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
    JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
    WHERE fsm.fiscal_year = 2021
    GROUP BY dc.channel
)
SELECT
    channel,
    gross_sales_mln,
    ROUND(gross_sales_mln * 100 / SUM(gross_sales_mln) OVER (), 2) AS percentage
FROM gross_sales
ORDER BY gross_sales_mln DESC;

10.) WITH product_sales AS (
    SELECT
        dp.division,
        dp.product_code,
        dp.product,
        SUM(fsm.sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS rank_order
    FROM dim_product dp
    JOIN fact_sales_monthly fsm ON dp.product_code = fsm.product_code
    WHERE fsm.fiscal_year = 2021
    GROUP BY dp.division, dp.product_code, dp.product
)
SELECT
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM product_sales
WHERE rank_order <= 3
ORDER BY division, rank_order;

       

