# SnowflakeCloner

SnowflakeCloner is A meltano utility extension for cloning Snowflake tables and views into a development or testing environment.

## Installing this extension for local development

1. Install the project dependencies with `poetry install`:

```shell
cd path/to/your/project
poetry install
```

2. Verify that you can invoke the extension:

```shell
poetry run snowflakecloner_extension --help
poetry run snowflakecloner_extension describe --format=yaml
poetry run snowflakecloner_invoker --help # if you have are wrapping another tool
```

## Template updates

This project was generated with [copier](https://copier.readthedocs.io/en/stable/) from the [Meltano EDK template](https://github.com/meltano/edk).
Answers to the questions asked during the generation process are stored in the `.copier_answers.yml` file.

Removing this file can potentially cause unwanted changes to the project if the supplied answers differ from the original when using `copier update`.

## Using with Meltano
After the utility is installed you will need to configure it in meltano.

1) Specify config in your meltano.yml file -- usually a .yml file you have created for development like dev.meltano.yml

```
      utilities:
      - name: snowflake-cloner
        config:
           clone_from_db_raw: RAW
           clone_to_db_raw: DEV_TEST
           account: xyzabc.us-east-1
           user: ${USER_PREFIX}
           password: ${SNOWFLAKE_PASSWORD}
           role: loader
           warehouse: GENERAL_WH
           threads: 1
           schema_prefix: ${USER_PREFIX}_
```
2) ensure you set the ```$USER_PREFIX``` and ```$SNOWFLAKE_PASSWORD``` variables in your .env file
3) run using ```meltano run snowflake-cloner:clone_raw``` replace raw with prep or prod to use another one of the default commands. See the utilities/snowflakecloner/utilities_meltano.yml file to understand the ```clone``` command configuration or add your own command. 
