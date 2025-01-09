#!/bin/bash
function reboot() {
    read -p "Changes require a reboot to take effect. Do you want to reboot now (y/n)? " answer

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo "Rebooting the system..."
        sudo reboot
    else
        echo "Reboot has been canceled. You will need to manually reboot your system to apply the changes."
    fi
}
function R1() {
    echo "------------------------------------------------------------"
    echo "Processor model identification:"
    lscpu | grep -E "Architecture|Model name|Vendor ID|CPU(s)"
    echo "Checking features:"
    # Check for specific flags
    FLAGS=$(grep "flags" /proc/cpuinfo | head -n 1)    
    if [[ "$FLAGS" == *"lm"* ]]; then
        echo "- Processor supports long mode (64-bit)."
    fi
    if [[ "$FLAGS" == *"nx"* ]]; then
        echo "- Processor supports NX/XD protections."
    fi
    if [[ "$FLAGS" == *"vmx"* ]] || [[ "$FLAGS" == *"svm"* ]]; then
        echo "- Processor supports hardware virtualization."
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
echo "Checking and enabling PAE and NX/XD features....."
architecture=$(uname -m)
if [ "$architecture" == "x86_64" ]; then
    echo "Your system is 64-bit."
    if cat /proc/cpuinfo | grep -iq nx; then
        echo "Processor supports the NX/XD bit (No-Execute)."
    else
        echo "Processor does not support the NX/XD bit."
        echo "The NX/XD (No-Execute) bit is not enabled on this processor."
        echo "Enabling the NX/XD bit..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 noexec=off"/' /etc/default/grub
        sudo update-grub
        echo "The NX/XD bit has been enabled via GRUB. Please restart your system to apply the changes."
        #reboot
    fi
else
    echo "Your system is 32-bit."
    if cat /proc/cpuinfo | grep -iq pae; then
        echo "Processor supports PAE (Physical Address Extension)."
    else
        echo "Processor does not support PAE."
        echo "NX cannot be enabled without PAE on this system."
        exit 1
    fi
    if cat /proc/cpuinfo | grep -iq nx; then
        echo "Processor supports the NX/XD bit (No-Execute)."
    else
        echo "Processor does not support the NX/XD bit."
    fi

    echo "Checking PAE activation and installing a PAE kernel if necessary..."
    if ! uname -r | grep -q pae; then
        echo "PAE kernel is not installed. Installing now..."
        sudo apt update
        sudo apt install -y linux-image-generic-pae
        echo "PAE kernel has been installed. Please restart your system to apply the changes."
    else
        echo "PAE kernel is already installed."
    fi
    echo "Enabling NX/XD bit via GRUB..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 noexec=off"/' /etc/default/grub
    sudo update-grub
    echo "NX/XD bit has been enabled via GRUB. Please restart your system to apply the changes."
    #reboot
fi
echo "------------------------------------------------------------"
echo "Checking the status of Hyper-Threading and CPU resources..."
hyper_threading_status=$(lscpu | grep "Thread(s) per core" | awk '{print $4}')
echo "Number of threads per core: $hyper_threading_status"
if [ "$hyper_threading_status" -gt 1 ]; then
    echo "Hyper-Threading is enabled on this system."
    read -p "Would you like to disable Hyper-Threading for security reasons? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Disabling Hyper-Threading in the kernel..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 noht"/' /etc/default/grub
        sudo update-grub
        echo "Hyper-Threading has been disabled in GRUB. You will need to restart the system to apply this change."
        #reboot
    else
        echo "Hyper-Threading remains enabled. No changes made."
    fi
else
    echo "Hyper-Threading is already disabled on this system."
fi

echo "------------------------------------------------------------"
echo "Checking for the SMEP feature on the system..."
smeppresent=$(dmesg | grep -i "smep" || true)
if [[ ! -z "$smeppresent" ]]; then
    echo "The SMEP feature is enabled on this system."
else
    echo "The SMEP feature is not enabled on this system."
    read -p "Would you like to enable SMEP to improve security? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Enabling SMEP..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nopti"/' /etc/default/grub
        sudo update-grub
        echo "SMEP has been enabled. You need to restart the system to apply this change."
        #reboot
    else
        echo "SMEP remains disabled. No changes made."
    fi
fi
echo "------------------------------------------------------------"
echo "Checking for the SMAP feature on the system..."
smappresent=$(dmesg | grep -i "smap" || true)
if [[ ! -z "$smappresent" ]]; then
    echo "The SMAP feature is enabled on this system."
else
    echo "The SMAP feature is not enabled on this system."
    read -p "Would you like to enable SMAP to improve security? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Enabling SMAP..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nosmap"/' /etc/default/grub
        sudo update-grub
        echo "SMAP has been enabled. A system restart is required to apply this change."
        #reboot
    else
        echo "SMAP remains disabled. No changes made."
    fi
fi
echo "------------------------------------------------------------"
echo "Checking for AES-NI support on the processor..."
if grep -q aes /proc/cpuinfo; then
    echo "Your processor supports AES-NI."
else
    echo "Your processor does not support AES-NI."
    read -p "It is recommended to use a processor with AES-NI. Would you like to search for a compatible processor? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Searching for a processor compatible with AES-NI..."
    else
        echo "No search performed. AES-NI is not supported on this system."
    fi
fi
echo "------------------------------------------------------------"
echo "Checking for RDRAND and RDSEED instruction support:"
if grep -q rdrand /proc/cpuinfo; then
    echo "Your processor supports the RDRAND instruction for generating hardware entropy."
else
    echo "Your processor does not support the RDRAND instruction."
fi

if grep -q rdseed /proc/cpuinfo; then
    echo "Your processor supports the RDSEED instruction for generating a seed for pseudo-random number generators."
else
    echo "Your processor does not support the RDSEED instruction."
    echo "It is recommended to use hardware entropy sources like RDRAND and RDSEED along with other independent sources."
fi
echo "------------------------------------------------------------"
echo "Checking for CPU virtualization support (VT-x / AMD-V):"
if grep -q vmx /proc/cpuinfo; then
    echo "Your processor supports VT-x virtualization (Intel)."
    virtualization_supported=true
elif grep -q svm /proc/cpuinfo; then
    echo "Your processor supports AMD-V virtualization (AMD)."
    virtualization_supported=true
else
    echo "Your processor does not support CPU context virtualization."
    virtualization_supported=false
fi
if [ "$virtualization_supported" = true ]; then
    read -p "Would you like to disable CPU context virtualization for security reasons? (y/n): " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        echo "CPU context virtualization needs to be disabled in BIOS/UEFI."
        echo "Restart your machine and access BIOS/UEFI settings to disable VT-x/AMD-V."
        echo "Note that this action requires a restart to take effect."
    else
        echo "CPU context virtualization will remain enabled."
    fi
fi
echo "------------------------------------------------------------"
echo "Checking for IOMMU virtualization support (VT-d/AMD-Vi)..."
if grep -q "vmx" /proc/cpuinfo && dmesg | grep -i "IOMMU" > /dev/null; then
    echo "Your processor and system support IOMMU (VT-d/AMD-Vi)."
    iommu_supported=true
else
    echo "Your processor or system does not support IOMMU (VT-d/AMD-Vi)."
    iommu_supported=false
fi
if [ "$iommu_supported" = true ]; then
    read -p "Would you like to enable the IOMMU service to enhance security for I/O devices? (y/n) : " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        echo "Enabling the IOMMU service needs to be done in the BIOS/UEFI."
        echo "Restart your machine and access BIOS/UEFI settings to enable VT-d/AMD-Vi."
        echo "Note that this action requires a restart to take effect."
    else
        echo "The IOMMU service will remain disabled."
    fi
fi
echo "It is recommended to enable IOMMU functionality to block potential attacks via malicious I/O devices."
echo "------------------------------------------------------------"
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
    echo "------------------------------------------------------------"
    echo "Checking peripheral components status..."
    if lsusb > /dev/null 2>&1; then
        echo "USB ports detected."
        read -p "Do you want to disable USB ports (y/n)? " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Disabling USB ports..."
            sudo modprobe -r usbcore
        fi
    fi
    if lspci | grep -i wireless > /dev/null; then
        echo "Wi-Fi card detected."
        read -p "Do you want to disable the Wi-Fi card (y/n)? " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Disabling Wi-Fi card..."
            sudo ip link set $(lspci | grep -i wireless | awk '{print $1}') down
        fi
    fi
    if lspci | grep -i esata > /dev/null; then
        echo "eSATA controller detected."
        read -p "Do you want to disable the eSATA controller (y/n)? " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Disabling eSATA controller..."
            sudo modprobe -r sata_sil24
        fi
    fi
    if lspci | grep -i bluetooth > /dev/null; then
        echo "Bluetooth card detected."
        read -p "Do you want to disable the Bluetooth card (y/n)? " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Disabling Bluetooth card..."
            sudo rfkill block bluetooth
        fi
    fi
    if dmesg | grep -i ttyS > /dev/null; then
        echo "Serial ports detected."
        read -p "Do you want to disable serial ports (y/n)? " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Disabling serial ports..."
            sudo systemctl stop serial-getty@ttyS0.service
            sudo systemctl disable serial-getty@ttyS0.service
        fi
    fi
    echo "A reboot may be required to apply some changes."
    echo "------------------------------------------------------------"    
}

