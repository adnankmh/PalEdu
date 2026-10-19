-- Disposable PostgreSQL 16 test only. Never run against real user data.
\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
grant usage on schema public to anon, authenticated;
\ir ../supabase/migrations/20261019000100_curriculum.sql
insert into auth.users(id) values
 ('11111111-1111-4111-8111-111111111111'),
 ('22222222-2222-4222-8222-222222222222');
insert into public.curriculum_revisions(id,academic_year,status,display_name) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-2027','published','Visible'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','2026-2027','draft','Hidden');
insert into public.curriculum_units(id,revision_id,grade,track,term,subject,title,published) values
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',6,'عام',1,'رياضيات','Visible',true),
 ('dddddddd-dddd-4ddd-8ddd-dddddddddddd','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',6,'عام',1,'رياضيات','Hidden',false),
 ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',6,'عام',1,'رياضيات','Hidden revision',true);
insert into public.curriculum_lessons(id,unit_id,title,source_id,license_id,reviewer_id,review_status,published) values
 ('ffffffff-ffff-4fff-8fff-ffffffffffff','cccccccc-cccc-4ccc-8ccc-cccccccccccc','Visible','test-source','test-license','reviewer','approved',true),
 ('66666666-6666-4666-8666-666666666666','cccccccc-cccc-4ccc-8ccc-cccccccccccc','Visible 2','test-source','test-license','reviewer','approved',true),
 ('99999999-9999-4999-8999-999999999999','cccccccc-cccc-4ccc-8ccc-cccccccccccc','Unreviewed','test-source','test-license',null,'draft',false),
 ('88888888-8888-4888-8888-888888888888','dddddddd-dddd-4ddd-8ddd-dddddddddddd','Hidden parent','test-source','test-license','reviewer','approved',true),
 ('77777777-7777-4777-8777-777777777777','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Hidden revision','test-source','test-license','reviewer','approved',true);
insert into public.student_progress(user_id,lesson_id,best_score) values
 ('11111111-1111-4111-8111-111111111111','ffffffff-ffff-4fff-8fff-ffffffffffff',20),
 ('22222222-2222-4222-8222-222222222222','ffffffff-ffff-4fff-8fff-ffffffffffff',80);
set role anon;
do $test$
declare denied boolean := false;
begin
 if (select count(*) from public.curriculum_revisions) <> 1 then raise exception 'Draft revision exposed'; end if;
 if (select count(*) from public.curriculum_units) <> 1 then raise exception 'Hidden unit exposed'; end if;
 if (select count(*) from public.curriculum_lessons) <> 2 then raise exception 'Hidden lesson exposed'; end if;
 begin perform 1 from public.student_progress;
 exception when insufficient_privilege then denied := true; end;
 if not denied then raise exception 'Anonymous progress exposed'; end if;
end $test$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $test$
declare denied boolean := false;
declare affected integer;
begin
 if (select count(*) from public.student_progress) <> 1 then raise exception 'Other student progress exposed'; end if;
 if (select best_score from public.student_progress) <> 20 then raise exception 'Wrong student score'; end if;
 if (select count(*) from public.curriculum_lessons) <> 2 then raise exception 'Hidden lesson exposed'; end if;
 begin
  insert into public.student_progress(user_id,lesson_id,best_score)
  values ('22222222-2222-4222-8222-222222222222','66666666-6666-4666-8666-666666666666',100);
 exception when insufficient_privilege then denied := true; end;
 if not denied then raise exception 'Cross-user insert succeeded'; end if;
 update public.student_progress set best_score=55 where user_id='11111111-1111-4111-8111-111111111111';
 get diagnostics affected = row_count;
 if affected <> 1 then raise exception 'Own update failed'; end if;
 update public.student_progress set best_score=0 where user_id='22222222-2222-4222-8222-222222222222';
 get diagnostics affected = row_count;
 if affected <> 0 then raise exception 'Cross-user update succeeded'; end if;
 insert into public.student_progress(user_id,lesson_id,best_score)
 values ('11111111-1111-4111-8111-111111111111','66666666-6666-4666-8666-666666666666',75);
 denied := false;
 begin update public.curriculum_lessons set published=false;
 exception when insufficient_privilege then denied := true; end;
 if not denied then raise exception 'Student modified publication'; end if;
end $test$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','',false);
do $test$
begin
 if (select count(*) from public.student_progress) <> 0 then raise exception 'Null JWT exposed progress'; end if;
end $test$;
reset role;
do $test$
declare denied boolean := false;
begin
 begin
  insert into public.curriculum_lessons(unit_id,title,source_id,license_id,review_status,published)
  values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','Invalid','source','license','draft',true);
 exception when check_violation then denied := true; end;
 if not denied then raise exception 'Unreviewed publication accepted'; end if;
end $test$;
select 'Curriculum RLS integration passed on disposable PostgreSQL' as result;
