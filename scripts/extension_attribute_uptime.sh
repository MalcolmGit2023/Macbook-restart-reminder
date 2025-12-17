#!/bin/bash
# EA: Uptime in Days
boot_epoch=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
uptime_days=$(( ( $(date +%s) - boot_epoch ) / 86400 ))
echo "<result>${uptime_days}</result>"
