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