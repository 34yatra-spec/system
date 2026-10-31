# reel-hub API Guide

HTTP API reference for reel-hub.

- **Base URL**: `https://reel-hub.31yatra.workers.dev`
- **Auth**: `Authorization: Bearer <REEL_API_TOKEN>` on all `/v1/*` routes
- **Content type**: `application/json` for POST bodies

```bash
set -a; . /kaggle/working/productions/reel-hub/.reel_hub.env; set +a
# provides REEL_HUB_URL and REEL_HUB_TOKEN
```

## Conventions

- Reel IDs are `IG_<shortcode>`. Endpoints that accept `:id` also accept the shortcode without the `IG_` prefix.
- Timestamps are ISO 8601 UTC strings.
- Errors use:

```json
{ "error": { "code": "invalid_request", "message": "owner is required" } }
```

- Error codes: `unauthorized`, `invalid_request`, `invalid_transition`, `lock_owner_mismatch`, `lock_lost`, `not_found`, `internal`.
- HTTP codes: `200`, `400`, `401`, `404`, `409`, `415`, `500`, `502`, `503`.
- Missing or invalid bearer token returns `401`. An unset `REEL_API_TOKEN` returns `500 misconfigured`.

### Reel statuses

`PENDING`, `PROCESSING`, `UPLOADING`, `RENDERED`, `POSTED`, `SKIPPED`, `FAILED`.

### Reel object

| Field | Type | Meaning |
| --- | --- | --- |
| `reel_id` | string | `IG_<shortcode>` |
| `instagram_url` | string | Canonical Instagram URL |
| `instagram_shortcode` | string | Instagram shortcode |
| `original_url` | string | URL as received |
| `status` | string | One of the statuses above |
| `caption_no` | number | Stable sequential number |
| `caption` | string \| null | Full caption text |
| `title` | string \| null | Display title; defaults to the caption's first line |
| `local_file_path` | string \| null | Rendered file path |
| `category` | string \| null | Category slug |
| `subcategory` | string \| null | Subcategory slug |
| `category_confidence` | number \| null | Classifier confidence |
| `category_reason` | string \| null | Classifier reason |
| `production_attempts` | number | Number of claims |
| `lock_owner` | string \| null | Current lock owner |
| `lock_expires_at` | string \| null | Lock expiry |
| `collected_at` | string | Collection timestamp |
| `processing_started_at` | string \| null | Claim timestamp |
| `processing_completed_at` | string \| null | Completion timestamp |
| `posted_at` | string \| null | Posted timestamp |
| `caption_updated_at` | string \| null | Last caption write |
| `error_message` | string \| null | Last failure reason |
| `next_retry_at` | string \| null | Earliest retry time |
| `updated_at` | string | Last update timestamp |

---

## GET /health

Public. Returns service and D1 health.

```bash
curl -sS "$REEL_HUB_URL/health" | jq .
```

```json
{ "ok": true, "service": "reel-hub", "version": "0.1.0", "d1": "ok" }
```

`503` with `ok: false` when D1 is unavailable.

---

## GET /v1/stats

Overall and per-category counts.

```bash
curl -sS -H "Authorization: Bearer $REEL_HUB_TOKEN" "$REEL_HUB_URL/v1/stats" | jq .
```

```json
{
  "totals": {
    "PENDING": 2,
    "PROCESSING": 0,
    "UPLOADING": 0,
    "RENDERED": 0,
    "POSTED": 0,
    "SKIPPED": 0,
    "FAILED": 0
  },
  "pending_count": 2,
  "categories": [
    { "category": "UNCATEGORIZED", "PENDING": 2, "RENDERED": 0, "total": 2 }
  ]
}
```

---

## GET /v1/jobs

List reels, newest first.

| Query | Default | Notes |
| --- | --- | --- |
| `status` | `ALL` | Any status or `ALL` |
| `category` | none | Category slug or name |
| `limit` | `25` | `1`–`100` |
| `offset` | `0` | Pagination |

```bash
curl -sS -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  "$REEL_HUB_URL/v1/jobs?status=PENDING&category=ASTROLOGY&limit=10&offset=0" | jq .
```

