"""Deterministic, synthetic-only diet proposal rules for the Fase 5 demo."""


def build_proposal(profile, goal=None, restrictions=None):
    restrictions = restrictions if isinstance(restrictions, list) else []
    normalized = {str(item).strip().lower() for item in restrictions if str(item).strip()}
    breakfast = "Owsianka z jogurtem naturalnym i owocami — propozycja do weryfikacji"
    if normalized & {"lactosa", "laktoza", "dairy", "nabiał"}:
        breakfast = "Owsianka na napoju roślinnym i owoce — propozycja do weryfikacji"
    if normalized & {"gluten", "gluten-free", "bez glutenu"}:
        breakfast = "Owsianka certyfikowana bezglutenowa i owoce — propozycja do weryfikacji"
    return {
        "profileSnapshot": {"ecosystem": profile.get("tag"), "state": profile.get("state"), "symptom": profile.get("symptom")},
        "goal": goal or "Not specified — confirm with patient",
        "restrictions": restrictions,
        "ruleTrace": [{"rule": "restriction-aware-breakfast", "applied": bool(normalized), "inputs": sorted(normalized)}],
        "meals": [
            {"name": "Śniadanie", "description": breakfast, "kcal": 420},
            {"name": "Obiad", "description": "Zupa warzywna i źródło białka dobrane po potwierdzeniu tolerancji", "kcal": 620},
            {"name": "Kolacja", "description": "Lekki posiłek zgodny z potwierdzonym wzorcem żywienia", "kcal": 410},
        ],
        "warnings": [
            "Synthetic demo content — not clinical advice",
            "Human review required before patient delivery",
            *(["Restrictions supplied by user require manual verification against the patient's clinical record"] if restrictions else []),
        ],
        "sources": [{"id": "demo-source-placeholder", "label": "Approved source registry placeholder", "status": "VERIFY_BEFORE_USE"}],
    }
