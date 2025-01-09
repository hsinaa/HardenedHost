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

# Function to collect system information
collect_system_info() {
    echo "Collecting system information..."

    echo "Kernel Version:"
    uname -r
    echo "$(date): Kernel version" >> $REPORT_FILE
    uname -r >> $REPORT_FILE

    echo "Full Kernel Details:"
    uname -a
    echo "$(date): Full Kernel Details:" >> $REPORT_FILE
    uname -a >> $REPORT_FILE

    echo "Current sysctl parameters:"
    sysctl -a
    echo "$(date): Current sysctl parameters:" >> $REPORT_FILE
    sysctl -a >> $REPORT_FILE

    echo "Loaded kernel modules:"
    lsmod
    echo "$(date): Loaded kernel modules:" >> $REPORT_FILE
    lsmod >> $REPORT_FILE

    echo "Checking for kernel updates..."
    apt list --upgradable | grep linux
}

# Function to monitor and adapt system based on kernel logs
monitor_and_adapt() {
    echo "Monitoring system logs for suspicious activities..."

    # Analyze kernel logs via dmesg
    if dmesg | grep -i "error"; then
        echo "Errors detected in kernel logs. Enhancing security measures..."
        echo "blacklist usb_storage" >> /etc/modprobe.d/blacklist.conf
        echo "Module 'usb_storage' has been blacklisted."
    else
        echo "No kernel errors detected."
    fi
}

# Function to automate kernel updates
automate_kernel_updates() {
    echo -e "${YELLOW}Automating kernel patch updates...${RESET}"

    if install_package "kpatch"; then
        echo "Applying live kernel patches..."
        #Verifing if the file latest_patch.kpatch exist
        if [ -f "latest_patch.kpatch" ]; then
            kpatch apply latest_patch.kpatch
            echo -e "${GREEN}[INFO] Kernel patch applied successfully.${RESET}"
            echo "$(date): Kernel patch applied successfully" >> "$REPORT_FILE"
        else
            echo -e "${RED}[ERROR] 'latest_patch.kpatch' file not found.${RESET}"
            echo "$(date): Patch file 'latest_patch.kpatch' not found" >> "$REPORT_FILE"
        fi
    fi
}

# Function to set up auditd for kernel monitoring
setup_auditd() {
    echo "Setting up auditd for kernel monitoring..."
    if install_package "auditd"; then
        auditctl -w /sbin/modprobe -p x -k kernel_module_load
        echo "Auditd is now monitoring kernel module loading."
    fi
}

# Function for vulnerability scanning
vulnerability_scanning() {
    # Lynis is an auditing tool for Linux/Unix systems. It performs security checks and system hardening suggestions.
    if install_package "lynis"; then
        echo -e "${YELLOW}[INFO] Running Lynis audit...${RESET}"
        lynis audit system
        echo -e "${GREEN}[SUCCESS] Lynis audit completed.${RESET}"
        echo "$(date): Lynis audit completed" >> "$REPORT_FILE"
    fi

    # OpenVAS (Open Vulnerability Assessment Scanner) is a full-featured vulnerability scanner to detect vulnerabilities in networks and systems.
    if install_package "openvas"; then
        echo -e "${YELLOW}[INFO] Setting up OpenVAS...${RESET}"
        openvas --setup
        echo -e "${GREEN}[SUCCESS] OpenVAS setup completed.${RESET}"
        echo "$(date): OpenVAS setup completed" >> "$REPORT_FILE"
    fi 

    # osquery is a tool for querying system data and monitoring system configurations using SQL-like queries.
    if install_package "osquery"; then
        echo -e "${YELLOW}[INFO] Running osquery...${RESET}"
        osqueryi "SELECT * FROM os_version;"
        echo -e "${GREEN}[SUCCESS] osquery executed successfully.${RESET}"
        echo "$(date): osquery executed successfully" >> "$REPORT_FILE"
    fi

    # kcheck is a tool for verifying kernel updates and identifying kernel-specific vulnerabilities or configuration issues.
    if install_package "kcheck"; then
        echo -e "${YELLOW}[INFO] Running kcheck for kernel vulnerabilities...${RESET}"
        kcheck --status
        echo -e "${GREEN}[SUCCESS] kcheck executed successfully.${RESET}"
        echo "$(date): kcheck executed successfully" >> "$REPORT_FILE"
    fi
}


# Function to monitor kernel using eBPF
kernel_monitoring() {
    echo "Setting up eBPF tools for advanced kernel monitoring..."

    #Install dependancies
    install_package "bpfcc-tools"
    install_package "linux-headers-$(uname -r)"
    install_package "clang"
    install_package "llvm"
    install_package "libelf-dev"apt install -y bpfcc-tools linux-headers-$(uname -r) clang llvm libelf-dev
    
    #install bcc : BPF compiler collection
    install_package "python3-bpfcc"

    #install bpftool
    git clone https://github.com/libbpf/bpftool.git
    cd bpftool/src || exit
    make && sudo make install

    #Configure eBPF
    mount -t bpf bpf /sys/fs/bpf/
    mkdir -p /sys/fs/bpf/my_programs
    echo "BPF programs and maps setup complete."

    # List attached programs
    echo "Listing attached BPF programs:"
    bpftool prog show
    echo "Attached BPF programs:" >> $REPORT_FILE
    bpftool prog show >> $REPORT_FILE

    # Inspect BPF maps
    echo "Inspecting BPF maps:"
    bpftool map show
    echo "BPF maps:" >> $REPORT_FILE
    bpftool map show >> $REPORT_FILE
}

# Function to configure security measures
configure_security() {
    collect_system_info
    monitor_and_adapt
    automate_kernel_updates
    setup_auditd
    vulnerability_scanning
    kernel_monitoring
}

# Main menu
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] This script must be run as root.${RESET}"
    exit 1
else
    REPORT_FILE="Hardening_report.log"
    echo -e "${BLUE}************************************************${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*        Kernel Execution Script Report        *${RESET}" >> $REPORT_FILE
    echo -e "${BLUE}*----------------------------------------------*${RESET}" >> $REPORT_FILE
    echo -e "${WHITE}*                "Date: $(date)"              *${RESET}" >> $REPORT_FILE                          
    echo -e "${BLUE}************************************************${RESET}" >> $REPORT_FILE
    configure_security 
    echo "  " >> $REPORT_FILE
fi


    