"""Meltano SnowflakeCloner extension."""
from __future__ import annotations

import concurrent.futures
import os
import pkgutil
import subprocess
import sys
from pathlib import Path
from typing import Any
from snowflakecloner_ext.snowflake_wrapper import SnowflakeWrapper

import structlog
from meltano.edk import models
from meltano.edk.extension import ExtensionBase
from meltano.edk.process import Invoker, log_subprocess_error
from tqdm import tqdm

log = structlog.get_logger()


class SnowflakeCloner(ExtensionBase):
    """Extension implementing the ExtensionBase interface."""

    def __init__(self) -> None:
        """Initialize the extension."""
        self.snowflakecloner_bin = "None"  # verify this is the correct name
        self.snowflakecloner_invoker = Invoker(self.snowflakecloner_bin)

    def invoke(self, command_name: str | None, *command_args: Any) -> None:
        """Invoke the underlying cli, that is being wrapped by this extension.

        Args:
            command_name: The name of the command to invoke.
            command_args: The arguments to pass to the command.
        """
        try:
            self.snowflakecloner_invoker.run_and_log(command_name, *command_args)
        except subprocess.CalledProcessError as err:
            log_subprocess_error(
                f"snowflakecloner {command_name}", err, "SnowflakeCloner invocation failed"
            )
            sys.exit(err.returncode)

    def describe(self) -> models.Describe:
        """Describe the extension.

        Returns:
            The extension description
        """
        # TODO: could we auto-generate all or portions of this from typer instead?
        return models.Describe(
            commands=[
                models.ExtensionCommand(
                    name="snowflakecloner_extension", description="extension commands"
                ),
                models.InvokerCommand(
                    name="snowflakecloner_invoker", description="pass through invoker"
                ),
            ]
        )

    def clone(
        self,
        clone_from_db: str,
        clone_to_db: str,
        account: str,
        user: str,
        password: str,
        role: str,
        warehouse: str,
        threads: int,
        schema_prefix: str,
    )  -> None:
        """Clone Snowflake objects.

        Returns:
            None
        """


        log.info("Cloning...")
        
        snowflake = SnowflakeWrapper(
            user=user,
            password=password,
            account=account,
            warehouse=warehouse,
            # database=DATABASE,
            # schema=SCHEMA
            role=role,
        )

        tables = snowflake.execute(
            f"""
            SELECT table_schema, table_name, table_type, is_transient
            FROM {clone_from_db}.information_schema.tables
            WHERE table_schema != 'INFORMATION_SCHEMA'
            """,
            fetch=True
        )

        create_schema = list({
            f"CREATE OR REPLACE SCHEMA {clone_to_db}.{schema_prefix}{row[0]};"
            for row in tables
        })

        create_table = [
            f"CREATE OR REPLACE {'TRANSIENT ' if row[3] == 'YES' else ''}TABLE {clone_to_db}.{schema_prefix}{row[0]}.{row[1]} CLONE {clone_from_db}.{row[0]}.{row[1]};"
            for row in tables if 'TABLE' in row[2]
        ]

        commands = create_schema + create_table

        with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
            results = list(tqdm(executor.map(snowflake.execute, commands), total=len(commands)))
