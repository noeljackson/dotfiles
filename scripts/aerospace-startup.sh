#!/bin/bash
# AeroSpace startup - creates windows then moves/arranges them

log() { echo "[$(date +%H:%M:%S)] $1"; }

# Track windows we've already seen
SEEN_FILE="/tmp/aerospace-seen-windows"
> "$SEEN_FILE"

get_new_window() {
    local app_id="$1"
    local seen=$(cat "$SEEN_FILE" 2>/dev/null)
    local all_wids=$(aerospace list-windows --all --app-bundle-id "$app_id" --format '%{window-id}' 2>/dev/null)

    for wid in $all_wids; do
        if ! echo "$seen" | grep -q "^${wid}$"; then
            echo "$wid"
            echo "$wid" >> "$SEEN_FILE"
            return 0
        fi
    done
    return 1
}

open_and_move_iterm() {
    local target_ws="$1"
    log "Creating iTerm for ws $target_ws"

    # Mark existing windows as seen
    aerospace list-windows --all --app-bundle-id com.googlecode.iterm2 --format '%{window-id}' >> "$SEEN_FILE" 2>/dev/null

    osascript -e 'tell application "iTerm" to create window with default profile'
    sleep 1

    local wid=$(get_new_window "com.googlecode.iterm2")
    if [ -n "$wid" ]; then
        log "  -> window $wid moving to ws $target_ws"
        aerospace move-node-to-workspace --window-id "$wid" "$target_ws"
    else
        log "  -> ERROR: no new window detected"
    fi
}

open_and_move_brave() {
    local target_ws="$1"
    log "Creating Brave for ws $target_ws"

    # Mark existing windows as seen
    aerospace list-windows --all --app-bundle-id com.brave.Browser --format '%{window-id}' >> "$SEEN_FILE" 2>/dev/null

    osascript -e 'tell application "Brave Browser" to make new window'
    sleep 1

    local wid=$(get_new_window "com.brave.Browser")
    if [ -n "$wid" ]; then
        log "  -> window $wid moving to ws $target_ws"
        aerospace move-node-to-workspace --window-id "$wid" "$target_ws"
    else
        log "  -> ERROR: no new window detected"
    fi
}

arrange_workspace() {
    local ws="$1"
    log "Arranging workspace $ws"
    aerospace workspace "$ws"
    sleep 0.5

    # Get windows
    iterm_wids=($(aerospace list-windows --workspace "$ws" --app-bundle-id com.googlecode.iterm2 --format '%{window-id}'))
    brave_wid=$(aerospace list-windows --workspace "$ws" --app-bundle-id com.brave.Browser --format '%{window-id}' | head -1)

    log "  Found ${#iterm_wids[@]} iTerm, brave=$brave_wid"

    if [ ${#iterm_wids[@]} -lt 4 ]; then
        log "  Not enough iTerm windows, skipping arrange"
        return
    fi

    # Move iTerm[2] and iTerm[3] down to create bottom row
    aerospace focus --window-id "${iterm_wids[2]}"
    sleep 0.1
    aerospace move down
    sleep 0.2

    aerospace focus --window-id "${iterm_wids[3]}"
    sleep 0.1
    aerospace move down
    sleep 0.2

    # Move Brave to right edge
    if [ -n "$brave_wid" ]; then
        aerospace focus --window-id "$brave_wid"
        sleep 0.1
        aerospace move right
        aerospace move right
        sleep 0.2
    fi
}

log "=== Starting ==="
> "$SEEN_FILE"

# Launch apps
log "Launching apps..."
open -a "iTerm"
open -a "Brave Browser"
sleep 2

# Create windows: for each workspace, 1 Brave + 4 iTerm
for ws in 1 2 3 4; do
    log "--- Creating windows for workspace $ws ---"
    open_and_move_brave "$ws"
    open_and_move_iterm "$ws"
    open_and_move_iterm "$ws"
    open_and_move_iterm "$ws"
    open_and_move_iterm "$ws"
done

sleep 2

# Arrange each workspace
for ws in 1 2 3 4; do
    arrange_workspace "$ws"
done

aerospace workspace 1
log "=== Complete ==="