function R4() {
    echo "------------------------------------------------------------"    
    if ! command -v mokutil &> /dev/null; then
        echo "mokutil is not installed. Installing now..."
        if command -v apt &> /dev/null; then
            apt update && apt install -y mokutil
        elif command -v dnf &> /dev/null; then
            dnf install -y mokutil
        elif command -v yum &> /dev/null; then
            yum install -y mokutil
        else
            echo "Package manager not supported. Please install mokutil manually."
            exit 1
        fi
    fi
    if ! command -v sbsign &> /dev/null; then
        echo "sbsign is not installed. Installing now..."
        if command -v apt &> /dev/null; then
            apt update && apt install -y sbsigntools
        elif command -v dnf &> /dev/null; then
            dnf install -y sbsigntools
        elif command -v yum &> /dev/null; then
            yum install -y sbsigntools
        else
            echo "Package manager not supported. Please install sbsigntools manually."
            exit 1
        fi
    fi

    echo "Generating private and public key..."
    openssl genpkey -algorithm RSA -out MOK.key -pkeyopt rsa_keygen_bits:2048
    openssl rsa -in MOK.key -pubout -out MOK.pub
    echo "Importing the public key into UEFI..."
    mokutil --import MOK.pub
    echo "Signing the boot loader..."
    sbsign --key MOK.key --cert MOK.pem /boot/efi/EFI/grubx64.efi
    echo "Signing the kernel image..."
    sbsign --key MOK.key --cert MOK.pem /boot/vmlinuz-$(uname -r)
    echo "Files have been successfully signed. Please restart and validate the key."
    echo "------------------------------------------------------------"
}
# Define colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'	

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
else
    while true; do
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${bLUE}*                 Hardware Script Menu                    *${RESET}"
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "${WHITE}* 1) Choose & configure your hardware                    *${RESET}"
        echo -e "${WHITE}* 2) Configure BIOS/UEFI                                 *${RESET}"           
        echo -e "${WHITE}* 3) Replace preloaded keys                              *${RESET}" 
        echo -e "${WHITE}* 4) Exit                                                *${RESET}"                             
        echo -e "${BLUE}***********************************************************${RESET}"
        echo -e "\nPlease select an option: "
        read choice
        case $choice in
            1) R1 ;;
            2) R2 ;;
            3) R4 ;;
            4) echo -e "${CYAN}[INFO] Exiting the script...${RESET}"
               exit ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}" ;;
        esac
        echo -e "\nPress any key to return to the menu..."
        read -n 1 -s
    done
fi