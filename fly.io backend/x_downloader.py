import yt_dlp

def download_x_video(url):
    ydl_opts = {
        'outtmpl': '%(uploader)s - %(title)s.%(ext)s',
        'merge_output_format': 'mp4',
        'ffmpeg_location': 'C:/ffmpeg/bin/ffmpeg.exe',
        'quiet': False
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
    except Exception as e:
        print("❌ Error occurred:", e)

if __name__ == "__main__":
    url = input("Enter X/Twitter video URL: ").strip()
    download_x_video(url)

