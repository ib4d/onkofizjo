import unittest
from pathlib import Path

from assistant_engine import create_run


class AssistantEngineTests(unittest.TestCase):
    root = Path(__file__).resolve().parents[1]

    def test_unapproved_or_missing_sources_refuse_conclusion(self):
        result = create_run(self.root, "demo-patient-ewa-dabrowska", "review", ["know-003"])
        self.assertEqual(result["status"], "REVIEW_REQUIRED")
        self.assertEqual(result["sources"], [])
        self.assertTrue(result["noInferenceWithoutEvidence"])

    def test_approved_source_is_cited_but_still_needs_review(self):
        result = create_run(self.root, "demo-patient-maria-nowak", "diet workflow", ["know-001"])
        self.assertEqual(result["status"], "NEEDS_REVIEW")
        self.assertEqual(result["sources"], ["know-001"])
        self.assertTrue(result["humanReviewRequired"])


if __name__ == "__main__":
    unittest.main()
