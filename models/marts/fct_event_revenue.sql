{{ config(materialized='table') }}

with pre_event_revenue as (

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
    has_data_quality_issue
    from {{ ref('pre_fct_event_revenue') }}

),

latest_stage_per_proposal as (

    select
        client_proposal_id,
        quote_stage_key,
        billing_stage,
        billing_stage_rank,
        current_quote_id,
        current_quote_created_at
    from (
        select distinct
            client_proposal_id,
            quote_stage_key,
            billing_stage,
            billing_stage_rank,
            current_quote_id,
            current_quote_created_at,
            row_number() over (
                partition by client_proposal_id
                order by
                    billing_stage_rank desc,
                    current_quote_created_at desc,
                    current_quote_id desc
            ) as rn
        from pre_event_revenue
    )
    where rn = 1

),

final as (

    select
        p.event_revenue_key,
        p.quote_stage_key,
        p.client_proposal_id,
        p.client_request_id,
        p.client_request_company_id,
        p.client_request_company_name,
        p.client_proposal_house_id,
        p.service_owner_id,
        p.client_proposal_status,
        p.client_proposal_start_at,
        p.client_proposal_end_at,
        p.client_proposal_participants_count,
        p.client_proposal_quote_role,
        p.billing_stage,
        p.billing_stage_rank,
        p.billing_stage_label,
        p.client_proposal_quote_key,
        p.current_quote_id,
        p.current_quote_client_request_id,
        p.current_quote_house_id,
        p.current_quote_payment_type,
        p.current_quote_status,
        p.current_quote_deposit_rate,
        p.current_quote_start_at,
        p.current_quote_end_at,
        p.current_quote_created_at,
        p.pricing_item_count,
        p.service_line_count,
        p.client_fee_line_count,
        p.partner_commission_line_count,
        p.max_pricing_stage_rank,
        p.pricing_stage_count,
        p.gmv_service_net,
        p.gmv_with_client_fees,
        p.naboo_client_fees,
        p.naboo_partner_commission,
        p.total_margin,
        p.supplier_net_payout,
        p.total_discount,
        p.service_gross_amount,
        p.is_quote_role_consistent,
        p.is_request_consistent,
        p.is_house_consistent,
        p.is_source_client_proposal_id_consistent,
        p.is_billing_stage_known,
        p.is_pricing_stage_known,
        p.is_quote_data_quality_valid,
        p.is_current_quote_pricing_item_data_quality_valid,
        p.is_revenue_component_data_quality_valid,
        p.has_data_quality_issue
    from pre_event_revenue p
    inner join latest_stage_per_proposal l
        on p.client_proposal_id = l.client_proposal_id
       and p.quote_stage_key = l.quote_stage_key

)

select *
from final