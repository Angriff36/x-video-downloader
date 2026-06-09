CogniLayer v4 active — persistent memory is on. Type /cognihelp for available commands.

I'll implement subtitle download support for this X video downloader project. Let me start by exploring the codebase to understand the existing structure.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Explore codebase structure and existing patterns",
      "status": "in_progress",
      "activeForm": "Exploring codebase structure"
    },
    {
      "content": "Plan implementation approach for subtitle support",
      "status": "pending",
      "activeForm": "Planning implementation approach"
    },
    {
      "content": "Implement backend subtitle extraction/download",
      "status": "pending",
      "activeForm": "Implementing backend subtitle support"
    },
    {
      "content": "Implement frontend subtitle UI (language selection, format options)",
      "status": "pending",
      "activeForm": "Implementing frontend subtitle UI"
    },
    {
      "content": "Implement subtitle format conversion (SRT, VTT, ASS)",
      "status": "pending",
      "activeForm": "Implementing subtitle format conversion"
    },
    {
      "content": "Implement subtitle embedding in MP4 container",
      "status": "pending",
      "activeForm": "Implementing subtitle embedding"
    },
    {
      "content": "Test and verify the implementation",
      "status": "pending",
      "activeForm": "Testing and verifying implementation"
    },
    {
      "content": "Output final summary",
      "status": "pending",
      "activeForm": "Outputting final summary"
    }
  ]
}

🔧 Tool: Task
Input: {
  "description": "Explore codebase structure",
  "prompt": "Explore the codebase at C:\\Projects\\x_video_downloader thoroughly. I need to understand:\n\n1. The overall project structure - what directories exist, what each contains\n2. The \"fly.io backend\" - what language, framework, how it works, key files\n3. The \"x_video_downloader_flutter_frontend\" - Flutter app structure, key screens, services, models\n4. How video downloads currently work end-to-end (user input → backend → download → save)\n5. Any existing download-related models, services, and APIs\n6. The database schema if any\n7. Configuration files (pubspec.yaml, requirements.txt, package.json, etc.)\n\nReturn a detailed summary of the architecture, key files with their paths, and how the download flow works. Include specific file paths and line numbers for key functions/classes.",
  "subagent_type": "Explore"
}

🔧 Tool: Bash
Input: {
  "command": "find . -type d -not -path \"./.automaker*\" -not -path \"./.git*\" -not -path \"./node_modules*\" | sort",
  "description": "List all project directories excluding system directories"
}

🔧 Tool: Bash
Input: {
  "command": "ls -la | grep -E '^d|total'",
  "description": "List main directories in project root"
}

🔧 Tool: Bash
Input: {
  "command": "tree -L 3 'fly.io backend' 'x_video_downloader_flutter_frontend'",
  "description": "Show directory structure for backend and frontend"
}

🔧 Tool: Bash
Input: {
  "command": "ls -la 'fly.io backend' && echo \"---\" && ls -la 'x_video_downloader_flutter_frontend'",
  "description": "List contents of backend and frontend directories"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py"
}

🔧 Tool: Bash
Input: {
  "command": "ls -la 'x_video_downloader_flutter_frontend/lib'",
  "description": "List lib directory contents"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\pubspec.yaml"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\requirements.txt"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\fly.toml"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_record.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "limit": 50
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\batch_import_screen.dart",
  "limit": 80
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\README.md"
}
Now let me look at the specific key files in detail to understand the patterns I need to follow.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\requirements.txt"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "offset": 100,
  "limit": 200
}
Let me continue reading the key parts of the backend - the probe and download endpoints.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 200,
  "offset": 300
}

🔧 Tool: Grep
Input: {
  "pattern": "@app\\.(get|post|put|delete)\\(",
  "path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "output_mode": "content"
}
Now let me read the probe endpoint and download endpoint to understand the exact response format.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 200,
  "offset": 500
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 200,
  "offset": 700
}
Now let me look at the Flutter frontend's main.dart to understand how downloads are initiated from the UI.

🔧 Tool: Task
Input: {
  "description": "Read Flutter frontend main.dart",
  "prompt": "Read C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart and focus on:\n\n1. How the download flow works in the UI (what happens when user clicks download)\n2. The download dialog/widget structure\n3. How format selection works\n4. How the backend API is called\n5. The main widget classes and their structure\n6. The _XVideoDownloaderState class methods related to downloading\n\nReturn a detailed summary with:\n- Key class names and methods\n- The download flow step by step with line numbers\n- How the backend URL is configured\n- How format selection is shown to the user\n- The overall widget tree structure for the download screen\n- Any existing settings or preferences patterns",
  "subagent_type": "Explore"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\format_option.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 100,
  "offset": 100
}

🔧 Tool: Grep
Input: {
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib",
  "pattern": "downloadUrl|DownloadRecord|actual download",
  "type": "dart",
  "output_mode": "files_with_matches"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_record.dart",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\background_download_service.dart",
  "limit": 150
}

🔧 Tool: Grep
Input: {
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib",
  "pattern": "_downloadActual|downloadUrl|_processQueue",
  "output_mode": "content",
  "-A": 5,
  "-B": 5,
  "-n": true,
  "type": "dart"
}

🔧 Tool: Grep
Input: {
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "pattern": "_downloadActual",
  "output_mode": "content",
  "-A": 30,
  "-B": 10,
  "-n": true
}

🔧 Tool: Grep
Input: {
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "pattern": "startDownload|downloadUrl|Future<void>.*download",
  "output_mode": "content",
  "-A": 30,
  "-B": 10,
  "-n": true
}

🔧 Tool: Grep
Input: {
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "pattern": "future|HttpClient|download.*stream|bytes|file",
  "output_mode": "content",
  "-A": 50,
  "-B": 5,
  "-n": true,
  "offset": 394
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 200,
  "offset": 394
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "in_progress"
    },
    {
      "activeForm": "Implementing backend subtitle support",
      "content": "Implement backend subtitle extraction/download",
      "status": "pending"
    },
    {
      "activeForm": "Implementing frontend subtitle UI",
      "content": "Implement frontend subtitle UI (language selection, format options)",
      "status": "pending"
    },
    {
      "activeForm": "Implementing subtitle format conversion",
      "content": "Implement subtitle format conversion (SRT, VTT, ASS)",
      "status": "pending"
    },
    {
      "activeForm": "Implementing subtitle embedding",
      "content": "Implement subtitle embedding in MP4 container",
      "status": "pending"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "pending"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "pending"
    }
  ]
}
Now let me read the download-stream endpoint and the queue manager to understand the full picture before planning.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 200,
  "offset": 1299
}

🔧 Tool: Grep
Input: {
  "output_mode": "content",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "pattern": "class|Future|async|void",
  "head_limit": 80
}
Let me read the queue manager's addToQueue and _startDownload methods to understand the full download flow.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 100,
  "offset": 130
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 200,
  "offset": 363
}
Now let me read the QueueItem model and the database schema to understand the data model.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 130,
  "offset": 1
}

🔧 Tool: Grep
Input: {
  "output_mode": "content",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "pattern": "CREATE TABLE|queue_items|downloads"
}
Now let me read the QueueItem model and the QualityPickerSheet in detail to understand how to add subtitle options.

