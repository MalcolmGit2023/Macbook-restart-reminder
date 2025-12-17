
#!/bin/bash
# Restart Prompt via SwiftDialog (generic, no heredocs)
# Shows "Try later" and "Reboot Now".
# Scope via Jamf Smart Group for extended uptime (e.g., >= 14 days).

set -euo pipefail

# -----------------------
# Configuration
# -----------------------
DIALOG_BIN="/usr/local/bin/dialog"
LOGO_PATH="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
LOG_FILE="/var/tmp/restart_prompt.log"
TITLE="Important Message: Restart Needed"
DESCRIPTION="Your Mac has been running for an extended period. Restarting helps maintain performance and reliability.

Click **Reboot Now** to restart, or **Try later** to dismiss this reminder."
BUTTON1="Reboot Now"
BUTTON2="Try later"

# Optional grace period (seconds) before reboot, to let users save work
SAVE_GRACE_SECONDS="180"   # set to "0" to skip grace
DEBUG=${DEBUG:-false}

# -----------------------
# Logging
# -----------------------
log() { printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE" >/dev/null; }

# -----------------------
# Save grace prompt (SwiftDialog countdown or sleep)
# -----------------------
save_grace_prompt() {
  local seconds="$1"
  if [[ "$seconds" -gt 0 ]]; then
    if [[ -x "$DIALOG_BIN" ]]; then
      "$DIALOG_BIN" \
        --title "Restart Imminent" \
        --message "Your Mac will restart in approximately $(($seconds/60)) minute(s). Please save open documents now." \
        --icon "$LOGO_PATH" \
        --moveable \
        --button1text "Restart Now" \
        --timer "$seconds" \
        --commandfile /dev/null \
        >/dev/null 2>&1 || true
    else
      sleep "$seconds"
    fi
  fi
}

# -----------------------
# Perform reboot
# -----------------------
do_reboot() {
  if [[ "$DEBUG" == "true" ]]; then
    log "DEBUG enabled: reboot simulated (not executed)."
    return 0
  fi

  log "Attempting reboot (launchctl)..."
  if launchctl reboot system >/dev/null 2>&1; then
    return 0
  fi

  log "launchctl reboot failed; attempting shutdown..."
  if /sbin/shutdown -r now >/dev/null 2>&1; then
    return 0
  fi

  log "shutdown failed or requires privileges; attempting AppleScript..."
  /usr/bin/osascript \
    -e 'do shell script "/sbin/shutdown -r now" with administrator privileges' >/dev/null 2>&1 || {
      log "AppleScript reboot attempt failed."
      return 1
    }
}

# -----------------------
# Main
# -----------------------
log "Prompt started."

# If SwiftDialog missing, fall back to a simple AppleScript (no heredoc)
if [[ ! -x "$DIALOG_BIN" ]]; then
  log "SwiftDialog not found at $DIALOG_BIN; presenting minimal AppleScript dialog."
  /usr/bin/osascript \
    -e 'set dlgText to "Your Mac has been running for an extended period. Restarting helps maintain performance and reliability.\n\nClick Reboot Now to restart, or Try later to dismiss this reminder."' \
    -e 'display dialog dlgText buttons {"Try later", "Reboot Now"} default button "Try later" with icon caution with title "Restart Needed"' \
    -e 'set theButton to button returned of result' \
    -e 'if theButton is "Reboot Now" then do shell script "/sbin/shutdown -r now" with administrator privileges' \
    >/dev/null 2>&1 || true
  log "Prompt completed via AppleScript fallback."
  exit 0
fi

# Show SwiftDialog
"$DIALOG_BIN" \
  --title "$TITLE" \
  --message "$DESCRIPTION" \
  --icon "$LOGO_PATH" \
  --button1text "$BUTTON1" \
  --button2text "$BUTTON2" \
  --height "329" \
  --width "575" \
  --moveable \
  --ontop >/dev/null 2>&1
response=$?  # 0=button1, 2=button2, 3=closed, 10=timer

case "$response" in
  0)
    log "User selected: $BUTTON1"
    if [[ "$SAVE_GRACE_SECONDS" =~ ^[0-9]+$ ]] && [[ "$SAVE_GRACE_SECONDS" -gt 0 ]]; then
      log "Showing save grace prompt for $SAVE_GRACE_SECONDS seconds."
      save_grace_prompt "$SAVE_GRACE_SECONDS"
    fi
    if ! do_reboot; then
      log "ERROR: Reboot attempts failed."
      exit 1
    fi
    ;;
  2)
    log "User selected: $BUTTON2 (Try later). No action."
    ;;
  3|10)
    log "Dialog closed or timed out. No action."
    ;;
   *)
    log "Unexpected exit code: $response. No action."
    ;;
esac
