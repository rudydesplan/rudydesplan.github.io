{{ config(materialized='view') }}

with current_quote_stage as (

    select
        quote_stage_key,
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
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
        has_quote_data_quality_issue
    from {{ ref('dim_quote_stage') }}

),

pricing_snapshot_stages as (

    select
        pricing_stage,
        pricing_stage_rank,
        pricing_stage_label
    from {{ ref('dim_pricing_snapshot_stage') }}

),

current_quote_pricing_items as (

    select
        cqs.quote_stage_key,
        cqs.client_proposal_id,
        cqs.client_request_id,
        cqs.client_proposal_house_id,
        cqs.client_proposal_status,
        cqs.client_proposal_start_at,
        cqs.client_proposal_end_at,
        cqs.client_proposal_participants_count,
        cqs.client_proposal_quote_key,
        cqs.current_quote_id,
        cqs.current_quote_client_request_id,
        cqs.current_quote_house_id,
        cqs.current_quote_payment_type,
        cqs.current_quote_status,
        cqs.current_quote_deposit_rate,
        cqs.current_quote_start_at,
        cqs.current_quote_end_at,
        cqs.current_quote_created_at,
        cqs.has_quote_data_quality_issue,

        ipi.client_proposal_quote_pricing_item_key,
        ipi.client_proposal_quote_role,
        ipi.billing_stage,
        ipi.billing_stage_rank,
        ipi.billing_stage_label,
        ipi.is_billing_stage_known,
        ipi.quote_id,
        ipi.quote_client_request_id,
        ipi.quote_house_id,
        ipi.quote_payment_type,
        ipi.quote_status,
        ipi.quote_deposit_rate,
        ipi.quote_start_at,
        ipi.quote_end_at,
        ipi.quote_created_at,
        ipi.is_quote_role_consistent,
        ipi.is_request_consistent,
        ipi.is_house_consistent,

        ipi.pricing_item_id,
        ipi.pricing_item_source_client_proposal_id,
        ipi.service_owner_id,
        ipi.pricing_deposit_status,
        pss.pricing_stage_rank,
        pss.pricing_stage_label,
        ipi.pricing_type,
        ipi.pricing_category,
        ipi.price_option_quantity,
        ipi.total_price_base_price_price_without_vat,
        ipi.total_price_base_price_price_with_vat,
        ipi.price_option_user_fees_rate,
        ipi.price_option_owner_fees_rate,
        ipi.price_option_discount_rate,
        ipi.is_source_client_proposal_id_consistent

    from current_quote_stage cqs
    inner join {{ ref('int_proposal_quote_pricing_items') }} ipi
        on cqs.client_proposal_quote_key = ipi.client_proposal_quote_key
    left join pricing_snapshot_stages pss
        on ipi.pricing_deposit_status = pss.pricing_stage

),

ranked_pricing_items as (

    select
        quote_stage_key,
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
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
        has_quote_data_quality_issue,

        client_proposal_quote_pricing_item_key,
        client_proposal_quote_role,
        billing_stage,
        billing_stage_rank,
        billing_stage_label,
        is_billing_stage_known,
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

        pricing_item_id,
        pricing_item_source_client_proposal_id,
        service_owner_id,
        pricing_deposit_status,
        coalesce(pricing_stage_rank, 0) as pricing_stage_rank,
        pricing_stage_label,
        pricing_type,
        pricing_category,
        price_option_quantity,
        total_price_base_price_price_without_vat,
        total_price_base_price_price_with_vat,
        price_option_user_fees_rate,
        price_option_owner_fees_rate,
        price_option_discount_rate,
        is_source_client_proposal_id_consistent,

        row_number() over (
            partition by client_proposal_quote_key, pricing_item_id
            order by
                coalesce(pricing_stage_rank, 0) desc,
                client_proposal_quote_pricing_item_key desc
        ) as pricing_item_snapshot_order

    from current_quote_pricing_items

),

