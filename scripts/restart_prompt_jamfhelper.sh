#!/bin/bash
# Restart Reminder using Jamf Helper
# Adapted from GitHub project

JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
LOGO_PATH="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
TITLE="Restart Reminder"
HEADING="Please Restart Your Mac"
DESCRIPTION="Your Mac has been running for an extended period. Restarting helps maintain performance and reliability."

if [[ ! -x "$JAMF_HELPER" ]]; then
  echo "jamfHelper not found"
  exit 1
fi

response=$("$JAMF_HELPER" -windowType hud -title "$TITLE" -heading "$HEADING" -description "$DESCRIPTION" -icon "$LOGO_PATH" -button1 "Reboot Now" -button2 "Try Later" -defaultButton 2)

if [[ "$response" == "0" ]]; then
  /sbin/shutdown -r now
fi
