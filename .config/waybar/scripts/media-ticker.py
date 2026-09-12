#!/usr/bin/env python3
import json
import subprocess
import time
import unicodedata

WIDTH = 24
GAP = "   "
SCROLL_DT = 0.35
IDLE_DT = 1.0


def char_width(ch: str) -> int:
    if unicodedata.combining(ch):
        return 0
    
    return 2 if unicodedata.east_asian_width(ch) in ("F", "W") else 1


def display_width(text: str) -> int:
    return sum(char_width(c) for c in text)


def slice_display(text: str, start: int, width: int) -> str:
    chars = [(ch, char_width(ch)) for ch in text]
    i = 0
    skipped = 0
    
    while i < len(chars) and skipped < start:
        skipped += chars[i][1]
        i += 1

    out = []
    taken = 0
    
    while i < len(chars) and taken < width:
        ch, w = chars[i]
        if taken + w > width:
            break
        out.append(ch)
        taken += w
        i += 1

    if taken < width:
        out.append(" " * (width - taken))
    
    return "".join(out)


def playerctl(*args: str) -> str:
    try:
        return subprocess.check_output(
            ["playerctl", *args],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def track() -> tuple[str, str]:
    status = playerctl("status")
    
    if status not in {"Playing", "Paused"}:
        return status or "Stopped", ""

    artist = playerctl("metadata", "artist")
    title = playerctl("metadata", "title")
    
    if artist and title:
        return status, f"{artist} — {title}"
    
    return status, title or artist


def emit(text: str, tooltip: str, css_class: str) -> None:
    print(
        json.dumps({"text": text, "tooltip": tooltip, "class": css_class}),
        flush=True,
    )


def main() -> None:
    last = ""
    offset = 0
    
    while True:
        status, text = track()
        css = status.lower() if status else "stopped"
        
        if not text:
            emit(slice_display("Not playing", 0, WIDTH), "Not playing", "stopped")
            last = ""
            offset = 0
            time.sleep(IDLE_DT)
            continue

        if text != last:
            last = text
            offset = 0

        if display_width(text) <= WIDTH:
            emit(slice_display(text, 0, WIDTH), text, css)
            time.sleep(IDLE_DT)
            continue

        loop = text + GAP
        
        emit(slice_display(loop + text, offset, WIDTH), text, css)
        
        offset = (offset + 1) % display_width(loop)
        time.sleep(SCROLL_DT)


if __name__ == "__main__":
    main()