```json
{ "rows": [ { "reel_id": "IG_XXXX", "caption_no": 3, "status": "PENDING" } ], "total": 1, "limit": 10, "offset": 0 }
```

Invalid `status` returns `400 invalid_request`.

---

## GET /v1/jobs/:id

Fetch one reel and its recent events.

```bash
curl -sS -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  "$REEL_HUB_URL/v1/jobs/IG_XXXX" | jq .
```

```json
{
  "job": { "reel_id": "IG_XXXX", "caption_no": 3, "status": "RENDERED" },
  "events": [
    { "event_type": "rendered", "from_status": "PROCESSING", "to_status": "RENDERED" }
  ]
}
```

`404 not_found` if the reel does not exist.

---

## POST /v1/jobs/claim

Claims the oldest eligible reel and sets `PROCESSING` with a lock.

Eligible: `PENDING`; retryable `FAILED` past `next_retry_at`; `PROCESSING`/`UPLOADING` with an expired lock. All are capped by `max_attempts`.

Request:

```json
{
  "owner": "opencode-kaggle",
  "lock_seconds": 5400,
  "max_attempts": 3,
  "category": "ASTROLOGY"
}
```

| Field | Required | Notes |
| --- | --- | --- |
| `owner` | yes | Max 120 chars |
| `lock_seconds` | no | Default `DEFAULT_LOCK_SECONDS` (5400), clamped 60–86400 |
| `max_attempts` | no | Default `MAX_PRODUCTION_ATTEMPTS` (3) |
| `category` | no | Filter by category |

```bash
curl -sS -X POST -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"owner":"opencode-kaggle"}' \
  "$REEL_HUB_URL/v1/jobs/claim" | jq .
```

Claimed:

```json
{
  "job": {
    "reel_id": "IG_XXXX",
    "caption_no": 3,
    "status": "PROCESSING",
    "lock_owner": "opencode-kaggle",
    "lock_expires_at": "2026-10-31T07:00:00.000Z",
    "production_attempts": 1
  },
  "lock_seconds": 5400
}
```

Nothing available:

```json
{ "job": null, "lock_seconds": 5400 }
```

Side effects: increments `production_attempts`, sets `processing_started_at`, clears `error_message` and `next_retry_at`, records a `claimed` event.

---

## POST /v1/jobs/:id/heartbeat

Extends the lock on a `PROCESSING` or `UPLOADING` reel owned by `owner`.

```json
{ "owner": "opencode-kaggle", "lock_seconds": 5400 }
```

```bash
curl -sS -X POST -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"owner":"opencode-kaggle","lock_seconds":5400}' \
  "$REEL_HUB_URL/v1/jobs/IG_XXXX/heartbeat" | jq .
```

```json
{ "job": { "lock_expires_at": "2026-10-31T07:30:00.000Z" }, "lock_expires_at": "2026-10-31T07:30:00.000Z" }
```

Errors: `409 invalid_transition` if not `PROCESSING`/`UPLOADING`; `409 lock_owner_mismatch` if another owner holds the lock.

---

## POST /v1/jobs/:id/complete

Marks a claimed reel `RENDERED` and stores the caption.

Request:

```json
{
  "owner": "opencode-kaggle",
  "caption": "Why You Feel Stuck\nFull caption text here...",
  "title": "Why You Feel Stuck",
  "local_file_path": "/kaggle/working/productions/reel-hub/rendered/0003_why-you-feel-stuck.mp4"
}
```

| Field | Required | Notes |
| --- | --- | --- |
| `owner` | yes | Must match `lock_owner` |
| `caption` | yes | Max 5000 chars |
| `title` | no | Max 200 chars; defaults to the caption's first non-empty line |
| `local_file_path` | no | Defaults to `<RENDER_DIR>/<caption_no padded>_<title-slug>.mp4` |

```bash
curl -sS -X POST -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"owner":"opencode-kaggle","caption":"First line is the title\nRest of the caption"}' \
  "$REEL_HUB_URL/v1/jobs/IG_XXXX/complete" | jq .
```