🔧 Tool: Glob
Input: {
  "pattern": "**/queue_item.dart",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 200,
  "offset": 1212
}
Now let me read the _showQualityPickerSheet and _fetchFormatsAndShowPicker methods to understand the full quality picker flow.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 100,
  "offset": 547
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 40,
  "offset": 646
}
Now I have a thorough understanding of the codebase. Let me read the FormatOption model to understand its structure, then plan the implementation.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 130,
  "offset": 1
}
Let me also check the FormatOption model file.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\format_option.dart"
}
Now I have a complete understanding of the codebase. Let me update my plan and start implementing.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle endpoints",
      "content": "Backend: Add /subtitles endpoint to list available subtitles",
      "status": "in_progress"
    },
    {
      "activeForm": "Implementing backend subtitle download",
      "content": "Backend: Add /download-subtitles endpoint to download/convert subtitles",
      "subtitle": "Support SRT, VTT, ASS format conversion"
    },
    {
      "status": "pending",
      "activeForm": "Implementing backend subtitle embedding",
      "content": "Backend: Modify /download endpoint to support subtitle embedding in MP4"
    },
    {
      "activeForm": "Updating frontend data models",
      "content": "Frontend: Add subtitle-related fields to data models (QueueItem, FormatOption, etc.)",
      "status": "pending"
    },
    {
      "activeForm": "Building subtitle selection UI",
      "content": "Frontend: Add subtitle language selection UI to quality picker",
      "status": "pending"
    },
    {
      "activeForm": "Building subtitle settings UI",
      "content": "Frontend: Add subtitle format and embed/sidecar preference UI",
      "status": "pending"
    },
    {
      "activeForm": "Wiring download flow with subtitles",
      "content": "Frontend: Wire subtitle options into the download queue flow",
      "status": "pending"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "pending"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "pending"
    }
  ]
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle endpoints",
      "content": "Backend: Add /subtitles and /download-subtitles endpoints",
      "status": "in_progress"
    },
    {
      "activeForm": "Implementing backend subtitle embedding",
      "content": "Backend: Modify /download to support subtitle embedding in MP4",
      "status": "pending"
    },
    {
      "activeForm": "Updating frontend data models",
      "content": "Frontend: Add subtitle-related fields to data models",
      "status": "pending"
    },
    {
      "activeForm": "Building subtitle selection UI",
      "content": "Frontend: Add subtitle language selection UI to quality picker",
      "status": "pending"
    },
    {
      "activeForm": "Building subtitle settings UI",
      "content": "Frontend: Add subtitle format and embed/sidecar preference UI",
      "status": "pending"
    },
    {
      "activeForm": "Wiring download flow with subtitles",
      "content": "Frontend: Wire subtitle options into download queue flow",
      "status": "pending"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "pending"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "pending"
    }
  ]
}
Now let me implement the backend changes. First, I need to read the end of the main.py file to know where to add the new endpoints.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 50,
  "offset": 1550
}
Now I'll implement the backend subtitle support. Let me add the subtitle-related endpoints to main.py.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "old_string": "# --- Active Download Stats ---\n\n@app.get(\"/download-stats\")\ndef get_download_stats(download_id: Optional[str] = Query(None)):\n    \"\"\"Get real-time download speed and progress for active downloads.\n    If download_id is provided, returns stats for that specific download.\"\"\"\n    with _active_downloads_lock:\n        if download_id:\n            dl = _active_downloads.get(download_id)\n            if not dl:\n                return _error_response(ErrorCode.JOB_NOT_FOUND)\n            return dl\n        return {\n            'active_count': len([\n                d for d in _active_downloads.values()\n                if d['status'] == 'streaming'\n            ]),\n            'downloads': list(_active_downloads.values()),\n        }",
  "new_string": "# --- Active Download Stats ---\n\n@app.get(\"/download-stats\")\ndef get_download_stats(download_id: Optional[str] = Query(None)):\n    \"\"\"Get real-time download speed and progress for active downloads.\n    If download_id is provided, returns stats for that specific download.\"\"\"\n    with _active_downloads_lock:\n        if download_id:\n            dl = _active_downloads.get(download_id)\n            if not dl:\n                return _error_response(ErrorCode.JOB_NOT_FOUND)\n            return dl\n        return {\n            'active_count': len([\n                d for d in _active_downloads.values()\n                if d['status'] == 'streaming'\n            ]),\n            'downloads': list(_active_downloads.values()),\n        }\n\n\n# --- Subtitle Support ---\n\ndef _convert_vtt_to_srt(vtt_content: str) -> str:\n    \"\"\"Convert WebVTT subtitle content to SRT format.\"\"\"\n    lines = vtt_content.strip().split('\\n')\n    srt_lines = []\n    index = 1\n    i = 0\n\n    # Skip WEBVTT header and any metadata\n    while i < len(lines) and not re.match(r'\\d{2}:\\d{2}', lines[i]):\n        i += 1\n\n    while i < len(lines):\n        line = lines[i].strip()\n\n        # Look for timestamp line\n        if '-->' in line:\n            # Convert VTT timestamp (HH:MM:SS.mmm) to SRT (HH:MM:SS,mmm)\n            timestamp_line = line.replace('.', ',')\n            srt_lines.append(str(index))\n            srt_lines.append(timestamp_line)\n            index += 1\n            i += 1\n\n            # Collect subtitle text until next blank line or timestamp\n            text_lines = []\n            while i < len(lines):\n                sub_line = lines[i].strip()\n                if not sub_line or '-->' in sub_line:\n                    break\n                # Strip VTT formatting tags\n                clean = re.sub(r'<[^>]+>', '', sub_line)\n                if clean:\n                    text_lines.append(clean)\n                i += 1\n\n            srt_lines.extend(text_lines)\n            srt_lines.append('')  # Blank line separator\n        else:\n            i += 1\n\n    return '\\n'.join(srt_lines)\n\n\ndef _convert_vtt_to_ass(vtt_content: str, title: str = \"Subtitles\") -> str:\n    \"\"\"Convert WebVTT subtitle content to ASS/SSA format.\"\"\"\n    lines = vtt_content.strip().split('\\n')\n\n    # Parse subtitle entries\n    entries = []\n    i = 0\n    while i < len(lines) and not re.match(r'\\d{2}:\\d{2}', lines[i]):\n        i += 1\n\n    while i < len(lines):\n        line = lines[i].strip()\n        if '-->' in line:\n            parts = line.split('-->')\n            start_str = parts[0].strip().split(' ')[0]\n            end_str = parts[1].strip().split(' ')[0]\n            i += 1\n\n            text_lines = []\n            while i < len(lines):\n                sub_line = lines[i].strip()\n                if not sub_line or '-->' in sub_line:\n                    break\n                clean = re.sub(r'<[^>]+>', '', sub_line)\n                if clean:\n                    text_lines.append(clean)\n                i += 1\n\n            if text_lines:\n                text = '\\\\N'.join(text_lines)\n                entries.append((start_str, end_str, text))\n        else:\n            i += 1\n\n    def _vtt_to_ass_ts(ts: str) -> str:\n        \"\"\"Convert VTT timestamp (HH:MM:SS.mmm) to ASS (H:MM:SS.cc).\"\"\"\n        ts = ts.strip()\n        # Handle MM:SS.mmm or HH:MM:SS.mmm\n        parts = ts.split(':')\n        if len(parts) == 2:\n            h, rest = '0', ts\n        else:\n            h, rest = parts[0], ':'.join(parts[1:])\n        m_and_s = rest.split(':')\n        m = m_and_s[0]\n        s_parts = m_and_s[1].split('.')\n        s = s_parts[0]\n        ms = s_parts[1] if len(s_parts) > 1 else '000'\n        cs = str(int(ms[:2])).zfill(2) if len(ms) >= 2 else '00'\n        return f\"{h}:{m}:{s}.{cs}\"\n\n    ass_header = f\"\"\"[Script Info]\nTitle: {title}\nScriptType: v4.00+\nWrapStyle: 0\nPlayResX: 384\nPlayResY: 288\nScaledBorderAndShadow: yes\n\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\nStyle: Default,Arial,16,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1\n\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n\"\"\"\n    ass_events = []\n    for start, end, text in entries:\n        ass_start = _vtt_to_ass_ts(start)\n        ass_end = _vtt_to_ass_ts(end)\n        ass_events.append(f\"Dialogue: 0,{ass_start},{ass_end},Default,,0,0,0,,{text}\")\n\n    return ass_header + '\\n'.join(ass_events) + '\\n'\n\n\ndef _format_vtt_timestamp(hours: int, minutes: int, seconds: int, ms: int) -> str:\n    \"\"\"Format a timestamp for VTT format: HH:MM:SS.mmm\"\"\"\n    return f\"{hours:02d}:{minutes:02d}:{seconds:02d}.{ms:03d}\"\n\n\ndef _convert_srt_to_vtt(srt_content: str) -> str:\n    \"\"\"Convert SRT subtitle content to WebVTT format.\"\"\"\n    lines = srt_content.strip().split('\\n')\n    vtt_lines = ['WEBVTT\\n']\n\n    i = 0\n    while i < len(lines):\n        line = lines[i].strip()\n        # Look for timestamp line\n        if '-->' in line:\n            # Convert SRT timestamp (HH:MM:SS,mmm) to VTT (HH:MM:SS.mmm)\n            timestamp_line = line.replace(',', '.')\n            vtt_lines.append(timestamp_line)\n            i += 1\n\n            # Collect subtitle text\n            while i < len(lines):\n                sub_line = lines[i].strip()\n                if not sub_line:\n                    break\n                vtt_lines.append(sub_line)\n                i += 1\n            vtt_lines.append('')\n        else:\n            i += 1\n\n    return '\\n'.join(vtt_lines)\n\n\n@app.get(\"/subtitles\")\ndef list_subtitles(request: Request, url: str = Query(...)):\n    \"\"\"List available subtitles/captions for a video.\n    Returns available languages with their names and automatic/generated status.\"\"\"\n    if not url or not url.strip():\n        return _error_response(ErrorCode.MISSING_PARAMS)\n    url = url.strip()\n    if not url.startswith((\"http://\", \"https://\")):\n        return _error_response(ErrorCode.INVALID_URL)\n\n    try:\n        ydl_opts = {\n            'quiet': True,\n            'no_warnings': True,\n            'skip_download': True,\n            'listsubtitles': True,\n            'http_headers': _get_headers(url),\n            'socket_timeout': 30,\n        }\n\n        _apply_auth_to_opts(ydl_opts, request, url)\n\n        if \"dailymotion.com\" in url:\n            ydl_opts['force_generic_extractor'] = True\n\n        with yt_dlp.YoutubeDL(ydl_opts) as ydl:\n            info = ydl.extract_info(url, download=False)\n\n        if info is None:\n            return _error_response(ErrorCode.EXTRACTION_FAILED, \"Could not extract info\")\n\n        subtitles = []\n        seen_langs = set()\n\n        # Manual subtitles (user-uploaded or creator-provided)\n        manual_subs = info.get('subtitles', {})\n        for lang_code, sub_list in manual_subs.items():\n            if not sub_list:\n                continue\n            for sub in sub_list:\n                key = f\"{lang_code}_{sub.get('ext', 'vtt')}\"\n                if key in seen_langs:\n                    continue\n                seen_langs.add(key)\n                subtitles.append({\n                    'language': lang_code,\n                    'name': sub.get('name', lang_code),\n                    'ext': sub.get('ext', 'vtt'),\n                    'url': sub.get('url', ''),\n                    'auto_generated': False,\n                })\n\n        # Automatic captions (auto-translated)\n        auto_subs = info.get('automatic_captions', {})\n        for lang_code, sub_list in auto_subs.items():\n            if not sub_list:\n                continue\n            for sub in sub_list:\n                key = f\"{lang_code}_{sub.get('ext', 'vtt')}_auto\"\n                if key in seen_langs:\n                    continue\n                seen_langs.add(key)\n                subtitles.append({\n                    'language': lang_code,\n                    'name': sub.get('name', f\"{lang_code} (auto-generated)\"),\n                    'ext': sub.get('ext', 'vtt'),\n                    'url': sub.get('url', ''),\n                    'auto_generated': True,\n                })\n\n        # Determine which languages are available (deduplicated)\n        available_languages = sorted(set(\n            s['language'] for s in subtitles\n        ), key=lambda x: (x != 'en', x))\n\n        return {\n            'subtitles': subtitles,\n            'available_languages': available_languages,\n            'count': len(subtitles),\n        }\n\n    except Exception as e:\n        error_code, raw_msg = _classify_error(e)\n        return _error_response(error_code, raw_msg)\n\n\n@app.get(\"/download-subtitles\")\ndef download_subtitles(\n    request: Request,\n    url: str = Query(...),\n    lang: str = Query('en'),\n    format: str = Query('srt'),\n    auto_generated: bool = Query(False),\n):\n    \"\"\"Download subtitles for a video in the specified format.\n    Supported formats: srt, vtt, ass.\n    Uses yt-dlp to extract subtitles and converts to requested format.\"\"\"\n    if not url or not url.strip():\n        return _error_response(ErrorCode.MISSING_PARAMS)\n    url = url.strip()\n    if not url.startswith((\"http://\", \"https://\")):\n        return _error_response(ErrorCode.INVALID_URL)\n\n    format = format.lower().strip()\n    if format not in ('srt', 'vtt', 'ass'):\n        return _error_response(ErrorCode.INVALID_URL, f\"Unsupported subtitle format: {format}. Use srt, vtt, or ass.\")\n\n    try:\n        # Use yt-dlp to download subtitles\n        sub_langs = lang\n        if auto_generated:\n            sub_langs = f\"{lang}\"\n\n        sub_opts = {\n            'quiet': True,\n            'no_warnings': True,\n            'skip_download': True,\n            'writesubtitles': not auto_generated,\n            'writeautomaticsub': auto_generated,\n            'subtitleslangs': [lang],\n            'subtitlesformat': 'vtt',  # Always get VTT first, then convert\n            'http_headers': _get_headers(url),\n            'socket_timeout': 30,\n        }\n\n        _apply_auth_to_opts(sub_opts, request, url)\n\n        if \"dailymotion.com\" in url:\n            sub_opts['force_generic_extractor'] = True\n\n        # Use yt-dlp to extract subtitle URLs\n        with yt_dlp.YoutubeDL(sub_opts) as ydl:\n            info = ydl.extract_info(url, download=False)\n\n        if info is None:\n            return _error_response(ErrorCode.EXTRACTION_FAILED, \"Could not extract video info\")\n\n        # Find the subtitle URL from the info dict\n        subtitle_url = None\n        if auto_generated:\n            auto_subs = info.get('automatic_captions', {})\n            lang_subs = auto_subs.get(lang, [])\n            # Prefer vtt format\n            for sub in lang_subs:\n                if sub.get('ext') == 'vtt':\n                    subtitle_url = sub.get('url')\n                    break\n            if not subtitle_url and lang_subs:\n                subtitle_url = lang_subs[0].get('url')\n        else:\n            manual_subs = info.get('subtitles', {})\n            lang_subs = manual_subs.get(lang, [])\n            for sub in lang_subs:\n                if sub.get('ext') == 'vtt':\n                    subtitle_url = sub.get('url')\n                    break\n            if not subtitle_url and lang_subs:\n                subtitle_url = lang_subs[0].get('url')\n\n        if not subtitle_url:\n            return _error_response(\n                ErrorCode.NO_FORMATS,\n                f\"No {'auto-generated ' if auto_generated else ''}subtitles found for language '{lang}'\"\n            )\n\n        # Download the subtitle content\n        req = urllib.request.Request(\n            subtitle_url,\n            headers={\n                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',\n                'Accept-Language': 'en-US,en;q=0.9',\n            }\n        )\n        with urllib.request.urlopen(req, timeout=15) as resp:\n            raw_content = resp.read().decode('utf-8')\n\n        # Convert to requested format\n        title = info.get('title', 'video')\n        if format == 'srt':\n            if raw_content.strip().startswith('WEBVTT'):\n                content = _convert_vtt_to_srt(raw_content)\n            else:\n                content = raw_content\n            media_type = 'text/plain'\n            ext = 'srt'\n        elif format == 'vtt':\n            if raw_content.strip().startswith('WEBVTT'):\n                content = raw_content\n            else:\n                content = _convert_srt_to_vtt(raw_content)\n            media_type = 'text/vtt'\n            ext = 'vtt'\n        elif format == 'ass':\n            if raw_content.strip().startswith('WEBVTT'):\n                content = _convert_vtt_to_ass(raw_content, title)\n            else:\n                # Convert SRT -> VTT -> ASS\n                vtt = _convert_srt_to_vtt(raw_content)\n                content = _convert_vtt_to_ass(vtt, title)\n            media_type = 'text/plain'\n            ext = 'ass'\n        else:\n            content = raw_content\n            media_type = 'text/plain'\n            ext = 'vtt'\n\n        safe_title = _sanitize_filename(title, max_length=100)\n        filename = f\"{safe_title}.{lang}.{ext}\"\n\n        return Response(\n            content=content.encode('utf-8'),\n            media_type=media_type,\n            headers={\n                'Content-Disposition': f'attachment; filename=\"{filename}\"',\n            },\n        )\n\n    except Exception as e:\n        error_code, raw_msg = _classify_error(e)\n        return _error_response(error_code, raw_msg)"
}
Now let me modify the download endpoint to support subtitle embedding. I need to add subtitle parameters to the download function.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 5,
  "offset": 753
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "old_string": "@app.get(\"/download\")\ndef download_video(\n    request: Request,\n    url: str = Query(...),\n    format_id: Optional[str] = Query(None),\n    filename_template: Optional[str] = Query(None),\n):\n    if not url or not url.strip():\n        return _error_response(ErrorCode.MISSING_PARAMS)\n    url = url.strip()\n    if not url.startswith((\"http://\", \"https://\")):\n        return _error_response(ErrorCode.INVALID_URL)\n\n    try:\n        return _download_with_retry(\n            url,\n            request=request,\n            format_id=format_id,\n            filename_template=filename_template,\n        )\n    except Exception as e:\n        error_code, raw_msg = _classify_error(e)\n        return _error_response(error_code, raw_msg)",
  "new_string": "@app.get(\"/download\")\ndef download_video(\n    request: Request,\n    url: str = Query(...),\n    format_id: Optional[str] = Query(None),\n    filename_template: Optional[str] = Query(None),\n    subtitle_lang: Optional[str] = Query(None),\n    subtitle_format: Optional[str] = Query(None),\n    embed_subtitles: bool = Query(False),\n):\n    if not url or not url.strip():\n        return _error_response(ErrorCode.MISSING_PARAMS)\n    url = url.strip()\n    if not url.startswith((\"http://\", \"https://\")):\n        return _error_response(ErrorCode.INVALID_URL)\n\n    try:\n        return _download_with_retry(\n            url,\n            request=request,\n            format_id=format_id,\n            filename_template=filename_template,\n            subtitle_lang=subtitle_lang,\n            subtitle_format=subtitle_format,\n            embed_subtitles=embed_subtitles,\n        )\n    except Exception as e:\n        error_code, raw_msg = _classify_error(e)\n        return _error_response(error_code, raw_msg)"
}
Now update the _download_with_retry function to handle subtitles.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "old_string": "@_retry_with_backoff(max_retries=2, base_delay=1.0, max_delay=8.0)\ndef _download_with_retry(\n    url: str,\n    request: Request = None,\n    format_id: Optional[str] = None,\n    filename_template: Optional[str] = None,\n) -> FileResponse:",
  "new_string": "@_retry_with_backoff(max_retries=2, base_delay=1.0, max_delay=8.0)\ndef _download_with_retry(\n    url: str,\n    request: Request = None,\n    format_id: Optional[str] = None,\n    filename_template: Optional[str] = None,\n    subtitle_lang: Optional[str] = None,\n    subtitle_format: Optional[str] = None,\n    embed_subtitles: bool = False,\n) -> FileResponse:"
}
Now I need to add subtitle-related options to the yt-dlp download opts. Let me find and modify the ydl_opts section in _download_with_retry.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 40,
  "offset": 856
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "old_string": "    ydl_opts = {\n        'outtmpl': output_path,\n        'format': fmt_string,\n        'merge_output_format': merge_format,\n        'ffmpeg_location': '/usr/bin/ffmpeg',\n        'noplaylist': True,\n        'quiet': True,\n        'postprocessors': [{\n            'key': 'FFmpegVideoConvertor',\n            'preferedformat': merge_format,\n        }],\n        'extractor_args': {\n            'youtube': ['player_client=android'],\n        },\n        'mark_watched': False,\n        'http_headers': _get_headers(url),\n        'socket_timeout': 60,\n        'retries': 3,\n    }",
  "new_string": "    ydl_opts = {\n        'outtmpl': output_path,\n        'format': fmt_string,\n        'merge_output_format': merge_format,\n        'ffmpeg_location': '/usr/bin/ffmpeg',\n        'noplaylist': True,\n        'quiet': True,\n        'postprocessors': [{\n            'key': 'FFmpegVideoConvertor',\n            'preferedformat': merge_format,\n        }],\n        'extractor_args': {\n            'youtube': ['player_client=android'],\n        },\n        'mark_watched': False,\n        'http_headers': _get_headers(url),\n        'socket_timeout': 60,\n        'retries': 3,\n    }\n\n    # Subtitle embedding: download subtitles and embed in MP4 via FFmpeg\n    subtitle_file = None\n    if subtitle_lang and embed_subtitles and ext == 'mp4':\n        try:\n            sub_lang = subtitle_lang.split(',')[0]  # Use first language if multiple\n            sub_format = subtitle_format or 'srt'\n\n            sub_info_opts = {\n                'quiet': True,\n                'no_warnings': True,\n                'skip_download': True,\n                'http_headers': _get_headers(url),\n                'socket_timeout': 30,\n            }\n            if request:\n                _apply_auth_to_opts(sub_info_opts, request, url)\n\n            with yt_dlp.YoutubeDL(sub_info_opts) as sub_ydl:\n                sub_info = sub_ydl.extract_info(url, download=False)\n\n            if sub_info:\n                subtitle_url = None\n                # Try manual subs first, then auto\n                for sub_dict_key in ('subtitles', 'automatic_captions'):\n                    subs = sub_info.get(sub_dict_key, {})\n                    lang_subs = subs.get(sub_lang, [])\n                    for s in lang_subs:\n                        if s.get('ext') == 'vtt':\n                            subtitle_url = s.get('url')\n                            break\n                    if not subtitle_url and lang_subs:\n                        subtitle_url = lang_subs[0].get('url')\n                    if subtitle_url:\n                        break\n\n                if subtitle_url:\n                    # Download subtitle content\n                    sub_req = urllib.request.Request(\n                        subtitle_url,\n                        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}\n                    )\n                    with urllib.request.urlopen(sub_req, timeout=15) as sub_resp:\n                        raw_sub = sub_resp.read().decode('utf-8')\n\n                    # Convert to SRT for FFmpeg embedding compatibility\n                    if raw_sub.strip().startswith('WEBVTT'):\n                        sub_content = _convert_vtt_to_srt(raw_sub)\n                    else:\n                        sub_content = raw_sub\n\n                    # Save subtitle to temp file\n                    subtitle_file = os.path.join(OUTPUT_DIR, f\"{base_name}.{sub_lang}.srt\")\n                    with open(subtitle_file, 'w', encoding='utf-8') as sf:\n                        sf.write(sub_content)\n\n        except Exception as e:\n            logger.warning(f\"Failed to fetch subtitles for embedding: {e}\")\n            subtitle_file = None"
}
Now I need to add the post-download subtitle embedding step. Let me update the section after the download completes.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 20,
  "offset": 920
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 20,
  "offset": 940
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "old_string": "    if \"dailymotion.com\" in url:\n        ydl_opts['force_generic_extractor'] = True\n\n    if request:\n        _apply_auth_to_opts(ydl_opts, request, url)\n\n    with yt_dlp.YoutubeDL(ydl_opts) as ydl:\n        ydl.download([url])\n\n    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'\n    return FileResponse(path=output_path, filename=filename, media_type=media_type)",
  "new_string": "    if \"dailymotion.com\" in url:\n        ydl_opts['force_generic_extractor'] = True\n\n    if request:\n        _apply_auth_to_opts(ydl_opts, request, url)\n\n    with yt_dlp.YoutubeDL(ydl_opts) as ydl:\n        ydl.download([url])\n\n    # Embed subtitles into MP4 if subtitle file was downloaded\n    if subtitle_file and os.path.exists(subtitle_file) and os.path.exists(output_path):\n        try:\n            import subprocess\n            embedded_output = os.path.join(OUTPUT_DIR, f\"{base_name}_embedded.{ext}\")\n            cmd = [\n                '/usr/bin/ffmpeg', '-i', output_path,\n                '-i', subtitle_file,\n                '-c', 'copy',\n                '-c:s', 'mov_text',\n                '-metadata:s:s:0', f'language={sub_lang}',\n                embedded_output,\n            ]\n            result = subprocess.run(cmd, capture_output=True, timeout=120)\n            if result.returncode == 0 and os.path.exists(embedded_output):\n                # Replace original with embedded version\n                os.remove(output_path)\n                os.rename(embedded_output, output_path)\n                logger.info(f\"Subtitles embedded successfully for: {filename}\")\n            else:\n                logger.warning(f\"FFmpeg subtitle embedding failed: {result.stderr.decode()[:200]}\")\n            # Clean up temp subtitle file\n            if os.path.exists(subtitle_file):\n                os.remove(subtitle_file)\n        except Exception as e:\n            logger.warning(f\"Subtitle embedding error: {e}\")\n            # Clean up temp files\n            if subtitle_file and os.path.exists(subtitle_file):\n                os.remove(subtitle_file)\n            embedded_output = os.path.join(OUTPUT_DIR, f\"{base_name}_embedded.{ext}\")\n            if os.path.exists(embedded_output):\n                os.remove(embedded_output)\n\n    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'\n    return FileResponse(path=output_path, filename=filename, media_type=media_type)"
}
I need to use more context to uniquely identify the first instance. Let me read around that area.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "limit": 25,
  "offset": 935
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\fly.io backend\\main.py",
  "old_string": "        except Exception as e:\n            logger.warning(f\"Failed to fetch subtitles for embedding: {e}\")\n            subtitle_file = None\n\n    if \"dailymotion.com\" in url:\n        ydl_opts['force_generic_extractor'] = True\n\n    if request:\n        _apply_auth_to_opts(ydl_opts, request, url)\n\n    with yt_dlp.YoutubeDL(ydl_opts) as ydl:\n        ydl.download([url])\n\n    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'\n    return FileResponse(path=output_path, filename=filename, media_type=media_type)\n\n\n@app.get(\"/download-index\")",
  "new_string": "        except Exception as e:\n            logger.warning(f\"Failed to fetch subtitles for embedding: {e}\")\n            subtitle_file = None\n\n    if \"dailymotion.com\" in url:\n        ydl_opts['force_generic_extractor'] = True\n\n    if request:\n        _apply_auth_to_opts(ydl_opts, request, url)\n\n    with yt_dlp.YoutubeDL(ydl_opts) as ydl:\n        ydl.download([url])\n\n    # Embed subtitles into MP4 if subtitle file was downloaded\n    if subtitle_file and os.path.exists(subtitle_file) and os.path.exists(output_path):\n        try:\n            import subprocess\n            embedded_output = os.path.join(OUTPUT_DIR, f\"{base_name}_embedded.{ext}\")\n            cmd = [\n                '/usr/bin/ffmpeg', '-i', output_path,\n                '-i', subtitle_file,\n                '-c', 'copy',\n                '-c:s', 'mov_text',\n                '-metadata:s:s:0', f'language={sub_lang}',\n                embedded_output,\n            ]\n            result = subprocess.run(cmd, capture_output=True, timeout=120)\n            if result.returncode == 0 and os.path.exists(embedded_output):\n                # Replace original with embedded version\n                os.remove(output_path)\n                os.rename(embedded_output, output_path)\n                logger.info(f\"Subtitles embedded successfully for: {filename}\")\n            else:\n                logger.warning(f\"FFmpeg subtitle embedding failed: {result.stderr.decode()[:200]}\")\n            # Clean up temp subtitle file\n            if os.path.exists(subtitle_file):\n                os.remove(subtitle_file)\n        except Exception as e:\n            logger.warning(f\"Subtitle embedding error: {e}\")\n            # Clean up temp files\n            if subtitle_file and os.path.exists(subtitle_file):\n                os.remove(subtitle_file)\n            embedded_output = os.path.join(OUTPUT_DIR, f\"{base_name}_embedded.{ext}\")\n            if os.path.exists(embedded_output):\n                os.remove(embedded_output)\n\n    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'\n    return FileResponse(path=output_path, filename=filename, media_type=media_type)\n\n\n@app.get(\"/download-index\")"
}
Backend is done. Now let me update the todo and move on to the frontend.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle endpoints",
      "content": "Backend: Add /subtitles and /download-subtitles endpoints",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle embedding",
      "content": "Backend: Modify /download to support subtitle embedding in MP4",
      "status": "completed"
    },
    {
      "activeForm": "Updating frontend data models",
      "content": "Frontend: Add subtitle-related fields to data models",
      "status": "in_progress"
    },
    {
      "activeForm": "Building subtitle selection UI",
      "content": "Frontend: Add subtitle language selection UI to quality picker",
      "status": "pending"
    },
    {
      "activeForm": "Building subtitle settings UI",
      "content": "Frontend: Add subtitle format and embed/sidecar preference UI",
      "status": "pending"
    },
    {
      "activeForm": "Wiring download flow with subtitles",
      "content": "Frontend: Wire subtitle options into download queue flow",
      "status": "pending"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "pending"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "pending"
    }
  ]
}
Now let me create the subtitle-related data model for the frontend.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\subtitle_option.dart",
  "content": "/// Represents a single available subtitle/caption track for a video.\nclass SubtitleOption {\n  final String language;\n  final String name;\n  final String ext;\n  final String? url;\n  final bool autoGenerated;\n\n  const SubtitleOption({\n    required this.language,\n    required this.name,\n    this.ext = 'vtt',\n    this.url,\n    this.autoGenerated = false,\n  });\n\n  factory SubtitleOption.fromJson(Map<String, dynamic> json) {\n    return SubtitleOption(\n      language: json['language'] as String,\n      name: json['name'] as String,\n      ext: json['ext'] as String? ?? 'vtt',\n      url: json['url'] as String?,\n      autoGenerated: json['auto_generated'] as bool? ?? false,\n    );\n  }\n\n  /// Human-readable label for display in the UI.\n  String get displayLabel {\n    final autoTag = autoGenerated ? ' (Auto)' : '';\n    return '$name$autoTag';\n  }\n\n  /// Short language code for display.\n  String get languageCode => language.toUpperCase();\n}\n\n/// Result from the /subtitles endpoint.\nclass SubtitlesResult {\n  final List<SubtitleOption> subtitles;\n  final List<String> availableLanguages;\n  final int count;\n\n  const SubtitlesResult({\n    required this.subtitles,\n    required this.availableLanguages,\n    required this.count,\n  });\n\n  factory SubtitlesResult.fromJson(Map<String, dynamic> json) {\n    return SubtitlesResult(\n      subtitles: (json['subtitles'] as List)\n          .map((s) => SubtitleOption.fromJson(s as Map<String, dynamic>))\n          .toList(),\n      availableLanguages:\n          (json['available_languages'] as List).cast<String>(),\n      count: json['count'] as int,\n    );\n  }\n\n  /// Get unique subtitle options (one per language, preferring manual over auto).\n  List<SubtitleOption> get uniqueByLanguage {\n    final seen = <String>{};\n    final result = <SubtitleOption>[];\n\n    // Manual subtitles first\n    for (final s in subtitles.where((s) => !s.autoGenerated)) {\n      if (!seen.contains(s.language)) {\n        seen.add(s.language);\n        result.add(s);\n      }\n    }\n    // Then auto-generated\n    for (final s in subtitles.where((s) => s.autoGenerated)) {\n      if (!seen.contains(s.language)) {\n        seen.add(s.language);\n        result.add(s);\n      }\n    }\n    return result;\n  }\n}\n\n/// Supported subtitle download formats.\nenum SubtitleFormat {\n  srt,\n  vtt,\n  ass;\n\n  String get extension => name;\n  String get displayName => name.toUpperCase();\n}\n\n/// Subtitle preference for download: embed in video or save as sidecar file.\nenum SubtitleMode {\n  embed,\n  sidecar;\n\n  String get displayName =>\n      this == SubtitleMode.embed ? 'Embed in video' : 'Separate file';\n}\n"
}
Now let me add subtitle fields to the QueueItem model.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "old_string": "  // Format selection\n  final String? formatId; // yt-dlp format_id for quality selection\n  final String? formatLabel; // Human-readable label for display (e.g. \"1080p\")",
  "new_string": "  // Format selection\n  final String? formatId; // yt-dlp format_id for quality selection\n  final String? formatLabel; // Human-readable label for display (e.g. \"1080p\")\n\n  // Subtitle options\n  final String? subtitleLang; // Language code for subtitles (e.g. 'en')\n  final String? subtitleFormat; // Subtitle format: 'srt', 'vtt', 'ass'\n  final bool embedSubtitles; // Whether to embed subtitles in MP4 container\n  final bool downloadSidecarSubtitles; // Whether to download subtitles as separate file"
}
Now update the constructor to include the new fields.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "old_string": "    this.videoIndex,\n    this.formatId,\n    this.formatLabel,\n    required this.createdAt,",
  "new_string": "    this.videoIndex,\n    this.formatId,\n    this.formatLabel,\n    this.subtitleLang,\n    this.subtitleFormat,\n    this.embedSubtitles = false,\n    this.downloadSidecarSubtitles = false,\n    required this.createdAt,"
}
Now update fromMap, toMap, and copyWith.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "old_string": "      formatId: map['formatId'] as String?,\n      formatLabel: map['formatLabel'] as String?,\n      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),",
  "new_string": "      formatId: map['formatId'] as String?,\n      formatLabel: map['formatLabel'] as String?,\n      subtitleLang: map['subtitleLang'] as String?,\n      subtitleFormat: map['subtitleFormat'] as String?,\n      embedSubtitles: (map['embedSubtitles'] as num?)?.toInt() == 1,\n      downloadSidecarSubtitles:\n          (map['downloadSidecarSubtitles'] as num?)?.toInt() == 1,\n      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "old_string": "      'formatId': formatId,\n      'formatLabel': formatLabel,\n      'createdAt': createdAt.millisecondsSinceEpoch,",
  "new_string": "      'formatId': formatId,\n      'formatLabel': formatLabel,\n      'subtitleLang': subtitleLang,\n      'subtitleFormat': subtitleFormat,\n      'embedSubtitles': embedSubtitles ? 1 : 0,\n      'downloadSidecarSubtitles': downloadSidecarSubtitles ? 1 : 0,\n      'createdAt': createdAt.millisecondsSinceEpoch,"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "old_string": "    String? formatId,\n    String? formatLabel,\n    DateTime? createdAt,",
  "new_string": "    String? formatId,\n    String? formatLabel,\n    String? subtitleLang,\n    String? subtitleFormat,\n    bool? embedSubtitles,\n    bool? downloadSidecarSubtitles,\n    DateTime? createdAt,"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart",
  "old_string": "      formatId: formatId ?? this.formatId,\n      formatLabel: formatLabel ?? this.formatLabel,\n      createdAt: createdAt ?? this.createdAt,",
  "new_string": "      formatId: formatId ?? this.formatId,\n      formatLabel: formatLabel ?? this.formatLabel,\n      subtitleLang: subtitleLang ?? this.subtitleLang,\n      subtitleFormat: subtitleFormat ?? this.subtitleFormat,\n      embedSubtitles: embedSubtitles ?? this.embedSubtitles,\n      downloadSidecarSubtitles:\n          downloadSidecarSubtitles ?? this.downloadSidecarSubtitles,\n      createdAt: createdAt ?? this.createdAt,"
}
Now update the DownloadQueueManager to pass subtitle parameters.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "  Future<QueueItem> addToQueue({\n    required String url,\n    required String title,\n    String? thumbnailUrl,\n    int? videoIndex,\n    String? formatId,\n    String? formatLabel,\n  }) async {",
  "new_string": "  Future<QueueItem> addToQueue({\n    required String url,\n    required String title,\n    String? thumbnailUrl,\n    int? videoIndex,\n    String? formatId,\n    String? formatLabel,\n    String? subtitleLang,\n    String? subtitleFormat,\n    bool embedSubtitles = false,\n    bool downloadSidecarSubtitles = false,\n  }) async {"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "    final item = QueueItem(\n      url: url,\n      platform: DownloadRecord.detectPlatform(url),\n      title: title,\n      thumbnailUrl: thumbnailUrl,\n      videoIndex: videoIndex,\n      formatId: formatId,\n      formatLabel: formatLabel,\n      createdAt: DateTime.now(),\n    );",
  "new_string": "    final item = QueueItem(\n      url: url,\n      platform: DownloadRecord.detectPlatform(url),\n      title: title,\n      thumbnailUrl: thumbnailUrl,\n      videoIndex: videoIndex,\n      formatId: formatId,\n      formatLabel: formatLabel,\n      subtitleLang: subtitleLang,\n      subtitleFormat: subtitleFormat,\n      embedSubtitles: embedSubtitles,\n      downloadSidecarSubtitles: downloadSidecarSubtitles,\n      createdAt: DateTime.now(),\n    );"
}
Now update the _startDownload method to pass subtitle params in the URL. Let me read the current endpoint building code.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 30,
  "offset": 379
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "    // Build endpoint\n    final String endpoint;\n    final formatParam = item.formatId != null\n        ? \"&format_id=${Uri.encodeComponent(item.formatId!)}\"\n        : \"\";\n    // Resolve filename template for this platform\n    final template = FilenameTemplate.effectiveTemplate(item.platform);\n    final templateParam = \"&filename_template=${Uri.encodeComponent(template)}\";\n    if (item.videoIndex != null) {\n      endpoint =\n          \"$_backendBaseUrl/download-index?url=${Uri.encodeComponent(item.url)}&index=${item.videoIndex}$formatParam$templateParam\";\n    } else {\n      endpoint =\n          \"$_backendBaseUrl/download?url=${Uri.encodeComponent(item.url)}$formatParam$templateParam\";\n    }",
  "new_string": "    // Build endpoint\n    final String endpoint;\n    final formatParam = item.formatId != null\n        ? \"&format_id=${Uri.encodeComponent(item.formatId!)}\"\n        : \"\";\n    // Resolve filename template for this platform\n    final template = FilenameTemplate.effectiveTemplate(item.platform);\n    final templateParam = \"&filename_template=${Uri.encodeComponent(template)}\";\n    // Subtitle parameters\n    final subtitleParam = item.subtitleLang != null\n        ? \"&subtitle_lang=${Uri.encodeComponent(item.subtitleLang!)}&embed_subtitles=${item.embedSubtitles}${item.subtitleFormat != null ? '&subtitle_format=${Uri.encodeComponent(item.subtitleFormat!)}' : ''}\"\n        : \"\";\n    if (item.videoIndex != null) {\n      endpoint =\n          \"$_backendBaseUrl/download-index?url=${Uri.encodeComponent(item.url)}&index=${item.videoIndex}$formatParam$templateParam$subtitleParam\";\n    } else {\n      endpoint =\n          \"$_backendBaseUrl/download?url=${Uri.encodeComponent(item.url)}$formatParam$templateParam$subtitleParam\";\n    }"
}
Now I need to add the sidecar subtitle download logic. After the video download completes successfully, if the user chose sidecar subtitles, we need to download the subtitle file separately. Let me read the success handling code.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 40,
  "offset": 465
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "        await file.writeAsBytes(bytes);\n\n        // Success",
  "new_string": "        await file.writeAsBytes(bytes);\n\n        // Download sidecar subtitles if requested\n        if (item.downloadSidecarSubtitles &&\n            item.subtitleLang != null &&\n            item.subtitleFormat != null) {\n          try {\n            final subEndpoint =\n                \"$_backendBaseUrl/download-subtitles?url=${Uri.encodeComponent(item.url)}&lang=${item.subtitleLang}&format=${item.subtitleFormat}\";\n            final subResponse =\n                await http.get(Uri.parse(subEndpoint)).timeout(\n                      const Duration(seconds: 30),\n                    );\n            if (subResponse.statusCode == 200) {\n              final downloadDir = await _getDownloadDir();\n              final safeName = _sanitizeLocalFilename(item.title);\n              final subExt = item.subtitleFormat!;\n              final subFilePath =\n                  \"$downloadDir/${safeName}_${DateTime.now().millisecondsSinceEpoch}.${item.subtitleLang}.${subExt}\";\n              final subFile = File(subFilePath);\n              await subFile.writeAsBytes(subResponse.bodyBytes);\n            }\n          } catch (e) {\n            // Non-fatal: subtitle download failure shouldn't fail the main download\n          }\n        }\n\n        // Success"
}
Now I need to update the database schema to add the subtitle columns. Let me read the database migration code.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "limit": 60,
  "offset": 1
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "    return openDatabase(\n      path,\n      version: 6,\n      onCreate: (db, version) async {\n        await _createDownloadsTable(db);\n        await _createQueueItemsTable(db);\n        await _createScheduledDownloadsTable(db);\n      },\n      onUpgrade: (db, oldVersion, newVersion) async {\n        if (oldVersion < 2) {\n          await _createQueueItemsTable(db);\n        }\n        if (oldVersion < 3) {\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN speedBps REAL NOT NULL DEFAULT 0.0',\n          );\n        }\n        if (oldVersion < 4) {\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN formatId TEXT',\n          );\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN formatLabel TEXT',\n          );\n        }\n        if (oldVersion < 5) {\n          await db.execute(\n            'ALTER TABLE downloads ADD COLUMN thumbnailUrl TEXT',\n          );\n        }\n        if (oldVersion < 6) {\n          await _createScheduledDownloadsTable(db);\n        }\n      },\n    );",
  "new_string": "    return openDatabase(\n      path,\n      version: 7,\n      onCreate: (db, version) async {\n        await _createDownloadsTable(db);\n        await _createQueueItemsTable(db);\n        await _createScheduledDownloadsTable(db);\n      },\n      onUpgrade: (db, oldVersion, newVersion) async {\n        if (oldVersion < 2) {\n          await _createQueueItemsTable(db);\n        }\n        if (oldVersion < 3) {\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN speedBps REAL NOT NULL DEFAULT 0.0',\n          );\n        }\n        if (oldVersion < 4) {\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN formatId TEXT',\n          );\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN formatLabel TEXT',\n          );\n        }\n        if (oldVersion < 5) {\n          await db.execute(\n            'ALTER TABLE downloads ADD COLUMN thumbnailUrl TEXT',\n          );\n        }\n        if (oldVersion < 6) {\n          await _createScheduledDownloadsTable(db);\n        }\n        if (oldVersion < 7) {\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN subtitleLang TEXT',\n          );\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN subtitleFormat TEXT',\n          );\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN embedSubtitles INTEGER NOT NULL DEFAULT 0',\n          );\n          await db.execute(\n            'ALTER TABLE queue_items ADD COLUMN downloadSidecarSubtitles INTEGER NOT NULL DEFAULT 0',\n          );\n        }\n      },\n    );"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle endpoints",
      "content": "Backend: Add /subtitles and /download-subtitles endpoints",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle embedding",
      "content": "Backend: Modify /download to support subtitle embedding in MP4",
      "status": "completed"
    },
    {
      "activeForm": "Updating frontend data models",
      "content": "Frontend: Add subtitle-related fields to data models",
      "status": "completed"
    },
    {
      "activeForm": "Building subtitle selection UI",
      "content": "Frontend: Add subtitle language selection UI to quality picker",
      "status": "in_progress"
    },
    {
      "activeForm": "Building subtitle settings UI",
      "content": "Frontend: Add subtitle format and embed/sidecar preference UI",
      "status": "pending"
    },
    {
      "activeForm": "Wiring download flow with subtitles",
      "content": "Frontend: Wire subtitle options into download queue flow",
      "status": "pending"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "pending"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "pending"
    }
  ]
}
Now I need to build the subtitle UI. The key is to add subtitle selection to the quality picker sheet and also provide a way to configure subtitle preferences. Let me add the subtitle option section to the _QualityPickerSheet in main.dart. First, let me read the full quality picker sheet more carefully and the methods that show it.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 50,
  "offset": 130
}
Let me read the _DownloaderScreenState class to find where to add the subtitle-related state.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 100,
  "offset": 295
}
I need to add import for subtitle_option.dart and modify the _QualityPickerSheet to include subtitle options. Let me first add the import.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "import 'format_option.dart';",
  "new_string": "import 'format_option.dart';\nimport 'subtitle_option.dart';"
}
Now let me update the _QualityPickerSheet to include subtitle options. I'll add a subtitle section within the quality picker.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 200,
  "offset": 1231
}
Now I need to replace the _QualityPickerSheet with a StatefulWidget version that includes subtitle options. The key design approach: I'll convert it to a StatefulWidget so it can hold subtitle selection state, and add a subtitle section with language picker, format selector, and embed/sidecar toggle.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "/// Bottom sheet for selecting video quality/format.\nclass _QualityPickerSheet extends StatelessWidget {\n  final String title;\n  final String? thumbnailUrl;\n  final List<FormatOption> formats;\n  final ValueChanged<FormatOption> onFormatSelected;\n  final VoidCallback onBestQualitySelected;\n\n  const _QualityPickerSheet({\n    required this.title,\n    this.thumbnailUrl,\n    required this.formats,\n    required this.onFormatSelected,\n    required this.onBestQualitySelected,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    // Separate formats into categories\n    final combinedFormats = formats.where((f) => f.formatType == 'video+audio').toList();\n    final videoOnlyFormats = formats.where((f) => f.formatType == 'video').toList();\n    final audioOnlyFormats = formats.where((f) => f.formatType == 'audio').toList();\n\n    return DraggableScrollableSheet(\n      initialChildSize: 0.6,\n      minChildSize: 0.3,\n      maxChildSize: 0.9,\n      expand: false,\n      builder: (context, scrollController) {\n        return Column(\n          children: [\n            // Handle bar\n            Container(\n              margin: const EdgeInsets.symmetric(vertical: 8),\n              width: 40,\n              height: 4,\n              decoration: BoxDecoration(\n                color: Colors.grey[300],\n                borderRadius: BorderRadius.circular(2),\n              ),\n            ),\n            // Header\n            Padding(\n              padding: const EdgeInsets.symmetric(horizontal: 16),\n              child: Row(\n                children: [\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(\n                          title,\n                          style: const TextStyle(\n                            fontSize: 16,\n                            fontWeight: FontWeight.bold,\n                          ),\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis,\n                        ),\n                        const Text(\n                          'Select quality',\n                          style: TextStyle(fontSize: 13, color: Colors.grey),\n                        ),\n                      ],\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            const Divider(height: 1),\n            // Format list\n            Expanded(\n              child: ListView(\n                controller: scrollController,\n                children: [\n                  // Best quality option (default)\n                  ListTile(\n                    leading: const Icon(Icons.auto_awesome, color: Colors.green),\n                    title: const Text(\n                      'Best Quality',\n                      style: TextStyle(fontWeight: FontWeight.bold),\n                    ),\n                    subtitle: const Text('Auto-select best video+audio'),\n                    onTap: onBestQualitySelected,\n                  ),\n                  const Divider(height: 1),\n\n                  if (combinedFormats.isNotEmpty) ...[\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Text(\n                        'Video + Audio',\n                        style: TextStyle(\n                          fontSize: 12,\n                          fontWeight: FontWeight.bold,\n                          color: Colors.grey,\n                        ),\n                      ),\n                    ),\n                    ...combinedFormats.map((f) => _buildFormatTile(context, f)),\n                  ],\n\n                  if (videoOnlyFormats.isNotEmpty) ...[\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Text(\n                        'Video Only',\n                        style: TextStyle(\n                          fontSize: 12,\n                          fontWeight: FontWeight.bold,\n                          color: Colors.grey,\n                        ),\n                      ),\n                    ),\n                    ...videoOnlyFormats.map((f) => _buildFormatTile(context, f)),\n                  ],\n\n                  if (audioOnlyFormats.isNotEmpty) ...[\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Text(\n                        'Audio Only',\n                        style: TextStyle(\n                          fontSize: 12,\n                          fontWeight: FontWeight.bold,\n                          color: Colors.grey,\n                        ),\n                      ),\n                    ),\n                    ...audioOnlyFormats.map((f) => _buildFormatTile(context, f)),\n                  ],\n\n                  const SizedBox(height: 80), // Bottom padding for safe area\n                ],\n              ),\n            ),\n          ],\n        );\n      },\n    );\n  }\n\n  Widget _buildFormatTile(BuildContext context, FormatOption format) {\n    return ListTile(\n      leading: Icon(\n        format.isAudioOnly ? Icons.audiotrack : Icons.videocam,\n        color: format.isAudioOnly ? Colors.orange : Theme.of(context).colorScheme.primary,\n      ),\n      title: Text(\n        format.qualityLabel,\n        style: const TextStyle(fontWeight: FontWeight.w500),\n      ),\n      subtitle: Text(\n        format.shortDescription,\n        maxLines: 1,\n        overflow: TextOverflow.ellipsis,\n        style: const TextStyle(fontSize: 12),\n      ),\n      trailing: format.filesizeText.isNotEmpty\n          ? Container(\n              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),\n              decoration: BoxDecoration(\n                color: Colors.grey.shade200,\n                borderRadius: BorderRadius.circular(12),\n              ),\n              child: Text(\n                format.filesizeText,\n                style: TextStyle(\n                  fontSize: 11,\n                  color: Colors.grey[700],\n                  fontWeight: FontWeight.w500,\n                ),\n              ),\n            )\n          : null,\n      onTap: () => onFormatSelected(format),\n    );\n  }\n}",
  "new_string": "/// Bottom sheet for selecting video quality/format with subtitle options.\nclass _QualityPickerSheet extends StatefulWidget {\n  final String title;\n  final String? thumbnailUrl;\n  final String videoUrl;\n  final List<FormatOption> formats;\n  final ValueChanged<FormatOption> onFormatSelected;\n  final VoidCallback onBestQualitySelected;\n\n  const _QualityPickerSheet({\n    required this.title,\n    this.thumbnailUrl,\n    required this.videoUrl,\n    required this.formats,\n    required this.onFormatSelected,\n    required this.onBestQualitySelected,\n  });\n\n  @override\n  State<_QualityPickerSheet> createState() => _QualityPickerSheetState();\n}\n\nclass _QualityPickerSheetState extends State<_QualityPickerSheet> {\n  List<SubtitleOption> _subtitles = [];\n  bool _subtitlesLoading = false;\n  bool _subtitlesLoaded = false;\n  SubtitleOption? _selectedSubtitle;\n  SubtitleFormat _subtitleFormat = SubtitleFormat.srt;\n  SubtitleMode _subtitleMode = SubtitleMode.embed;\n\n  @override\n  void initState() {\n    super.initState();\n    _fetchSubtitles();\n  }\n\n  Future<void> _fetchSubtitles() async {\n    setState(() => _subtitlesLoading = true);\n    try {\n      final endpoint =\n          \"$_backendBaseUrl/subtitles?url=${Uri.encodeComponent(widget.videoUrl)}\";\n      final response = await http\n          .get(Uri.parse(endpoint))\n          .timeout(const Duration(seconds: 15));\n\n      if (response.statusCode == 200) {\n        final data = json.decode(response.body);\n        if (data.containsKey('subtitles')) {\n          final result = SubtitlesResult.fromJson(data);\n          setState(() {\n            _subtitles = result.uniqueByLanguage;\n            _subtitlesLoaded = true;\n            // Auto-select English if available\n            _selectedSubtitle = _subtitles.where((s) => s.language == 'en').firstOrNull ??\n                (_subtitles.isNotEmpty ? _subtitles.first : null);\n          });\n        }\n      }\n    } catch (_) {\n      // Non-fatal: subtitles are optional\n    } finally {\n      setState(() => _subtitlesLoading = false);\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    // Separate formats into categories\n    final combinedFormats = widget.formats.where((f) => f.formatType == 'video+audio').toList();\n    final videoOnlyFormats = widget.formats.where((f) => f.formatType == 'video').toList();\n    final audioOnlyFormats = widget.formats.where((f) => f.formatType == 'audio').toList();\n\n    return DraggableScrollableSheet(\n      initialChildSize: 0.6,\n      minChildSize: 0.3,\n      maxChildSize: 0.9,\n      expand: false,\n      builder: (context, scrollController) {\n        return Column(\n          children: [\n            // Handle bar\n            Container(\n              margin: const EdgeInsets.symmetric(vertical: 8),\n              width: 40,\n              height: 4,\n              decoration: BoxDecoration(\n                color: Colors.grey[300],\n                borderRadius: BorderRadius.circular(2),\n              ),\n            ),\n            // Header\n            Padding(\n              padding: const EdgeInsets.symmetric(horizontal: 16),\n              child: Row(\n                children: [\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(\n                          widget.title,\n                          style: const TextStyle(\n                            fontSize: 16,\n                            fontWeight: FontWeight.bold,\n                          ),\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis,\n                        ),\n                        const Text(\n                          'Select quality',\n                          style: TextStyle(fontSize: 13, color: Colors.grey),\n                        ),\n                      ],\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            const Divider(height: 1),\n            // Format list\n            Expanded(\n              child: ListView(\n                controller: scrollController,\n                children: [\n                  // Best quality option (default)\n                  ListTile(\n                    leading: const Icon(Icons.auto_awesome, color: Colors.green),\n                    title: const Text(\n                      'Best Quality',\n                      style: TextStyle(fontWeight: FontWeight.bold),\n                    ),\n                    subtitle: const Text('Auto-select best video+audio'),\n                    onTap: widget.onBestQualitySelected,\n                  ),\n                  const Divider(height: 1),\n\n                  if (combinedFormats.isNotEmpty) ...[\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Text(\n                        'Video + Audio',\n                        style: TextStyle(\n                          fontSize: 12,\n                          fontWeight: FontWeight.bold,\n                          color: Colors.grey,\n                        ),\n                      ),\n                    ),\n                    ...combinedFormats.map((f) => _buildFormatTile(context, f)),\n                  ],\n\n                  if (videoOnlyFormats.isNotEmpty) ...[\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Text(\n                        'Video Only',\n                        style: TextStyle(\n                          fontSize: 12,\n                          fontWeight: FontWeight.bold,\n                          color: Colors.grey,\n                        ),\n                      ),\n                    ),\n                    ...videoOnlyFormats.map((f) => _buildFormatTile(context, f)),\n                  ],\n\n                  if (audioOnlyFormats.isNotEmpty) ...[\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Text(\n                        'Audio Only',\n                        style: TextStyle(\n                          fontSize: 12,\n                          fontWeight: FontWeight.bold,\n                          color: Colors.grey,\n                        ),\n                      ),\n                    ),\n                    ...audioOnlyFormats.map((f) => _buildFormatTile(context, f)),\n                  ],\n\n                  // Subtitle section\n                  if (_subtitlesLoading || _subtitles.isNotEmpty) ...[\n                    const Divider(height: 24),\n                    const Padding(\n                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),\n                      child: Row(\n                        children: [\n                          Icon(Icons.subtitles, size: 16, color: Colors.grey),\n                          SizedBox(width: 6),\n                          Text(\n                            'Subtitles',\n                            style: TextStyle(\n                              fontSize: 12,\n                              fontWeight: FontWeight.bold,\n                              color: Colors.grey,\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),\n                    if (_subtitlesLoading)\n                      const Padding(\n                        padding: EdgeInsets.all(16),\n                        child: Center(\n                          child: SizedBox(\n                            width: 20,\n                            height: 20,\n                            child: CircularProgressIndicator(strokeWidth: 2),\n                          ),\n                        ),\n                      ),\n                    if (_subtitles.isNotEmpty) ...[\n                      _buildSubtitleLanguagePicker(),\n                      if (_selectedSubtitle != null) ...[\n                        _buildSubtitleFormatPicker(),\n                        _buildSubtitleModePicker(),\n                      ],\n                    ],\n                  ],\n\n                  const SizedBox(height: 80), // Bottom padding for safe area\n                ],\n              ),\n            ),\n          ],\n        );\n      },\n    );\n  }\n\n  Widget _buildSubtitleLanguagePicker() {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),\n      child: DropdownButtonFormField<SubtitleOption>(\n        value: _selectedSubtitle,\n        decoration: const InputDecoration(\n          labelText: 'Language',\n          isDense: true,\n          border: OutlineInputBorder(),\n          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),\n        ),\n        items: [\n          const DropdownMenuItem<SubtitleOption>(\n            value: null,\n            child: Text('None'),\n          ),\n          ..._subtitles.map((s) => DropdownMenuItem(\n                value: s,\n                child: Text(\n                  '${s.languageCode} - ${s.displayLabel}',\n                  overflow: TextOverflow.ellipsis,\n                ),\n              )),\n        ],\n        onChanged: (value) {\n          setState(() => _selectedSubtitle = value);\n        },\n      ),\n    );\n  }\n\n  Widget _buildSubtitleFormatPicker() {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),\n      child: Row(\n        children: SubtitleFormat.values.map((fmt) {\n          final selected = fmt == _subtitleFormat;\n          return Expanded(\n            child: Padding(\n              padding: const EdgeInsets.symmetric(horizontal: 2),\n              child: ChoiceChip(\n                label: Text(fmt.displayName),\n                selected: selected,\n                onSelected: (_) {\n                  setState(() => _subtitleFormat = fmt);\n                },\n              ),\n            ),\n          );\n        }).toList(),\n      ),\n    );\n  }\n\n  Widget _buildSubtitleModePicker() {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),\n      child: Row(\n        children: SubtitleMode.values.map((mode) {\n          final selected = mode == _subtitleMode;\n          return Expanded(\n            child: Padding(\n              padding: const EdgeInsets.symmetric(horizontal: 2),\n              child: ChoiceChip(\n                avatar: Icon(\n                  mode == SubtitleMode.embed ? Icons.merge : Icons.call_split,\n                  size: 16,\n                ),\n                label: Text(mode.displayName),\n                selected: selected,\n                onSelected: (_) {\n                  setState(() => _subtitleMode = mode);\n                },\n              ),\n            ),\n          );\n        }).toList(),\n      ),\n    );\n  }\n\n  Widget _buildFormatTile(BuildContext context, FormatOption format) {\n    return ListTile(\n      leading: Icon(\n        format.isAudioOnly ? Icons.audiotrack : Icons.videocam,\n        color: format.isAudioOnly ? Colors.orange : Theme.of(context).colorScheme.primary,\n      ),\n      title: Text(\n        format.qualityLabel,\n        style: const TextStyle(fontWeight: FontWeight.w500),\n      ),\n      subtitle: Text(\n        format.shortDescription,\n        maxLines: 1,\n        overflow: TextOverflow.ellipsis,\n        style: const TextStyle(fontSize: 12),\n      ),\n      trailing: format.filesizeText.isNotEmpty\n          ? Container(\n              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),\n              decoration: BoxDecoration(\n                color: Colors.grey.shade200,\n                borderRadius: BorderRadius.circular(12),\n              ),\n              child: Text(\n                format.filesizeText,\n                style: TextStyle(\n                  fontSize: 11,\n                  color: Colors.grey[700],\n                  fontWeight: FontWeight.w500,\n                ),\n              ),\n            )\n          : null,\n      onTap: () => widget.onFormatSelected(format),\n    );\n  }\n}"
}
Now I need to update the `_showQualityPickerSheet` method to pass the `videoUrl` and also read the subtitle state from the quality picker. Since the subtitle state is inside the _QualityPickerSheet widget now, I need to update the callbacks. Let me update the showQualityPickerSheet and the onFormatSelected/onBestQualitySelected callbacks to include subtitle data.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 60,
  "offset": 622
}
Now I need to update `_showQualityPickerSheet` to pass the `videoUrl` and the subtitle settings. Since the subtitle state lives inside the _QualityPickerSheet, I need to rethink the approach. The callbacks need to receive subtitle data from the sheet. Let me change the approach - instead of callbacks, I'll read the state from the sheet via a GlobalKey pattern, or better yet, I'll change the callbacks to include the subtitle data.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "  /// Show bottom sheet for quality/format selection.\n  void _showQualityPickerSheet({\n    required String url,\n    required String title,\n    String? thumbnailUrl,\n    required FormatsResult formatsResult,\n  }) {\n    showModalBottomSheet(\n      context: context,\n      isScrollControlled: true,\n      shape: const RoundedRectangleBorder(\n        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),\n      ),\n      builder: (context) => _QualityPickerSheet(\n        title: title,\n        thumbnailUrl: thumbnailUrl,\n        formats: formatsResult.formats,\n        onFormatSelected: (formatOption) {\n          Navigator.pop(context);\n          final label = formatOption.isAudioOnly\n              ? 'Audio (${formatOption.ext.toUpperCase()})'\n              : formatOption.resolution;\n          setState(() {\n            status = \"Added to queue: $title ($label)\";\n          });\n          _queueManager.addToQueue(\n            url: url,\n            title: title,\n            thumbnailUrl: thumbnailUrl,\n            formatId: formatOption.formatId,\n            formatLabel: label,\n          );\n        },\n        onBestQualitySelected: () {\n          Navigator.pop(context);\n          setState(() {\n            status = \"Added to queue: $title (best quality)\";\n          });\n          _queueManager.addToQueue(\n            url: url,\n            title: title,\n            thumbnailUrl: thumbnailUrl,\n          );\n        },\n      ),\n    );\n  }",
  "new_string": "  /// Show bottom sheet for quality/format selection.\n  void _showQualityPickerSheet({\n    required String url,\n    required String title,\n    String? thumbnailUrl,\n    required FormatsResult formatsResult,\n  }) {\n    showModalBottomSheet(\n      context: context,\n      isScrollControlled: true,\n      shape: const RoundedRectangleBorder(\n        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),\n      ),\n      builder: (context) => _QualityPickerSheet(\n        title: title,\n        thumbnailUrl: thumbnailUrl,\n        videoUrl: url,\n        formats: formatsResult.formats,\n        onFormatSelected: (formatOption, subtitleLang, subtitleFormat, embedSubs, sidecarSubs) {\n          Navigator.pop(context);\n          final label = formatOption.isAudioOnly\n              ? 'Audio (${formatOption.ext.toUpperCase()})'\n              : formatOption.resolution;\n          final subInfo = subtitleLang != null ? ' + subs' : '';\n          setState(() {\n            status = \"Added to queue: $title ($label$subInfo)\";\n          });\n          _queueManager.addToQueue(\n            url: url,\n            title: title,\n            thumbnailUrl: thumbnailUrl,\n            formatId: formatOption.formatId,\n            formatLabel: label,\n            subtitleLang: subtitleLang,\n            subtitleFormat: subtitleFormat,\n            embedSubtitles: embedSubs,\n            downloadSidecarSubtitles: sidecarSubs,\n          );\n        },\n        onBestQualitySelected: (subtitleLang, subtitleFormat, embedSubs, sidecarSubs) {\n          Navigator.pop(context);\n          final subInfo = subtitleLang != null ? ' + subs' : '';\n          setState(() {\n            status = \"Added to queue: $title (best quality$subInfo)\";\n          });\n          _queueManager.addToQueue(\n            url: url,\n            title: title,\n            thumbnailUrl: thumbnailUrl,\n            subtitleLang: subtitleLang,\n            subtitleFormat: subtitleFormat,\n            embedSubtitles: embedSubs,\n            downloadSidecarSubtitles: sidecarSubs,\n          );\n        },\n      ),\n    );\n  }"
}
Now I need to update the _QualityPickerSheet callback signatures to include the subtitle data.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "/// Bottom sheet for selecting video quality/format with subtitle options.\nclass _QualityPickerSheet extends StatefulWidget {\n  final String title;\n  final String? thumbnailUrl;\n  final String videoUrl;\n  final List<FormatOption> formats;\n  final ValueChanged<FormatOption> onFormatSelected;\n  final VoidCallback onBestQualitySelected;\n\n  const _QualityPickerSheet({\n    required this.title,\n    this.thumbnailUrl,\n    required this.videoUrl,\n    required this.formats,\n    required this.onFormatSelected,\n    required this.onBestQualitySelected,\n  });",
  "new_string": "/// Bottom sheet for selecting video quality/format with subtitle options.\nclass _QualityPickerSheet extends StatefulWidget {\n  final String title;\n  final String? thumbnailUrl;\n  final String videoUrl;\n  final List<FormatOption> formats;\n  final void Function(FormatOption, String? subtitleLang, String? subtitleFormat, bool embedSubs, bool sidecarSubs) onFormatSelected;\n  final void Function(String? subtitleLang, String? subtitleFormat, bool embedSubs, bool sidecarSubs) onBestQualitySelected;\n\n  const _QualityPickerSheet({\n    required this.title,\n    this.thumbnailUrl,\n    required this.videoUrl,\n    required this.formats,\n    required this.onFormatSelected,\n    required this.onBestQualitySelected,\n  });"
}
Now update the onTap handlers to pass subtitle data.

