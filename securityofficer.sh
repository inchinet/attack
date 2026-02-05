#!/bin/bash

# Define the jail to use for banning
JAIL="apache-auth"

# Look for suspicious authentication failures or specific attack patterns in logs
# This script can be customized to grep for specific 403/404 patterns
sudo awk -v cutoff_epoch="$(date -d '24 hours ago' +%s)" ' \
     BEGIN {\
         split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month, " ");\
         for(i=1; i<=12; i++) m[month[i]]=i;\
     }\
     {\
         split(substr($4, 2), dt, ":");\
         split(dt[1], d, "/");\
         log_epoch = mktime(d[3] " " m[d[2]] " " d[1] " " dt[2] " " dt[3] " " dt[4]);\
         if (log_epoch >= cutoff_epoch) {\
             print $1, substr($4, 2, 17);\
         }\
     }' /var/log/apache2/access.log | sort | uniq -c | awk ' \
     {\
         if ($1 >= 100) {\
             print $1, $2, $3\
         }\
     }' | while read count ip minute; do
    echo "SECURITY ALERT: $count suspicious requests from $ip. Triggering ban..."
    sudo fail2ban-client set "$JAIL" banip "$ip" > /dev/null 2>&1
done
