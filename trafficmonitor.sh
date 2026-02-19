#!/bin/bash

# Configuration
JAIL="apache-auth"
THRESHOLD=30  # Maximum requests per minute before banning

sudo awk -v cutoff_epoch="$(date -d '1 hour ago' +%s)" ' \
     BEGIN {\
         split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month, " ");\
         for(i=1; i<=12; i++) m[month[i]]=i;\
     }\
     {\
         split(substr($4, 2), dt, ":");\
         split(dt[1], d, "/");\
         log_epoch = mktime(d[3] " " m[d[2]] " " d[1] " " dt[2] " " dt[3] " " dt[4]);\
         if (log_epoch >= cutoff_epoch) {\
#             print $1, substr($4, 2, 17);\
             formatted_dt = substr($4, 2, 11) "_" substr($4, 14, 5);\
             print $1, formatted_dt;\
         }\
     }' /var/log/apache2/access.log | sort | uniq -c | awk -v limit="$THRESHOLD" ' \
     {\
         if ($1 >= limit && !seen[$2]++) {\
             print $1, $2, $3\
         }\
     }' | while read count ip minute; do
    if [ -n "$ip" ]; then
        # Only report and ban if the IP is NOT already banned in this jail
        if ! sudo fail2ban-client status "$JAIL" | grep -Fq "$ip"; then
            echo "ALERT: $count requests from $ip during minute ${minute/_/ }. Triggering ban..."
            sudo fail2ban-client set "$JAIL" banip "$ip" > /dev/null 2>&1
        fi
    fi
done
