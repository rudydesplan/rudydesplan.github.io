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