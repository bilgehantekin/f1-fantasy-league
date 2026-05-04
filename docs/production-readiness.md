# GridCall Production Readiness

This checklist keeps app code, Supabase schema, and store setup moving together.

## Before Testing a New Build

1. Apply every new file in `supabase/migrations/` to the target database.
2. Reload PostgREST schema cache after adding or changing RPCs:
   `notify pgrst, 'reload schema';`
3. Run `flutter analyze` and `flutter test` from `app/`.
4. Launch the app with production-like flags:
   `flutter run --dart-define=ENABLE_DEMO_CONTENT=false`

## Supabase Auth

- Add `io.supabase.gridcall://auth-callback` to Supabase Auth additional redirect URLs.
- Configure Google provider in Supabase and Google Cloud.
- Configure Apple provider in Supabase and Apple Developer.
- Keep Apple login visible whenever Google login is visible on iOS.
- For remote/prod builds, pass `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `OAUTH_REDIRECT_URL` via `--dart-define`.

## Demo Content

Demo-only UI is guarded by:

```bash
--dart-define=ENABLE_DEMO_CONTENT=true
```

Production builds should keep this false. Mock live timing, fake live events, and demo race-card scores must not be shown to production users.

## App Store Basics

- Privacy policy URL hosted at https://gridcall.app/privacy (mirror `docs/privacy-policy.md`).
- Terms of service URL hosted at https://gridcall.app/terms (mirror `docs/terms-of-service.md`).
- Support / privacy email: bilgehan.2002@gmail.com (must work — Apple verifies it).
- Account deletion: in-app via Profile → "Hesabı silme talebi oluştur". Backend wipe is wired through `process_account_deletion()` + `delete-accounts` edge function on a daily cron (see Account Deletion Pipeline below).
- Demo reviewer account: create one before submission and put credentials in App Store Connect review notes.
- Notification purpose: app uses **local** notifications only (flutter_local_notifications). No remote push tokens are collected. The iOS purpose string lives in `Info.plist` (`NSUserNotificationsUsageDescription`).
- **Premium / IAP**: not in this release. The `/premium` route, paywall screen, and the upsell card have been removed from the build. The `dev_toggle_premium` RPC is revoked and dropped by the latest migrations, and any old `manual/dev_toggle` subscription rows are removed. Re-add real StoreKit / RevenueCat plus restore-purchases flow before reintroducing.
- **F1 brand & data**: the app must ship with a clear "Unofficial — not affiliated with Formula 1, FIA, teams or drivers" disclaimer in onboarding, in the in-app About dialog, and in both legal docs. Avoid F1 logos, team logos, official driver portraits, pist/circuit logos and any wording that mimics official broadcast lines in icons, screenshots, and store metadata.
- **App Store Connect privacy answers**: declare only what we actually collect — Email, Name (optional), User Content (predictions), Identifiers (auth user id), Diagnostics (Sentry). Do **not** declare push tokens, ad data, location, contacts, or behavioral analytics.

## Privacy Manifest (iOS)

Apple now requires `PrivacyInfo.xcprivacy` and "required reason API" declarations. Before submission:

- Keep `ios/Runner/PrivacyInfo.xcprivacy` in the Runner target resources. It declares no tracking, the app data types used by GridCall, and required-reason API categories currently expected from Flutter/shared preferences.
- Re-check Sentry's published privacy manifest and link it as a sub-package privacy manifest where supported.

## Account Deletion Pipeline

Production wiring (run once per environment):

1. Apply `0028_account_deletion_processing.sql` to the target database.
2. Ensure Vault secrets `gridcall_project_url` and `gridcall_service_role_key` already exist (same secrets used by the OpenF1 ingest cron).
3. Deploy the edge function: `supabase functions deploy delete-accounts`.
4. Verify the `gridcall-delete-accounts` cron job in `cron.job` runs daily at 03:00 UTC.
5. Smoke test: insert a deletion request with `scheduled_for = now() - interval '1 minute'`, invoke the edge function manually, confirm the user's predictions, league memberships, profile and `auth.users` row are gone and the request status is `completed`.

The 30-day grace period is enforced in SQL (`scheduled_for = now() + interval '30 days'`), matches the privacy policy retention text, and gives users time to reach out and cancel by emailing support.

Suggested App Review note:

> Users can start account deletion in Profile by tapping "Hesabı silme talebi oluştur". The app creates a pending deletion request, signs the user out, and hides the profile. A Supabase scheduled job invokes the `delete-accounts` edge function daily; that service-role function wipes user-owned rows with `process_account_deletion()`, deletes the Supabase Auth user through `auth.admin.deleteUser`, then marks the request completed. The policy states a 30-day cancellation window.

## Release Smoke Test

- Sign up
- Complete onboarding
- Create a league
- Share league invite
- Join via invite code with a second user
- Save a prediction before lock
- Open weekly summary after results exist
- Change notification settings
- Rename league, regenerate invite code, remove member, transfer ownership
- Open Profile → "Hakkında" and confirm the unofficial-app disclaimer renders
- Open Profile → "Hesabı silme talebi oluştur" with a throwaway account, confirm the dialog shows the 30-day window and that the user is signed out
