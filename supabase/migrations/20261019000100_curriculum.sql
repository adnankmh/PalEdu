-- PalEdu PostgreSQL/Supabase foundation (NOT DEPLOYED).
-- Do not run against production without review, backups and policy tests.
create extension if not exists pgcrypto;

create table public.curriculum_revisions (
  id uuid primary key default gen_random_uuid(),
  academic_year text not null check (length(academic_year) between 4 and 16),
  status text not null default 'draft'
    check (status in ('draft','review','published','archived')),
  display_name text not null,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.curriculum_units (
  id uuid primary key default gen_random_uuid(),
  revision_id uuid not null references public.curriculum_revisions(id),
  grade smallint not null check (grade between 1 and 12),
  track text not null,
  term smallint not null check (term between 1 and 2),
  subject text not null,
  title text not null,
  sort_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.curriculum_lessons (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references public.curriculum_units(id),
  title text not null,
  summary text not null default '',
  duration_minutes integer not null default 7
    check (duration_minutes between 1 and 240),
  content_manifest_url text,
  source_id text not null,
  license_id text not null,
  reviewer_id text,
  review_status text not null default 'draft'
    check (review_status in ('draft','in_review','approved','rejected')),
  published boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint approved_only_publish check (
    not published or (
      review_status = 'approved' and reviewer_id is not null
      and length(source_id) > 0 and length(license_id) > 0
    )
  )
);

create table public.student_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.curriculum_lessons(id),
  best_score smallint not null check (best_score between 0 and 100),
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

create index idx_units_public on public.curriculum_units
  (grade, track, term, subject, sort_order, id) where published;
create index idx_lessons_public on public.curriculum_lessons
  (unit_id, sort_order, id) where published;
create index idx_revisions_public on public.curriculum_revisions
  (published_at desc) where status='published';
create index idx_progress_user_recent on public.student_progress
  (user_id, updated_at desc);

alter table public.curriculum_revisions enable row level security;
alter table public.curriculum_units enable row level security;
alter table public.curriculum_lessons enable row level security;
alter table public.student_progress enable row level security;

-- Publication writes belong to an audited, trusted backend only.
revoke all on public.curriculum_revisions from anon, authenticated;
revoke all on public.curriculum_units from anon, authenticated;
revoke all on public.curriculum_lessons from anon, authenticated;
revoke all on public.student_progress from anon, authenticated;

grant select on public.curriculum_revisions to anon, authenticated;
grant select on public.curriculum_units to anon, authenticated;
grant select on public.curriculum_lessons to anon, authenticated;
grant select, insert, update on public.student_progress to authenticated;

create policy "read_published_revisions" on public.curriculum_revisions
  for select to anon, authenticated using (status = 'published');

create policy "read_published_units" on public.curriculum_units
  for select to anon, authenticated using (
    published and exists (
      select 1 from public.curriculum_revisions rev
      where rev.id=revision_id and rev.status='published'
    )
  );

create policy "read_published_lessons" on public.curriculum_lessons
  for select to anon, authenticated using (
    published and review_status='approved' and exists (
      select 1 from public.curriculum_units unit
      where unit.id=unit_id and unit.published and exists (
        select 1 from public.curriculum_revisions rev
        where rev.id=unit.revision_id and rev.status='published'
      )
    )
  );

create policy "read_own_progress" on public.student_progress
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "insert_own_progress" on public.student_progress
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "update_own_progress" on public.student_progress
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Before production: actual RLS integration tests, backup/PITR,
-- age-appropriate consent flows, quotas, API throttling and audit logging.
