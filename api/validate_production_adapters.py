"""Executable checks for the provider boundary's fail-closed behavior."""
from production_adapters import ProductionAdapters, ProductionIntegrationNotConfigured


adapters = ProductionAdapters.unconfigured()
try:
    adapters.assert_ready()
except ProductionIntegrationNotConfigured as error:
    assert "OIDC" in str(error)
    assert "PostgreSQL" in str(error)
    assert "encrypted storage" in str(error)
    assert "external audit sink" in str(error)
else:
    raise AssertionError("unconfigured production adapters were accepted")

for operation in (
    lambda: adapters.identity.verify("Bearer synthetic"),
    lambda: adapters.database.health_check(),
    lambda: adapters.storage.create_download_url(patient_id="patient", object_key="doc", ttl_seconds=60),
    lambda: adapters.audit_sink.append(event_hash="hash", payload={}),
):
    try:
        operation()
    except ProductionIntegrationNotConfigured:
        pass
    else:
        raise AssertionError("unconfigured production adapter operation did not fail closed")

print("PASS: production provider boundary fails closed until real OIDC, PostgreSQL, storage and audit adapters are registered.")
