#!/bin/bash
# Color definitions for design
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

# Function to configure filesystem and security
configure_security() {

    echo -e "${CYAN}[INFO] Configuring filesystem options...${RESET}"

    # Backup sysctl.conf
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    echo -e "${CYAN}[INFO] Backup created: /etc/sysctl.conf.bak${RESET}"

    # Add recommended filesystem options
    echo -e "${CYAN}Do you want to add recommand filesystem options (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
        echo "fs.protected_fifos = 2" >> /etc/sysctl.conf
        echo "fs.protected_regular = 2" >> /etc/sysctl.conf
        echo "fs.protected_symlinks = 1" >> /etc/sysctl.conf
        echo "fs.protected_hardlinks = 1" >> /etc/sysctl.conf

        sysctl -p
        echo -e "${GREEN}[INFO] Filesystem options applied.${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}recommended filesystem options not added${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi

    # Add PAM lockout rules
    echo -e "${CYAN}Do you want to add PAM lockout rules (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        if ! grep -q "pam_faillock.so" /etc/pam.d/common-auth; then
            echo "auth required pam_faillock.so deny=3 unlock_time=600 onerr=fail" >> /etc/pam.d/common-auth
            echo "account required pam_faillock.so" >> /etc/pam.d/common-account
        fi
        echo -e "${GREEN}[INFO] PAM lockout rules applied.${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}PAM lockout rules not added${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi

    # Configure password policies
    echo -e "${CYAN}Do you want to add PAM lockout rules (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
        sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
        echo -e "${GREEN}[INFO] Password policies configured.${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}password policies not congigured${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi

    # Disable root login via SSH
    echo -e "${CYAN}Do you want to disable root login via SSH (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl restart sshd
        echo -e "${GREEN}[INFO] Root login via SSH disabled.${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}root login via SSH not disabled${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi

    # Record the action in the log file.
    local user_action=$1
    local username=$(whoami)
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_file="/var/log/admin_actions.log"

    echo "$timestamp - $username - $user_action" >> $log_file

    # Disable unused service accounts
    echo -e "${CYAN}Do you want to disable unused service accounts (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        echo -e "${CYAN}[INFO] Disabling unused service accounts...${RESET}"
        for user in $(getent passwd | awk -F: '{if ($3 >= 1000 && $7 != "/usr/sbin/nologin") print $1}'); do
            usermod -s /usr/sbin/nologin "$user"
        done
        echo -e "${GREEN}[INFO] Unused service accounts disabled.${RESET}"
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}Unused service accountsH not disabled${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi

    # Enable automatic screen lock
    echo -e "${CYAN}Do you want to enable automatic screen lock (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        echo -e "${CYAN}[INFO] Configuring automatic screen lock...${RESET}"
        if ! grep -q "
        readonly TMOUT" /etc/profile; then
            echo "readonly TMOUT=600" >> /etc/profile
            echo "export TMOUT" >> /etc/profile
            echo -e "${GREEN}[INFO] Automatic screen lock configured.${RESET}"
        else
            echo -e "${GREEN}[INFO] TMOUT is already configured.${RESET}"
        fi
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}Automatic screen lock not configured${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    while true; do
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${BLUE}*                Authentication Script Menu               *${RESET}"
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${WHITE}* 1) Update System                                       *${RESET}"
        echo -e "${WHITE}* 2) Configure Security                                  *${RESET}"
        echo -e "${WHITE}* 3) Exit                                                *${RESET}"
        echo -e "******************************************************************${RESET}"
        read -p "Select an option: " choice
        case $choice in
            1) update_system ;;
            2) configure_security ;;
            3) 
                echo -e "${CYAN}[INFO] Exiting the script...${RESET}"
                exit ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}" ;;
        esac
        echo -e "\nPress any key to return to the menu..."
        read -n 1 -s
    done
fi