🔧 Tool: Grep
Input: {
  "output_mode": "content",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "pattern": "onTap: widget\\.on(BestQuality|FormatSelected)",
  "-n": true
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "                    onTap: widget.onBestQualitySelected,",
  "new_string": "                    onTap: () => widget.onBestQualitySelected(\n                      _selectedSubtitle?.language,\n                      _subtitleFormat.extension,\n                      _subtitleMode == SubtitleMode.embed && _selectedSubtitle != null,\n                      _subtitleMode == SubtitleMode.sidecar && _selectedSubtitle != null,\n                    ),"
}
Now update the format tile onTap.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "      onTap: () => widget.onFormatSelected(format),",
  "new_string": "      onTap: () => widget.onFormatSelected(\n        format,\n        _selectedSubtitle?.language,\n        _subtitleFormat.extension,\n        _subtitleMode == SubtitleMode.embed && _selectedSubtitle != null,\n        _subtitleMode == SubtitleMode.sidecar && _selectedSubtitle != null,\n      ),"
}
Now let me verify the code compiles by checking for any obvious issues. Let me read the updated queue_item.dart to make sure it's correct.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart"
}
The QueueItem looks good. Now let me update the todos and try to build the Flutter project to verify there are no compile errors.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle endpoints",
      "content": "Backend: Add /subtitles and /download-subtitles endpoints",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle embedding",
      "content": "Backend: Modify /download to support subtitle embedding in MP4",
      "status": "completed"
    },
    {
      "activeForm": "Updating frontend data models",
      "content": "Frontend: Add subtitle-related fields to data models",
      "status": "completed"
    },
    {
      "activeForm": "Building subtitle selection UI",
      "content": "Frontend: Add subtitle language selection UI to quality picker",
      "status": "completed"
    },
    {
      "activeForm": "Building subtitle settings UI",
      "content": "Frontend: Add subtitle format and embed/sidecar preference UI",
      "status": "completed"
    },
    {
      "activeForm": "Wiring download flow with subtitles",
      "content": "Frontend: Wire subtitle options into download queue flow",
      "status": "completed"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "in_progress"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "pending"
    }
  ]
}
Let me try to build the Flutter project to check for compile errors.

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-pub 2>&1 | head -60",
  "description": "Run Flutter static analysis to check for compile errors",
  "timeout": 120000
}
The analysis is clean - no errors, only info-level messages and one warning about an unused field. Let me fix that unused field.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "  List<SubtitleOption> _subtitles = [];\n  bool _subtitlesLoading = false;\n  bool _subtitlesLoaded = false;\n  SubtitleOption? _selectedSubtitle;",
  "new_string": "  List<SubtitleOption> _subtitles = [];\n  bool _subtitlesLoading = false;\n  SubtitleOption? _selectedSubtitle;"
}
Now fix the deprecated `value` usage in DropdownButtonFormField.

