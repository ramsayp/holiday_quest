# HolidayQuest

A real-time group holiday gamification app. Players check in to venues, tag friends, earn points, and compete on a live leaderboard. Built on Salesforce, Cloudflare Workers, and GitHub Pages as a PWA.

---

## Architecture

```
Phone/Browser
     ↓
GitHub Pages (app/)
     ↓
Cloudflare Worker (salesforce-proxy.paulsbramsay.workers.dev)
  - Handles CORS
  - Issues and verifies JWT tokens
  - Forwards requests to Salesforce
     ↓
Salesforce Sites (empathetic-raccoon-47lfd3-dev-ed.trailblaze.my.salesforce-sites.com)
  - Apex REST endpoint
  - All data storage
```

---

## Folder Structure

```
holiday_quest/
├── app/                          # PWA app — served via GitHub Pages
│   ├── holidayquest.html         # Main app (React 18 via CDN + Babel)
│   ├── manifest.json             # PWA manifest
│   ├── sw.js                     # Service worker (cache: holidayquest-v3)
│   ├── icon-192.png              # App icon
│   └── icon-512.png              # App icon
├── salesforce/                   # Salesforce DX project
│   ├── sfdx-project.json
│   └── classes/                  # Apex classes
│       ├── RestAPIPostEndpoint.cls
│       ├── RestAPIPostFactory.cls
│       ├── RestAPIPostInterface.cls
│       ├── CreateClientHandler.cls
│       ├── VerifyClientHandler.cls
│       ├── SetupAccountHandler.cls
│       ├── CheckEmailHandler.cls
│       ├── HQ_CreateHolidayHandler.cls
│       ├── HQ_GetMyHolidaysHandler.cls
│       ├── HQ_GetHolidayStateHandler.cls
│       ├── HQ_AddPlayerByEmailHandler.cls
│       ├── HQ_CreateCheckinHandler.cls
│       ├── HQ_UpdatePlayerHandler.cls
│       ├── HQ_RemovePlayerHandler.cls
│       ├── HQ_AddPlaceHandler.cls
│       ├── HQ_UpdatePlaceHandler.cls
│       ├── HQ_RemovePlaceHandler.cls
│       ├── HQ_WrapHolidayHandler.cls
│       └── HQ_ReopenHolidayHandler.cls
├── cloudflare/
│   ├── worker.js                 # Cloudflare Worker proxy
│   └── wrangler.toml             # Wrangler deployment config
└── README.md
```

---

## Live URLs

| Service | URL |
|---|---|
| App (GitHub Pages) | https://ramsayp.github.io/holiday_quest/app/holidayquest.html |
| Cloudflare Worker | https://salesforce-proxy.paulsbramsay.workers.dev |
| Salesforce Site | https://empathetic-raccoon-47lfd3-dev-ed.trailblaze.my.salesforce-sites.com/holidayquest/services/apexrest/restAPIPostEndpoint |
| Salesforce Org | https://empathetic-raccoon-47lfd3-dev-ed.trailblaze.my.salesforce.com |
| GitHub Repo | https://github.com/ramsayp/holiday_quest |

---

## Salesforce Schema

### Platform Objects (app-agnostic)

**Client__c** — Platform identity. One record per user across all apps.
| Field | Type | Notes |
|---|---|---|
| Name | Text | Standard field — display name |
| Email__c | Email | Unique, External ID |
| Password_Hash__c | Text(64) | SHA-256 hash of password |
| Is_Placeholder__c | Checkbox | True = invited but not yet registered |

### HolidayQuest Objects

**Holiday__c**
| Field | Type | Notes |
|---|---|---|
| Name | Text | Standard field — holiday name |
| Client__c | Lookup(Client) | Who created it |
| Wrapped__c | Checkbox | True = holiday ended |

**Player__c** — Master-Detail to Holiday
| Field | Type | Notes |
|---|---|---|
| Name | Text | Display name for this holiday |
| Holiday__c | Master-Detail | Cascade deletes checkins |
| Client__c | Lookup(Client) | Links player to platform identity |
| Is_Admin__c | Checkbox | Admin can manage players/places |
| Color__c | Text | Hex colour e.g. #E64A19 |

**Place__c** — Master-Detail to Holiday
| Field | Type | Notes |
|---|---|---|
| Name | Text | Venue name |
| Holiday__c | Master-Detail | Cascade deletes checkins |
| Category__c | Text | Bar, Pub, Club, Restaurant, Other |
| Points__c | Number | Points awarded for check-in |

