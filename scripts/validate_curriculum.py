#!/usr/bin/env python3
"""Validate demo curriculum integrity without confusing it with ministry content."""
import json
from pathlib import Path

data = json.loads(Path("assets/curriculum/sample_lessons.json").read_text(encoding="utf-8"))
assert data["contentStatus"] == "demonstration_only"
lessons = data["lessons"]
ids = set()
for lesson in lessons:
    assert lesson["id"] not in ids, "duplicate lesson ID"
    ids.add(lesson["id"])
    assert 1 <= lesson["grade"] <= 12, "invalid grade"
    assert lesson["title"] and lesson["subject"] and lesson["sections"]
    for question in lesson["questions"]:
        assert len(question["options"]) >= 2
        assert 0 <= question["answer"] < len(question["options"])
        assert question["prompt"] and question["explanation"]
assert {l["grade"] for l in lessons} == set(range(1, 13))
print(f"Validated {len(lessons)} original demo lessons; no official content claims.")
