# Security review and endpoint access matrix

This review reflects the current `server.js` route table. All mutations additionally require the existing same-origin `Origin` check and `X-Requested-With: sb` header. All authenticated endpoints require an approved, active session; `must_change` sessions may access only `/api/me`, `/api/logout`, and `/api/password`. `T` means admin or teacher, `ALL` means admin, teacher, or student, `S` means student, and `STORY_ROLES` means admin, teacher, student, or parent. Anonymous access is limited to the explicitly marked public routes.

## Endpoint-by-endpoint access

| Method and path | Who may call it | Additional authorization / data scope |
|---|---|---|
| `GET /api/me` | Anonymous or any session | Returns only the caller's public user record. |
| `POST /api/signup` | Anonymous | Public account request; role limited to student, teacher, or parent; admin signup is rejected. |
| `POST /api/login` | Anonymous | Rate limited; approved account required; lockout protections apply. |
| `POST /api/logout` | Anonymous or any session | Revokes only the presented session. |
| `POST /api/password` | Admin, teacher, student, parent | Changes only the caller's password and revokes their other sessions. |
| `GET /api/health` | Anonymous | Database `SELECT 1`; reports availability, database kind, and time only. |
| `GET /api/users` | Admin, teacher | Admin sees user roster; teacher sees assigned-class pupils only. |
| `POST /api/users` | Admin | Creates accounts; may assign classes. |
| `POST /api/users/import` | Admin | Imports pupils into existing classes; generated initial passwords are returned once. |
| `PATCH /api/users/:id` | Admin, teacher | Admin approval/disable/class assignment. Teacher is scoped to pupils in assigned classes; teacher password reset is limited to those pupils. |
| `GET /api/tests` | Admin, teacher, student | Students receive only published, non-archived tests visible to their class; answer keys are excluded. |
| `POST /api/tests` | Admin, teacher | Teacher is restricted to assigned classes/levels. |
| `GET /api/tests/:id` | Admin, teacher, student | Test/class scoping; students see only published tests and answer keys are stripped. |
| `GET /api/tests/:id/analytics` | Admin, teacher | Class-scoped analytics; teacher sees only assigned classes. |
| `PATCH /api/tests/:id` | Admin, teacher | Class-scoped; content cannot be changed after an attempt exists. |
| `DELETE /api/tests/:id` | Admin, teacher | Class-scoped archive; does not hard-delete attempts. |
| `POST /api/tests/:id/start` | Student | Own eligible published test only. |
| `GET /api/tests/:id/draft` | Student | Own in-progress attempt only. |
| `POST /api/tests/:id/save` | Student | Own in-progress attempt only. |
| `POST /api/tests/:id/submit` | Student | Own attempt; server marks answers, enforces one completed attempt, and stores result. |
| `POST /api/tests/:id/duplicate` | Admin, teacher | Class-scoped test duplication. |
| `GET /api/attempts/:id` | Admin, teacher, student | Student sees own attempt; teacher sees assigned-class attempts; admin sees all. |
| `POST /api/attempts/:id/marks` | Admin, teacher | Class-scoped manual marking. |
| `GET /api/results` | Admin, teacher, student | Admin sees all; teacher assigned classes; student own completed results. |
| `GET /api/results/export` | Admin, teacher | Class/test scope enforced before CSV export. |
| `POST /api/tests/:id/retake` | Admin, teacher | Teacher class scope; previous attempt is archived and retained. |
| `POST /api/results/:id/comment` | Admin, teacher | Teacher may comment only on assigned-class results. |
| `GET /api/audit` | Admin | Administrative audit entries only. |
| `GET /api/sessions` | Admin, teacher, student, parent | Lists only caller's active sessions; token hashes are never returned. |
| `POST /api/sessions/revoke-all` | Admin, teacher, student, parent | Revokes only caller's sessions. |
| `GET /api/stories` | Admin, teacher, student, parent | Publicly visible story content is published-only; teacher/student filtering uses assigned/own class. |
| `GET /api/stories/:id` | Admin, teacher, student, parent | Drafts only for admin/teacher; class-scoped teacher/student; parents only published content. |
| `POST /api/stories` | Admin, teacher | Teacher restricted to assigned levels; source and licence required. |
| `PUT /api/stories/:id` | Admin, teacher | Teacher can edit only stories at assigned levels. |
| `DELETE /api/stories/:id` | Admin, teacher | Teacher can affect only assigned-level stories. |
| `PATCH /api/stories/:id/publish` | Admin, teacher | Teacher can publish only assigned-level stories. |
| `GET /api/stories/:id/practice` | Student | Own class published story; answer keys stripped. |
| `POST /api/stories/:id/read` | Student | Own reading progress only. |
| `POST /api/stories/:id/complete` | Student | Own completion record only; published story/class enforced. |
| `GET /api/progress` | Student | Own progress only. |
| `GET /api/classes` | Admin, teacher | Teacher sees assigned classes only. |
| `POST /api/classes` | Admin | Creates class. |
| `POST /api/classes/:id/members` | Admin | Adds a valid user/class membership. |
| `POST /api/classes/:id/promote` | Admin | Promotes eligible pupil membership. |
| `GET /api/stories/:id/resources` | Admin, teacher, student, parent | Access scoped to the referenced story and class. |
| `POST /api/uploads/sign` | Admin, teacher | Validates file name, MIME, size and story access before signing. |
| `POST /api/resources/complete` | Admin, teacher | Registers validated upload metadata. |
| `GET /api/resources/:id/url` | Admin, teacher, student, parent | Short-lived signed URL only after resource/story access checks. |
| `POST /api/question-bank/import` | Admin, teacher | Teacher restricted to assigned story levels; imported questions start unapproved. |
| `GET /api/question-bank` | Admin, teacher | Teacher sees only assigned-level story questions. |
| `PATCH /api/question-bank/:id` | Admin, teacher | Teacher restricted to question's story level. |
| `GET /api/import-jobs` | Admin, teacher | Teacher's own jobs / assigned class scope. |
| `POST /api/import-jobs` | Admin, teacher | Creates import tracking record for caller. |
| `POST /api/ai/story-details` | Admin, teacher | AI usage limited per caller/day; provider key remains server-side. |
| `POST /api/ai/questions` | Admin, teacher | Story scope and daily AI limit enforced; generated questions remain drafts. |
| `POST /api/ai/mark` | Admin, teacher | Class-scoped marking assistance and daily AI limit. |
| `GET /api/parent/children` | Parent | Linked children only. |
| `POST /api/parent-links` | Admin | Links parent to a valid pupil. |
| `GET /api/parent/attempts/:id` | Parent | Linked child and completed attempt required. |
| `GET /api/parent/results` | Parent | Linked children only; completed results only. |
| `GET /api/announcements` | Admin, teacher, student, parent | Target role/class filtering; only active announcements. |
| `POST /api/announcements` | Admin | Creates school announcement. |
| `GET /api/settings` | Admin | School settings only. |
| `PUT /api/settings` | Admin | School settings only; audit logged. |
| `GET /api/backup` (JSON) | Admin | Exports key tables; excludes password hashes and sessions. |
| `GET /api/backup?format=csv` | Admin | Same data/scope as JSON, CSV serialization; treat export as sensitive. |