**Checkin__c** — Master-Detail to Player and Place
| Field | Type | Notes |
|---|---|---|
| Player__c | Master-Detail | Who was checked in |
| Place__c | Master-Detail | Where |
| Tagged_By__c | Lookup(Player) | Null = self check-in, populated = tagged by this player |

---

## Apex Classes

### REST Endpoint
- **RestAPIPostEndpoint** — single `@HttpPost` entry point, routes by `type` field
- **RestAPIPostFactory** — switch statement routing type → handler
- **RestAPIPostInterface** — interface all handlers implement: `process(Object payload)`

### Platform Handlers (no prefix — reusable across apps)
| Handler | Type | Description |
|---|---|---|
| CreateClientHandler | Public | Register new client. Converts placeholder if email exists |
| VerifyClientHandler | Public | Verify email + password hash. Rejects placeholders |
| SetupAccountHandler | Public | Convert placeholder → full account |
| CheckEmailHandler | Public | Check if email exists and if placeholder |

### HolidayQuest Handlers (HQ_ prefix)
| Handler | Auth | Description |
|---|---|---|
| HQ_CreateHolidayHandler | JWT | Create Holiday + admin Player for creator |
| HQ_GetMyHolidaysHandler | JWT | Get all holidays for a clientId |
| HQ_GetHolidayStateHandler | JWT | Get full game state (players, places, checkins) |
| HQ_AddPlayerByEmailHandler | JWT | Add player by email. Creates placeholder if not registered |
| HQ_CreateCheckinHandler | JWT | Create checkin. taggedById null = self, populated = tag |
| HQ_UpdatePlayerHandler | JWT | Update player name and colour |
| HQ_RemovePlayerHandler | JWT | Delete player (cascade deletes checkins) |
| HQ_AddPlaceHandler | JWT | Add a venue |
| HQ_UpdatePlaceHandler | JWT | Update venue name, points, category |
| HQ_RemovePlaceHandler | JWT | Delete venue (cascade deletes checkins) |
| HQ_WrapHolidayHandler | JWT | End holiday — show final results only |
| HQ_ReopenHolidayHandler | JWT | Reopen wrapped holiday |

### Public Routes (no JWT required)
`CreateClient`, `VerifyClient`, `SetupAccount`, `CheckEmail`, `GetToken`

---

## Cloudflare Worker

**File:** `cloudflare/worker.js`  
**URL:** `salesforce-proxy.paulsbramsay.workers.dev`  
**Config:** `cloudflare/wrangler.toml`

### What it does
1. Handles CORS preflight (OPTIONS requests) — Salesforce Sites can't do this natively
2. Public routes — forwards directly to Salesforce without JWT check
3. Protected routes — verifies JWT before forwarding
4. Signs JWT tokens on `GetToken` requests

### Environment Variables (set in Cloudflare dashboard, never in code)
| Variable | Notes |
|---|---|
| JWT_SECRET | Secret key for signing/verifying JWTs |

### JWT Payload
```json
{
  "sub": "clientId",
  "name": "Paul Ramsay",
  "email": "paul@email.com",
  "app": "holidayquest",
  "iat": 1234567890,
  "exp": 1234567890
}
```
Expiry: 12 hours

### Deploy Worker
```bash
cd cloudflare
wrangler deploy
```

---

## App (holidayquest.html)

Single HTML file — React 18 via CDN, Babel standalone, no build step.

### Tech Stack
- React 18 (CDN)
- Babel standalone (JSX compilation in browser)
- CSS custom properties for theming
- localStorage for session persistence
- Service Worker for PWA/offline

### localStorage Keys
| Key | Value |
|---|---|
| hq_jwt | JWT token |
| hq_client | `{ clientId, name, email }` |
| hq_holiday | Last active holidayId |
| hq_player | Last active playerId |

### Leaderboard & Ranking

Uses **competition ranking** (1, 1, 3 style) — players with equal points share the same rank.

| Behaviour | Detail |
|---|---|
| Tied rank | Both players receive the same rank number (e.g. two players on 500pts both show rank 1) |
| Tie indicator | A small `=` badge appears above the rank number in the leaderboard list |
| Podium heights | Block height is driven by rank, not array position — tied players render at the same height (rank 1 → 110px, rank 2 → 78px, rank 3 → 58px) |
| Zero points | Podium block renders flat (8px) with the rank label shown above the block |
| Podium label | Tied podium positions show `=N` (e.g. `=1`) instead of the position number |

