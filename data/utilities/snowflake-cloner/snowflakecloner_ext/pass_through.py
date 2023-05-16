"""Passthrough shim for SnowflakeCloner extension."""
import sys

import structlog
from meltano.edk.logging import pass_through_logging_config
from snowflakecloner_ext.extension import SnowflakeCloner


def pass_through_cli() -> None:
    """Pass through CLI entry point."""
    pass_through_logging_config()
    ext = SnowflakeCloner()
    ext.pass_through_invoker(
        structlog.getLogger("snowflakecloner_invoker"),
        *sys.argv[1:] if len(sys.argv) > 1 else []
    )
