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