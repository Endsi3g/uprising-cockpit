# GEMINI.md — Uprising Emergency Cockpit

> This file gives AI assistants (Gemini, Claude, GPT, etc.) full context about this project.

## Project Identity

**App name**: Uprising Emergency Cockpit  
**Platform**: Flutter (iOS + Android)  
**Language**: Dart  
**Mode**: Light mode only  
**UI inspiration**: Jobber mobile app design (Atlantis design system, Tory Blue #0D609E)

## What This App Does

A mobile dashboard for Quebec plumbers and roofers that shows in real-time:  
- How much money Uprising AI has **saved** by intercepting missed emergency calls
- Which leads were captured, qualified, and booked automatically by AI
- Scheduled interventions on a calendar
- Stats and trends over the last 30 days
- AI chat assistant (Groq / Ollama) for business insights

## Stack

- **Flutter** + **Riverpod 2** (state) + **GoRouter 13** (navigation)
- **Supabase** (PostgreSQL, Realtime, Edge Functions)
- **Groq API** – `llama-3.3-70b-versatile` (AI, free tier)
- **Ollama** – `llama3.2` (local AI fallback at localhost:11434)
- **Twilio** (inbound call/SMS webhooks)
- **fl_chart** (bar + line charts)
- **home_widget** (Android + iOS home screen widgets)
- **google_fonts** (Inter)
- **flutter_dotenv** (.env config)

## Folder Structure

```
lib/
├── core/
│   ├── theme/         # AppTheme, AppColors (Jobber-inspired light mode)
│   ├── supabase/      # SupabaseConfig, router.dart, shell_scaffold.dart
│   ├── groq/          # GroqService (HTTP, French prompts)
│   ├── ollama/        # OllamaService (local fallback)
│   └── constants.dart # Table names, enum types, dev business_id
├── models/            # Lead, Client, Booking, Stats, Transcript
├── repositories/      # LeadRepository, BookingRepository, StatsRepository
└── features/
    ├── cockpit/       # Main dashboard (KPI hero + realtime feed)
    ├── lead_detail/   # Emergency detail (timeline, transcript, actions)
    ├── jobs/          # Jobs list with filters
    ├── calendar/      # Week picker + daily bookings
    ├── stats/         # Charts + KPI tiles
    ├── clients/       # Client list + profile
    ├── ai_chat/       # Groq/Ollama AI assistant
    └── settings/      # Business config + value presets
supabase/
├── schema.sql         # Full schema + seed data
└── functions/         # Edge Functions (Twilio, Groq)
```

## Design System

| Token | Value |
|---|---|
| Primary | `#0D609E` (Tory Blue) |
| Success | `#1A9E5B` (green) |
| Warning | `#E8891A` (amber) |
| Danger | `#D93626` (red) |
| Background | `#FFFFFF` |
| Surface | `#F6F7F8` |
| Text Primary | `#1A1A1A` |
| Text Secondary | `#6B7280` |
| Font | Inter (Google Fonts) |

## Key Business Logic

- `$ sauvés` = sum of `estimated_value_cad` for leads where `ai_handled=true` AND `missed_by_human=true`
- Lead statuses: `nouveau → qualifie → booke → complete` (or `perdu`)
- Dev hardcodes `business_id = '00000000-0000-0000-0000-000000000001'` (no auth yet)

## Auth Strategy

Auth is **deferred** — currently using a hardcoded `DEV_BUSINESS_ID`.  
When adding auth: Supabase Auth (email magic link) → update RLS policies → replace `kDevBusinessId` with `supabase.auth.currentUser?.id`.

## Environment Variables (.env)

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
GROQ_API_KEY=
OLLAMA_BASE_URL=http://localhost:11434
DEV_BUSINESS_ID=00000000-0000-0000-0000-000000000001
```

## Common Commands

```bash
flutter run                        # Run on connected device
flutter run -d chrome              # Run on web (limited)
flutter build apk --release        # Build Android APK
flutter pub get                    # Install dependencies
flutter pub run build_runner build # Generate Riverpod code
```

## Supabase

- Project: https://czbxtvvbdimtqysxgovp.supabase.co
- Run `supabase/schema.sql` in SQL editor before first run
- RLS is disabled for dev (enable before prod)

## What's NOT done yet (next tasks)

1. Supabase Edge Function: `twilio-webhook` (creates leads from inbound calls)
2. Supabase Edge Function: `groq-process` (summarizes transcripts)
3. Android + iOS home screen widgets
4. Auth (Supabase magic link)
5. Push notifications (FCM)
6. Client detail screen full implementation
