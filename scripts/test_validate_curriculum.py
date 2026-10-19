"""Regression tests for the offline sample content validator."""
import copy
import json
import unittest
from pathlib import Path

from validate_curriculum import validate_catalog


class CurriculumIntegrityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sample = json.loads(Path(
            "assets/curriculum/sample_lessons.json").read_text(encoding="utf-8"))

    def modified(self):
        return copy.deepcopy(self.sample)

    def test_sample_is_valid(self):
        self.assertEqual(validate_catalog(self.sample), 48)

    def test_empty_questions_rejected(self):
        data = self.modified()
        data["lessons"][0]["questions"] = []
        with self.assertRaisesRegex(ValueError, "no questions"):
            validate_catalog(data)

    def test_duplicate_matching_answers_rejected(self):
        data = self.modified()
        questions = data["lessons"][0]["questions"]
        questions[2]["options"][questions[2]["answer"]] = (
            questions[0]["options"][questions[0]["answer"]])
        with self.assertRaisesRegex(ValueError, "Ambiguous matching answer"):
            validate_catalog(data)

    def test_duplicate_answer_choices_rejected(self):
        data = self.modified()
        q = data["lessons"][0]["questions"][0]
        q["options"][0] = q["options"][1]
        with self.assertRaisesRegex(ValueError, "Repeated choices"):
            validate_catalog(data)

    def test_blank_explanation_rejected(self):
        data = self.modified()
        data["lessons"][0]["questions"][0]["explanation"] = " "
        with self.assertRaisesRegex(ValueError, "Missing explanation"):
            validate_catalog(data)

    def test_duplicate_lesson_ids_rejected(self):
        data = self.modified()
        data["lessons"][1]["id"] = data["lessons"][0]["id"]
        with self.assertRaisesRegex(ValueError, "Duplicate lesson ID"):
            validate_catalog(data)

    def test_official_claim_rejected(self):
        data = self.modified()
        data["contentStatus"] = "official"
        with self.assertRaisesRegex(ValueError, "demonstration only"):
            validate_catalog(data)


if __name__ == "__main__":
    unittest.main()
