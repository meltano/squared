SELECT DISTINCT
    command,
    command_category,
    SPLIT(command, ' ') AS split_parts,
    SPLIT_PART(command, ' ', 3) AS split_part_3,
    SPLIT_PART(command, ' ', 4) AS split_part_4
FROM {{ ref('structured_events') }}