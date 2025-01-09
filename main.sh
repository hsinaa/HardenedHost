#!/bin/bash
# Colors for clearer messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Function to update the system
update_system() {
    echo -e "\n${CYAN}[INFO] Do you want to update the system? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        echo -e "${YELLOW}Updating system...${RESET}"
        sudo apt update && sudo apt upgrade -y
        echo -e "${GREEN}[INFO] The system has been updated successfully.${RESET}"
    else
        echo -e "${RED}[INFO] The system update has been skipped.${RESET}"
    fi
}

show_static_modules() {
    echo -e "${YELLOW}Available Modules :${RESET}"
    echo "1. Authentication"
    echo "2. Filesystem"
    echo "3. Kernel"
    echo "4. Material"
    echo "5. Partition"
    echo "6. Network"
    echo -e "${BLUE}Do you confirm to statically harden your system (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        echo -e "${CYAN}[INFO] Calling script auth.sh...${RESET}"
        bash auth.sh
        echo -e "${GREEN}[INFO] Authentication script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script filesystem.sh...${RESET}"
        bash FileSystem.sh
        echo -e "${GREEN}[INFO] Filesystem script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script kernel.sh...${RESET}"
        bash kernel.sh
        echo -e "${GREEN}[INFO] Kernel script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script material.sh...${RESET}"
        bash material.sh
        echo -e "${GREEN}[INFO] Material script finished...${RESET}"
        
        echo -e "${CYAN}[INFO] Calling script partition.sh...${RESET}"
        bash partition.sh
        echo -e "${GREEN}[INFO] Partition script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script network.sh...${RESET}"
        bash network.sh
        echo -e "${GREEN}[INFO] network script finished...${RESET}"
        echo -e "${GREEN}[INFO] Static hardening completed successfully.${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}System not statically hardened${RESET}"
    else
        echo -e "${RED}[ERROR] Invalid input.${RESET}"
    fi
}

show_dynamic_modules() {
    echo -e "${YELLOW}Available Modules :${RESET}"
    echo "1. Authentication"
    echo "2. Filesystem"
    echo "3. Kernel"
    echo "4. Material"
    echo "5. Partition"
    echo "6. Network"
    echo -e "${BLUE}Do you confirm to dynamically harden your system (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        
        # Create a report file
        REPORT_FILE="Hardening_report.log"
        touch "$REPORT_FILE"
        echo -e "${BLUE}****************************************************${RESET}" > $REPORT_FILE
        echo -e "${BLUE}*       Centralized Dynamic Hardening Report       *${RESET}" >> $REPORT_FILE
        echo -e "${BLUE}*--------------------------------------------------*${RESET}" >> $REPORT_FILE
        echo -e "${WHITE}*                   "Date: $(date)"               *${RESET}" >> $REPORT_FILE   
        echo -e "${BLUE}****************************************************${RESET}" >> $REPORT_FILE
        echo "  " >> $REPORT_FILE
        echo "  " >> $REPORT_FILE

        echo -e "${CYAN}[INFO] Calling script auth-dynamic.sh...${RESET}"
        bash auth-dynamic.sh
        echo -e "${GREEN}[INFO] Authentication script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script FS-dynamic.sh...${RESET}"
        bash FS-dynamic.sh
        echo -e "${GREEN}[INFO] Filesystem script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script kernel-dynamic.sh...${RESET}"
        bash kernel-dynamic.sh
        echo -e "${GREEN}[INFO] Kernel script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script material-dynamic.sh...${RESET}"
        bash material-dynamic.sh
        echo -e "${GREEN}[INFO] Material script finished...${RESET}"
        
        echo -e "${CYAN}[INFO] Calling script partition-dynamic.sh...${RESET}"
        bash partition-dynamic.sh
        echo -e "${GREEN}[INFO] Partition script finished...${RESET}"

        echo -e "${CYAN}[INFO] Calling script network-dynamic.sh...${RESET}"
        bash network-dynamic.sh
        echo -e "${GREEN}[INFO] Network script finished...${RESET}"
        echo -e "${GREEN}[INFO] Dynamic hardening completed successfully.${RESET}"
        echo -e "${GREEN}Report saved to $REPORT_FILE${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}System not dynamically hardened${RESET}"
    else
        echo -e "${RED}[ERROR] Invalid input.${RESET}"
    fi
}

