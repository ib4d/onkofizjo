import unittest

from diet_engine import build_proposal


class DietEngineTests(unittest.TestCase):
    def test_lactose_rule_is_traceable_and_changes_meal(self):
        result = build_proposal({"tag": "Dietetyka", "state": "Plan", "symptom": "Fatigue"}, restrictions=["lactosa"])
        self.assertTrue(result["ruleTrace"][0]["applied"])
        self.assertIn("roślinnym", result["meals"][0]["description"])

    def test_empty_restrictions_do_not_invent_constraints(self):
        result = build_proposal({}, restrictions=[])
        self.assertEqual(result["ruleTrace"][0]["inputs"], [])
        self.assertFalse(result["ruleTrace"][0]["applied"])
        self.assertIn("confirm", result["goal"])


if __name__ == "__main__":
    unittest.main()
