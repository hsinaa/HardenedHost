#!/bin/bash
# Define colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'


install_package() {
    package_name=$1
    if ! dpkg -l | grep -q "$package_name"; then
        echo -e "${CYAN}Installing $package_name...${RESET}"
        if sudo apt install -y "$package_name"; then
            echo -e "${GREEN}$package_name installed successfully.${RESET}"
            echo "$(date): $package_name installed successfully" >> "$REPORT_FILE"
            return 0
        else
            echo -e "${RED}Failed to install $package_name.${RESET}"
            echo "$(date): Failed to install $package_name" >> "$REPORT_FILE"
            return 1
        fi
    else
        echo -e "${GREEN}$package_name is already installed.${RESET}"
        return 0
    fi
}

# Function to check critical file permissions
check_critical_files() {
    echo -e "${CYAN}Checking permissions of critical system files...${RESET}"
    files=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/root")
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            chmod 644 "$file"
            chown root:root "$file"
            echo -e "${GREEN}Permissions for $file have been hardened.${RESET}"
        fi
    done
    echo "$(date): permissions of critical system files checked" >> $REPORT_FILE
}

# Function to harden files using AIDE
apply_aide() {
    if install_package "aide"; then
        echo -e "${CYAN}Applying AIDE policy for file monitoring...${RESET}"
        aide --check || aide --init
        echo "$(date): AIDE policy for file monitoring applied " >> $REPORT_FILE
    fi
}

# Function to monitor file changes with inotify
monitor_file_changes() {
    if install_package "inotify-tools"; then
        FILES=("/etc/passwd" "/etc/shadow" "/etc/ssh/sshd_config" "/root")
        REPORT_PATH="/var/log/file_changes.log"

        echo "Monitoring started at $(date)" > "$REPORT_PATH"
        echo -e "${CYAN}Logs will be recorded in: $REPORT_PATH${RESET}"
        echo -e "${CYAN}Monitoring changes to sensitive files...${RESET}"

        for file in "${FILES[@]}"; do
            echo -e "${YELLOW}Monitoring $file...${RESET}"
        done

        # Lancer le monitoring en arrière-plan
        {
            for file in "${FILES[@]}"; do
                echo -e "${YELLOW}Monitoring $file...${RESET}"
                inotifywait -m -e modify,create,delete "$file" |
                    while read -r path action file; do
                        echo "$(date): Change detected in $path$file: $action" >> "$REPORT_PATH"
                    done
            done
        } &
        # Afficher le PID du processus de monitoring
        MONITOR_PID=$!
        echo -e "${CYAN}Monitoring started in the background (PID: $MONITOR_PID).${RESET}"

        # Retourner sans bloquer le script
        return 0
    fi
} 
#Function to generate repports about system events
generate_repport_logwatch() {
    if install_package "logwatch"; then
        REPORT_PATH="logwatch-report.txt"
        # Generate the report
        sudo logwatch --detail High --range "yesterday" --service all > "$REPORT_PATH"
        echo -e "${GREEN}The Logwatch report is saved here:${RESET} $REPORT_PATH"
    fi
}


# Function for dynamic sudoers management
check_sudoers() {
    echo -e "${CYAN}Checking sudoers file validity...${RESET}"
    if visudo -c; then
        echo -e "${GREEN}Sudoers file is valid.${RESET}"
    else
        echo -e "${RED}Error in sudoers file.${RESET}"
        exit 1
    fi
}

apply_security_policies() {
    echo "Applying security policies..."
    if install_package "ufw"; then
        echo "Deny incoming trafic............."
        sudo ufw default deny incoming
        echo "Allow outging trafic............."
        sudo ufw default allow outgoing
        echo "Enabling Fire-Wall policies......"
        sudo ufw enable
        echo -e "${GREEN}Firewall policies applied successfully.${RESET}"
        echo "$(date): Firewall policies applied " >> $REPORT_FILE
    fi

    echo "Disabling root SSH login........."
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart ssh
    echo -e "${CYAN}Root SSH login disabled.${RESET}"
    echo "$(date): Root SSH login disabled " >> $REPORT_FILE
}

monitor_system_logs() {
    if install_package "journalctl"; then
        echo -e "${CYAN}Monitoring system logs for unusual activities...${RESET}"
        # Use journalctl to display logs and filter for keywords
        journalctl -f | while read line; do
            echo "$line" | grep -i -E "error|fail|denied|unauthorized"
            if [ $? -eq 0 ]; then
                echo "Suspicious activity detected: $line"
            fi
        done
        echo "$(date): System logs for unusual activities monitored" >> $REPORT_FILE
    fi
}

