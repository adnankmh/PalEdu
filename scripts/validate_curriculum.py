#!/usr/bin/env python3
"""Validate sample lesson structure and unambiguous matching answers."""
import json
from pathlib import Path

CATALOG = Path("assets/curriculum/sample_lessons.json")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_catalog(data):
    require(isinstance(data, dict), "Catalog must be a JSON object")
    require(data.get("contentStatus") == "demonstration_only",
            "Content must be clearly labeled as demonstration only")
    lessons = data.get("lessons")
    require(isinstance(lessons, list), "Missing lesson list")
    ids = set()
    grades = set()
    for lesson in lessons:
        require(isinstance(lesson, dict), "Lesson must be an object")
        lesson_id = lesson.get("id")
        require(isinstance(lesson_id, str) and lesson_id.strip(),
                "Missing lesson ID")
        require(lesson_id not in ids, f"Duplicate lesson ID: {lesson_id}")
        ids.add(lesson_id)
        grade = lesson.get("grade")
        require(type(grade) is int and 1 <= grade <= 12,
                f"Invalid grade: {lesson_id}")
        grades.add(grade)
        for key in ("subject", "title", "summary"):
            value = lesson.get(key)
            require(isinstance(value, str) and value.strip(),
                    f"Missing {key}: {lesson_id}")
        sections = lesson.get("sections")
        require(isinstance(sections, list) and bool(sections) and
                all(isinstance(s, str) and s.strip() for s in sections),
                f"Missing lesson sections: {lesson_id}")
        questions = lesson.get("questions")
        require(isinstance(questions, list) and bool(questions),
                f"Lesson has no questions: {lesson_id}")
        correct_answers = set()
        for index, question in enumerate(questions):
            require(isinstance(question, dict),
                    f"Invalid question {index}: {lesson_id}")
            for key in ("prompt", "explanation"):
                value = question.get(key)
                require(isinstance(value, str) and value.strip(),
                        f"Missing {key} in {lesson_id} question {index}")
            options = question.get("options")
            require(isinstance(options, list) and len(options) >= 2 and
                    all(isinstance(v, str) and v.strip() for v in options),
                    f"Invalid options in {lesson_id} question {index}")
            normalized = [value.strip() for value in options]
            require(len(set(normalized)) == len(normalized),
                    f"Repeated choices in {lesson_id} question {index}")
            answer = question.get("answer")
            require(type(answer) is int and 0 <= answer < len(options),
                    f"Invalid answer index in {lesson_id} question {index}")
            label = normalized[answer]
            require(label not in correct_answers,
                    f"Ambiguous matching answer '{label}' in {lesson_id}")
            correct_answers.add(label)
    require(grades == set(range(1, 13)), "Demo must cover grades 1-12")
    return len(lessons)


def main():
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    count = validate_catalog(data)
    print(f"Validated {count} demonstration lessons with unique matching answers.")


if __name__ == "__main__":
    main()
