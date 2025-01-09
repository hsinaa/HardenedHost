#!/bin/bash
# Define colors for styling
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

# Function to install a package
install_package() {
    package_name=$1
    if ! dpkg -l | grep -q "$package_name"; then
        echo -e "${CYAN}Installing $package_name...${RESET}"
        if sudo apt install -y "$package_name"; then
            echo -e "${GREEN}$package_name installed successfully.${RESET}"
            return 0
        else
            echo -e "${RED}Failed to install $package_name.${RESET}"
            return 1
        fi
    else
        echo -e "${GREEN}$package_name is already installed.${RESET}"
        return 0
    fi
}


# Function to configure security
configure_security() {
    echo -e "${CYAN}Starting security configuration...${RESET}"
    
    # Secure /etc/fstab
    echo -e "${CYAN}Securing /etc/fstab...${RESET}"
    grep -q "tmpfs /tmp" /etc/fstab || echo "tmpfs /tmp tmpfs defaults,noexec,nodev,nosuid 0 0" >> /etc/fstab
    echo "/var /var ext4 defaults,nodev 0 0" >> /etc/fstab
    echo "/home /home ext4 defaults,nodev,nosuid 0 0" >> /etc/fstab
    echo "Securing /etc/fstab completed."

    # Configure permissions for sensitive files
    echo -e "${CYAN}Configuring permissions for sensitive files...${RESET}"
    chmod 600 /etc/shadow
    chmod 644 /etc/passwd
    chmod -R o-rwx /root
    chmod 700 /boot
    echo -e "${GREEN}Sensitive files permissions configured.${RESET}"

    # Enable logging for administrative actions
    echo "Enabling logging for administrative actions..."
    echo 'Defaults log_output' | sudo EDITOR='tee -a' visudo
    echo -e "${GREEN}[INFO] File editing secured with sudo.${RESET}"
    

    
   # Audit sensitive files
    echo -e "${CYAN}Auditing sensitive files...${RESET}"
    find / -xdev \( -path /proc -o -path /run -o -path /sys \) -prune -o \( -nouser -o -nogroup \) -exec ls -l {} \; > /var/log/sensitive_files_audit.log 2>/dev/null
    echo "${GREEN}Audit completed. Results saved in /var/log/sensitive_files_audit.log.${RESET}"

    # Disable unused filesystems
    echo -e "${CYAN}Disabling unused filesystems...${RESET}"
    echo "install cramfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
    echo "install squashfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
    echo "install udf /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
    echo "Disabling unused filesystems completed."

    # Modify the default UMASK value
    echo -e "${CYAN}Modifying UMASK default value...${RESET}"
    sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
    echo "UMASK value set to 027."

    # Create a dedicated sudo group
    echo -e "${CYAN}Creating a dedicated sudo group...${RESET}"
    groupadd -f sudoers
    echo "%sudoers ALL=(ALL:ALL) ALL" >> /etc/sudoers
    echo "Dedicated sudo group created."

    # Secure file editing with sudo
    #echo "Defaults editor=/usr/bin/vi" >> /etc/sudoers
    echo "Defaults editor=/usr/bin/vi" | sudo EDITOR='tee -a' visudo
    echo -e "${GREEN}[INFO] File editing secured with sudo.${RESET}"

    # Limit EXEC directive usage
    echo -e "${CYAN}Limiting usage of commands requiring EXEC directive...${RESET}"
    #echo 'Cmnd_Alias NOEXEC = /bin/sh, /bin/bash' >> /etc/sudoers
    echo 'Cmnd_Alias NOEXEC = /bin/sh, /bin/bash' | sudo EDITOR='tee -a' visudo
    #echo 'Defaults!NOEXEC noexec' >> /etc/sudoers
    echo 'Defaults!NOEXEC noexec' | sudo EDITOR='tee -a' visudo
    echo "EXEC directive usage limited."

    # Configure SELinux or AppArmor
    echo -e "${BLUE}Which security module would you like to activate: SELinux or AppArmor?${RESET}"
    read -p "Enter your choice: " option

    if [[ "$option" == "SELinux" || "$option" == "selinux" ]]; then
        # Enable SELinux
        echo -e "${CYAN}Activating SELinux......${RESET}"
        if install_package "selinux-basics"; then
            if install_package "selinux-policy-default"; then
                if install_package "auditd"; then
                    sudo selinux-activate
                    sudo selinux-config-enforcing
                    echo "SELinux has been activated and configured in 'enforcing' mode. A reboot is required."
                fi
            fi
        fi   
    elif [[ "$option" == "AppArmor" || "$option" == "apparmor" ]]; then
        # Enable AppArmor
        echo -e "${CYAN}Activating AppArmor......${RESET}"
        if install_package "apparmor apparmor-utils"; then 
            sudo systemctl enable apparmor
            sudo systemctl start apparmor
            echo "AppArmor has been activated and is now running."
        fi
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi

    # Audit sensitive files
    echo -e "${BLUE}Do you want to install auditd (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        if install_package "auditd"; then
            auditctl -w /etc/passwd -p wa -k passwd_changes
            auditctl -w /etc/shadow -p wa -k shadow_changes
            auditctl -w /boot -p wa -k boot_changes
            echo -e "${GREEN}[INFO] File auditing enabled.${RESET}"
        fi
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}auditd was not installed${RESET}"
    else
        echo -e "${RED}Invalid input.${RESET}"
    fi
    
    # Avoid files or directories without known user or group
    echo -e "${BLUE}Auditing files without a known user or group...${RESET}"
    find / -xdev \( -path /proc -o -path /run -o -path /sys \) -prune -o \( -nouser -o -nogroup \) -exec ls -l {} \; 2>/dev/null
    echo "Audit completed."


    # Enable the sticky bit on writable directories
    echo -e "${BLUE}Enabling sticky bit on writable directories...${RESET}"
    find / -xdev \( -path /proc -o -path /run -o -path /sys \) -prune -o -type d -perm -002 -exec chmod +t {} \; 2>/dev/null
    echo "Sticky bit enabled on writable directories."

    # Audit executables with setuid and setgid
    echo -e "${BLUE}Auditing executables with setuid and setgid...${RESET}"
    find / -xdev \( -path /proc -o -path /run -o -path /sys \) -prune -o -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; 2>/dev/null
    echo "Audit completed."

    # Audit executables with setuid root and setgid root
    echo -e "${BLUE}Auditing executables with setuid root and setgid root...${RESET}"
    find / -xdev \( -path /proc -o -path /run -o -path /sys \) -prune -o -type f \( -perm -4000 -o -perm -2000 \) -user root -exec ls -l {} \; 2>/dev/null
    echo "Audit completed."

    # Fonction pour activer AIDE
    echo -e "${BLUE}Installation et configuration d'AIDE...${RESET}"
    echo -e " ${BLUE}Do you want to install aide (y/n)?${RESET}"
    read -p "Enter your choice: " option
    if [[ "$option" == "yes" || "$option" == "y" ]]; then
        if install_package "aide"; then
            aideinit
            cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
            echo "AIDE configuré. Exécutez 'aide --check' pour vérifier l'intégrité."
        fi
    elif [[ "$option" == "no" || "$option" == "n" ]]; then
        echo -e "${YELLOW}AIDE is not installed${RESET}"
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
        echo -e "${bLUE}*                File system Script Menu                  *${RESET}"
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${WHITE}* 1) Update System                                       *${RESET}"
        echo -e "${WHITE}* 2) Configure Security                                  *${RESET}"           
        echo -e "${WHITE}* 3) Exit                                                *${RESET}"                            
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "\nPlease select an option: "
        read choice
        case $choice in
            1) update_system ;;
            2) configure_security ;;
            3) echo -e "${CYAN}[INFO] Exiting the script...${RESET}"
               exit ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}" ;;
        esac
        echo -e "\nPress any key to return to the menu..."
        read -n 1 -s
    done
fi
