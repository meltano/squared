with github as (
    select distinct author_id, author_username from dbt_prod.stg_github__issues
    union
    select distinct author_id, author_username from dbt_prod.stg_github__pull_requests 
),
gitlab as (

	select distinct author_id, author_username from {{ ref('stg_gitlab__merge_requests') }}
	union
	select distinct author_id, author_username from {{ ref('stg_gitlab__issues') }}

),
name_matches as (
select
    github.author_id AS github_author_id,
    github.author_username AS github_author_username,
    gitlab.author_id AS gitlab_author_id,
    gitlab.author_username AS gitlab_author_username
from github
full join gitlab on lower(github.author_username) = lower(gitlab.author_username)
),
blend_all as (
select
    COALESCE(name_matches.github_author_id, manual_contributor_id_mapping.github_id) AS github_author_id,
    COALESCE(name_matches.github_author_username, manual_contributor_id_mapping.github_username) AS github_author_username,
    COALESCE(name_matches.gitlab_author_id, manual_contributor_id_mapping.gitlab_id) AS gitlab_author_id,
    COALESCE(name_matches.gitlab_author_username, manual_contributor_id_mapping.gitlab_username) AS gitlab_author_username
from name_matches
left join {{ ref('contributor_id_mapping') }} on name_matches.github_author_id = manual_contributor_id_mapping.github_id
)
select
    COALESCE(cast(github_author_id as varchar), '') || COALESCE(cast(gitlab_author_id as varchar), '') AS user_surrogate_key,
    *
from blend_all
