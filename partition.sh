#!/bin/bash
# Define colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'


function partition_type() {
echo "------------------------------------------------------------"
echo "Recommended disk partitioning"
# Define mount points and their recommended options
declare -A recommended_mount_points=(
    ["/boot"]="nosuid,nodev,noexec"
    ["/opt"]="nosuid,nodev"
    ["/tmp"]="nosuid,nodev,noexec"
    ["/srv"]="nosuid,nodev"
    ["/home"]="nosuid,nodev"
    ["/proc"]="hidepid=2"
    ["/usr"]="nodev"
    ["/var"]="nosuid,nodev"
    ["/var/log"]="nosuid,nodev,noexec"
    ["/var/tmp"]="nosuid,nodev,noexec"
)

# Check mounted partitions and fix if necessary
echo "Checking mounted partitions and their options..."

for mount in "${!recommended_mount_points[@]}"; do
    recommended_options="${recommended_mount_points[$mount]}"
    # Check if the partition is mounted
    current_options=$(mount | grep -E " on $mount " | awk '{print $6}' | tr -d '()')

    if [ -n "$current_options" ]; then
        if [ "$current_options" == "$recommended_options" ]; then
            echo "OK: $mount is compliant ($current_options)"
        else
            echo "NOT COMPLIANT: $mount ($current_options instead of $recommended_options)"
            read -p "Would you like to apply the recommended options ($recommended_options) to $mount? (y/n) " response
            if [[ "$response" == "y" || "$response" == "Y" ]]; then
                echo "Applying options $recommended_options to $mount..."
                mount -o remount,$recommended_options $mount
                if [ $? -eq 0 ]; then
                    echo "Options for $mount have been successfully corrected."
                else
                    echo "Error updating options for $mount."
                fi
            else
                echo "No changes made to $mount."
            fi
        fi
    else
        echo "MISSING: $mount is not mounted"
    fi
done

echo "------------------------------------------------------------"
}

function boot_access() {
echo "------------------------------------------------------------"
# Check current options for /boot
current_boot_options=$(mount | grep -E " on /boot " | awk '{print $6}' | tr -d '()')

# Recommended options for /boot
recommended_boot_options="nosuid,nodev,noexec,noauto"

if [ -n "$current_boot_options" ]; then
    # If /boot is mounted, check its options
    if [ "$current_boot_options" == "$recommended_boot_options" ]; then
        echo "OK: /boot is compliant with options ($current_boot_options)."
    else
        echo "NOT COMPLIANT: /boot is mounted with ($current_boot_options) instead of ($recommended_boot_options)."
        read -p "Would you like to correct the options for /boot? (y/n) " response
        if [[ "$response" == "y" || "$response" == "Y" ]]; then
            echo "Correcting options for /boot..."
            mount -o remount,$recommended_boot_options /boot
            if [ $? -eq 0 ]; then
                echo "Options for /boot have been successfully corrected."
            else
                echo "Error correcting options for /boot."
            fi
        else
            echo "No changes made to /boot."
        fi
    fi
else
    # If /boot is not mounted, check or configure in /etc/fstab
    echo "/boot is not mounted."
    if grep -qE "^/boot" /etc/fstab; then
        current_fstab=$(grep "^/boot" /etc/fstab | awk '{print $4}')
        if [ "$current_fstab" == "$recommended_boot_options" ]; then
            echo "OK: /boot is correctly configured in /etc/fstab with ($current_fstab)."
        else
            echo "NOT COMPLIANT: /boot is configured in /etc/fstab with ($current_fstab) instead of ($recommended_boot_options)."
            read -p "Would you like to correct /boot configuration in /etc/fstab? (y/n) " response
            if [[ "$response" == "y" || "$response" == "Y" ]]; then
                sed -i 's|^/boot.*|/boot ext4 nosuid,nodev,noexec,noauto 0 2|' /etc/fstab
                echo "The /boot configuration in /etc/fstab has been corrected."
            else
                echo "No changes made to /etc/fstab for /boot."
            fi
        fi
    else
        echo "/boot is not configured in /etc/fstab."
        read -p "Would you like to add /boot to /etc/fstab with recommended options? (y/n) " response
        if [[ "$response" == "y" || "$response" == "Y" ]]; then
            echo "/boot ext4 nosuid,nodev,noexec,noauto 0 2" >> /etc/fstab
            echo "/boot has been successfully added to /etc/fstab."
        else
            echo "No changes made to /etc/fstab."
        fi
    fi
fi
echo "------------------------------------------------------------"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    while true; do
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${BLUE}*                Partitioning Script Menu                  *${RESET}"
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${WHITE}* 1) Partition the disk                                   ${RESET}"
        echo -e "${WHITE}* 2) Restrict access to "/boot"                           *${RESET}"           
        echo -e "${WHITE}* 3) Exit                                                 *${RESET}"                            
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "\nPlease select an option: "
        read choice
        case $choice in
            1) partition_type ;;
            2) boot_access ;;
            3) echo -e "${CYAN}[INFO] Exiting the script...${RESET}"
               exit ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}" ;;
        esac
        echo -e "\nPress any key to return to the menu..."
        read -n 1 -s
    done
fi