#!/bin/bash

# Get the timestamp for 24 hours ago in epoch format
CUTOFF_EPOCH=$(date -d '24 hours ago' +%s)

# Extract banned IPs and their jails from fail2ban.log within the last 24 hours
sudo grep -E 'fail2ban.actions.*\[.*\] (Ban|Drop)' /var/log/fail2ban.log | \
awk -v cutoff_epoch="$CUTOFF_EPOCH" '
     BEGIN {
         FS="[ ,|]"; # Split by space, comma, or pipe
     }
     {
         # Extract date and time parts
         split($1, date_parts, "-");
         split($2, time_parts, ":");
         
         # Convert YYYY-MM-DD HH:MM:SS to epoch
         log_epoch = mktime(date_parts[1]" "date_parts[2]" "date_parts[3]" "time_parts[1]" "time_parts[2]" "time_parts[3]);
         
         if (log_epoch >= cutoff_epoch) {
             # Look for the jail name and IP address
             jail = "unknown"
             ip = ""
             for (i=1; i<=NF; i++) {
                 # Capture jail name from [jail-name]
                 if ($i ~ /^\[.*\]$/) {
                     jail = substr($i, 2, length($i)-2)
                 }
                 if (($i == "Ban" || $i == "Drop") && ($(i+1) ~ /^[0-9a-fA-F:.]+$/)) {
                     ip = $(i+1);
                     if (ip != "" && jail != "") {
                         print jail, ip;
                         break;
                     }
                 }
             }
         }
     }' | sort -u | while read jail ip; do
    # Fetch country information for each IP
    country=$(curl -s -m 5 "https://ipinfo.io/$ip/country" || echo "??")
    country=$(echo "$country" | tr -d '\n')
    echo "$ip ($country) [$jail]"
done

