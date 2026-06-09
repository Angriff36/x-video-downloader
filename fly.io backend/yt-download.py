import yt_dlp

def download_video(url):
    ydl_opts = {
        'format': 'bv*+ba/best[ext=mp4]/best',
        'outtmpl': '%(title)s.%(ext)s',
        'merge_output_format': 'mp4',
        'ffmpeg_location': 'C:/ffmpeg/bin/ffmpeg.exe',
        'quiet': False
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
    except Exception as e:
        print("An error occurred:", e)

if __name__ == "__main__":
    url = input("Enter YouTube video URL: ").strip()
    download_video(url)
