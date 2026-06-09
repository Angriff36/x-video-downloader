from fastapi import FastAPI, Query
from fastapi.responses import FileResponse
import yt_dlp
import os

app = FastAPI()

OUTPUT_DIR = "downloads"
os.makedirs(OUTPUT_DIR, exist_ok=True)

@app.get("/download")
def download_x_video(url: str = Query(...)):
    try:
        ydl_opts = {
            'outtmpl': f'{OUTPUT_DIR}/%(uploader)s - %(title)s.%(ext)s',
            'merge_output_format': 'mp4',
            'ffmpeg_location': 'C:/ffmpeg/bin/ffmpeg.exe',
            'quiet': True
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            result = ydl.extract_info(url, download=True)
            filename = ydl.prepare_filename(result)

        # Return the video as a downloadable file
        return FileResponse(path=filename, filename=os.path.basename(filename), media_type='video/mp4')
    except Exception as e:
        return {"error": str(e)}
