WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_slack', 'channels') }}

    UNION ALL

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_slack_public', 'channels') }}

),

renamed AS (

    SELECT
        id AS channel_id,
        creator AS creator_user_id,
        is_archived,
        is_channel,
        is_ext_shared,
        is_general,
        is_group,
        is_im,
        is_member,
        is_mpim,
        is_org_shared,
        is_pending_ext_shared,
        is_private,
        is_shared,
        name AS channel_name,
        name_normalized AS channel_name_normalized,
        num_members,
        parent_conversation,
        pending_connected_team_ids,
        pending_shared,
        previous_names,
        purpose,
        shared_team_ids,
        topic,
        unlinked,
        TO_TIMESTAMP_NTZ(created::INT) AS created_at
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
