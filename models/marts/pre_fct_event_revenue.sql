{{ config(materialized='table') }}

with revenue_components as (

    select
        client_proposal_quote_pricing_item_key,
        quote_stage_key,
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
        is_billing_stage_known,
        client_proposal_quote_key,
        current_quote_id,
        current_quote_client_request_id,
        current_quote_house_id,
        current_quote_payment_type,
        current_quote_status,
        current_quote_deposit_rate,
        current_quote_start_at,
        current_quote_end_at,
        current_quote_created_at,
        pricing_item_id,
        pricing_item_source_client_proposal_id,
        service_owner_id,
        pricing_stage,
        pricing_stage_rank,
        pricing_stage_label,
        pricing_type,
        pricing_category,
        price_option_quantity,
        total_price_base_price_price_without_vat,
        total_price_base_price_price_with_vat,
        price_option_user_fees_rate,
        price_option_owner_fees_rate,
        price_option_discount_rate,
        is_service_line,
        is_client_fee_line,
        is_partner_commission_line,
        service_gross_amount,
        discount_amount,
        service_net_amount,
        client_fee_amount,
        partner_commission_amount,
        total_margin_amount,
        gmv_service_net_amount,
        gmv_with_client_fees_amount,
        net_supplier_payout_amount,
        is_quote_role_consistent,
        is_request_consistent,
        is_house_consistent,
        is_source_client_proposal_id_consistent,
        has_quote_data_quality_issue,
        is_pricing_stage_known,
        has_current_quote_pricing_item_data_quality_issue,
        has_revenue_component_data_quality_issue
    from {{ ref('int_pricing_item_revenue_components') }}

),

requests as (

    select
        client_request_id,
        client_request_company_id,
        client_request_company_name
    from {{ ref('stg_client_requests') }}

),

aggregated as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'rc.quote_stage_key',
            'rc.service_owner_id'
        ]) }} as event_revenue_key,

        rc.quote_stage_key,
        rc.client_proposal_id,
        rc.client_request_id,
        r.client_request_company_id,
        r.client_request_company_name,
        rc.client_proposal_house_id,
        rc.service_owner_id,

        rc.client_proposal_status,
        rc.client_proposal_start_at,
        rc.client_proposal_end_at,
        rc.client_proposal_participants_count,

        rc.client_proposal_quote_role,
        rc.billing_stage,
        rc.billing_stage_rank,
        rc.billing_stage_label,

        rc.client_proposal_quote_key,
        rc.current_quote_id,
        rc.current_quote_client_request_id,
        rc.current_quote_house_id,
        rc.current_quote_payment_type,
        rc.current_quote_status,
        rc.current_quote_deposit_rate,
        rc.current_quote_start_at,
        rc.current_quote_end_at,
        rc.current_quote_created_at,

        count(*) as pricing_item_count,
        countif(rc.is_service_line) as service_line_count,
        countif(rc.is_client_fee_line) as client_fee_line_count,
        countif(rc.is_partner_commission_line) as partner_commission_line_count,

        max(rc.pricing_stage_rank) as max_pricing_stage_rank,
        count(distinct rc.pricing_stage) as pricing_stage_count,

        round(sum(rc.gmv_service_net_amount), 2) as gmv_service_net,
        round(sum(rc.gmv_with_client_fees_amount), 2) as gmv_with_client_fees,
        round(sum(rc.client_fee_amount), 2) as naboo_client_fees,
        round(sum(rc.partner_commission_amount), 2) as naboo_partner_commission,
        round(sum(rc.total_margin_amount), 2) as total_margin,
        round(sum(rc.net_supplier_payout_amount), 2) as supplier_net_payout,
        round(sum(rc.discount_amount), 2) as total_discount,
		round(sum(rc.service_gross_amount), 2) as service_gross_amount,

        logical_and(rc.is_quote_role_consistent) as is_quote_role_consistent,
        logical_and(rc.is_request_consistent) as is_request_consistent,
        logical_and(rc.is_house_consistent) as is_house_consistent,
        logical_and(rc.is_source_client_proposal_id_consistent) as is_source_client_proposal_id_consistent,
        logical_and(rc.is_billing_stage_known) as is_billing_stage_known,
        logical_and(rc.is_pricing_stage_known) as is_pricing_stage_known,
        logical_and(not rc.has_quote_data_quality_issue) as is_quote_data_quality_valid,
        logical_and(not rc.has_current_quote_pricing_item_data_quality_issue) as is_current_quote_pricing_item_data_quality_valid,
        logical_and(not rc.has_revenue_component_data_quality_issue) as is_revenue_component_data_quality_valid

    from revenue_components rc
    left join requests r
        on rc.client_request_id = r.client_request_id
    group by
        event_revenue_key,
        rc.quote_stage_key,
        rc.client_proposal_id,
        rc.client_request_id,
        r.client_request_company_id,
        r.client_request_company_name,
        rc.client_proposal_house_id,
        rc.service_owner_id,
        rc.client_proposal_status,
        rc.client_proposal_start_at,
        rc.client_proposal_end_at,
        rc.client_proposal_participants_count,
        rc.client_proposal_quote_role,
        rc.billing_stage,
        rc.billing_stage_rank,
        rc.billing_stage_label,
        rc.client_proposal_quote_key,
        rc.current_quote_id,
        rc.current_quote_client_request_id,
        rc.current_quote_house_id,
        rc.current_quote_payment_type,
        rc.current_quote_status,
        rc.current_quote_deposit_rate,
        rc.current_quote_start_at,
        rc.current_quote_end_at,
        rc.current_quote_created_at

)

select
    event_revenue_key,
    quote_stage_key,
    client_proposal_id,
    client_request_id,
    client_request_company_id,
    client_request_company_name,
    client_proposal_house_id,
    service_owner_id,
    client_proposal_status,
    client_proposal_start_at,
    client_proposal_end_at,
    client_proposal_participants_count,
    client_proposal_quote_role,
    billing_stage,
    billing_stage_rank,
    billing_stage_label,
    client_proposal_quote_key,
    current_quote_id,
    current_quote_client_request_id,
    current_quote_house_id,
    current_quote_payment_type,
    current_quote_status,
    current_quote_deposit_rate,
    current_quote_start_at,
    current_quote_end_at,
    current_quote_created_at,
    pricing_item_count,
    service_line_count,
    client_fee_line_count,
    partner_commission_line_count,
    max_pricing_stage_rank,
    pricing_stage_count,
    gmv_service_net,
    gmv_with_client_fees,
    naboo_client_fees,
    naboo_partner_commission,
    total_margin,
    supplier_net_payout,
    total_discount,
	service_gross_amount,
    is_quote_role_consistent,
    is_request_consistent,
    is_house_consistent,
    is_source_client_proposal_id_consistent,
    is_billing_stage_known,
    is_pricing_stage_known,
    is_quote_data_quality_valid,
    is_current_quote_pricing_item_data_quality_valid,
    is_revenue_component_data_quality_valid,
    not (
        is_quote_role_consistent
        and is_request_consistent
        and is_house_consistent
        and is_source_client_proposal_id_consistent
        and is_billing_stage_known
        and is_pricing_stage_known
        and is_quote_data_quality_valid
        and is_current_quote_pricing_item_data_quality_valid
        and is_revenue_component_data_quality_valid
    ) as has_data_quality_issue
from aggregated