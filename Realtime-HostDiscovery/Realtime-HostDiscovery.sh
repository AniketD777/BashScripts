#!/bin/bash

HOSTSFILE="alive-hosts.txt"
NETRANGE="$1"
INTERFACE="$2"
FROM_EMAIL="sender@test.com"
TO_EMAIL="receiver@test.com"

if [[ ! -f ${HOSTSFILE} ]]; then
    touch ${HOSTSFILE};
fi

if [[ ! ${NETRANGE} ]]; then
    echo "[-] IP block range not specified."; 
    echo "Usage Example: $0 172.16.5.0/24 [INTERFACE]"; # Interface not mandatory. In arp-scan we can specify the interface too.
    exit 1
fi

while true; do
    echo "[*] Performing ARP scan against ${NETRANGE}..."
    # Build the base arp-scan command options
    ARP_SCAN_CMD="sudo arp-scan -x ${NETRANGE}"

    # Check if the INTERFACE variable is set. 
    # If it is, append the -I option and its value to the command string.
    if [[ -n ${INTERFACE} ]]; then
        ARP_SCAN_CMD+=" -I ${INTERFACE}"
    fi
    
    ${ARP_SCAN_CMD} | while read -r line; do # -x option to get output in plaintext which is better for parsing the output.
            ip=$(echo ${line} | awk '{print $1}');
            if ! grep -q -e "^${ip}$" ${HOSTSFILE}; then # -q for quiet mode to avoid any output
                echo ${ip} >> ${HOSTSFILE};
                # Time to alert the user via a mail notification
                sendemail -f "${FROM_EMAIL}" \
                -t "${TO_EMAIL}" \
                -u "ARP Scan Notification" \
                -m "A new host was discovered: ${ip}";
            fi
        done

    # Remove the dead hosts from list
    while read -r line; do
        ip=$(echo ${line} | awk '{print $1}');
        if ! ping -c 1 ${ip} > /dev/null; then
            sed -i "s/^${ip}$//g" ${HOSTSFILE};
            sed -i '/^$/d' ${HOSTSFILE}; # Remove empty lines
        fi
    done < ${HOSTSFILE}

    sleep 10; # Time interval for scan in seconds.
done
