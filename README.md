# Restart Reminder Project

This repository provides scripts and resources to remind users to restart their macOS devices after extended uptime. Restarting regularly helps maintain performance, apply updates, and prevent issues.

## Included Files
- **scripts/restart_prompt_swiftdialog.sh**: Uses [SwiftDialog](https://github.com/bartreardon/swiftDialog) to display a modern, user-friendly prompt with two options:
  - **Reboot Now**: Immediately restarts the Mac.
  - **Try Later**: Dismisses the prompt without restarting.

  **Features:**
  - Displays a branded or default icon.
  - Falls back to an AppleScript dialog if SwiftDialog is not installed.
  - Can be run in Jamf policies with root privileges for seamless reboot.

- **scripts/restart_prompt_jamfhelper.sh**: Alternative script using Jamf Helper HUD window for restart reminders.

- **scripts/extension_attribute_uptime.sh**: Jamf Extension Attribute script that calculates system uptime in days. This is used to build Smart Groups for targeting devices that have been running for 14 days or more.

## How the SwiftDialog Script Works
1. Checks if SwiftDialog is installed.
2. If available, shows a dialog with **Reboot Now** and **Try Later** buttons.
3. If user clicks **Reboot Now**, the script attempts to restart the Mac using `/sbin/shutdown -r now`.
4. If SwiftDialog is missing, falls back to an AppleScript dialog that prompts for admin credentials to restart.

## Deployment Steps in Jamf

### 1. Upload Scripts
- Navigate to **Settings → Computer Management → Scripts**.
- Click **New** and upload `restart_prompt_swiftdialog.sh`.
- Optionally upload `restart_prompt_jamfhelper.sh` as an alternative.

### 2. Create Extension Attribute
- Go to **Settings → Computer Management → Extension Attributes**.
- Click **New**.
- Name: `Computer Uptime (Days)`.
- Input Type: **Script**.
- Paste contents of `extension_attribute_uptime.sh`.
- Save.

### 3. Create Smart Group
- Navigate to **Computers → Smart Computer Groups → New**.
- Name: `Uptime ≥ 14 Days`.
- Criteria: `Computer Uptime (Days)` **greater than** `14`.
- Save.

### 4. Create Policy
- Go to **Computers → Policies → New**.
- Name: `Restart Reminder`.
- Scope: Smart Group `Uptime ≥ 14 Days`.
- Trigger: **Check-in**.
- Frequency: **Once per day**.
- Payload: Add the restart script (`restart_prompt_swiftdialog.sh` or JamfHelper version).
- Save.

## Testing Tips
- Run the script locally with `DEBUG=true` to simulate behavior without reboot.
- Use a test Smart Group with a lower threshold (e.g., 1 day) for validation.

## Notes
- Ensure SwiftDialog is deployed to all Macs before using the SwiftDialog script.
- JamfHelper script requires Jamf binary and works without additional installs.

