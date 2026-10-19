# PalEdu — secure identity and content backend

**Status:** schema and Flutter client code only; not provisioned in Supabase.
Production access must be verified by actual RLS integration tests and security review.

## 1. Supabase setup
1. Create a project owned by the organization. Enable email confirmations and appropriate anti-abuse measures (CAPTCHA, signup limits, email rate limits).
2. Apply \`supabase/migrations/20261019_roles_content.sql\` in your database migration pipeline.
3. Configure public Flutter parameters *without* a service-role key:
   - \`SUPABASE_URL\`
   - \`SUPABASE_ANON_KEY\` (publishable client key, **not** a secret)
4. Set \`--dart-define\` values in app builds / CI as required. Missing configuration leaves preview only, with role sign-in disabled.
5. Students self-register with **student** role only. Educators must submit a role request. An approved admin grants educator privileges via a protected server function.

## 2. First administrator, done privately
- Create the admin Auth user through the *private* Supabase dashboard or Admin API.
- Set a strong, unique password; **do not reuse any password pasted into chat**.
- Promote its user_id in the private database SQL console as a one-time operator action:
  \`update public.paledu_profiles set role='admin' where user_id='<PRIVATE_AUTH_USER_UUID>'::uuid;\`
- Never commit passwords, admin email addresses, service-role keys, signed JWTs, or pre-made password hashes to GitHub.
- Enable administrator MFA in auth provider and audit access.

## 3. Publishing flow
Teacher/trainer account approved → uploads PDF/MP4/image to their own UUID prefix in private \`paledu-curriculum\` bucket → creates metadata status=pending and rights evidence → admin reviews → protected RPC marks as published → students browse only published content and retrieve short-lived signed URLs.

## 4. Verification still required
- Test student cannot alter \`role\` or publish without approval.
- Test teachers cannot create or approve admin requests, or upload to another UID path.
- Test nonpublished files cannot be downloaded by unrelated students.
- Test private bucket, signed URL expiry, cache headers, file scanning, rights evidence and retention.
- Run staging load tests; 500k registered students is not equivalent to 500k concurrent users.
- Review minors' privacy and applicable Google Play Families requirements.
