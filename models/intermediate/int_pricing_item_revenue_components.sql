{{ config(materialized='view') }}

with current_quote_pricing_items as (

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

        quote_id,
        quote_client_request_id,
        quote_house_id,
        quote_payment_type,
        quote_status,
        quote_deposit_rate,
        quote_start_at,
        quote_end_at,
        quote_created_at,

        pricing_item_id,
        pricing_item_source_client_proposal_id,
        service_owner_id,
        pricing_stage,
        pricing_stage_rank,
        pricing_stage_label,
        pricing_type,
        pricing_category,
        price_option_quantity,
		
        cast(coalesce(total_price_base_price_price_without_vat, 0) as numeric) as total_price_base_price_price_without_vat,
        cast(coalesce(total_price_base_price_price_with_vat, 0) as numeric) as total_price_base_price_price_with_vat,
        cast(coalesce(price_option_user_fees_rate, 0) as numeric) as price_option_user_fees_rate,
        cast(coalesce(price_option_owner_fees_rate, 0) as numeric) as price_option_owner_fees_rate,
        cast(coalesce(price_option_discount_rate, 0) as numeric) as price_option_discount_rate,

        is_quote_role_consistent,
        is_request_consistent,
        is_house_consistent,
        is_source_client_proposal_id_consistent,
        has_quote_data_quality_issue,
        is_pricing_stage_known,
        has_current_quote_pricing_item_data_quality_issue
    from {{ ref('int_current_quote_pricing_items') }}

),

components as (

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

        quote_id,
        quote_client_request_id,
        quote_house_id,
        quote_payment_type,
        quote_status,
        quote_deposit_rate,
        quote_start_at,
        quote_end_at,
        quote_created_at,

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

        pricing_type = 'AD_HOC' as is_service_line,
        pricing_type = 'USER_FEES' as is_client_fee_line,
        pricing_type = 'OWNER_FEES' as is_partner_commission_line,

        case
            when pricing_type = 'AD_HOC' then total_price_base_price_price_with_vat
            else cast(0 as numeric)
        end as service_gross_amount,

        case
            when pricing_type = 'AD_HOC' then total_price_base_price_price_with_vat * price_option_discount_rate
            else cast(0 as numeric)
        end as discount_amount,

        case
            when pricing_type = 'AD_HOC' then total_price_base_price_price_with_vat - (total_price_base_price_price_with_vat * price_option_discount_rate)
            else cast(0 as numeric)
        end as service_net_amount,

        case
            when pricing_type = 'USER_FEES' then total_price_base_price_price_with_vat
            else cast(0 as numeric)
        end as client_fee_amount,

        case
            when pricing_type = 'OWNER_FEES' then total_price_base_price_price_with_vat
            else cast(0 as numeric)
        end as partner_commission_amount,

        case
            when pricing_type in ('USER_FEES', 'OWNER_FEES') then total_price_base_price_price_with_vat
            else cast(0 as numeric)
        end as total_margin_amount,

        case
            when pricing_type = 'AD_HOC' then total_price_base_price_price_with_vat - (total_price_base_price_price_with_vat * price_option_discount_rate)
            else cast(0 as numeric)
        end as gmv_service_net_amount,

        case
            when pricing_type = 'AD_HOC' then total_price_base_price_price_with_vat - (total_price_base_price_price_with_vat * price_option_discount_rate)
            when pricing_type = 'USER_FEES' then total_price_base_price_price_with_vat
            else cast(0 as numeric)
        end as gmv_with_client_fees_amount,

        case
            when pricing_type = 'AD_HOC' then total_price_base_price_price_with_vat - (total_price_base_price_price_with_vat * price_option_discount_rate)
            when pricing_type = 'OWNER_FEES' then -total_price_base_price_price_with_vat
            else cast(0 as numeric)
        end as net_supplier_payout_amount,
		
		is_quote_role_consistent,
        is_request_consistent,
        is_house_consistent,
        is_source_client_proposal_id_consistent,
        has_quote_data_quality_issue,
        is_pricing_stage_known,
        has_current_quote_pricing_item_data_quality_issue,

        not (
            is_quote_role_consistent
            and is_request_consistent
            and is_house_consistent
            and is_source_client_proposal_id_consistent
            and is_billing_stage_known
            and is_pricing_stage_known
            and not has_quote_data_quality_issue
            and not has_current_quote_pricing_item_data_quality_issue
        ) as has_revenue_component_data_quality_issue

    from current_quote_pricing_items

)

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

    quote_id,
    quote_client_request_id,
    quote_house_id,
    quote_payment_type,
    quote_status,
    quote_deposit_rate,
    quote_start_at,
    quote_end_at,
    quote_created_at,

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

from components