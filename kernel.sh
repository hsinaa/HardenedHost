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
    #Backup
    cp /etc/default/grub /etc/default/grub.bak
    cp /etc/sysctl.d/99-security.conf /etc/sysctl.d/99-security.conf.bak
    echo "Configuring kernel for security..."
    GRUB_FILE="/etc/default/grub"

    # Add kernel parameters via GRUB
    KERNEL_PARAMS=()
    # L1TF vulnerability mitigation: forces full mitigation for L1 Terminal Fault
    echo -e "${CYAN}[INFO] Do you want to enforce full mitigation for L1 Terminal Fault (L1TF)? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("l1tf=full,force")
    fi

    # Enable page poisoning: helps detect memory corruption errors
    echo -e "${CYAN}[INFO] Do you want to enable page poisoning to detect memory corruption errors? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("page_poison=on")
    fi

    # PTI (Page Table Isolation): mitigates Spectre variant 2 attacks
    echo -e "${CYAN}[INFO] Do you want to enable Page Table Isolation (PTI) to mitigate Spectre variant 2 attacks? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("pti=on")
    fi

    # Disables slab merging to help mitigate certain types of kernel heap attacks
    echo -e "${CYAN}[INFO] Do you want to disable slab merging to reduce kernel heap attack surfaces? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("slab_nomerge=yes")
    fi

    # SLUB Debugging: helps to detect issues in SLUB memory allocation (useful for debugging)
    echo -e "${CYAN}[INFO] Do you want to enable SLUB debugging to detect memory allocation issues? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("slub_debug=FZP")
    fi

    # Speculative Store Bypass Disable: mitigates Spectre variant 4 attacks
    echo -e "${CYAN}[INFO] Do you want to disable speculative store bypass to mitigate Spectre variant 4 attacks? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("spec_store_bypass_disable=seccomp")
    fi

    # Spectre variant 2: enables protection against Spectre v2 attacks
    echo -e "${CYAN}[INFO] Do you want to enable protection against Spectre variant 2 attacks? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("spectre_v2=on")
    fi

    # MDS (Microarchitectural Data Sampling): full mitigation for MDS vulnerabilities
    echo -e "${CYAN}[INFO] Do you want to enable full mitigation for Microarchitectural Data Sampling (MDS) vulnerabilities? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("mds=full")
    fi

    # Disable Machine Check Exception (MCE): disables kernel panic on certain hardware errors
    echo -e "${CYAN}[INFO] Do you want to disable Machine Check Exception (MCE) to avoid kernel panic on certain hardware errors? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("mce=0")
    fi

    # Shuffle memory page allocation to improve security and reduce attack surface
    echo -e "${CYAN}[INFO] Do you want to enable memory page allocation shuffling to improve security? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("page_alloc.shuffle=1")
    fi

    # Set the default quality of the hardware RNG (Random Number Generator)
    echo -e "${CYAN}[INFO] Do you want to set the default quality of the hardware RNG (Random Number Generator) to improve randomness? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("rng_core.default_quality=500")
    fi

    # Restrict dmesg (kernel log) access for security
    echo -e "${CYAN}[INFO] Do you want to restrict access to kernel logs (dmesg) for security purposes? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.dmesg_restrict=1")
    fi

    # Restrict kernel pointer access to prevent unauthorized access to sensitive data
    echo -e "${CYAN}[INFO] Do you want to restrict kernel pointer access to prevent unauthorized access to sensitive data? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.kptr_restrict=2")
    fi

    # Limit the maximum PID (Process ID) to improve security by reducing the number of processes
    echo -e "${CYAN}[INFO] Do you want to limit the maximum PID (Process ID) to improve security? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.pid_max=65536")
    fi

    # Set maximum CPU time percentage for performance events
    echo -e "${CYAN}[INFO] Do you want to set the maximum CPU time percentage for performance events? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.perf_cpu_time_max_percent=1")
    fi

    # Limit the sample rate for performance events to prevent data overload
    echo -e "${CYAN}[INFO] Do you want to limit the sample rate for performance events to prevent data overload? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.perf_event_max_sample_rate=1")
    fi

    # Restrict access to performance events for non-privileged users
    echo -e "${CYAN}[INFO] Do you want to restrict access to performance events for non-privileged users? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.perf_event_paranoid=2")
    fi

    # Enable Address Space Layout Randomization (ASLR) for added memory layout randomness
    echo -e "${CYAN}[INFO] Do you want to enable Address Space Layout Randomization (ASLR) for additional memory layout randomness? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.randomize_va_space=2")
    fi

    # Disable Magic SysRq key for security (prevents certain key combinations to control the kernel)
    echo -e "${CYAN}[INFO] Do you want to disable the Magic SysRq key for security purposes? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.sysrq=0")
    fi

    # Disable unprivileged BPF (Berkeley Packet Filter) for better security
    echo -e "${CYAN}[INFO] Do you want to disable unprivileged BPF (Berkeley Packet Filter) for better security? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.unprivileged_bpf_disabled=1")
    fi

    # Panic on kernel oops (serious error), to force immediate reboot
    echo -e "${CYAN}[INFO] Do you want to enable kernel panic on oops to force an immediate reboot? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.panic_on_oops=1")
    fi

    # Disable loading of kernel modules for security
    echo -e "${CYAN}[INFO] Do you want to disable loading of kernel modules to improve security? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        KERNEL_PARAMS+=("kernel.modules_disabled=1")
    fi

    # Display all selected kernel parameters
    echo -e "${CYAN}[INFO] Selected kernel parameters:${RESET}"
    echo "${KERNEL_PARAMS[@]}"

    echo "Adding kernel parameters to the GRUB configuration file..."
    for param in "${KERNEL_PARAMS[@]}"; do
    # Append each parameter to GRUB_CMDLINE_LINUX_DEFAULT in GRUB file
    if ! grep -q "$param" "$GRUB_FILE"; then
        sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s|\"\$| $param\"|" "$GRUB_FILE"
    fi
    done

    # Update GRUB configuration
    echo "Updating GRUB..."
    update-grub

    # Configure sysctl for specific security parameters
    SYSCTL_FILE="/etc/sysctl.d/99-security.conf"
    SYSCTL_PARAMS=()
    # Restrict dmesg access via sysctl
    echo -e "${CYAN}[INFO] Do you want to restrict dmesg access via sysctl? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        SYSCTL_PARAMS+=("kernel.dmesg_restrict=1")
    fi 

    # Restrict kernel pointer access
    echo -e "${CYAN}[INFO] Do you want to restrict kernel pointer access? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        SYSCTL_PARAMS+=("kernel.kptr_restrict=2")
    fi  

    # Enable ASLR for randomization of address space
    echo -e "${CYAN}[INFO] Do you want to enable ASLR for randomization of address space? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        SYSCTL_PARAMS+=("kernel.randomize_va_space=2")
    fi 

    echo "Adding sysctl parameters for security..."
    for param in "${SYSCTL_PARAMS[@]}"; do
    # Append each sysctl parameter to the sysctl file
    if ! grep -q "$param" "$SYSCTL_FILE"; then
        echo "$param" >> "$SYSCTL_FILE"
    fi
    done

    # Apply sysctl settings
    sysctl -p "$SYSCTL_FILE"
    if [ $? -eq 0 ]; then
    echo -e "${GREEN}[INFO] Sysctl parameters applied successfully.${RESET}"
    else
        echo -e "${RED}[ERROR] Failed to apply sysctl parameters.${RESET}"
    fi

    # Disable Magic SysRq key (force shutdown key combinations)
    echo -e "${CYAN}[INFO] Do you want to disable Magic SysRq key? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        echo 0 > /proc/sys/kernel/sysrq
    fi

    # Enable ASLR (Address Space Layout Randomization)
    echo -e "${CYAN}[INFO] Do you want to enable ASLR (Address Space Layout Randomization)? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        echo 2 > /proc/sys/kernel/randomize_va_space
    fi

    # Restrict the use of perf_event_open (performance monitoring)
    echo -e "${CYAN}[INFO] Do you want to restrict the use of perf_event_open? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        echo 2 > /proc/sys/kernel/perf_event_paranoid
    fi

    # Disable core dumps
    echo -e "${CYAN}[INFO] Do you want to disable core dumps? (y/n):${RESET}"
    read -p "Your choice: " choice
    if [ "$choice" == "y" ]; then
        echo "* hard core 0" >> /etc/security/limits.conf
        echo -e "${GREEN}Core dumps disabled.${RESET}"
    fi

    echo -e "${GREEN}[INFO] Security configuration completed successfully.${RESET}"
    echo -e "${CYAN}[INFO] A reboot is required for some parameters to take effect.${RESET}"
}

if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
else
    while true; do
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${BLUE}*                   Kernel Script Menu                    *${RESET}"
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${WHITE}1) Update System                                         *${RESET}"
        echo -e "${WHITE}2) Configure Security                                    *${RESET}"
        echo -e "${WHITE}3) Exit                                                  *${RESET}"
        echo -e "${BLUE}***********************************************************${RESET}"
        read -p "Select an option: " choice
        case $choice in
            1) update_system ;;
            2) configure_security ;;
            3) echo -e "${CYAN}[INFO] Exiting script...${RESET}"
            exit ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}" ;;
        esac
fi