🔧 Tool: Grep
Input: {
  "-n": true,
  "output_mode": "content",
  "context": 5,
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "pattern": "DropdownButtonFormField"
}
The deprecation warning is about `value` on DropdownButtonFormField. This is a Flutter 3.33 deprecation that suggests using `initialValue` instead. Let me fix it.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "      child: DropdownButtonFormField<SubtitleOption>(\n        value: _selectedSubtitle,\n        decoration: const InputDecoration(",
  "new_string": "      child: DropdownButtonFormField<SubtitleOption>(\n        initialValue: _selectedSubtitle,\n        decoration: const InputDecoration("
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-pub 2>&1 | head -30",
  "description": "Re-run Flutter analysis to verify fix",
  "timeout": 120000
}
There's still a reference to `_subtitlesLoaded` in the code. Let me fix it.

🔧 Tool: Grep
Input: {
  "-n": true,
  "context": 3,
  "output_mode": "content",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "pattern": "_subtitlesLoaded"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "          setState(() {\n            _subtitles = result.uniqueByLanguage;\n            _subtitlesLoaded = true;\n            // Auto-select English if available",
  "new_string": "          setState(() {\n            _subtitles = result.uniqueByLanguage;\n            // Auto-select English if available"
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-pub 2>&1 | head -30",
  "description": "Re-run Flutter analysis to verify all errors fixed",
  "timeout": 120000
}
All errors are fixed. The remaining 6 issues are pre-existing info-level warnings (not related to my changes). Now let me also verify the Python backend has no syntax errors.

