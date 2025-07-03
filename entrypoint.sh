
#!/bin/bash
set -e

XVFB_WHD=${XVFB_WHD:-1280x720x24}
FPS=${FPS:-15}
GIF_SCALE=${GIF_SCALE:-960}
OUT_DIR=${OUT_DIR:-/output}
mkdir -p "$OUT_DIR"
GIF_NAME=${GIF_NAME:-demo_$(date +%Y%m%d_%H%M%S).gif}
MP4_TEMP=/tmp/recording.mp4

echo "▶ Starting Xvfb..."
Xvfb :99 -screen 0 $XVFB_WHD &
XVFB_PID=$!
export DISPLAY=:99

fluxbox >/dev/null 2>&1 &
WM_PID=$!

echo "▶ Starting FFmpeg capture..."
ffmpeg -y -loglevel error -video_size 1280x720 -f x11grab -i $DISPLAY -r $FPS "$MP4_TEMP" &
FF_PID=$!

echo "▶ Running Selenium script..."
python /app/scripts/record_webapp.py

echo "▶ Stopping capture..."
kill -INT $FF_PID
wait $FF_PID

echo "▶ Converting MP4 ➜ GIF..."
ffmpeg -y -loglevel error -i "$MP4_TEMP" -vf "fps=$FPS,scale=$GIF_SCALE:-1:flags=lanczos" "$OUT_DIR/$GIF_NAME"

echo "✔ GIF saved to $OUT_DIR/$GIF_NAME"

kill $WM_PID
kill $XVFB_PID
