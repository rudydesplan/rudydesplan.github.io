stg_quotes.sql :

{{ config(materialized='view') }}

with source as (

    select
        quote_id,
        client_request_id,
        house_id,
        payment_type,
        status,
        deposit_rate,
        start_date,
        end_date,
        created_at,
        deleted
    from {{ source('naboo_test', 'quotes') }}

),

filtered as (

    select
        quote_id,
        client_request_id,
        house_id,
        payment_type,
        status,
        deposit_rate,
        start_date,
        end_date,
        created_at
    from source
    where deleted = false

),

normalized as (

    select
        quote_id,
        client_request_id,
        house_id as quote_house_id,

        upper(payment_type) as quote_payment_type,
        upper(status) as quote_status,

        -- normalize micro-rate → ratio
        deposit_rate / 1000000 as quote_deposit_rate,

        start_date as quote_start_at,
        end_date as quote_end_at,

        created_at as quote_created_at,
		
		current_timestamp() as _loaded_at

    from filtered

)

select
    quote_id,
    client_request_id,
    quote_house_id,
    quote_payment_type,
    quote_status,
    quote_deposit_rate,
    quote_start_at,
    quote_end_at,
    quote_created_at,
	_loaded_at
from normalized

stg_client_requests.sql :

{{ config(materialized='view') }}

with source as (

    select
        request_id,
        company_id,
        company_name,
        status,
        created_at,
        adults,
        deleted
    from {{ source('naboo_test', 'client_requests') }}

),

filtered as (

    -- Remove deleted rows
    select
        request_id,
        company_id,
        company_name,
        status,
        created_at,
        adults
    from source
    where deleted = false

),

normalized as (

    select
	
		{{ dbt_utils.generate_surrogate_key(['request_id']) }} as client_request_key,
	
        -- Primary key
        request_id as client_request_id,

        -- Company information
        company_id as client_request_company_id,
		
        nullif(trim(company_name), '') as client_request_company_name,

        -- Status normalization
        upper(status) as client_request_status,

        -- Metadata
        created_at as client_request_created_at,

        -- Business metric
        adults as client_request_participants_count,
		
		current_timestamp() as _loaded_at

    from filtered

)

select
	client_request_key,
    client_request_id,
    client_request_company_id,
    client_request_company_name,
    client_request_status,
    client_request_created_at,
    client_request_participants_count,
	_loaded_at
from normalized

stg_client_proposals.sql :

{{ config(materialized='view') }}

with source as (

    select
        client_proposal_id,
        client_request_id,
        house_id,
        status,
        deposit_rate,
        deposit_quote_ids,
        balance_quote_ids,
        balance_post_stay_quote_ids,
        start_date,
        end_date,
        adults,
        deleted
    from {{ source('naboo_test', 'client_proposals') }}

),

filtered as (

    select
        client_proposal_id,
        client_request_id,
        house_id,
        status,
        deposit_rate,
        deposit_quote_ids,
        balance_quote_ids,
        balance_post_stay_quote_ids,
        start_date,
        end_date,
        adults
    from source
    where deleted = false

),

normalized as (

    select
        client_proposal_id ,
        client_request_id ,
        house_id as client_proposal_house_id,

        upper(status) as client_proposal_status,

        -- normalize micro-rate → ratio
        deposit_rate / 1000000 as client_proposal_deposit_rate,

        deposit_quote_ids,
        balance_quote_ids,
        balance_post_stay_quote_ids,

        start_date as client_proposal_start_at,
        end_date as client_proposal_end_at,

        adults as client_proposal_participants_count,
		
		current_timestamp() as _loaded_at

    from filtered

)

select
    client_proposal_id,
    client_request_id,
    client_proposal_house_id,
    client_proposal_status,
    client_proposal_deposit_rate,
    deposit_quote_ids,
    balance_quote_ids,
    balance_post_stay_quote_ids,
    client_proposal_start_at,
    client_proposal_end_at,
    client_proposal_participants_count,
	_loaded_at
from normalized

stg_client_pricing_items.sql :

{{ config(materialized='view') }}

with source as (

    select
        pricing_item_id,
        quote_id,
        client_proposal_id,
        service_owner_id,
        deposit_status,
        type,
        category,
        price_option_quantity,
        total_price_base_price_price_without_vat,
        total_price_base_price_price_with_vat,
        price_option_fees_user_fees_rate,
        price_option_fees_owner_fees_rate,
        price_option_discount_rate,
        deleted
    from {{ source('naboo_test', 'client_pricing_items') }}

),

filtered as (

    select
        pricing_item_id,
        quote_id,
        client_proposal_id,
        service_owner_id,
        deposit_status,
        type,
        category,
        price_option_quantity,
        total_price_base_price_price_without_vat,
        total_price_base_price_price_with_vat,
        price_option_fees_user_fees_rate,
        price_option_fees_owner_fees_rate,
        price_option_discount_rate
    from source
    where deleted = false

),

normalized as (

    select
        pricing_item_id,
        quote_id,

        -- kept only for information (not reliable for joins)
        client_proposal_id,

        service_owner_id,

        upper(deposit_status) as pricing_deposit_status,
        upper(type) as pricing_type,
        upper(category) as pricing_category,

        price_option_quantity ,

        total_price_base_price_price_without_vat,
        total_price_base_price_price_with_vat,

        -- normalize micro-rates → ratios
        price_option_fees_user_fees_rate / 1000000 as price_option_user_fees_rate,
        price_option_fees_owner_fees_rate / 1000000 as price_option_owner_fees_rate,
        price_option_discount_rate / 1000000 as price_option_discount_rate,
		
		current_timestamp() as _loaded_at

    from filtered

)

select
    pricing_item_id,
    quote_id,
    client_proposal_id,
    service_owner_id,
    pricing_deposit_status,
    pricing_type,
    pricing_category,
    price_option_quantity,
    total_price_base_price_price_without_vat,
    total_price_base_price_price_with_vat,
    price_option_user_fees_rate,
    price_option_owner_fees_rate,
    price_option_discount_rate,
	_loaded_at
from normalized