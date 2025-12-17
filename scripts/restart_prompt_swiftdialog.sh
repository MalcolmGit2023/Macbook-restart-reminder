#!/bin/bash
# Restart Prompt using SwiftDialog
# Shows Reboot Now and Try Later buttons
# Generic version without company branding

DIALOG_BIN="/usr/local/bin/dialog"
LOGO_PATH="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
TITLE="Restart Needed"
DESCRIPTION="Your Mac has been running for an extended period. Restarting helps maintain performance and reliability.

Click Reboot Now to restart, or Try Later to dismiss this reminder."
BUTTON1="Reboot Now"
BUTTON2="Try Later"

if [[ ! -x "$DIALOG_BIN" ]]; then
  /usr/bin/osascript <<'EOF'
  display dialog "Your Mac has been running for an extended period. Restarting helps maintain performance and reliability." buttons {"Try Later", "Reboot Now"} default button "Try Later" with icon caution with title "Restart Needed"
  set theButton to button returned of result
  if theButton is "Reboot Now" then
    do shell script "/sbin/shutdown -r now" with administrator privileges
  end if
EOF
  exit 0
fi

"$DIALOG_BIN" --title "$TITLE" --message "$DESCRIPTION" --icon "$LOGO_PATH" --button1text "$BUTTON1" --button2text "$BUTTON2"
response=$?
if [[ "$response" == "0" ]]; then
  /sbin/shutdown -r now
fi