# Function to check system status
check_system_status() {
    echo -e "${CYAN}Security measures applied... Please wait while we check your system status.${RESET}"

    # Display logged in users
    echo -e "${YELLOW}Logged in users:${RESET}"
    who

    # Display system uptime
    echo -e "${YELLOW}Uptime:${RESET}"
    uptime

    # Display disk usage
    echo -e "${YELLOW}Disk usage:${RESET}"
    df -h

    # Display memory usage
    echo -e "${YELLOW}Memory usage:${RESET}"
    free -h

    # Check for critical services
    echo -e "${YELLOW}Checking critical services:${RESET}"
    services=("ssh" "apache2" "nginx" "mysql")
    for service in "${services[@]}"; do
        systemctl is-active --quiet $service && echo -e "${GREEN}$service is running.${RESET}" || echo -e "${RED}$service is not running.${RESET}"
    done

    # Check for kernel version
    echo -e "${YELLOW}Kernel version:${RESET}"
    uname -r

    # Check for system updates
    echo -e "${YELLOW}Checking for system updates:${RESET}"
    if command -v apt &> /dev/null; then
        apt list --upgradable 2>/dev/null | grep -v "Listing" || echo -e "${GREEN}No updates available.${RESET}"
    elif command -v yum &> /dev/null; then
        yum check-update || echo -e "${GREEN}No updates available.${RESET}"
    fi

    # Check open ports
    echo -e "${YELLOW}Open ports:${RESET}"
    netstat -tuln | grep LISTEN

    # Check firewall status
    echo -e "${YELLOW}Firewall status:${RESET}"
    if command -v ufw &> /dev/null; then
        ufw status
    elif command -v iptables &> /dev/null; then
        iptables -L
    else
        echo -e "${RED}No firewall tool detected.${RESET}"
    fi

    # Display top resource-consuming processes
    echo -e "${YELLOW}Top 5 resource-consuming processes:${RESET}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6

    # Users with root privileges
    echo -e "${YELLOW}Users with root privileges:${RESET}"
    awk -F: '$3 == 0 {print $1}' /etc/passwd

    # Check critical file permissions
    echo -e "${YELLOW}Critical file permissions:${RESET}"
    ls -l /etc/passwd /etc/shadow /etc/sudoers

    # Check active SSH sessions
    echo -e "${YELLOW}Active SSH sessions:${RESET}"
    who | grep 'pts'

    # Check swap usage
    echo -e "${YELLOW}Swap usage:${RESET}"
    swapon --show
}


if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] This script must be run as root.${RESET}"
    exit 1
else
    echo -e "${BLUE}********************************************************************************${RESET}"
    echo -e "${BLUE}*                                                                              *${RESET}"
    echo -e "${BLUE}*    ██   ██ ███████ █████   █████  ███████ ███    ██ ███████ █████            *${RESET}"
    echo -e "${BLUE}*    ██   ██ ██   ██ ██   █  █    █ ██      ██ █   ██ ██      █    █           *${RESET}"
    echo -e "${BLUE}*    ███████ ███████ █████   █    █ ██████  ██  █  ██ ██████  █    █           *${RESET}"
    echo -e "${BLUE}*    ██   ██ ██   ██ ██   █  █    █ ██      ██   █ ██ ██      █    █           *${RESET}"
    echo -e "${BLUE}*    ██   ██ ██   ██ ██   █  █████  ███████ ██    ███ ███████ █████            *${RESET}"
    echo -e "${BLUE}*                                                                              *${RESET}"
    echo -e "${BLUE}*                      ██   ██  █████   ██████  ███████                        *${RESET}"
    echo -e "${BLUE}*                      ██   ██ █     █ █        █  █  █                        *${RESET}"
    echo -e "${BLUE}*                      ███████ █     █ ███████     █                           *${RESET}"
    echo -e "${BLUE}*                      ██   ██ █     █       █     █                           *${RESET}"
    echo -e "${BLUE}*                      ██   ██  █████  ██████      █                           *${RESET}" 
    echo -e "${BLUE}*                                                                              *${RESET}"
    echo -e "${BLUE}*                                                                              *${RESET}"
    echo -e "${BLUE}*********************************************************************************${RESET}"
    while true; do
        echo -e "${WHITE}1) Update System ${RESET}"
        echo -e "${WHITE}2) Static Hardening ${RESET}"
        echo -e "${WHITE}3) Dynamic Hardening ${RESET}"
        echo -e "${WHITE}4) check_system_status ${RESET}"
        echo -e "${WHITE}5) Exit      ${RESET}"
        read -p "Select an option: " module_type
        case $module_type in
            1) update_system ;;
            2) show_static_modules ;;
            3) show_dynamic_modules ;;
            4) check_system_status ;;
            5) echo -e "${CYAN}[INFO] Exiting script...${RESET}"
               exit ;;
            *) echo -e "${RED}[ERROR] Invalid option. Please try again.${RESET}" ;;
        esac
    done
fi
