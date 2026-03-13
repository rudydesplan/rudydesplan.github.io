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