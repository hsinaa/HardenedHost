#!/bin/bash
# Define colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'	
function reboot() {
    read -p "Changes require a restart to take effect. Do you want to reboot now (y/n)? " answer

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo "Rebooting the system..."
        sudo reboot
    else
        echo "Restart has been canceled. You will need to manually restart your system to apply the changes."
    fi
}

function R1() {
    echo "------------------------------------------------------------"
    echo "Processor Model Identification:"
    lscpu | grep -E "Architecture|Model name|Vendor ID|CPU(s)"
    echo "Feature Set Verification:"
    FLAGS=$(grep "flags" /proc/cpuinfo | head -n 1)
    if [[ "$FLAGS" == *"lm"* ]]; then
        echo "- The processor supports long mode (64-bit)."
    fi
    if [[ "$FLAGS" == *"nx"* ]]; then
        echo "- The processor supports NX/XD protections."
    fi
    if [[ "$FLAGS" == *"vmx"* ]] || [[ "$FLAGS" == *"svm"* ]]; then
        echo "- The processor supports hardware virtualization."
    fi
    echo "------------------------------------------------------------"
    echo "Checking if your processor supports 64-bit architecture:"
    if grep -q " lm " /proc/cpuinfo; then
        echo "Your processor supports 64-bit architecture."
        ARCH=$(uname -m)
        if [[ $ARCH == "x86_64" ]]; then
            echo "Your operating system is 64-bit (x86_64)."
        else
            echo "Your operating system is 32-bit ($ARCH)."
            echo "Consider migrating to a 64-bit OS to take advantage of modern features."
        fi
    else
        echo "Your processor does not support 64-bit architecture."
    fi
    echo "------------------------------------------------------------"
    echo "Checking and enabling PAE and NX/XD features..."
    architecture=$(uname -m)
    if [ "$architecture" == "x86_64" ]; then
        echo "Your system is 64-bit."
        if cat /proc/cpuinfo | grep -iq nx; then
            echo "The processor supports the NX/XD bit (No-Execute)."
        else
            echo "The processor does not support the NX/XD bit."
        fi
    fi
}


function R2() {
    read -p "Do you want to set up a GRUB password for secure boot? (yes/no): " response
    if [[ "$response" != "yes" ]]; then
        echo "Skipping GRUB password setup."
        return
    fi
    echo "------------------------------------------------------------"
    echo "Setting up GRUB password for secure boot..."
    read -sp "Enter the password for GRUB: " grub_password
    echo
    read -sp "Confirm the password: " confirm_password
    echo
    if [[ "$grub_password" != "$confirm_password" ]]; then
        echo "Error: Passwords do not match. Exiting function."
        return
    fi
    hashed_password=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 2>/dev/null | grep "grub.pbkdf2" | awk '{print $NF}')
    if [[ -z "$hashed_password" ]]; then
        echo "Error generating the hashed password. Exiting function."
        return
    fi
    echo "Hashed password: $hashed_password"
    echo "Configuring GRUB password..."
    cat <<EOF | sudo tee /etc/grub.d/01_secure_boot
set superusers="admin"
password_pbkdf2 admin $hashed_password
EOF
    sudo chmod +x /etc/grub.d/01_secure_boot
    echo "Updating GRUB configuration..."
    sudo update-grub
    echo "GRUB password setup completed successfully!"
}

function R4(){
    echo "------------------------------------------------------------"
    if ! command -v mokutil &> /dev/null; then
        echo "mokutil n'est pas installé. Installation en cours..."
        if command -v apt &> /dev/null; then
            apt update && apt install -y mokutil
        elif command -v dnf &> /dev/null; then
            dnf install -y mokutil
        elif command -v yum &> /dev/null; then
            yum install -y mokutil
        else
            echo "Gestionnaire de paquets non supporté. Veuillez installer mokutil manuellement."
            exit 1
        fi
    fi
}



# Main function for hardening
apply_dynamic_hardening() {
    echo -e "${BLUE}Starting dynamic hardening...${RESET}"
    R1
    R2
    R4  
    echo -e "${GREEN}Partition hardening completed successfully!${RESET}"
}

# Ensure the script runs as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    REPORT_FILE="Hardening_report.log"
    echo -e "${BLUE}********************************************${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*   System hardening report   *${RESET}" >> $REPORT_FILE
    echo -e "${WHITE}*               Date: $(date)           *${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}********************************************${RESET}" >> $REPORT_FILE
    apply_dynamic_hardening 
    echo "  " >> $REPORT_FILE
fi

