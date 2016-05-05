#!/bin/bash

SSH_CONNLIMIT=5
REDIRECT_FROM="127.0.0.1:8888"
REDIRECT_TO="10.0.0.252:80"
REDIRECT_USE_XINETD=0
EXT_NETWORK="10.0.0.*"

#----------------------------

# Initial checks
which iptables >/dev/null || {
    echo "iptables not found!"
    exit 1
}
which ip >/dev/null || {
    echo "iproute2 not found!"
    exit 1
}

# Get EXTIF, EXTIP
iface=(`ip addr |grep inet |grep $EXT_NETWORK |awk '{ print $NF, $2}'`)
EXTIF=${iface[0]}
EXTIP=${iface[1]%/*}

# Print configuration
    printf "    %-21s: %s\n" "External interface" ${EXTIF}
    printf "    %-21s: %s\n" "External IP address" ${EXTIP}

[ ${SSH_CONNLIMIT} -gt 0 ] && {
    printf "    %-21s: %s\n" "SSH connection limit" ${SSH_CONNLIMIT}
} || {
    printf "    %-21s: %s\n" "SSH connection limit" "${SSH_CONNLIMIT} (unlimited)"
}

[ ${REDIRECT_USE_XINETD} -eq 0 ] && {
    printf "    %-21s: %s\n" "Port redirection" "${REDIRECT_FROM} -> ${REDIRECT_TO}"
} || {
    printf "    %-21s: %s\n" "Port redirection" "xinetd (skipped)"
}

# Flush iptables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Disable connection tracking
iptables -t raw -A PREROUTING -j NOTRACK
iptables -t raw -A OUTPUT -j NOTRACK

# Accept lo traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow DNS resolver
iptables -A INPUT -p udp --dport 1024:65535 --sport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 1024:65535 --sport 53 -j ACCEPT

# Allow SSH response
iptables -A INPUT -p tcp --dport 1024:65535 --sport 22 -j ACCEPT

# Allow HTTP response
iptables -A INPUT -p tcp --dport 1024:65535 --sport 80 -j ACCEPT

# Accept inbound SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Set SSH connection limit (enables conntrack)
[ ${SSH_CONNLIMIT} -gt 0 ] && {
    iptables -I INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above ${SSH_CONNLIMIT} --connlimit-mask 0 -j REJECT --reject-with tcp-reset
    iptables -t raw -I PREROUTING -p tcp --dport 22 -j RETURN
}

# Accept inbound 8080
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# Port redirection (enables conntrack) 
[ ${REDIRECT_USE_XINETD} -eq 0 ] && {
    echo 1 > /proc/sys/net/ipv4/conf/all/route_localnet
    iptables -t nat -A OUTPUT -d ${REDIRECT_FROM%:*} -p tcp --dport ${REDIRECT_FROM#*:} -j DNAT --to-destination ${REDIRECT_TO}
    iptables -t nat -A POSTROUTING -o ${EXTIF} -s 127.0.0.0/8 -j SNAT --to-source ${EXTIP}
    [[ $REDIRECT_FROM =~ ^127 ]] && CHAIN_FROM="OUTPUT" || CHAIN_FROM="PREROUTING"
    [[ $REDIRECT_TO =~ ^127 ]] && CHAIN_TO="OUTPUT" || CHAIN_TO="PREROUTING"
    iptables -t raw -I ${CHAIN_FROM} -d ${REDIRECT_FROM%:*} -p tcp --dport ${REDIRECT_FROM#*:} -j RETURN
    iptables -t raw -I ${CHAIN_TO} -s ${REDIRECT_TO%:*} -p tcp --sport ${REDIRECT_TO#*:} -j RETURN
}

# Set  policy
iptables -P INPUT DROP

