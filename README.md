### **Table of Contents**

1. [Overview](#overview)  
2. [Objectives](#objectives)  
3. [Key Features](#key-features)  
4. [Project Structure](#project-structure)  
   - [Main Script (`main.sh`)](#main-script-mainsh)  
   - [Modules](#modules)  
     1. [System Update (`update_system`)](#system-update-updatesystem)  
     2. [Static Hardening (`show_static_modules`)](#static-hardening-show_static_modules)  
     3. [Dynamic Hardening (`show_dynamic_modules`)](#dynamic-hardening-show_dynamic_modules)  
     4. [System Status Check (`check_system_status`)](#system-status-check-check_system_status)  
5. [Installation](#installation)  
6. [Usage](#usage)  
7. [Acknowledgments](#acknowledgments)

   
## **Overview**  
Welcome to *Hardening as Code for Linux*, a project developed collaboratively with **Chaima Bissi** and under the supervision of **Pr. Omar Achbarou**. Inspired by the best practices of **ANSSI (Agence nationale de la sécurité des systèmes d'information)**, HardenedHost is a collection of scripts aimed at improving the security of various Linux system components.  

### **Objectives**  
Our primary goal is to secure Linux systems by addressing six critical components:  
- **Authentication**  
- **File System**  
- **Kernel**  
- **Hardware**  
- **Network**  
- **Partitioning**  

### **Key Features**  
- **Modular Architecture**: Dedicated scripts for each component.  
- **Static Hardening**: Predefined configurations to mitigate vulnerabilities.  
- **Dynamic Hardening**: Real-time adaptability with continuous monitoring.  

---

## **Project Structure**  

### **Main Script (`main.sh`)**  
The entry point for the hardening process, providing a user-friendly interface for executing system updates, static hardening, dynamic hardening, system checks, or exiting the program.  

### **Modules**  
1. **System Update (`update_system`)**: Ensures the system is up-to-date before applying hardening configurations.  
2. **Static Hardening (`show_static_modules`)**:  
   - `auth.sh`  
   - `FileSystem.sh`  
   - `kernel.sh`  
   - `material.sh`  
   - `partition.sh`  
   - `network.sh`  
3. **Dynamic Hardening (`show_dynamic_modules`)**:  
   - `auth-dynamic.sh`  
   - `FS-dynamic.sh`  
   - `kernel-dynamic.sh`  
   - `material-dynamic.sh`  
   - `partition-dynamic.sh`  
   - `network-dynamic.sh`  
4. **System Status Check (`check_system_status`)**:  
   - Displays connected users.  
   - Checks disk and memory usage.  
   - Verifies active services.  
   - Controls critical permissions.  

---

## **Installation**  

1. Clone the repository:  
   ```bash
   git clone https://github.com/hsinaa/HardenedHost.git
   ```  
2. Navigate to the project directory:  
   ```bash
   cd HardenedHost
   ```
3. Add executable permission:  
   ```bash
   sudo chmod u+x ./main.sh
   ``` 
4. Run the main script with elevated privileges:  
   ```bash
   sudo ./main.sh
   ```  

---

## **Usage**  

- **Interactive Menu**: Use the main script to navigate and execute the desired hardening or system checks.  
- **Modular Execution**: Each module can also be run individually for targeted hardening.  

---

## **Acknowledgments**  
A special thanks to **Chaima Bissi** and **Pr. Omar Achbarou** for their collaboration and guidance throughout the development of this project.  

