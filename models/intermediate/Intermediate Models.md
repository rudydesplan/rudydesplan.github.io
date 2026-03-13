dim_quote_stage.sql :

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
        is_house_consistent

    from {{ ref('int_proposal_quotes') }}

),

billing_stages as (

    select
        billing_stage,
        billing_stage_rank,
        billing_stage_label
    from {{ ref('dim_billing_stage') }}

),

enriched as (

    select
        pq.client_proposal_quote_key,
        pq.client_proposal_id,
        pq.client_request_id,
        pq.client_proposal_house_id,
        pq.client_proposal_status,
        pq.client_proposal_start_at,
        pq.client_proposal_end_at,
        pq.client_proposal_participants_count,
        pq.client_proposal_quote_role,

        bs.billing_stage,
        bs.billing_stage_rank,
        bs.billing_stage_label,

        pq.quote_id,
        pq.quote_client_request_id,
        pq.quote_house_id,
        pq.quote_payment_type,
        pq.quote_status,
        pq.quote_deposit_rate,
        pq.quote_start_at,
        pq.quote_end_at,
        pq.quote_created_at,

        pq.is_quote_role_consistent,
        pq.is_request_consistent,
        pq.is_house_consistent

    from proposal_quotes pq
    left join billing_stages bs
        on pq.client_proposal_quote_role = bs.billing_stage

),

ranked as (

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

        row_number() over (
            partition by client_proposal_id
            order by
                coalesce(billing_stage_rank, 0) desc,
                quote_created_at desc,
                quote_id desc
        ) as quote_stage_order

    from enriched

),

final as (

    select

        {{ dbt_utils.generate_surrogate_key(['client_proposal_id']) }} as quote_stage_key,

        client_proposal_id ,
        client_request_id ,
        client_proposal_house_id ,
        client_proposal_status ,
        client_proposal_start_at ,
        client_proposal_end_at ,
        client_proposal_participants_count,

        billing_stage,
        billing_stage_rank,
        billing_stage_label,

        client_proposal_quote_key ,

        quote_id as current_quote_id,
        quote_client_request_id as current_quote_client_request_id,
        quote_house_id as current_quote_house_id,
        quote_payment_type as current_quote_payment_type,
        quote_status as current_quote_status,
        quote_deposit_rate as current_quote_deposit_rate,
        quote_start_at as current_quote_start_at,
        quote_end_at as current_quote_end_at,
        quote_created_at as current_quote_created_at,

        is_quote_role_consistent,
        is_request_consistent,
        is_house_consistent,

        billing_stage_rank is not null as is_billing_stage_known,

        not (
            is_quote_role_consistent
            and is_request_consistent
            and is_house_consistent
            and billing_stage_rank is not null
        ) as has_quote_data_quality_issue

    from ranked
    where quote_stage_order = 1

)

select
    quote_stage_key,

    client_proposal_id,
    client_request_id,
    client_proposal_house_id,
    client_proposal_status,
    client_proposal_start_at,
    client_proposal_end_at,
    client_proposal_participants_count,

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

    is_quote_role_consistent,
    is_request_consistent,
    is_house_consistent,

    is_billing_stage_known,
    has_quote_data_quality_issue

from final

int_current_quote_pricing_items.sql :

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

ranked as (

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
        ) as pricing_snapshot_order

    from current_quote_pricing_items

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

    from ranked
    where pricing_snapshot_order = 1

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

int_pricing_item_revenue_components.sql :

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

int_proposal_quote_pricing_items.sql :

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
    from {{ ref('int_proposal_quotes') }}

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

int_proposal_quotes.sql :

{{ config(materialized='view') }}

with proposal_quote_roles as (

    select
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
        'DEPOSIT' as client_proposal_quote_role,
        deposit_quote_ids as raw_quote_ids
    from {{ ref('stg_client_proposals') }}

    union all

    select
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
        'BALANCE' as client_proposal_quote_role,
        balance_quote_ids as raw_quote_ids
    from {{ ref('stg_client_proposals') }}

    union all

    select
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
        'POST_BALANCE' as client_proposal_quote_role,
        balance_post_stay_quote_ids as raw_quote_ids
    from {{ ref('stg_client_proposals') }}

),

exploded as (

    select
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
        client_proposal_quote_role,
        trim(raw_quote_id) as client_proposal_quote_id
    from proposal_quote_roles,
    unnest(split(ifnull(raw_quote_ids, ''), ',')) as raw_quote_id

),

filtered as (

    select distinct
        client_proposal_id,
        client_request_id,
        client_proposal_house_id,
        client_proposal_status,
        client_proposal_start_at,
        client_proposal_end_at,
        client_proposal_participants_count,
        client_proposal_quote_role,
        client_proposal_quote_id
    from exploded
    where client_proposal_quote_id <> ''

),

billing_stages as (

    select
        billing_stage,
        billing_stage_rank,
        billing_stage_label
    from {{ ref('dim_billing_stage') }}

),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'f.client_proposal_id',
            'f.client_proposal_quote_role',
            'f.client_proposal_quote_id'
        ]) }} as client_proposal_quote_key,

        f.client_proposal_id,
        f.client_request_id,
        f.client_proposal_house_id,
        f.client_proposal_status,
        f.client_proposal_start_at,
        f.client_proposal_end_at,
        f.client_proposal_participants_count,

        f.client_proposal_quote_role,
        bs.billing_stage,
        bs.billing_stage_rank,
        bs.billing_stage_label,

        q.quote_id,

        q.client_request_id as quote_client_request_id,
        q.quote_house_id ,
        q.quote_payment_type,
        q.quote_status,
        q.quote_deposit_rate,
        q.quote_start_at,
        q.quote_end_at,
        q.quote_created_at,

        (f.client_proposal_quote_role = q.quote_payment_type) as is_quote_role_consistent,
        (f.client_request_id = q.client_request_id) as is_request_consistent,
        (f.client_proposal_house_id = q.quote_house_id) as is_house_consistent,
        (bs.billing_stage is not null) as is_billing_stage_known

    from filtered f
    inner join {{ ref('stg_quotes') }} q
        on f.client_proposal_quote_id = q.quote_id
    left join billing_stages bs
        on f.client_proposal_quote_role = bs.billing_stage

)

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
from joined

