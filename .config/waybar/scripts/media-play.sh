#!/usr/bin/env bash
status=$(playerctl status 2>/dev/null || echo Stopped)
class=$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')
printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"Play / Pause"}\n' \
    "$status" "$status" "$class"
