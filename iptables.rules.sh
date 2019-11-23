#!/bin/bash

ifname=`cat /proc/net/dev | awk -F: 'function trim(str){sub(/^[ \t]*/,"",str); sub(/[ \t]*$/,"",str); return str } NR>2 {print trim($1)}'  | grep -Ev '^lo|^sit|^stf|^gif|^dummy|^vmnet|^vir|^gre|^ipip|^ppp|^bond|^tun|^tap|^ip6gre|^ip6tnl|^teql|^ocserv' | awk 'NR==1 {print $0}'`
[ -n "$ifname" ] || exit 1
DIR=`dirname "$0"`
TCP=`cat "${DIR}/ocserv.conf" |grep '#\?tcp-port' |cut -d"=" -f2 |sed 's/\s//g'`
UDP=`cat "${DIR}/ocserv.conf" |grep '#\?udp-port' |cut -d"=" -f2 |sed 's/\s//g'`
IPV4_NET=`cat "${DIR}/ocserv.conf" |grep '#\?ipv4-network' |cut -d"=" -f2 |sed 's/\s//g'`

iptables -t nat -A POSTROUTING -s  ${IPV4_NET}/24 -o ${ifname} -j MASQUERADE
[ -n "$TCP" ] && iptables -I INPUT -p tcp --dport ${TCP} -j ACCEPT
[ -n "$UDP" ] && iptables -I INPUT -p udp --dport ${UDP} -j ACCEPT
iptables -A FORWARD -s ${IPV4_NET}/24 -j ACCEPT
iptables -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -A FORWARD -o vpns+ -j ACCEPT
iptables -A FORWARD -i vpns+ -j ACCEPT
