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