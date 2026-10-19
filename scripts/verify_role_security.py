#!/usr/bin/env python3
"""Static risk checks; NOT a substitute for real RLS integration tests."""
from pathlib import Path
migration = Path('supabase/migrations/20261019_roles_content.sql').read_text()
assert 'enable row level security' in migration
for name in ['paledu_profiles','paledu_role_requests','paledu_resources']:
    assert 'alter table public.' + name + ' enable row level security' in migration
assert "role text not null default 'student'" in migration
assert 'paledu_publish_requires_rights' in migration
assert 'paledu_review_resource' in migration
assert 'paledu_review_educator' in migration
assert 'split_part(name' in migration
app = Path('lib/portal/portal_service.dart').read_text()
assert 'service_role' not in app
assert 'SUPABASE_ANON_KEY' in app
assert 'signInWithPassword' in app
assert 'status' in app and "'pending'" in app
print('Security schema and client invariants found (static checks only).')
