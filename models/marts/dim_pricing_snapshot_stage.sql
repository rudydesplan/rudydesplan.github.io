{{ config(materialized='view') }}

with stages as (

    select
        'INITIAL' as pricing_stage,
        1 as pricing_stage_rank,
        'Initial snapshot' as pricing_stage_label

    union all

    select
        'FINAL' as pricing_stage,
        2 as pricing_stage_rank,
        'Final snapshot' as pricing_stage_label

    union all

    select
        'POST_FINAL' as pricing_stage,
        3 as pricing_stage_rank,
        'Post final snapshot' as pricing_stage_label

)

select
    pricing_stage,
    pricing_stage_rank,
    pricing_stage_label
from stages