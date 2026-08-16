"""Fail-closed startup gate for the future clinical production service."""
from dataclasses import dataclass
from typing import Mapping

from production_adapters import ProductionAdapters
from production_config import ProductionConfig, validate_production_environment


@dataclass(frozen=True)
class ProductionRuntime:
    config: ProductionConfig
    adapters: ProductionAdapters


def build_production_runtime(
    values: Mapping[str, str],
    adapters: ProductionAdapters,
) -> ProductionRuntime:
    """Return a runtime only when config and real adapters are both ready.

    The demo API must not call this function with synthetic sessions. A future
    production entrypoint should call it before binding an HTTP listener.
    """
    config = validate_production_environment(dict(values))
    adapters.assert_ready()
    return ProductionRuntime(config=config, adapters=adapters)