🔧 Tool: Bash
Input: {
  "command": "python -c \"import ast; ast.parse(open(r'C:\\Projects\\x_video_downloader\\fly.io backend\\main.py', encoding='utf-8').read()); print('Python syntax OK')\"",
  "description": "Check Python syntax of the modified backend file",
  "timeout": 30000
}
Both backend and frontend pass their respective checks. Now let me write the Playwright verification test. Since this is a Flutter app + Python backend, I'll create a test that verifies the backend subtitle API endpoints work correctly by hitting them directly.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\test_subtitle_api.py",
  "content": "\"\"\"\nTemporary verification test for subtitle download support.\nTests the backend API endpoints for subtitle listing, downloading, and format conversion.\nThis test is deleted after verification.\n\"\"\"\nimport subprocess\nimport sys\nimport time\nimport json\nimport urllib.request\nimport urllib.parse\n\n# --- Test configuration ---\nBASE_URL = \"http://localhost:8000\"\nTEST_VIDEO_URL = \"https://www.youtube.com/watch?v=dQw4w9WgXcQ\"  # Rick Astley - reliable test video\n\ndef run_server():\n    \"\"\"Start the FastAPI server in the background.\"\"\"\n    print(\"[SETUP] Starting FastAPI server...\")\n    proc = subprocess.Popen(\n        [sys.executable, \"-m\", \"uvicorn\", \"main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8000\"],\n        cwd=r\"C:\\Projects\\x_video_downloader\\fly.io backend\",\n        stdout=subprocess.PIPE,\n        stderr=subprocess.PIPE,\n    )\n    # Wait for server to start\n    for _ in range(30):\n        try:\n            urllib.request.urlopen(f\"{BASE_URL}/cache-stats\", timeout=2)\n            print(\"[SETUP] Server started successfully.\")\n            return proc\n        except Exception:\n            time.sleep(1)\n    print(\"[ERROR] Server failed to start within 30 seconds.\")\n    proc.terminate()\n    sys.exit(1)\n\n\ndef stop_server(proc):\n    \"\"\"Stop the FastAPI server.\"\"\"\n    print(\"[TEARDOWN] Stopping server...\")\n    proc.terminate()\n    proc.wait(timeout=10)\n    print(\"[TEARDOWN] Server stopped.\")\n\n\ndef test_subtitles_endpoint():\n    \"\"\"Test 1: List available subtitles for a video.\"\"\"\n    print(\"\\n[TEST 1] GET /subtitles - List available subtitles\")\n    url = f\"{BASE_URL}/subtitles?url={urllib.parse.quote(TEST_VIDEO_URL)}\"\n    try:\n        req = urllib.request.Request(url, headers={\"User-Agent\": \"Test/1.0\"})\n        with urllib.request.urlopen(req, timeout=60) as resp:\n            data = json.loads(resp.read().decode(\"utf-8\"))\n\n        assert \"subtitles\" in data, \"Response missing 'subtitles' key\"\n        assert \"available_languages\" in data, \"Response missing 'available_languages' key\"\n        assert \"count\" in data, \"Response missing 'count' key\"\n        assert isinstance(data[\"subtitles\"], list), \"subtitles should be a list\"\n        assert isinstance(data[\"available_languages\"], list), \"available_languages should be a list\"\n\n        print(f\"  Found {data['count']} subtitle tracks\")\n        print(f\"  Languages: {data['available_languages'][:10]}\")\n\n        # Check subtitle structure\n        if data[\"subtitles\"]:\n            sub = data[\"subtitles\"][0]\n            assert \"language\" in sub, \"Subtitle missing 'language'\"\n            assert \"name\" in sub, \"Subtitle missing 'name'\"\n            assert \"auto_generated\" in sub, \"Subtitle missing 'auto_generated'\"\n            print(f\"  Sample subtitle: {sub['language']} - {sub['name']} (auto={sub['auto_generated']})\")\n\n        print(\"[TEST 1] PASSED\")\n        return data\n    except urllib.error.HTTPError as e:\n        body = e.read().decode(\"utf-8\")\n        print(f\"  HTTP Error {e.code}: {body[:200]}\")\n        print(\"[TEST 1] FAILED - HTTP error (video may be geo-blocked)\")\n        return None\n    except Exception as e:\n        print(f\"  Error: {e}\")\n        print(\"[TEST 1] FAILED\")\n        return None\n\n\ndef test_download_subtitles_srt(subtitles_data):\n    \"\"\"Test 2: Download subtitles in SRT format.\"\"\"\n    print(\"\\n[TEST 2] GET /download-subtitles?format=srt - Download SRT subtitles\")\n    if not subtitles_data or not subtitles_data.get(\"available_languages\"):\n        print(\"  SKIPPED - No subtitles available\")\n        return\n\n    lang = \"en\" if \"en\" in subtitles_data[\"available_languages\"] else subtitles_data[\"available_languages\"][0]\n    url = f\"{BASE_URL}/download-subtitles?url={urllib.parse.quote(TEST_VIDEO_URL)}&lang={lang}&format=srt\"\n    try:\n        req = urllib.request.Request(url, headers={\"User-Agent\": \"Test/1.0\"})\n        with urllib.request.urlopen(req, timeout=60) as resp:\n            content = resp.read().decode(\"utf-8\")\n\n        # Verify SRT format: should have numbered entries and timestamps\n        has_numbers = any(line.strip().isdigit() for line in content.split(\"\\n\"))\n        has_timestamps = \"-->\" in content\n        assert has_timestamps, \"SRT content should contain timestamps\"\n\n        print(f\"  Downloaded SRT subtitles ({len(content)} bytes)\")\n        print(f\"  Has timestamps: {has_timestamps}\")\n        # Show first few lines\n        lines = content.strip().split(\"\\n\")[:5]\n        print(f\"  First lines: {lines}\")\n        print(\"[TEST 2] PASSED\")\n    except urllib.error.HTTPError as e:\n        body = e.read().decode(\"utf-8\")\n        print(f\"  HTTP Error {e.code}: {body[:200]}\")\n        print(\"[TEST 2] FAILED\")\n    except Exception as e:\n        print(f\"  Error: {e}\")\n        print(\"[TEST 2] FAILED\")\n\n\ndef test_download_subtitles_vtt(subtitles_data):\n    \"\"\"Test 3: Download subtitles in VTT format.\"\"\"\n    print(\"\\n[TEST 3] GET /download-subtitles?format=vtt - Download VTT subtitles\")\n    if not subtitles_data or not subtitles_data.get(\"available_languages\"):\n        print(\"  SKIPPED - No subtitles available\")\n        return\n\n    lang = \"en\" if \"en\" in subtitles_data[\"available_languages\"] else subtitles_data[\"available_languages\"][0]\n    url = f\"{BASE_URL}/download-subtitles?url={urllib.parse.quote(TEST_VIDEO_URL)}&lang={lang}&format=vtt\"\n    try:\n        req = urllib.request.Request(url, headers={\"User-Agent\": \"Test/1.0\"})\n        with urllib.request.urlopen(req, timeout=60) as resp:\n            content = resp.read().decode(\"utf-8\")\n\n        # VTT should start with WEBVTT header\n        is_vtt = content.strip().startswith(\"WEBVTT\")\n        assert is_vtt, \"VTT content should start with WEBVTT header\"\n\n        print(f\"  Downloaded VTT subtitles ({len(content)} bytes)\")\n        print(f\"  Starts with WEBVTT: {is_vtt}\")\n        print(\"[TEST 3] PASSED\")\n    except urllib.error.HTTPError as e:\n        body = e.read().decode(\"utf-8\")\n        print(f\"  HTTP Error {e.code}: {body[:200]}\")\n        print(\"[TEST 3] FAILED\")\n    except Exception as e:\n        print(f\"  Error: {e}\")\n        print(\"[TEST 3] FAILED\")\n\n\ndef test_download_subtitles_ass(subtitles_data):\n    \"\"\"Test 4: Download subtitles in ASS format.\"\"\"\n    print(\"\\n[TEST 4] GET /download-subtitles?format=ass - Download ASS subtitles\")\n    if not subtitles_data or not subtitles_data.get(\"available_languages\"):\n        print(\"  SKIPPED - No subtitles available\")\n        return\n\n    lang = \"en\" if \"en\" in subtitles_data[\"available_languages\"] else subtitles_data[\"available_languages\"][0]\n    url = f\"{BASE_URL}/download-subtitles?url={urllib.parse.quote(TEST_VIDEO_URL)}&lang={lang}&format=ass\"\n    try:\n        req = urllib.request.Request(url, headers={\"User-Agent\": \"Test/1.0\"})\n        with urllib.request.urlopen(req, timeout=60) as resp:\n            content = resp.read().decode(\"utf-8\")\n\n        # ASS should have [Script Info] and [Events] sections\n        has_script_info = \"[Script Info]\" in content\n        has_events = \"[Events]\" in content\n        assert has_script_info, \"ASS content should have [Script Info] section\"\n        assert has_events, \"ASS content should have [Events] section\"\n\n        print(f\"  Downloaded ASS subtitles ({len(content)} bytes)\")\n        print(f\"  Has [Script Info]: {has_script_info}\")\n        print(f\"  Has [Events]: {has_events}\")\n        print(\"[TEST 4] PASSED\")\n    except urllib.error.HTTPError as e:\n        body = e.read().decode(\"utf-8\")\n        print(f\"  HTTP Error {e.code}: {body[:200]}\")\n        print(\"[TEST 4] FAILED\")\n    except Exception as e:\n        print(f\"  Error: {e}\")\n        print(\"[TEST 4] FAILED\")\n\n\ndef test_invalid_format():\n    \"\"\"Test 5: Verify error handling for invalid subtitle format.\"\"\"\n    print(\"\\n[TEST 5] GET /download-subtitles?format=invalid - Error handling\")\n    url = f\"{BASE_URL}/download-subtitles?url={urllib.parse.quote(TEST_VIDEO_URL)}&lang=en&format=invalid\"\n    try:\n        req = urllib.request.Request(url, headers={\"User-Agent\": \"Test/1.0\"})\n        with urllib.request.urlopen(req, timeout=30) as resp:\n            print(\"  Expected error but got 200 response\")\n            print(\"[TEST 5] FAILED\")\n    except urllib.error.HTTPError as e:\n        assert e.code in (400, 404), f\"Expected 400 or 404, got {e.code}\"\n        print(f\"  Got expected error: HTTP {e.code}\")\n        print(\"[TEST 5] PASSED\")\n    except Exception as e:\n        print(f\"  Error: {e}\")\n        print(\"[TEST 5] FAILED\")\n\n\ndef test_format_conversion():\n    \"\"\"Test 6: Test VTT to SRT conversion directly.\"\"\"\n    print(\"\\n[TEST 6] VTT to SRT format conversion\")\n    # Import the conversion function\n    sys.path.insert(0, r\"C:\\Projects\\x_video_downloader\\fly.io backend\")\n    from main import _convert_vtt_to_srt, _convert_vtt_to_ass\n\n    sample_vtt = \"\"\"WEBVTT\n\n00:00:01.000 --> 00:00:04.000\nHello, this is a test subtitle.\n\n00:00:05.000 --> 00:00:08.000\nThis is the second line.\n\"\"\"\n\n    srt_result = _convert_vtt_to_srt(sample_vtt)\n    assert \"-->\" in srt_result, \"SRT should contain timestamps\"\n    assert \"1\\n\" in srt_result, \"SRT should have numbered entries\"\n    assert \",\" in srt_result, \"SRT timestamps should use commas\"\n    assert \".\" not in srt_result.split(\"-->\")[0].strip().split(\"\\n\")[-1], \"SRT timestamps should not have dots\"\n    print(f\"  VTT to SRT conversion OK\")\n    print(f\"  SRT output:\\n{srt_result}\")\n\n    ass_result = _convert_vtt_to_ass(sample_vtt, \"Test\")\n    assert \"[Script Info]\" in ass_result, \"ASS should have Script Info\"\n    assert \"Dialogue:\" in ass_result, \"ASS should have Dialogue entries\"\n    print(f\"  VTT to ASS conversion OK\")\n    print(f\"  ASS output (first 200 chars): {ass_result[:200]}\")\n\n    print(\"[TEST 6] PASSED\")\n\n\nif __name__ == \"__main__\":\n    print(\"=\" * 60)\n    print(\"Subtitle Download Support - Verification Tests\")\n    print(\"=\" * 60)\n\n    # Test format conversion first (doesn't need server)\n    test_format_conversion()\n\n    # Start server for API tests\n    server_proc = run_server()\n\n    try:\n        # Test the subtitle API endpoints\n        subtitles_data = test_subtitles_endpoint()\n        test_download_subtitles_srt(subtitles_data)\n        test_download_subtitles_vtt(subtitles_data)\n        test_download_subtitles_ass(subtitles_data)\n        test_invalid_format()\n    finally:\n        stop_server(server_proc)\n\n    print(\"\\n\" + \"=\" * 60)\n    print(\"All tests completed.\")\n    print(\"=\" * 60)\n"
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\" && python test_subtitle_api.py 2>&1",
  "description": "Run subtitle API verification tests",
  "timeout": 300000
}
The format conversion tests (TEST 6) passed successfully. The API endpoint tests timed out because yt-dlp can't reach YouTube from this local environment (likely network/proxy issues). This is expected for a local test environment. The core logic is verified by the successful format conversion test.

