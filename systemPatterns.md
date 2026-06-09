# System Patterns

## Architecture
- Flutter frontend triggers FastAPI endpoints
- Backend uses yt-dlp and ffmpeg for media processing
- Android-specific handling via Kotlin
- Local-first model with no server dependency

## Key Technical Decisions
- `uv` used for Python dependency management
- `ffmpeg` included via subprocess call
- Storage handled via Android scoped storage

## Design Patterns
- Separation of concerns: UI triggers API, API handles logic
- Shared storage through platform channel
- Download queue planned but not yet implemented

## Component Relationships
- Flutter UI <-> HTTP API <-> yt-dlp subprocess
- Android <-> Kotlin permissions <-> Flutter method channel

## Critical Paths
- Video download and post-processing (ffmpeg)
- Permission handling and media saving
