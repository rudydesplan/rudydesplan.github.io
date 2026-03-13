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