# Permifrost

## Adding and Installing

Run the following command to get the permifrost package installed in your Meltano project.

```bash
meltano install utility --custom permifrost
# (namespace) [permifrost]:
# (pip_url) [permifrost]:
# (executable) [permifrost]:
```

Then you need to create a spec file that will hold your roles definitions.

```bash
touch utilities/permifrost/roles.yml
```

Permifrost commands need to pass the path to the spec file, so you can either include it in each execution command or you can manually add a `commands` entry to your meltano.yml config so it looks like the following:

```yaml
  - name: permifrost
    namespace: permifrost
    pip_url: permifrost
    executable: permifrost
    commands:
      run: run utilities/permifrost/roles.yml
      spec-test: spec-test utilities/permifrost/roles.yml
```

If this plugin is run in an ephemeral environment or is run on a machine with a fresh clone of the repo, you will need to install the configured python packages before you can execute the plugin:

```bash
# Install
meltano install utility permifrost
```

Permifrost executions SQL commands on your behalf to update permissions based on your roles.yml config.
You need to include the following keys in your environment configuration and `.env` file (for passwords/account_id) in order for it to work.
The `PERMISSION_BOT_USER` needs to have the `SECURITYADMIN` role, see Settings section of [the README](https://gitlab.com/gitlab-data/permifrost/-/blob/master/README.md) for more detail.

```bash
PERMISSION_BOT_USER=
PERMISSION_BOT_ACCOUNT=
PERMISSION_BOT_WAREHOUSE=
PERMISSION_BOT_PASSWORD=
PERMISSION_BOT_DATABASE=
PERMISSION_BOT_ROLE=
```

These are some sample command examples. You can also include optional flags as shown with `--dry` - check out [the README](https://gitlab.com/gitlab-data/permifrost/-/blob/master/README.md) for more details:

```bash
# Run a spec-test
meltano invoke permifrost:spec-test

# Run a dryrun
meltano invoke permifrost:run --dry

# Run and execute changes
meltano invoke permifrost:run
```

## Squared Implementation Notes

For our permifrost implementation we used [GitLab's Data Team](https://about.gitlab.com/handbook/business-technology/data-team/platform/#snowflake-permissions-paradigm) as inspiration.

### Roles

The following strategy is borrowed from [GitLab's documentation](https://about.gitlab.com/handbook/business-technology/data-team/platform/#snowflake-permissions-paradigm) but is meant to be the source of truth for this repo as GitLab's strategy could change over time.

We follow this general strategy for role management:

- Every user has an associated user role
- Functional roles exist to represent common privilege sets (analyst_finance, data_manager, product_manager)
- Logical groups of data have their own object roles
- Object roles are assigned primarily to functional roles
- Higher privilege roles (accountadmin, securityadmin, useradmin, sysadmin) are assigned directly to users
- Service accounts have an identically named role
- Additional roles can be assigned either to the service account role or the service account itself, depending on usage and needs
- Individual privileges can be granted at the granularity of the table & view
- Warehouse usage can be granted to any role as needed, but granting to functional roles is recommended

#### User Roles

Every user will have their own user role that should match their user name. Object level permissions (database, schemas, tables) in Snowflake can only be granted to roles. Roles can be granted to users or to other roles. We strive to have all privileges flow through the user role so that a user only has to use one role to interact with the database. Exceptions are privileged roles such as accountadmin, securityadmin, useradmin, and sysadmin. These roles grant higher access and should be intentionally selected when using.

#### Functional Roles

Functional roles represent a group of privileges and role grants that typically map to a job family. The major exception is the analyst roles. There are several variants of the analyst role (this isnt true in the Squared repo yet) which map to different areas of the organization. These include analyst_core, analyst_finance, analyst_people, and more. Analysts are assigned to relevant roles and are explicitly granted access to the schemas they need.

Functional roles can be created at any time. It makes the most sense when there are multiple people who have very similar job families and permissions.

#### Object Roles

Object roles are for managing access to a set of data. Typically these represent all of the data for a given source. For example we could have a slack object role. This role grants access to the raw Slack data coming from Meltano, and also to the source models in the prep.slack schema. When a user needs access to Slack data, granting the slack role to that user's user role is the easiest solution. If for some reason access to the object role doesn't make sense, individual privileges can be granted at the granularity of a table.

### Execution

Currently permifrost isnt executed automatically or on a schedule.
If changes are made it should be executed manually.

### Object Creation

Permifrost does not create objects (databases, tables, users, roles, warehouses, etc.) in Snowflake, it just assigns permissions.
If new objects need to be created, then an admin (@pnadolny13 or @tayloramurphy) needs to create them before they can be assigned appropriate roles.

The following are the roles that should be used when creating new objects manually:

SYSADMIN
- Warehouses
- Databases

USERADMIN
- Roles
- Users

Permissions are managed by permifrost using SECURITYADMIN.

All tables and schemas are created and owned by sub-roles as appropriate.

### Databases

- raw: Data in the form that comes directly out of the source (Meltano taps).
This data is not intended to be accessed other than by pipelines because it could be duplicated, poorly named, sensitive, etc.

- prep: Data that is cleaned up but not ready to be analyzed yet.
The data is deduplicated, consistently named, etc.

- prod: Data that is ready to be consumed by reporting tools or analysts.
Metrics are defined [in the handbook](https://handbook.meltano.com/data-team/metrics-and-definitions).

### Meltano Roles

There is a `meltano` users that has 3 main roles that will be used in the Meltano project.

- `loader` has access to the `raw` schema to load data during the EL step.
- `transformer` has access to the `prep` and `prod` schemas to build models using dbt.
- `reporter` has access to read the `prod` schema to access consumption data with Superset.

Individual developers will get their own namespaced environment (i.e. `pnadolny_raw`, `pnadolny_prep`, `pnadolny_prod`) and appropriate roles for isolated development.
