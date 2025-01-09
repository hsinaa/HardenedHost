#!/bin/bash
# Color definitions for design
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

# Function to configure filesystem and security
configure_security() {
    echo -e "${CYAN}[INFO] Configuring filesystem options...${RESET}"
    # Backup sysctl.conf
    if [ ! -f /etc/sysctl.conf.bak ]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.bak
        echo -e "${GREEN}[INFO] Backup created: /etc/sysctl.conf.bak${RESET}"
        echo "$(date): Backup created: /etc/sysctl.conf.bak" >> $REPORT_FILE
    else
        echo -e "${YELLOW}[INFO] Backup already exists: /etc/sysctl.conf.bak${RESET}"
    fi

    # Add PAM lockout rules with check
    if ! grep -q "pam_faillock.so" /etc/pam.d/common-auth; then
        echo "auth required pam_faillock.so deny=3 unlock_time=600 onerr=fail" >> /etc/pam.d/common-auth
        echo "account required pam_faillock.so" >> /etc/pam.d/common-account
        echo -e "${GREEN}[INFO] PAM lockout rules applied.${RESET}"
        echo "$(date): PAM rules applied" >> $REPORT_FILE
    else
        echo -e "${CYAN}[INFO] PAM lockout rules already configured.${RESET}"
    fi

    # Configure password policies
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
    echo -e "${GREEN}[INFO] Password policies configured.${RESET}"
    echo "$(date): Password policies configured" >> $REPORT_FILE

    # Disable root login via SSH with check
    # Backup original sshd_config
    if [ ! -f /etc/sysctl.conf.bak ]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        echo -e "${BLUE}[INFO] Backup created: /etc/ssh/sshd_config.bak${RESET}"
        echo "$(date):Backup created: /etc/ssh/sshd_config.bak" >> $REPORT_FILE
    fi
    if ! grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl restart sshd
        echo -e "${GREEN}[INFO] Root login via SSH disabled.${RESET}"
        echo "$(date): Root loginvia SSH disabled" >> $REPORT_FILE
    else
        echo -e "${CYAN}[INFO] Root login via SSH already disabled.${RESET}"
    fi

    # Disable unused service accounts with check
    echo -e "${CYAN}[INFO] Disabling unused service accounts...${RESET}"
    for user in $(getent passwd | awk -F: '{if ($3 >= 1000 && $7 != "/usr/sbin/nologin") print $1}'); do
        shell=$(getent passwd "$user" | cut -d: -f7)
        if [[ "$shell" != "/usr/sbin/nologin" ]]; then
            echo "Do you want to disable service account: $user"
            read -p "Enter your choice: " op
            if [[ "$op" == "yes" ]]; then
                usermod -s /usr/sbin/nologin "$user"
                echo -e "${GREEN}[INFO] Service account $user disabled.${RESET}"
                echo "$(date): Service account $user disabled" >> $REPORT_FILE
            else
                echo -e "${RED}[INFO] Service account $user was not disabled.${RESET}"
            fi
        else
            echo -e "${CYAN}[INFO] Service account $user already disabled.${RESET}"
        fi
    done

    # Enable automatic screen lock with check
    if ! grep -q "TMOUT=600" /etc/profile; then
        echo "readonly TMOUT=600" >> /etc/profile
        echo "export TMOUT" >> /etc/profile
        echo -e "${GREEN}[INFO] Automatic screen lock configured.${RESET}"
        echo "$(date): Automatic screen lock configured" >> $REPORT_FILE
    else
        echo -e "${CYAN}[INFO] Automatic screen lock already configured.${RESET}"
    fi

    # Disable user accounts that never logged in
    echo -e "${CYAN}[INFO] Scanning for users who never logged in...${RESET}"
    for user in $(lastlog | grep "Never" | awk '{print $1}'); do
        if [[ "$user" != "USER" && "$user" != "root" ]]; then
            shell=$(getent passwd "$user" | cut -d: -f7)
            if [[ "$shell" != "/usr/sbin/nologin" ]]; then
                read -p "Do you want to disable the user account $user? (y/n): " answer
                if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
                    passwd -l "$user" 2>/dev/null
                    echo -e "${GREEN}The user account $user has been disabled.${RESET}"
                    echo "$(date): The user account $user has been disabled" >> $REPORT_FILE
                else
                    echo -e "${CYAN}The user account $user has not been disabled.${RESET}"
                fi
            else
                echo -e "${CYAN}[INFO] User account $user already disabled.${RESET}"
            fi
        fi
    done
    echo -e "${GREEN}[INFO] User account processing completed.${RESET}"

    # Install Fail2Ban if not installed
    echo -e "${CYAN}Installing & configuring fail2ban.......${RESET}"
    if install_package "fail2ban"; then
        if ! systemctl is-active --quiet fail2ban; then
            echo -e "${YELLOW}Starting Fail2ban...${RESET}"
            systemctl start fail2ban
        fi
        echo -e "${CYAN}Fail2ban status:${RESET}"
        fail2ban-client status sshd
        echo -e "${GREEN}[INFO]Monitoring SSH c  onnections with Fail2ban .${RESET}"
        echo "$(date): Monitoring SSH connections with Fail2ban" >> "$REPORT_FILE"
    fi

    #install_package "auditd"
    if install_package "auditd"; then 
        # Install audispd-plugins
        if install_package "audispd-plugins"; then
            # Start auditd service if it's not already running
            if ! systemctl is-active --quiet auditd; then
                echo -e "${YELLOW}Starting auditd...${RESET}"
                systemctl start auditd
            fi
            
            # Add audit rules to monitor sensitive files
            echo "-w /etc/passwd -p wa -k passwd_changes" >> /etc/audit/rules.d/audit.rules
            echo "-w /etc/shadow -p wa -k shadow_changes" >> /etc/audit/rules.d/audit.rules
            
            # Restart auditd to apply the new rules
            systemctl restart auditd
            echo -e "${GREEN}[INFO] Auditd configuration updated and service restarted.${RESET}"
            echo "$(date): Auditd configuration updated and service restarted" >> "$REPORT_FILE"
            
            # Add audit rules to monitor failed login attempts
            echo "-w /var/log/auth.log -p wa -k failed_logins" >> /etc/audit/rules.d/auth.log.rules
            
            # Restart auditd to apply the new rules
            systemctl restart auditd
            echo -e "${GREEN}[INFO] Audit rules for monitoring failed login attempts have been configured.${RESET}"
            echo "$(date): Audit rules added to monitor failed login attempts" >> "$REPORT_FILE"
            
            # Check for failed login attempts in the logs
            echo -e "${CYAN}[INFO] Checking for failed login attempts in the logs...${RESET}"
            failed_logins=$(grep 'Failed password' /var/log/auth.log | wc -l)
            if [ "$failed_logins" -gt 0 ]; then
                echo -e "${RED}[ALERT] There have been $failed_logins failed login attempts!${RESET}"
                echo "$(date): $failed_logins failed login attempts detected" >> "$REPORT_FILE"
            else
                echo -e "${GREEN}[INFO] No failed login attempts detected.${RESET}"
            fi
        fi
    fi
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    REPORT_FILE="Hardening_report.log"
    echo -e "${BLUE}************************************************${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*    Authentification Execution Script REPORT  *${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*----------------------------------------------*${RESET}" >> $REPORT_FILE
    echo -e "${WHITE}*                "Date: $(date)"              *${RESET}" >> $REPORT_FILE                          
    echo -e "${BLUE}************************************************${RESET}" >> $REPORT_FILE
    configure_security 
    echo "  " >> $REPORT_FILE
fi

    