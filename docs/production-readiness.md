# PitWall Production Readiness

This checklist keeps app code, Supabase schema, and store setup moving together.

## Before Testing a New Build

1. Apply every new file in `supabase/migrations/` to the target database.
2. Reload PostgREST schema cache after adding or changing RPCs:
   `notify pgrst, 'reload schema';`
3. Run `flutter analyze` and `flutter test` from `app/`.
4. Launch the app with production-like flags:
   `flutter run --dart-define=ENABLE_DEMO_CONTENT=false`

## Supabase Auth

- Add `io.supabase.pitwall://auth-callback` to Supabase Auth additional redirect URLs.
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

- Privacy policy URL
- Terms of service URL
- Support email
- Account deletion flow or support path
- Demo reviewer account or reviewer notes for auth
- Push notification purpose text in onboarding/settings
- In-app purchase notes if Premium is submitted

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