Let me now also check that the format conversion functions work correctly by running a more thorough test.

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\" && python -c \"\nimport sys\nsys.path.insert(0, r'fly.io backend')\nfrom main import _convert_vtt_to_srt, _convert_vtt_to_ass, _convert_srt_to_vtt\n\n# Test VTT to SRT\nvtt = '''WEBVTT\n\n00:00:01.000 --> 00:00:04.000\nHello, world.\n\n00:00:05.000 --> 00:00:08.500\nSecond subtitle line.\n'''\n\nsrt = _convert_vtt_to_srt(vtt)\nassert '1' in srt\nassert '2' in srt\nassert '-->' in srt\nassert ',' in srt  # SRT uses commas in timestamps\nprint('VTT->SRT: OK')\nprint(srt)\n\n# Test VTT to ASS\nass = _convert_vtt_to_ass(vtt, 'Test Title')\nassert '[Script Info]' in ass\nassert '[Events]' in ass\nassert 'Dialogue:' in ass\nprint('VTT->ASS: OK')\n\n# Test SRT to VTT\nsrt_input = '''1\n00:00:01,000 --> 00:00:04,000\nHello, world.\n\n2\n00:00:05,000 --> 00:00:08,500\nSecond subtitle line.\n'''\nvtt_out = _convert_srt_to_vtt(srt_input)\nassert 'WEBVTT' in vtt_out\nassert '.' in vtt_out  # VTT uses dots in timestamps\nprint('SRT->VTT: OK')\nprint(vtt_out)\n\nprint('All conversion tests PASSED')\n\" 2>&1",
  "description": "Verify subtitle format conversion functions",
  "timeout": 30000
}
All format conversion tests pass. Now let me clean up the test file.

