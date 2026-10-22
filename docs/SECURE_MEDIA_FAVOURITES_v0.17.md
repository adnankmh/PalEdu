# PalEdu v0.17 — Secure Local Media Favourites

Inside **مكتبة المناهج والموارد**, students can mark approved books, worksheets
and direct videos with a bookmark icon, and use **مفضلتي** to filter the
currently available resources. Existing grade, Tawjihi branch, semester,
content type and search constraints remain enforced; the bookmark does not
bypass the server's resource visibility rules.

Only stable resource_id UUID values are saved in SharedPreferences. These
are stored separately per signed-in account using a SHA-256 hashed local key.
Signed Supabase URLs, credentials, answers, documents, personal names and
private media files are never written by this feature. The list is capped at
250 entries per account and malformed records are ignored. Delete My Data
clears bookmarks for all local sign-in accounts on the device.

No extra Supabase tables or API permissions are required. Bookmarks do not
download videos or PDFs and do not sync across devices. Account login and
published resource availability still require a real configured Supabase
backend. This PR provides no copyrighted media corpus and makes no verified
500k-user capacity claim.

Quality gate: Flutter analyze and tests, Android APK and Web builds and security
guards must pass before merging into main.
