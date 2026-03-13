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