import time
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
import subprocess

def record_screen(output_path="/output/session.gif"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    ffmpeg_cmd = [
        "ffmpeg",
        "-y",
        "-video_size", "1280x720",
        "-f", "x11grab",
        "-i", ":99",
        "-t", "10",
        "-vf", "fps=10,scale=800:-1:flags=lanczos",
        "-gifflags", "+transdiff",
        output_path
    ]
    return subprocess.Popen(ffmpeg_cmd)

def main():
    proc = record_screen()
    time.sleep(2)

    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()))
    driver.get("https://example.com")
    time.sleep(5)
    driver.quit()

    proc.wait()

if __name__ == "__main__":
    main()
