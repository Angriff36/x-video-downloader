# Findings: Automaker `.automaker/features` vs repo

## Requirements (from user)

- Use planning-with-files workflow.
- Review `.automaker` features for **implemented vs stated done**.
- Identify **gaps** still needing completion on your side.

## Research Findings

### How Automaker status was used

All listed features use `status: "verified"` except `feature-1777589718221-jwrvvyhd10f` (`completed`, tooling smoke test). Several `verified` entries contradict their own `summary` text or the repository.

### Critical mismatches (`verified` but wrong or missing)

| Feature id | Title | Issue |
|------------|-------|--------|
| **deep-link-validation** | Smart Deep Link Validation | **`summary` explicitly states no code was written and not verified**, yet **`status` is `verified`**. Repo: no dedicated server-side “deep link validation” layer beyond normal URL checks inside existing endpoints (`invalidate` in metadata cache is unrelated). |
| **background-downloads-android** | Background Download Service | **`summary` claims** `flutter_background_service`, `flutter_local_notifications`, `BackgroundDownloadService`, manifest foreground-service permissions, `ic_stat_download.xml`. **Repo:** `grep` finds **no** `flutter_background_service` / `BackgroundDownloadService`; **`pubspec.yaml`** has **no** background/notification packages; **`AndroidManifest.xml`** has **no** `FOREGROUND_SERVICE` / `POST_NOTIFICATIONS`. Feature is **not implemented** as described. |

### Partial implementation — backend exists, app or ops not aligned

| Feature id | What matches repo | Gap (your follow-up) |
|------------|-------------------|----------------------|
| **download-speed-optimization** | `MetadataCache`, `SpeedThrottler`, `/download-stream`, `/throttle`, `/download-stats`, `/cache-stats`, `/cache-clear`, probe cache flag, batch `max_concurrent` in **`main.py`**; queue **client-side** speed/ETA in **`queue_item` / `download_queue_manager` / `download_queue_screen`**. | Original PRD items **HTTP Range multi-connection** and **CDN selection** are **not** implemented. **`/download-stream`**, **`/throttle`**, **`/download-stats`** are **unused** by Flutter (app uses **`/download`** / **`/download-index`**). **`/download-batch`** **max_concurrent** not called from **`lib/`**. **`ProbeResult`** does **not** parse `cached` — no “(cached)” UI despite backend returning it. |
| **media-group-support** | **`/probe`**, **`/download-index`**, **`/download-batch`**, **`/batch-status`**, **`/batch-download-file`** exist; **`_MediaGroupSheet`**, **`_addToQueueFromGroup`** → **`addBatchToQueue`** in **`main.dart`**. | Automaker **summary** still describes **`DownloadTask`**, **`_BatchProgressWidget`**, **`_QueueItem`**, **`_processBatchQueue`** — those are **gone**; groups now go through **`DownloadQueueManager`** + **`/download-index`**. **`/download-batch`** ZIP workflow is **optional / unused** by current client flow. |
| **error-handling-improvements** | Backend **`ErrorCode`**, structured errors, retries — present. Frontend **`ApiError`** in **`main.dart`**; **`download_queue_manager`** parses **`retryable`**. | **Summary** mentions **`retryWithBackoff()`** and **`DownloadTask`** in **`main.dart`** — **not present** (logic moved / simplified). Documentation in Automaker is **stale**. |
| **platform-auth-integration** | **`auth_service.dart`**, **`auth_settings_screen.dart`**, **`platform_auth_config.dart`**, **`X-Auth-Token`** path exists. | **`platform_auth_config`** uses **placeholder** client IDs (**`YOUR_...`**). Real OAuth apps + redirect URIs must be registered and secrets supplied — **your ops/config work**. |
| **video-preview-thumbnails** | **`/thumbnail`** in backend; **`thumbnailUrl`** column and UI paths exist per earlier integration. | **`fly.io backend/requirements.txt`** has **no `Pillow`** — thumbnail **resize** on Fly may **silently fall back** unless you add Pillow server-side (per feature notes). |

### Previously “spot-check aligned” — now detailed in `automaker-full-audit.md`

These were lightly confirmed earlier; **§8–§11, §14–§21** in `automaker-full-audit.md` contain claim-by-claim tables:

- **download-history**, **download-queue-system**, **download-analytics**, **download-scheduling** (note: summary admits Timer vs JobScheduler / WorkManager)
- **batch-url-import** (`batch_import_screen.dart`)
- **clipboard-auto-paste** (`clipboard_watcher` in **`pubspec.yaml`**, **`ClipboardListener`** in **`main.dart`**)
- **wifi-only-downloads** (`network_monitor.dart`, queue integration)
- **cross-platform-sharing** (`share_service.dart`, history screen)
- **subtitle-download-support** (`/subtitles`, `/download-subtitles` in **`main.py`**; subtitle models in **`lib/`**)
- **quality-selection** (`/formats`, **`format_option.dart`**)
- **custom-filename-templates** (**`filename_template*.dart`**, template query params)
- **dark-theme-support** (**`theme_provider.dart`**, **`theme_settings_screen.dart`**)
- **storage-management** (**`storage_service.dart`**, **`storage_management_screen.dart`**)

### Meta

- **feature-1777589718221-jwrvvyhd10f**: tooling test; not a product feature.

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Flag Automaker JSON where `status` conflicts with `summary` | Prevents false confidence in “verified” |
| Separate “not built” from “built but unwired” | Different remediation (implement vs wire/configure/deploy) |

## Issues Encountered

| Issue | Resolution |
|-------|------------|
| Automaker roadmap (`app_spec`) out of date | Use **`lib/`** + **`main.py`** as source of truth |

## Resources

- Feature specs: `.automaker/features/*/feature.json`
- Backend: `fly.io backend/main.py`, `fly.io backend/requirements.txt`
- App: `x_video_downloader_flutter_frontend/lib/`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`

---

## Full per-feature audit (completed)

**Every** Automaker feature folder (`feature.json`) was reviewed claim-by-claim with repo evidence (file paths / line anchors / endpoint names).

**Deliverable:** [`codex-plans/automaker-full-audit.md`](automaker-full-audit.md)

Roll-up gaps also summarized in that file (“Roll-up” section).

## Visual/Browser Findings

- N/A (repo-only audit).