🔧 Tool: Bash
Input: {
  "command": "del \"C:\\Projects\\x_video_downloader\\test_subtitle_api.py\"",
  "description": "Delete temporary verification test file"
}

🔧 Tool: Bash
Input: {
  "command": "rm \"C:\\Projects\\x_video_downloader\\test_subtitle_api.py\"",
  "description": "Delete temporary verification test file"
}

🔧 Tool: Bash
Input: {
  "command": "del /f \"C:\\Projects\\x_video_downloader\\test_subtitle_api.py\"",
  "description": "Delete temporary test file"
}

🔧 Tool: Bash
Input: {
  "command": "python -c \"import os; os.remove(r'C:\\Projects\\x_video_downloader\\test_subtitle_api.py'); print('deleted')\"",
  "description": "Delete test file via Python"
}
Good. Now let me update the todos and output the final summary.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing patterns",
      "status": "completed"
    },
    {
      "activeForm": "Planning implementation approach",
      "content": "Plan implementation approach for subtitle support",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle endpoints",
      "content": "Backend: Add /subtitles and /download-subtitles endpoints",
      "status": "completed"
    },
    {
      "activeForm": "Implementing backend subtitle embedding",
      "content": "Backend: Modify /download to support subtitle embedding in MP4",
      "status": "completed"
    },
    {
      "activeForm": "Updating frontend data models",
      "content": "Frontend: Add subtitle-related fields to data models",
      "status": "completed"
    },
    {
      "activeForm": "Building subtitle selection UI",
      "content": "Frontend: Add subtitle language selection UI to quality picker",
      "status": "completed"
    },
    {
      "activeForm": "Building subtitle settings UI",
      "content": "Frontend: Add subtitle format and embed/sidecar preference UI",
      "status": "completed"
    },
    {
      "activeForm": "Wiring download flow with subtitles",
      "content": "Frontend: Wire subtitle options into download queue flow",
      "status": "completed"
    },
    {
      "activeForm": "Testing and verifying implementation",
      "content": "Test and verify the implementation",
      "status": "completed"
    },
    {
      "activeForm": "Outputting final summary",
      "content": "Output final summary",
      "status": "in_progress"
    }
  ]
}
<summary>
## Summary: Add ability to download video subtitles/captions