configure_security() {
    echo -e "${CYAN}Starting security configuration...${RESET}"

    # Secure /etc/fstab if not already done
    echo -e "${CYAN}Securing /etc/fstab...${RESET}"
    if ! grep -q "tmpfs /tmp tmpfs defaults,noexec,nodev,nosuid 0 0" /etc/fstab; then
        echo "tmpfs /tmp tmpfs defaults,noexec,nodev,nosuid 0 0" >> /etc/fstab
        echo "Added tmpfs for /tmp with correct options"
    fi
    if ! grep -q "/var /var ext4" /etc/fstab; then
        echo "/var /var ext4 defaults,nodev 0 0" >> /etc/fstab
        echo "Added nodev for /var"
    fi
    if ! grep -q "/home /home ext4" /etc/fstab; then
        echo "/home /home ext4 defaults,nodev,nosuid 0 0" >> /etc/fstab
        echo "Added nodev,nosuid for /home"
    fi
    echo "Secured /etc/fstab completed."
    echo "$(date): Secured /etc/fstab applied " >> $REPORT_FILE

    # Disable unused filesystems if not already done
    echo -e "${CYAN}Disabling unused filesystems...${RESET}"
    if ! grep -q "install cramfs /bin/true" /etc/modprobe.d/disable-filesystems.conf; then
        echo "install cramfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
    fi
    if ! grep -q "install squashfs /bin/true" /etc/modprobe.d/disable-filesystems.conf; then
        echo "install squashfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
    fi
    if ! grep -q "install udf /bin/true" /etc/modprobe.d/disable-filesystems.conf; then
        echo "install udf /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
    fi
    echo -e "${GREEN}Disabling unused filesystems completed.${RESET}"

    # Enable logging for administrative actions if not already done
    echo -e "${CYAN}Enabling logging for administrative actions...${RESET}"
    if ! grep -q "Defaults log_output" /etc/sudoers; then
        echo 'Defaults log_output' | sudo EDITOR='tee -a' visudo
        echo "Enabled logging for sudo commands."
    fi
    echo -e "${GREEN}Administrative accountability enabled.${RESET}"
    echo "$(date): Administrative accountability enabled" >> $REPORT_FILE 

    # Modify the default UMASK value if not already done
    echo -e "${GREEN}Modifying UMASK default value...${RESET}"
    if ! grep -q "^UMASK 027" /etc/login.defs; then
        sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
        echo "Set UMASK to 027."
    fi
    echo "UMASK value set to 027."
    echo "$(date): UMASK value set to 027" >> $REPORT_FILE 

    # Create a dedicated sudo group if not already created
    echo -e "${CYAN}Creating a dedicated sudo group...${RESET}"
    if ! grep -q "%sudoers" /etc/sudoers; then
        groupadd -f sudoers
        echo "%sudoers ALL=(ALL:ALL) ALL" >> /etc/sudoers
        echo "Dedicated sudo group created."
    fi

    # Secure file editing with sudo if not already done
    echo -e "${RESET}Securing file editing with sudo...${RESET}"
    if ! grep -q "Defaults editor=/usr/bin/vi" /etc/sudoers; then
        echo "Defaults editor=/usr/bin/vi" | sudo EDITOR='tee -a' visudo
        echo "Secured file editing with vi editor."
    fi

    # Limit EXEC directive usage if not already done
    echo -e "${CYAN}Limiting usage of commands requiring EXEC directive...${RESET}"
    if ! grep -q 'Cmnd_Alias NOEXEC' /etc/sudoers; then
        echo 'Cmnd_Alias NOEXEC = /bin/sh, /bin/bash' | sudo EDITOR='tee -a' visudo
        echo "Limited usage of /bin/sh and /bin/bash."
    fi
    if ! grep -q 'Defaults!NOEXEC noexec' /etc/sudoers; then
        echo 'Defaults!NOEXEC noexec' | sudo EDITOR='tee -a' visudo
        echo "Limited EXEC directive usage."
    fi

    if ! grep -q "kernel.yama.ptrace_scope = 1" /etc/sysctl.conf; then
        echo "kernel.yama.ptrace_scope = 1" >> /etc/sysctl.conf
        sysctl -p
        echo "Set kernel.yama.ptrace_scope to 1"
    fi
}


# Main function for dynamic hardening
apply_dynamic_hardening() {
    echo -e "${BLUE}Starting dynamic hardening...${RESET}"
    check_critical_files
    monitor_connections
    apply_aide
    monitor_file_changes
    configure_security
    apply_security_policies
    monitor_system_logs
    echo "$(date): System logs monitored " >> $REPORT_FILE
    generate_repport_logwatch

    echo -e "${GREEN}System hardening completed successfully!${RESET}"
    echo "$(date): System hardening applied " >> $REPORT_FILE
}

# Interactive menu
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    REPORT_FILE="Hardening_report.log"
    echo -e "${BLUE}********************************************${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*    File system Execution Script REPORT   *${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*------------------------------------------*${RESET}" >> $REPORT_FILE
    echo -e "${WHITE}*               "Date: $(date)"           *${RESET}" >> $REPORT_FILE                          
    echo -e "${BLUE}********************************************${RESET}" >> $REPORT_FILE
    apply_dynamic_hardening 
    echo "  " >> $REPORT_FILE
fi