```json
{
  "file_name": "0003_why-you-feel-stuck.mp4",
  "job": {
    "reel_id": "IG_XXXX",
    "caption_no": 3,
    "status": "RENDERED",
    "title": "Why You Feel Stuck",
    "caption": "Why You Feel Stuck\nFull caption text here...",
    "local_file_path": "/kaggle/working/productions/reel-hub/rendered/0003_why-you-feel-stuck.mp4",
    "processing_completed_at": "2026-10-31T06:06:52.610Z",
    "lock_owner": null
  }
}
```

Side effects: clears the lock, sets `caption_updated_at`, records a `rendered` event.

Errors: `409 invalid_transition` if not `PROCESSING`; `409 lock_owner_mismatch`; `409 lock_lost` if the update loses a race.

---

## POST /v1/jobs/:id/fail

Marks a reel `FAILED` and clears the lock.

```json
{ "owner": "opencode-kaggle", "error": "render crashed", "retryable": true }
```

| Field | Required | Notes |
| --- | --- | --- |
| `owner` | no | Checked when the reel is locked |
| `error` | no | Max 2000 chars; default `production failed` |
| `retryable` | no | Default `true`; sets `next_retry_at` to +10 minutes. `false` prevents auto-retry |

Cannot fail a `RENDERED`, `POSTED`, or `SKIPPED` reel (`409 invalid_transition`).

---

## POST /v1/jobs/:id/category

Sets or changes the category, creating it if needed.

```json
{
  "category": "Astrology",
  "subcategory": "daily",
  "confidence": 0.92,
  "reason": "zodiac keywords",
  "actor": "opencode-kaggle"
}
```

| Field | Required | Notes |
| --- | --- | --- |
| `category` | yes | Slugified to uppercase |
| `subcategory` | no | Slugified |
| `confidence` | no | Number |
| `reason` | no | Max 1000 chars |
| `actor` | no | Default `opencode` |

```json
{ "job": { "category": "ASTROLOGY" }, "category": { "slug": "ASTROLOGY" }, "sync": null }
```

`sync` is always `null` while storage is disabled.

---

## GET /v1/categories

```bash
curl -sS -H "Authorization: Bearer $REEL_HUB_TOKEN" "$REEL_HUB_URL/v1/categories" | jq .
```

```json
{
  "categories": [
    {
      "slug": "ASTROLOGY",
      "name": "Astrology",
      "total": 4,
      "pending": 1,
      "processing": 0,
      "uploading": 0,
      "rendered": 3,
      "posted": 0,
      "skipped": 0,
      "failed": 0
    }
  ]
}
```

---

## GET /v1/admin/config

Reports readiness without exposing secret values.

```json
{
  "service": "reel-hub",
  "version": "0.1.0",
  "d1": "ok",
  "telegram": {
    "configured": true,
    "missing": [],
    "chat_id_configured": true,
    "bot_token_configured": true
  },
  "idrive": { "configured": false },
  "limits": { "max_production_attempts": 3, "default_lock_seconds": 5400 }
}
```

---

## GET|POST /v1/admin/telegram/webhook

- `GET` returns Telegram `getWebhookInfo`.
- `POST` registers the webhook at the request origin.

```bash
curl -sS -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  "$REEL_HUB_URL/v1/admin/telegram/webhook" | jq .
```

---

## POST /v1/admin/telegram/test

Sends a message to the first configured chat ID.

```json
{ "text": "reel-hub is connected." }
```

```bash
curl -sS -X POST -H "Authorization: Bearer $REEL_HUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"reel-hub is connected."}' \
  "$REEL_HUB_URL/v1/admin/telegram/test" | jq .
```

```json
{ "ok": true, "message_id": 122 }
```

---

## POST /v1/admin/recover

Fails `PROCESSING`/`UPLOADING` reels whose lock expired at or above `MAX_PRODUCTION_ATTEMPTS`.

```json
{ "recovered": 1, "reel_ids": ["IG_XXXX"] }
```

---

## POST /telegram/webhook

Internal Telegram callback. Requires header `X-Telegram-Bot-Api-Secret-Token: <TELEGRAM_WEBHOOK_SECRET>`. It does not use the bearer token.
