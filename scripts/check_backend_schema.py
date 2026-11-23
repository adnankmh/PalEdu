"""Static migration guardrails. NOT a substitute for real DB policy tests."""
from pathlib import Path
sql = Path("supabase/migrations/20261019000100_curriculum.sql").read_text(encoding="utf-8").lower()
tables = ["curriculum_revisions", "curriculum_units", "curriculum_lessons", "student_progress"]
for table in tables:
    assert "create table public." + table in sql
    assert "alter table public." + table + " enable row level security" in sql
assert "(select auth.uid()) = user_id" in sql
assert "from anon, authenticated" in sql
assert "approved_only_publish" in sql
print("Static SQL policy guardrails pass (database not deployed).")