## Controls in place

- Passwords use scrypt; sessions are random, hashed in storage, HttpOnly, and expiry checked server-side.
- Login throttling/lockout persists in the database. New signups are approval-gated.
- SQL values are parameterized; route authorization is enforced server-side and frontend visibility is not authorization.
- Student test and practice payloads omit answer keys and marking rubric keywords.
- Parent detail is scoped by `parent_links` and completed attempt status.
- Upload signing validates types and size; configure the Supabase bucket as private with matching restrictions.
- Production must use `HTTPS=1`, exact `CORS_ORIGINS`, private repository, and secrets in Render environment variables.
- The startup migration runner applies numbered migration scripts in order and stores successful migration IDs in `schema_migrations`.
- `/api/health` is intentionally anonymous for Render and checks the active database connection.

## Gaps and release cautions

1. **PostgreSQL production validation:** SQLite and the disposable PostgreSQL suite should both pass; a local SQLite pass does not establish compatibility with the live Supabase schema, policies, or connection-pooler settings. This environment did not provide a local PostgreSQL server or a throwaway PostgreSQL connection, so PostgreSQL execution remains unverified.
2. **Teacher-assisted pupil credential resets:** a teacher can reset a pupil password only when the pupil belongs to one of the teacher's assigned classes. This is powerful and should be retained only if school policy explicitly authorizes it.
3. **Backup confidentiality:** admin-only exports include pupil names, results, and assessment data. Protect downloaded backups, use encrypted storage, and define a retention/deletion policy.
4. **Storage scanning:** uploads are checked for metadata/size but are not antivirus scanned or content-sniffed by the app. Keep the bucket private and enforce its MIME and size rules.
5. **Bootstrap credentials:** rotate the known `admin` / `Admin@12345` credential immediately on a fresh deployment.
6. **Legacy level fallback:** some teacher/test/story visibility uses level labels as a fallback when class membership is absent. Continue auditing behavior as class assignment changes.

The Playwright journey covers admin sign-in and setup, teacher publishing, pupil completion, and parent result visibility. Run `npm test` for SQLite API/role tests, `npm run test:browser` for the browser journey, and `TEST_DATABASE_URL=<throwaway-postgres-url> npm run test:postgres` for PostgreSQL. Never point test runs at a production database.
