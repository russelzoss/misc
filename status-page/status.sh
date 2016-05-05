#!/bin/bash

MOUNT="/ /opt"
SYSLOG_FILES="/var/log/messages*"
SYSLOG_COUNT=10
STATUS_FILE="/srv/www/status/status.html"

exec > $STATUS_FILE

# Format output
fprint() {
    printf "%25s: %s\n" "$1" "$2"
}

# Uptime
UPTIME=`uptime |cut -d, -f1 |sed 's/ \+/ /g' |cut -d" " -f4-`
fprint "Uptime" "$UPTIME"

# Memory
MEM_TOTAL=`cat /proc/meminfo |awk '/^MemTotal:/ {print $2}'`
MEM_FREE=`cat /proc/meminfo |awk '/^MemFree:/ {print $2}'`
MEM_USED=$(($MEM_TOTAL - $MEM_FREE))
fprint "Memory free/used" "$MEM_FREE/$MEM_USED kB"

# Disk spece per mount
for m in $MOUNT; do
    DISK=(`df $m |awk '/^\//{print $3,$4}'`)
    fprint "Disk ($m) free/used" "${DISK[1]}/${DISK[0]} kB"
done

# Kernel version
KERNEL=`uname -r`
fprint "Kernel version" "$KERNEL"

# Syslog messages (last SYSLOG_COUNT lines)
# Take care of truncated logs
echo
fprint "Syslog messages" ""
MSG="" 
msg_add_count=$SYSLOG_COUNT
for syslog_file in $SYSLOG_FILES; do
    file $syslog_file |grep -q "compressed data" && CAT="xzcat" || CAT="cat"
    MSG="$MSG`$CAT $syslog_file |tail -n $msg_add_count`"
    msg_count=`echo "$MSG" |wc -l |awk '{print $1}'`
    msg_add_count=$(($SYSLOG_COUNT-$msg_count))
    [ $msg_add_count -le 0 ] && break 2
done
echo "$MSG"

# Network connections (ESTABLISHED)
echo
fprint "Network connections" ""
netstat -ntp |grep ESTABLISHED
