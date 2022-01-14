# Local Superset

This analyze module includes utilities to get Superset up and running locally using Docker along with the assets you need to be able to view the current state of the charts and dashboards.

## Importing
The following are the steps to get it running on your local:

-  Run the `up` command to start up all the Superset containers.
Once its done starting up you can go to http://localhost:8088/ and login using the default credenditals (user: admin, pass:admin).

    ```bash
    meltano --environment=userdev invoke superset:up
    ```

- Run the `import` command which executes the `./superset/import.py` script in this module to load all `./superset/assets` available from a previous `export`.


    ```bash
    meltano --environment=userdev invoke superset:import
    ```

- The last step is to go to the Data -> Databases tab in the Superset UI where you should see the Athena database.
As part of the export process credentials are masked with `XXXXXX` so you'll need to edit it with the full URL found in 1Password in `Squared Superset`.


## Exporting

If you change any of the assets in your local instance you'll need to export them to be checked back into git.
The following are the steps to export:

- Run the `export` command which executes the `./superset/export.py` script in this module which uses the API to export the current state of all assets to `./superset/assets`.
If assets were deleted then they will be removed from the assets module as well.
Currently exporting leaves some minor diffs on the `metadata.yaml` files even when they werent changed, liked the timestamp, these changes can be discarded before a git commit.


    ```bash
    meltano --environment=userdev invoke superset:export
    ```