deduplicated_pricing_items as (

    select
        quote_stage_key,
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
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
        has_quote_data_quality_issue,

        client_proposal_quote_pricing_item_key,
        client_proposal_quote_role,
        billing_stage,
        billing_stage_rank,
        billing_stage_label,
        is_billing_stage_known,
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

        pricing_item_id,
        pricing_item_source_client_proposal_id,
        service_owner_id,
        pricing_deposit_status,
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
        is_source_client_proposal_id_consistent

    from ranked_pricing_items
    where pricing_item_snapshot_order = 1

),

latest_stage_per_owner as (

    select
        quote_stage_key,
        service_owner_id,
        max(pricing_stage_rank) as max_pricing_stage_rank
    from deduplicated_pricing_items
    group by
        quote_stage_key,
        service_owner_id

),

filtered_latest_stage as (

    select
        dpi.quote_stage_key,
        dpi.client_proposal_id,
        dpi.client_request_id,
        dpi.client_proposal_house_id,
        dpi.client_proposal_status,
        dpi.client_proposal_start_at,
        dpi.client_proposal_end_at,
        dpi.client_proposal_participants_count,
        dpi.client_proposal_quote_key,
        dpi.current_quote_id,
        dpi.current_quote_client_request_id,
        dpi.current_quote_house_id,
        dpi.current_quote_payment_type,
        dpi.current_quote_status,
        dpi.current_quote_deposit_rate,
        dpi.current_quote_start_at,
        dpi.current_quote_end_at,
        dpi.current_quote_created_at,
        dpi.has_quote_data_quality_issue,

        dpi.client_proposal_quote_pricing_item_key,
        dpi.client_proposal_quote_role,
        dpi.billing_stage,
        dpi.billing_stage_rank,
        dpi.billing_stage_label,
        dpi.is_billing_stage_known,
        dpi.quote_id,
        dpi.quote_client_request_id,
        dpi.quote_house_id,
        dpi.quote_payment_type,
        dpi.quote_status,
        dpi.quote_deposit_rate,
        dpi.quote_start_at,
        dpi.quote_end_at,
        dpi.quote_created_at,
        dpi.is_quote_role_consistent,
        dpi.is_request_consistent,
        dpi.is_house_consistent,

        dpi.pricing_item_id,
        dpi.pricing_item_source_client_proposal_id,
        dpi.service_owner_id,
        dpi.pricing_deposit_status,
        dpi.pricing_stage_rank,
        dpi.pricing_stage_label,
        dpi.pricing_type,
        dpi.pricing_category,
        dpi.price_option_quantity,
        dpi.total_price_base_price_price_without_vat,
        dpi.total_price_base_price_price_with_vat,
        dpi.price_option_user_fees_rate,
        dpi.price_option_owner_fees_rate,
        dpi.price_option_discount_rate,
        dpi.is_source_client_proposal_id_consistent

    from deduplicated_pricing_items dpi
    inner join latest_stage_per_owner lspo
        on dpi.quote_stage_key = lspo.quote_stage_key
       and dpi.service_owner_id = lspo.service_owner_id
       and dpi.pricing_stage_rank = lspo.max_pricing_stage_rank

),

final as (

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
        pricing_deposit_status as pricing_stage,
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

        is_quote_role_consistent,
        is_request_consistent,
        is_house_consistent,
        is_source_client_proposal_id_consistent,
        has_quote_data_quality_issue,

        pricing_stage_rank > 0 as is_pricing_stage_known,

        not (
            is_quote_role_consistent
            and is_request_consistent
            and is_house_consistent
            and is_source_client_proposal_id_consistent
            and is_billing_stage_known
            and pricing_stage_rank > 0
        ) as has_current_quote_pricing_item_data_quality_issue

    from filtered_latest_stage

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

    is_quote_role_consistent,
    is_request_consistent,
    is_house_consistent,
    is_source_client_proposal_id_consistent,
    has_quote_data_quality_issue,
    is_pricing_stage_known,
    has_current_quote_pricing_item_data_quality_issue

from final