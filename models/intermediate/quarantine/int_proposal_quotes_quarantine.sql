{{ config(materialized='table') }}

select
    client_proposal_quote_key,
    client_proposal_id,
    client_request_id,
    client_proposal_house_id,
    client_proposal_status,
    client_proposal_start_at,
    client_proposal_end_at,
    client_proposal_participants_count,
    client_proposal_quote_role,
    billing_stage,
    billing_stage_rank,
    billing_stage_label,
    quote_id,
    quote_client_request_id,
    quote_house_id,
    quote_payment_type,
    quote_status,
    quote_deposit_rate,
    quote_start_at,
    quote_end_at,
    quote_created_at,
    is_quote_role_consistent,
    is_request_consistent,
    is_house_consistent,
    is_billing_stage_known
from {{ ref('int_proposal_quotes') }}
where is_quote_role_consistent = false