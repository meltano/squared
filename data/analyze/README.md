# Local Superset (Experimental)

This analyze module includes utilities to get Superset up and running locally using Docker along with the assets you need to be able to view the current state of the charts and dashboards.

> :warning: **WARNING**: This is no longer the recommended way of installing Superset in your Meltano project. Visit [MeltanoHub](https://hub.meltano.com/utilities/superset) for instructions on installing Superset.


> :warning: **WARNING**: The Superset assets in this repo are no longer the latest production assets, view the production instance for the most up to date versions of the assets.

## Installing

To install the Superset files into your Meltano project for the first time, follow the instructions in [the file-bundle repo](https://gitlab.com/meltano/files-superset).
These should be checked into your git project.
All subsequent usage of Superset will work simply by following the instructions below, there is no need to run a `meltano install` since the file bundle is Docker based and does not require a python executable.

## Starting Superset Locally

The following are the steps to get it running on your local:

-  Run the `up` command to start up all the Superset containers.

    ```bash
    meltano --environment=userdev invoke superset:up
    ```

Once its done starting up you can go to http://localhost:8088/ and login using the default credentials (user: admin, pass: admin).


## Importing

> :warning: **WARNING**: The file bundle is still in development and has some known bugs with importing/exporting.
The scripts are in the [export.py](./superset/export.py) and [import.py](./superset/import.py) modules and can be modified as needed.
Issues and contributions are greatly appreciated!

The following are the steps to assets (datasets/charts/dashboards/etc.) from your Meltano project imported into Superset:

- Run the `import` command which executes the `./superset/import.py` script in this module to load all `./superset/assets` available from a previous `export`.


    ```bash
    meltano --environment=userdev invoke superset:import
    ```

- The last step is to go to the Data -> Databases tab in the Superset UI where you should see your databases.
As part of the export process credentials are masked with `XXXXXX` so you'll need to edit it with their full crendentials.
For this project there should be an Athena database and the full URL can be found in 1Password in `Squared Superset`.


## Exporting

> :warning: **WARNING**: The file bundle is still in development and has some known bugs with importing/exporting.
The scripts are in the [export.py](./superset/export.py) and [import.py](./superset/import.py) modules and can be modified as needed.
Issues and contributions are greatly appreciated!

If you change any of the assets in your local instance you'll need to export them to be checked back into git.
The following are the steps to export:

- Run the `export` command which executes the `./superset/export.py` script in this module which uses the API to export the current state of all assets to `./superset/assets`.
If assets were deleted then they will be removed from the assets module as well.
Currently exporting leaves some minor diffs on the `metadata.yaml` files even when they werent changed, liked the timestamp, these changes can be discarded before a git commit.


    ```bash
    meltano --environment=userdev invoke superset:export
    ```