### App Statuses (screens)
| Status | Screen |
|---|---|
| booting | Loading spinner |
| login | Login / Register |
| accountSetup | Invited user sets name + password |
| holidays | My holidays list + create new |
| holidaySetup | After creating — invite players |
| app | Main game screen |
| wrapped | Final results |
| error | Error screen |

### User Journeys

**Journey 1 — New user registers:**
Register → My Holidays (empty) → Create Holiday → Holiday Setup (invite players) → App

**Journey 2 — Returning user:**
Login (email step) → (password step) → My Holidays → tap holiday → App

**Journey 3 — Invited user, already registered:**
Admin invites email → Player record created → User logs in normally → Holiday appears tagged "Invited"

**Journey 4 — Invited user, not yet registered:**
Admin invites email → Placeholder Client + Player created → User enters email on login → detected as placeholder → Account Setup screen → sets name + password → auto-login → Holiday appears

**Journey 5 — Placeholder user tries to register:**
Goes to Register tab → enters email → placeholder detected → redirected to Account Setup

### Password Security
- SHA-256 hashed in browser before transmission
- Hash stored in Salesforce `Password_Hash__c`
- Plain text password never leaves the device
- TODO: Add pepper via Cloudflare env variable for rainbow table protection

---

## Salesforce Setup Notes

### Site Configuration
- Site name: HolidayQuest
- URL prefix: `holidayquest`
- Status: Active
- Guest User: `guestholidayquest@00dqy00000oaegdma4.org.force.com`

### Guest User Permissions
The guest user profile needs:
- **Object permissions:** Read, Create, Edit on Client, Holiday, Player, Place, Checkin
- **Permission Set:** Delete permission on Player and Place (can't be set on guest profile directly — use a Permission Set assigned to the guest user)
- **Field-level security:** Read/Edit on all custom fields
- **Apex Class Access:** RestAPIPostEndpoint

### All Apex Classes Must Be
- `global without sharing` — required for guest user data access
- Added to Site's Public Access Settings → Apex Class Access

### Sharing Settings
- Client__c External Access: **Public Read/Write** — required so guest user can query records it created

---

## Deployment Guide

### Deploy App Changes
1. Edit `app/holidayquest.html`
2. Bump cache version in `app/sw.js` (`holidayquest-v3` → `v4` etc)
3. `git add -A && git commit -m "description" && git push`
4. GitHub Pages auto-deploys within 2 minutes

### Deploy Cloudflare Worker Changes
1. Edit `cloudflare/worker.js`
2. `cd cloudflare && wrangler deploy`
3. `cd .. && git add -A && git commit -m "update worker" && git push`

### Deploy Salesforce Changes
1. Edit class in `salesforce/classes/`
2. Deploy via Salesforce CLI: `sf project deploy start --target-org holidayquest`
3. Or paste into Developer Console manually
4. `git add -A && git commit -m "update apex" && git push`

### Retrieve Salesforce Classes
```bash
sf project retrieve start --metadata ApexClass --target-org holidayquest
```

---

## Backlog / Known Issues

### Bugs
- Password uses plain SHA-256 — add Cloudflare pepper for better security
- PWA cache requires manual version bump on every deploy

### Planned Features
- **Challenges** — venue-specific challenges with peer verification and bonus points
- **Push notifications** — notify when tagged or new activity
- **Live shareable leaderboard** — public URL anyone can view without logging in
- **Holiday templates** — save venue lists for reuse
- **Google OAuth** — one tap login

### Future Platform Features
- FootballQuest, CityQuest, OfficeQuest using same Client/Worker/Apex platform
- GitHub Actions for automated deployment to all three platforms
- Bcrypt password hashing in Cloudflare Worker
- MFA via TOTP

---

## Local Development Setup

### Prerequisites
- Node.js (for Wrangler)
- Salesforce CLI (`sf`)
- Git
- VS Code with Salesforce Extension Pack

### First Time Setup
```bash
git clone https://github.com/ramsayp/holiday_quest
cd holiday_quest
sf org login web --alias holidayquest
npm install -g wrangler
wrangler login
```

### VS Code Extensions
- Salesforce Extension Pack
- GitLens (recommended)
- Prettier (recommended)
