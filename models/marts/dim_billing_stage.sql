{{ config(materialized='view') }}

with stages as (

    select
        'DEPOSIT' as billing_stage,
        1 as billing_stage_rank,
        'Deposit' as billing_stage_label

    union all

    select
        'BALANCE' as billing_stage,
        2 as billing_stage_rank,
        'Balance' as billing_stage_label

    union all

    select
        'POST_BALANCE' as billing_stage,
        3 as billing_stage_rank,
        'Post balance' as billing_stage_label

)

select
    billing_stage,
    billing_stage_rank,
    billing_stage_label
from stages