#!/bin/bash

# Define colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Function to configure partitions with recommended options
function partitionment_type() {
echo "------------------------------------------------------------"
echo "Recommended disk partitioning"
# Recommended mount points and options
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

# Apply recommended options to partitions
echo "Checking and correcting mounted partitions..."
for mount in "${!recommended_mount_points[@]}"; do
    recommended_options="${recommended_mount_points[$mount]}"
    current_options=$(mount | grep -E " on $mount " | awk '{print $6}' | tr -d '()')

    if [ -n "$current_options" ]; then
        if [ "$current_options" != "$recommended_options" ]; then
            echo "Correcting options for $mount..."
            mount -o remount,$recommended_options $mount
            if [ $? -eq 0 ]; then
                echo "Success: Options for $mount corrected ($recommended_options)."
            else
                echo "Error: Failed to correct options for $mount."
            fi
        fi
    else
        echo "$mount is not mounted. Skipping."
    fi
done
echo "------------------------------------------------------------"
}

# Function to configure /boot options
function boot_access() {
echo "------------------------------------------------------------"
recommended_boot_options="nosuid,nodev,noexec,noauto"
current_boot_options=$(mount | grep -E " on /boot " | awk '{print $6}' | tr -d '()')

if [ -n "$current_boot_options" ]; then
    if [ "$current_boot_options" != "$recommended_boot_options" ]; then
        echo "Correcting options for /boot..."
        mount -o remount,$recommended_boot_options /boot
        if [ $? -eq 0 ]; then
            echo "Success: Options for /boot corrected."
        else
            echo "Error: Failed to correct options for /boot."
        fi
    fi
else
    if grep -qE "^/boot" /etc/fstab; then
        sed -i 's|^/boot.*|/boot ext4 nosuid,nodev,noexec,noauto 0 2|' /etc/fstab
        echo "Success: /boot configuration in /etc/fstab corrected."
    else
        echo "/boot ext4 nosuid,nodev,noexec,noauto 0 2" >> /etc/fstab
        echo "Success: /boot added in /etc/fstab."
    fi
fi
echo "------------------------------------------------------------"
}

# Main function for hardening
apply_dynamic_hardening() {
    echo -e "${BLUE}Starting dynamic hardening...${RESET}"
    partitionment_type 
    boot_access 
    echo -e "${GREEN}Partition hardening completed successfully!${RESET}"
}

# Ensure the script runs as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    REPORT_FILE="Hardening_report.log"
    echo -e "${BLUE}********************************************${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*   System hardening report                *${RESET}" >> $REPORT_FILE
    echo -e "${WHITE}*               Date: $(date)             *${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}********************************************${RESET}" >> $REPORT_FILE
    apply_dynamic_hardening 
    echo "  " >> $REPORT_FILE
fi
