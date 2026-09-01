import unittest
from unittest.mock import Mock, patch

import requests

import main


def _response(status_code: int, body: str, url: str) -> requests.Response:
    response = requests.Response()
    response.status_code = status_code
    response._content = body.encode("utf-8")
    response.encoding = "utf-8"
    response.url = url
    return response


class TikTokExtractorTests(unittest.TestCase):
    def test_uses_musicaldown_hd_video_when_short_link_and_tikwm_are_blocked(self):
        short_url = "https://www.tiktok.com/t/ZP8cNNsnw/"
        standard_url = "https://fastdl.muscdn.app/v3?token=standard"
        hd_url = "https://fastdl.muscdn.app/v3?token=hd"

        blocked_short_link = _response(403, "blocked", short_url)
        blocked_tikwm = _response(403, "blocked", "https://www.tikwm.com/api/")
        musicaldown_form = _response(
            200,
            """
            <form id="submit-form">
              <input id="link_url" name="_JKi" type="text">
              <input name="_sYcGr" type="hidden" value="form-token">
            </form>
            """,
            "https://musicaldown.com/en",
        )
        musicaldown_result = _response(
            200,
            f"""
            <a href="{standard_url}">Download MP4</a>
            <a href="{hd_url}">Download MP4 <strong>[HD]</strong></a>
            <a href="https://fastdl.muscdn.app/v3?token=watermark">Download MP4 [Watermark]</a>
            <a href="https://fastdl.muscdn.app/v3?token=audio">Download MP3</a>
            """,
            "https://musicaldown.com/download",
        )

        musicaldown_session = Mock()
        musicaldown_session.get.return_value = musicaldown_form
        musicaldown_session.post.return_value = musicaldown_result

        with (
            patch("requests.head", return_value=blocked_short_link),
            patch("requests.get", return_value=blocked_tikwm),
            patch("requests.Session", return_value=musicaldown_session),
        ):
            extracted = main._extract_tiktok(short_url)

        self.assertIsNotNone(extracted)
        self.assertEqual(hd_url, extracted["video_url"])
        self.assertEqual("TikTok", extracted["platform"])


if __name__ == "__main__":
    unittest.main()
