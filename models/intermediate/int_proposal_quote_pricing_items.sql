{{ config(materialized='view') }}

with proposal_quotes as (

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
    from {{ ref('int_proposal_quotes_valid') }}

),

pricing_items as (

    select
        pricing_item_id,
        quote_id,
        client_proposal_id as pricing_item_source_client_proposal_id,
        service_owner_id,
        pricing_deposit_status,
        pricing_type,
        pricing_category,
        price_option_quantity,
        total_price_base_price_price_without_vat,
        total_price_base_price_price_with_vat,
        price_option_user_fees_rate,
        price_option_owner_fees_rate,
        price_option_discount_rate
    from {{ ref('stg_client_pricing_items') }}

),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'pq.client_proposal_quote_key',
            'pi.pricing_item_id',
            'pi.pricing_deposit_status'
        ]) }} as client_proposal_quote_pricing_item_key,

        -- bridge key
        pq.client_proposal_quote_key,

        -- proposal columns
        pq.client_proposal_id,
        pq.client_request_id,
        pq.client_proposal_house_id,
        pq.client_proposal_status,
        pq.client_proposal_start_at,
        pq.client_proposal_end_at,
        pq.client_proposal_participants_count,

        -- quote columns
        pq.client_proposal_quote_role,
        pq.billing_stage,
        pq.billing_stage_rank,
        pq.billing_stage_label,
        pq.quote_id,
        pq.quote_client_request_id,
        pq.quote_house_id,
        pq.quote_payment_type,
        pq.quote_status,
        pq.quote_deposit_rate,
        pq.quote_start_at,
        pq.quote_end_at,
        pq.quote_created_at,

        -- quote data quality flags
        pq.is_quote_role_consistent,
        pq.is_request_consistent,
        pq.is_house_consistent,
        pq.is_billing_stage_known,

        -- pricing item columns
        pi.pricing_item_id,
        pi.pricing_item_source_client_proposal_id,
        pi.service_owner_id,
        pi.pricing_deposit_status,
        pi.pricing_type,
        pi.pricing_category,
        pi.price_option_quantity,
        pi.total_price_base_price_price_without_vat,
        pi.total_price_base_price_price_with_vat,
        pi.price_option_user_fees_rate,
        pi.price_option_owner_fees_rate,
        pi.price_option_discount_rate,

        -- pricing item / proposal consistency
        (
            pi.pricing_item_source_client_proposal_id is null
            or pi.pricing_item_source_client_proposal_id = pq.client_proposal_id
        ) as is_source_client_proposal_id_consistent

    from proposal_quotes pq
    inner join pricing_items pi
        on pq.quote_id = pi.quote_id

)

select
    client_proposal_quote_pricing_item_key,
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
    is_billing_stage_known,

    pricing_item_id,
    pricing_item_source_client_proposal_id,
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

    is_source_client_proposal_id_consistent

from joined