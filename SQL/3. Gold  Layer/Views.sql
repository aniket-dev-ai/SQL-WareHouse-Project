    /*==============================================================================
    GOLD LAYER - DIMENSION & FACT VIEWS
    ----------------------------------------------------------------------------
    Purpose:
        Create the analytical Star Schema for reporting and BI tools.

    Objects Created:
        • dim_customers
        • dim_products
        • fact_sales

    Notes:
        • Dimension tables provide descriptive business attributes.
        • Fact table stores measurable business transactions.
        • Surrogate keys are generated using ROW_NUMBER().
==============================================================================*/


/*==============================================================================
    VIEW: dim_customers
    ----------------------------------------------------------------------------
    Purpose:
        Creates the Customer Dimension by combining customer
        information from CRM and ERP systems.

    Source Tables:
        • silver.crm_cust_info
        • silver.erp_cust_az12
        • silver.erp_loc_a101

    Business Rules:
        • Generate surrogate Customer Key.
        • Enrich CRM customer data with ERP demographics.
        • Use CRM gender when available; otherwise use ERP gender.
        • Include customer location and birthdate.
==============================================================================*/

CREATE OR REPLACE VIEW gold.dim_customers AS

SELECT

    -- Generate surrogate key for the dimension
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,

    ci.cst_id              AS customer_id,
    ci.cst_key             AS customer_number,
    ci.cst_firstname       AS first_name,
    ci.cst_lastname        AS last_name,

    -- Customer location
    la.cntry               AS country,

    ci.cst_material_status AS marital_status,

    -- CRM gender has higher priority than ERP gender
    CASE
        WHEN ci.cst_gndr <> 'n/a'
            THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate           AS birthdate,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info AS ci

LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;



/*==============================================================================
    VIEW: dim_products
    ----------------------------------------------------------------------------
    Purpose:
        Creates the Product Dimension by combining product master
        data with ERP product category information.

    Source Tables:
        • silver.crm_prd_info
        • silver.erp_px_cat_g1v2

    Business Rules:
        • Generate surrogate Product Key.
        • Include only active products.
        • Enrich products with category hierarchy.
==============================================================================*/

CREATE OR REPLACE VIEW gold.dim_products AS

SELECT

    -- Generate surrogate key for the dimension
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt,
                 pn.prd_key
    ) AS product_key,

    pn.prd_id      AS product_id,
    pn.prd_key     AS product_number,
    pn.prd_nm      AS product_name,

    -- Product category hierarchy
    pn.cat_id      AS category_id,
    pc.cat         AS category,
    pc.subcat      AS subcategory,
    pc.maintenance AS maintenance,

    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info AS pn

LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id

-- Keep only currently active products
WHERE pn.prd_end_dt IS NULL;



/*==============================================================================
    VIEW: fact_sales
    ----------------------------------------------------------------------------
    Purpose:
        Creates the Sales Fact table by linking sales transactions
        with Customer and Product dimensions.

    Source Tables:
        • silver.crm_sales_details
        • gold.dim_products
        • gold.dim_customers

    Business Rules:
        • Replace business keys with surrogate keys.
        • Preserve all sales transactions.
        • Ready for analytical reporting and Power BI.
==============================================================================*/

CREATE OR REPLACE VIEW gold.fact_sales AS

SELECT

    -- Business identifier
    sd.sls_ord_num AS order_number,

    -- Foreign Keys
    pr.product_key,
    cu.customer_key,

    -- Date dimensions
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,

    -- Business measures
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price

FROM silver.crm_sales_details AS sd

LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;