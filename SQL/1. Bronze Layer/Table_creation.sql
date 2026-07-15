/*==============================================================================
Schema      : bronze
Layer       : Bronze (Raw Ingestion Layer)
Purpose     : Stores raw data ingested from CRM and ERP source systems.
              Data in this layer should remain as close as possible to the
              source without applying business transformations.

Best Practices:
- No business logic should be applied in the Bronze layer.
- Preserve source data for auditing and traceability.
- Data quality issues are intentionally retained.
- Transformations belong in the Silver and Gold layers.

Author      : <Your Name>
Project     : Data Warehouse Project
==============================================================================*/


/*==============================================================================
Table: bronze.crm_cust_info
Source System : CRM
Description   : Stores raw customer master information received from the CRM
                system.

Business Purpose:
- Maintains customer identity and demographic attributes.
- Acts as the primary customer dimension source for downstream layers.
==============================================================================*/

CREATE TABLE bronze.crm_cust_info (

    -- Unique customer identifier from CRM
    cst_id INT,

    -- Business/customer key used across source systems
    cst_key VARCHAR(50),

    -- Customer first name
    cst_firstname VARCHAR(50),

    -- Customer last name
    cst_lastname VARCHAR(50),

    -- Customer marital status
    cst_material_status VARCHAR(50),

    -- Customer gender
    cst_gndr VARCHAR(50),

    -- Record creation timestamp in CRM
    cst_create_date TIMESTAMP
);



/*==============================================================================
Table: bronze.crm_prd_info
Source System : CRM
Description   : Stores raw product master information including pricing,
                product category, and product lifecycle dates.

Business Purpose:
- Serves as the source for product dimension creation.
- Tracks historical product availability.
==============================================================================*/

CREATE TABLE bronze.crm_prd_info (

    -- Unique product identifier
    prd_id INT,

    -- Product business key
    prd_key VARCHAR(50),

    -- Product name
    prd_nm VARCHAR(50),

    -- Product base cost
    prd_cost INT,

    -- Product line/category code
    prd_line VARCHAR(50),

    -- Product availability start date
    prd_start_dt TIMESTAMP,

    -- Product availability end date
    prd_end_dt TIMESTAMP
);



/*==============================================================================
Table: bronze.crm_sales_details
Source System : CRM
Description   : Stores transactional sales order details.

Business Purpose:
- Captures individual order transactions.
- Forms the primary fact table source for sales analytics.
==============================================================================*/

CREATE TABLE bronze.crm_sales_details (

    -- Sales order number
    sls_ord_num VARCHAR(50),

    -- Product key associated with the order
    sls_prd_key VARCHAR(50),

    -- Customer identifier
    sls_cust_id INT,

    -- Order date (stored as integer in source)
    sls_order_dt INT,

    -- Shipping date (stored as integer in source)
    sls_ship_dt INT,

    -- Due date (stored as integer in source)
    sls_due_dt INT,

    -- Total sales amount
    sls_sales INT,

    -- Quantity sold
    sls_quantity INT,

    -- Selling price per unit
    sls_price INT
);



/*==============================================================================
Table: bronze.erp_loc_a101
Source System : ERP
Description   : Stores customer geographical information.

Business Purpose:
- Maps customers to their country.
- Supports geographical and regional reporting.
==============================================================================*/

CREATE TABLE bronze.erp_loc_a101 (

    -- Customer identifier
    cid VARCHAR(50),

    -- Customer country
    cntry VARCHAR(50)
);



/*==============================================================================
Table: bronze.erp_cust_az12
Source System : ERP
Description   : Stores additional customer demographic information.

Business Purpose:
- Provides demographic enrichment for customer analytics.
==============================================================================*/

CREATE TABLE bronze.erp_cust_az12 (

    -- Customer identifier
    cid VARCHAR(50),

    -- Customer birth date
    bdate TIMESTAMP,

    -- Customer gender
    gen VARCHAR(50)
);



/*==============================================================================
Table: bronze.erp_px_cat_g1v2
Source System : ERP
Description   : Stores product categorization and maintenance metadata.

Business Purpose:
- Provides product hierarchy information.
- Enables category and subcategory reporting.
==============================================================================*/

CREATE TABLE bronze.erp_px_cat_g1v2 (

    -- Product identifier
    id VARCHAR(50),

    -- Product category
    cat VARCHAR(50),

    -- Product subcategory
    subcat VARCHAR(50),

    -- Product maintenance classification
    maintenance VARCHAR(50)
);