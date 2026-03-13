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

    from {{ ref('int_proposal_quotes_valid') }}

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
            partition by client_proposal_id, client_proposal_quote_role
            order by
                case when is_quote_role_consistent then 0 else 1 end,
				case when quote_status = 'WON' then 0 else 1 end,
                quote_created_at desc,
                quote_id desc
        ) as quote_stage_order

    from enriched

),

final as (

    select

        {{ dbt_utils.generate_surrogate_key(['client_proposal_id','client_proposal_quote_role']) }} as quote_stage_key,

        client_proposal_id ,
        client_request_id ,
        client_proposal_house_id ,
        client_proposal_status ,
        client_proposal_start_at ,
        client_proposal_end_at ,
        client_proposal_participants_count,
		client_proposal_quote_role,

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

    is_quote_role_consistent,
    is_request_consistent,
    is_house_consistent,

    is_billing_stage_known,
    has_quote_data_quality_issue

from final