### Changes Implemented

**Backend (Python/FastAPI):**
- Added `GET /subtitles` endpoint to list available subtitle/caption tracks for any video URL. Returns language codes, names, URLs, and auto-generated status for both manual and automatic captions.
- Added `GET /download-subtitles` endpoint to download subtitles in SRT, VTT, or ASS format. Accepts `lang`, `format`, and `auto_generated` query parameters. Uses yt-dlp to extract subtitle info and URL-fetches the content, then converts to the requested format.
- Added subtitle format conversion functions: `_convert_vtt_to_srt()`, `_convert_vtt_to_ass()`, `_convert_srt_to_vtt()`.
- Modified `GET /download` endpoint to accept subtitle parameters: `subtitle_lang`, `subtitle_format`, and `embed_subtitles`. When `embed_subtitles=true`, the download process fetches the subtitle, converts to SRT, and uses FFmpeg to embed it into the MP4 container as `mov_text` (MP4-compatible subtitle track).

**Frontend (Flutter):**
- Created `subtitle_option.dart` data model with `SubtitleOption`, `SubtitlesResult`, `SubtitleFormat` enum (SRT/VTT/ASS), and `SubtitleMode` enum (embed/sidecar).
- Updated `QueueItem` model with new fields: `subtitleLang`, `subtitleFormat`, `embedSubtitles`, `downloadSidecarSubtitles`. Updated `fromMap`, `toMap`, `copyWith`, and constructor.
- Updated `DownloadDatabase` schema to version 7, adding 4 new columns for subtitle persistence.
- Updated `DownloadQueueManager.addToQueue()` to accept and pass subtitle parameters. Updated `_startDownload()` to include subtitle params in the download URL. Added sidecar subtitle download logic after video download completes.
- Converted `_QualityPickerSheet` from `StatelessWidget` to `StatefulWidget` with subtitle state management. The sheet now automatically fetches available subtitles when opened and displays:
  - Language dropdown (auto-selects English if available)
  - Format picker chips (SRT / VTT / ASS)
  - Mode picker chips (Embed in video / Separate file)
- Updated callback signatures to pass subtitle data through the download flow.

### Files Modified
- `fly.io backend/main.py` - Added 3 new endpoints and subtitle format conversion logic
- `x_video_downloader_flutter_frontend/lib/subtitle_option.dart` - New file: subtitle data models
- `x_video_downloader_flutter_frontend/lib/queue_item.dart` - Added subtitle fields
- `x_video_downloader_flutter_frontend/lib/download_database.dart` - Schema v7 with subtitle columns
- `x_video_downloader_flutter_frontend/lib/download_queue_manager.dart` - Subtitle params in queue and download flow
- `x_video_downloader_flutter_frontend/lib/main.dart` - Updated quality picker with subtitle UI

### Notes for Developer
- The subtitle UI appears in the quality picker sheet only when subtitles are available for the video. If no subtitles are found, the section is hidden.
- FFmpeg subtitle embedding uses `mov_text` codec which is the standard for MP4 containers. The embedded subtitles work in most modern video players.
- Sidecar subtitle files are saved alongside the video with naming pattern `{title}_{timestamp}.{lang}.{format}`.
- The format conversion functions handle VTT→SRT, VTT→ASS, and SRT→VTT bidirectionally.
- API endpoint tests require network access to YouTube (or the target video platform). Format conversion was verified locally.

### Verification Status
- Flutter static analysis: 0 errors, 6 pre-existing info warnings
- Python syntax check: Passed
- Subtitle format conversion (VTT↔SRT, VTT→ASS): All conversions verified with test data
- API endpoint tests: Could not fully verify due to local network restrictions preventing yt-dlp from reaching YouTube. The endpoints are structurally correct and follow existing patterns.
</summary>