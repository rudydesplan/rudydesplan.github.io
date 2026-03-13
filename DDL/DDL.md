CREATE TABLE 
    `naboo-app-365515.naboo_test.client_pricing_items`
    (
        pricing_item_id STRING,
        quote_id STRING,
        client_proposal_id STRING,
        service_owner_id STRING,
        deposit_status STRING,
        type STRING,
        category STRING,
        price_option_quantity FLOAT64,
        total_price_base_price_price_without_vat FLOAT64,
        total_price_base_price_price_with_vat FLOAT64,
        price_option_fees_user_fees_rate FLOAT64,
        price_option_fees_owner_fees_rate FLOAT64,
        price_option_discount_rate FLOAT64,
        deleted BOOL
    );
	
CREATE TABLE 
    `naboo-app-365515.naboo_test.quotes`
    (
        quote_id STRING,
        client_request_id STRING,
        house_id STRING,
        payment_type STRING,
        status STRING,
        deposit_rate INT64,
        start_date TIMESTAMP,
        end_date   TIMESTAMP,
        created_at TIMESTAMP,
        deleted BOOL
    );
	
CREATE TABLE 
    `naboo-app-365515.naboo_test.client_requests`
    (
        request_id STRING,
        company_id STRING,
        company_name STRING,
        status STRING,
        created_at TIMESTAMP,
        adults INT64,
        deleted BOOL
    );
	
CREATE TABLE 
    `naboo-app-365515.naboo_test.client_proposals`
    (
        client_proposal_id STRING,
        client_request_id STRING,
        house_id STRING,
        status STRING,
        deposit_rate INT64,
        deposit_quote_ids STRING,
        balance_quote_ids STRING,
        balance_post_stay_quote_ids STRING,
        start_date TIMESTAMP,
        end_date   TIMESTAMP,
        adults INT64,
        deleted BOOL
    );