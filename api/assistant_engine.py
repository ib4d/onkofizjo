"""Grounded, deterministic Hermes demo engine.

It deliberately refuses clinical conclusions when an approved source is not
available. This module never calls an external LLM and never invents evidence.
"""
import json
from pathlib import Path


def approved_sources(root: Path):
    document = json.loads((root / "data" / "demo-knowledge.json").read_text(encoding="utf-8"))
    return [item for item in document.get("items", []) if item.get("status") == "APPROVED_INTERNAL"]


def create_run(root: Path, patient_id: str, task: str, requested_sources=None):
    sources = requested_sources if isinstance(requested_sources, list) else []
    registry = {item["id"]: item for item in approved_sources(root)}
    contextual = {"patient-context": {"id": "patient-context", "status": "APPROVED_CONTEXT"}}
    available = {**registry, **contextual}
    matched = [available[item] for item in sources if item in available]
    trace = [{"requested": item, "matched": item in available, "status": available[item]["status"] if item in available else "UNAVAILABLE"} for item in sources]
    if not matched:
        answer = "There is not enough verified information to make a clinical recommendation."
        status = "REVIEW_REQUIRED"
        confidence = "low"
    else:
        answer = "Verified internal workflow context found. Prepare a draft for Gosia's review; do not treat this as clinical advice."
        status = "NEEDS_REVIEW"
        confidence = "bounded"
    return {
        "patientId": patient_id,
        "task": task,
        "status": status,
        "answer": answer,
        "sources": [item["id"] for item in matched],
        "sourceTrace": trace,
        "confidence": confidence,
        "humanReviewRequired": True,
        "noInferenceWithoutEvidence": True,
        "provider": "DEMO_GROUNDED_ENGINE",
    }
