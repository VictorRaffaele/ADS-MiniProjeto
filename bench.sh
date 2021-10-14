#!/usr/bin/env bash

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
else
	echo "Looks like you aren't running this installer on Debian or Ubuntu"
	exit
fi
if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo "Ubuntu 18.04 or higher is required to use this installer
This version of Ubuntu is too old and unsupported"
	exit
fi

if [[ "$os" == "debian" && "$os_version" -lt 10 ]]; then
	echo "Debian 10 or higher is required to use this installer
This version of Debian is too old and unsupported"
	exit
fi

# Check if user is root
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

# Check if the required packages are installed
if  [ ! -e '/usr/bin/wget' ] || [ ! -e '/usr/bin/fio' ] || [ ! -e '/usr/bin/curl' ] || [ ! -e '/usr/bin/jq' ]; then
    echo "Couldn't find [wget, fio, curl, jq]"    	
    read -n 1 -r -s -p  "Please press enter to install the required packages automatically" 
   
   apt update && apt install -y curl jq fio wget
fi

# Test IPv6 connectivity
ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
# Get public IP for ASN/ ISP check
as_check=$( wget -qO- -t1 -T2 icanhazip.com )


# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'


#
#
# FUNCTIONS
#
#

get_netinfo() {
    isp=$(curl -s http://ip-api.com/json/$as_check | jq '.isp' | sed 's/"//g')
    as=$(curl -s http://ip-api.com/json/$as_check | jq '.as' | sed 's/"//g')
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}
get_sys_type() {
    if [ $(systemd-detect-virt) == none ]; then 
            sys_type="Baremetal"
        elif [ $(systemd-detect-virt) == kvm ]; then
            sys_type="KVM"
        elif [ $(systemd-detect-virt) == lxc ]; then
            sys_type="LXC"
        elif [ $(systemd-detect-virt) == openvz ]; then
            sys_type="OpenVZ"
    fi
}

next() {
    printf "%-5s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    local output=$(LANG=C wget -O /dev/null -T30 $1 2>&1)
    local speedtest=$(printf '%s' "$output" | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
    local nodeName=$2
    printf "${YELLOW}%-32s${GREEN}%-24s${RED}%-14s${PLAIN}\n" "${nodeName}" "${speedtest}"
}

speed_result() {
    speed_test 'http://cachefly.cachefly.net/100mb.test' 'Cachefly CDN:'
    speed_test 'http://mirror.nl.leaseweb.net/speedtest/100mb.bin' 'Leaseweb (NL):'
    speed_test 'http://speedtest.dal06.softlayer.com/downloads/test100.zip' 'Softlayer DAL (US):'
    speed_test 'http://ping.online.net/100Mo.dat' 'Online.net (FR): '
    speed_test 'http://speedtest-bhs.as16276.ovh/files/100Mio.dat' 'OVH BHS (CA):'
}

cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
tram=$( free -m | awk '/Mem/ {print $2}' )
uram=$( free -m | awk '/Mem/ {print $3}' )
swap=$( free -m | awk '/Swap/ {print $2}' )
uswap=$( free -m | awk '/Swap/ {print $3}' )
up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
opsy=$( get_opsy )
arch=$( uname -m )
lbit=$( getconf LONG_BIT )
kern=$( uname -r )


clear
next
get_netinfo
get_sys_type
echo -e "System type          : ${BLUE}$sys_type${PLAIN}"
echo -e "CPU model            : ${BLUE}$cname${PLAIN}"
echo -e "Number of cores      : ${BLUE}$cores${PLAIN}"
echo -e "CPU frequency        : ${BLUE}$freq MHz${PLAIN}"
echo -e "Total size of Disk   : ${BLUE}$disk_total_size GB ($disk_used_size GB Used)${PLAIN}"
echo -e "Total amount of Mem  : ${BLUE}$tram MB ($uram MB Used)${PLAIN}"
echo -e "Total amount of Swap : ${BLUE}$swap MB ($uswap MB Used)${PLAIN}"
echo -e "System uptime        : ${BLUE}$up${PLAIN}"
echo -e "Load average         : ${BLUE}$load${PLAIN}"
echo -e "OS                   : ${BLUE}$opsy${PLAIN}"
echo -e "Arch                 : ${BLUE}$arch ($lbit Bit)${PLAIN}"
echo -e "Kernel               : ${BLUE}$kern${PLAIN}"
echo -e "ISP                  : ${BLUE}$isp${PLAIN}"
echo -e "ASN                  : ${BLUE}$as${PLAIN}"
if [[ "$ipv6" != "" ]]; then
echo -e "IPv6 Support         : ${BLUE}Yes${PLAIN}"
else
echo -e "IPv6 Support         : ${BLUE}No${PLAIN}"
fi
next

# Network speedtests
while [ TRUE ]
do

printf "%-32s%-24s%-14s\n" "Location" "Speed"
speed_result && next

done