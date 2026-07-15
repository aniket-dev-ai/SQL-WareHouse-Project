/*==============================================================================
    SILVER LAYER - CRM CUSTOMER INFORMATION
    ----------------------------------------------------------------------------
    Purpose:
        Load cleansed customer master data from the Bronze layer into the
        Silver layer.

    Transformations:
        1. Remove duplicate customer records (keep latest record).
        2. Trim leading/trailing spaces from names.
        3. Standardize marital status values.
        4. Standardize gender values.
        5. Exclude records with NULL customer IDs.

    Target:
        silver.crm_cust_info
==============================================================================*/

TRUNCATE TABLE silver.crm_cust_info;

INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_material_status,
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
    cst_key,

    -- Remove unnecessary whitespace
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname)  AS cst_lastname,

    -- Convert abbreviated marital status into descriptive values
    CASE
        WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_material_status,

    -- Convert abbreviated gender codes into standardized values
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,

    cst_create_date
FROM (
    SELECT
        *,
        -- Keep only the latest record for each customer
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;



/*==============================================================================
    SILVER LAYER - CRM PRODUCT INFORMATION
    ----------------------------------------------------------------------------
    Purpose:
        Load cleansed product master data into the Silver layer.

    Transformations:
        1. Extract Product Category ID from Product Key.
        2. Extract actual Product Key.
        3. Replace NULL product cost with zero.
        4. Convert product line codes into descriptive values.
        5. Convert product start date to DATE datatype.
        6. Calculate product end date using LEAD() for SCD Type-2 logic.

    Target:
        silver.crm_prd_info
==============================================================================*/

TRUNCATE TABLE silver.crm_prd_info;

ALTER TABLE silver.crm_prd_info
ADD COLUMN cat_id VARCHAR(50);

INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,

    -- Extract Category ID (e.g. AC-HE -> AC_HE)
    REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,

    -- Remove category prefix from Product Key
    SUBSTRING(prd_key FROM 7) AS prd_key,

    prd_nm,

    -- Replace missing product cost with zero
    COALESCE(prd_cost, 0) AS prd_cost,

    -- Standardize product line descriptions
    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,

    prd_start_dt::DATE,

    -- Calculate product end date from the next available start date
    (
        LEAD(prd_start_dt)
        OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - INTERVAL '1 day'
    )::DATE AS prd_end_dt

FROM bronze.crm_prd_info;



/*==============================================================================
    SILVER LAYER - CRM SALES DETAILS
    ----------------------------------------------------------------------------
    Purpose:
        Load cleansed sales transaction data.

    Transformations:
        1. Convert integer date values into DATE datatype.
        2. Replace invalid dates with NULL.
        3. Recalculate sales amount if missing or incorrect.
        4. Derive unit price when missing or invalid.

    Target:
        silver.crm_sales_details
==============================================================================*/

TRUNCATE TABLE silver.crm_sales_details;

INSERT INTO silver.crm_sales_details
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    -- Validate and convert Order Date
    CASE
        WHEN sls_order_dt = 0
             OR LENGTH(sls_order_dt::TEXT) <> 8
        THEN NULL
        ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
    END,

    -- Validate and convert Shipping Date
    CASE
        WHEN sls_ship_dt = 0
             OR LENGTH(sls_ship_dt::TEXT) <> 8
        THEN NULL
        ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
    END,

    -- Validate and convert Due Date
    CASE
        WHEN sls_due_dt = 0
             OR LENGTH(sls_due_dt::TEXT) <> 8
        THEN NULL
        ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
    END,

    -- Correct invalid or inconsistent sales amount
    CASE
        WHEN sls_sales IS NULL
             OR sls_sales <= 0
             OR sls_sales <> sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END,

    sls_quantity,

    -- Derive unit price when unavailable or invalid
    CASE
        WHEN sls_price IS NULL
             OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END

FROM bronze.crm_sales_details;



/*==============================================================================
    SILVER LAYER - ERP CUSTOMER MASTER
    ----------------------------------------------------------------------------
    Purpose:
        Clean ERP customer demographic information.

    Transformations:
        1. Remove 'NAS' prefix from Customer ID.
        2. Replace future birth dates with NULL.
        3. Standardize gender values.

    Target:
        silver.erp_cust_az12
==============================================================================*/

TRUNCATE TABLE silver.erp_cust_az12;

INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
SELECT

    -- Remove legacy customer ID prefix
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
        ELSE cid
    END,

    -- Future birth dates are considered invalid
    CASE
        WHEN bdate > CURRENT_DATE THEN NULL
        ELSE bdate
    END,

    -- Standardize gender values
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END

FROM bronze.erp_cust_az12;



/*==============================================================================
    SILVER LAYER - ERP CUSTOMER LOCATION
    ----------------------------------------------------------------------------
    Purpose:
        Clean ERP customer location information.

    Transformations:
        1. Remove hyphens from Customer ID.
        2. Standardize country names.
        3. Replace missing country values with 'n/a'.

    Target:
        silver.erp_loc_a101
==============================================================================*/

TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT

    -- Remove formatting characters from Customer ID
    REPLACE(cid, '-', '') AS cid,

    -- Standardize country names
    CASE
        WHEN BTRIM(cntry) = 'DE' THEN 'Germany'
        WHEN BTRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN cntry IS NULL
             OR BTRIM(cntry) = ''
        THEN 'n/a'
        ELSE BTRIM(cntry)
    END

FROM bronze.erp_loc_a101;



/*==============================================================================
    SILVER LAYER - ERP PRODUCT CATEGORY
    ----------------------------------------------------------------------------
    Purpose:
        Load ERP product category reference data into the Silver layer.

    Transformations:
        None.
        Data is copied directly from Bronze because it already satisfies
        Silver layer quality requirements.

    Target:
        silver.erp_px_cat_g1v2
==============================================================================*/

TRUNCATE TABLE silver.erp_px_cat_g1v2;

INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;