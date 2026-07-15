/*==============================================================================
    SILVER LAYER - TABLE CREATION SCRIPT
    ----------------------------------------------------------------------------
    Purpose:
        Recreate all Silver layer tables.

    Notes:
        • Existing Silver tables are dropped before recreation.
        • Each table includes a dwh_create_date column to capture
          the warehouse load timestamp.
        • These tables store cleansed and standardized data loaded
          from the Bronze layer.
==============================================================================*/

-- Drop existing Silver tables to ensure a clean deployment
DROP TABLE IF EXISTS
    silver.crm_cust_info,
    silver.crm_prd_info,
    silver.crm_sales_details,
    silver.erp_cust_az12,
    silver.erp_loc_a101,
    silver.erp_px_cat_g1v2;


/*==============================================================================
    TABLE: crm_cust_info
    ----------------------------------------------------------------------------
    Purpose:
        Stores cleansed customer master data after removing duplicates
        and standardizing business attributes.

    Source:
        bronze.crm_cust_info
==============================================================================*/
CREATE TABLE silver.crm_cust_info (
    cst_id               INT,
    cst_key              VARCHAR(50),
    cst_firstname        VARCHAR(50),
    cst_lastname         VARCHAR(50),
    cst_material_status  VARCHAR(50),
    cst_gndr             VARCHAR(50),
    cst_create_date      TIMESTAMP,

    -- Timestamp when the record is loaded into the Data Warehouse
    dwh_create_date      TIMESTAMP DEFAULT NOW()
);


/*==============================================================================
    TABLE: crm_prd_info
    ----------------------------------------------------------------------------
    Purpose:
        Stores standardized product master information including
        product lifecycle dates.

    Source:
        bronze.crm_prd_info
==============================================================================*/
CREATE TABLE silver.crm_prd_info (
    prd_id               INT,
    prd_key              VARCHAR(50),
    prd_nm               VARCHAR(50),
    prd_cost             INT,
    prd_line             VARCHAR(50),
    prd_start_dt         TIMESTAMP,
    prd_end_dt           TIMESTAMP,

    -- Timestamp when the record is loaded into the Data Warehouse
    dwh_create_date      TIMESTAMP DEFAULT NOW()
);


/*==============================================================================
    TABLE: crm_sales_details
    ----------------------------------------------------------------------------
    Purpose:
        Stores cleansed sales transaction data with validated dates,
        sales values, quantities, and pricing.

    Source:
        bronze.crm_sales_details
==============================================================================*/
CREATE TABLE silver.crm_sales_details (
    sls_ord_num          VARCHAR(50),
    sls_prd_key          VARCHAR(50),
    sls_cust_id          INT,
    sls_order_dt         INT,
    sls_ship_dt          INT,
    sls_due_dt           INT,
    sls_sales            INT,
    sls_quantity         INT,
    sls_price            INT,

    -- Timestamp when the record is loaded into the Data Warehouse
    dwh_create_date      TIMESTAMP DEFAULT NOW()
);


/*==============================================================================
    TABLE: erp_loc_a101
    ----------------------------------------------------------------------------
    Purpose:
        Stores standardized customer location information imported
        from the ERP system.

    Source:
        bronze.erp_loc_a101
==============================================================================*/
CREATE TABLE silver.erp_loc_a101 (
    cid                  VARCHAR(50),
    cntry                VARCHAR(50),

    -- Timestamp when the record is loaded into the Data Warehouse
    dwh_create_date      TIMESTAMP DEFAULT NOW()
);


/*==============================================================================
    TABLE: erp_cust_az12
    ----------------------------------------------------------------------------
    Purpose:
        Stores ERP customer demographic information after data
        cleansing and standardization.

    Source:
        bronze.erp_cust_az12
==============================================================================*/
CREATE TABLE silver.erp_cust_az12 (
    cid                  VARCHAR(50),
    bdate                TIMESTAMP,
    gen                  VARCHAR(50),

    -- Timestamp when the record is loaded into the Data Warehouse
    dwh_create_date      TIMESTAMP DEFAULT NOW()
);


/*==============================================================================
    TABLE: erp_px_cat_g1v2
    ----------------------------------------------------------------------------
    Purpose:
        Stores ERP product category reference data used for
        product classification.

    Source:
        bronze.erp_px_cat_g1v2
==============================================================================*/
CREATE TABLE silver.erp_px_cat_g1v2 (
    id                   VARCHAR(50),
    cat                  VARCHAR(50),
    subcat               VARCHAR(50),
    maintenance          VARCHAR(50),

    -- Timestamp when the record is loaded into the Data Warehouse
    dwh_create_date      TIMESTAMP DEFAULT NOW()
);