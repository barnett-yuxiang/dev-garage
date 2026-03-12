#!/bin/bash

# Script to display system hardware specifications
# Works on both macOS and Linux (Ubuntu)

# Function to print section headers
print_header() {
    echo -e "\n\033[1;34m$1\033[0m"
    echo "----------------------------------------"
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
else
    OS="Unknown"
fi

print_header "SYSTEM INFORMATION"
echo "Operating System: $OS"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
if [[ "$OS" == "Linux" ]]; then
    if command_exists lsb_release; then
        echo "Distribution: $(lsb_release -ds)"
    elif [ -f /etc/os-release ]; then
        echo "Distribution: $(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//;s/"//g')"
    fi
fi

# CPU Information
print_header "CPU SPECIFICATIONS"
if [[ "$OS" == "macOS" ]]; then
    # macOS CPU specs
    echo "CPU Model: $(sysctl -n machdep.cpu.brand_string)"
    echo "CPU Cores: $(sysctl -n hw.physicalcpu)"
    echo "CPU Threads: $(sysctl -n hw.logicalcpu)"
    echo "CPU Clock Speed: $(sysctl -n hw.cpufrequency | awk '{printf "%.2f GHz", $0/1000000000}')"
    echo "L2 Cache: $(sysctl -n hw.l2cachesize | awk '{printf "%.2f MB", $0/1024/1024}')"
    echo "L3 Cache: $(sysctl -n hw.l3cachesize | awk '{printf "%.2f MB", $0/1024/1024}')"
elif [[ "$OS" == "Linux" ]]; then
    # Linux CPU specs
    echo "CPU Model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d ':' -f2 | sed 's/^[ \t]*//')"
    echo "CPU Cores: $(grep -c "processor" /proc/cpuinfo)"
    echo "Physical CPUs: $(grep "physical id" /proc/cpuinfo | sort -u | wc -l)"
    if command_exists lscpu; then
        echo "CPU Architecture: $(lscpu | grep "Architecture" | awk '{print $2}')"
        echo "CPU Max Speed: $(lscpu | grep "CPU max MHz" | awk '{print $4 " MHz"}')"
        echo "CPU Min Speed: $(lscpu | grep "CPU min MHz" | awk '{print $4 " MHz"}')"
        echo "Cache Sizes:"
        lscpu | grep -E "L1d|L1i|L2|L3" | awk '{print $1 " " $3 " " $4}'
    fi
    if [ -f /proc/cpuinfo ]; then
        echo "CPU Flags: $(grep flags /proc/cpuinfo | head -1 | cut -d ':' -f2 | tr -s ' ' | cut -d ' ' -f-10)..."
    fi
fi

# Memory Information
print_header "MEMORY SPECIFICATIONS"
if [[ "$OS" == "macOS" ]]; then
    # macOS memory specs
    total_mem=$(sysctl -n hw.memsize | awk '{printf "%.2f GB", $0/1024/1024/1024}')
    echo "Total Physical Memory: $total_mem"

    # Memory type information if available
    if command_exists system_profiler; then
        echo -e "\nMemory Type Details:"
        system_profiler SPMemoryDataType | grep -E "Size|Type|Speed|Status" | sed 's/^[ \t]*//'
    fi
elif [[ "$OS" == "Linux" ]]; then
    # Linux memory specs
    total_mem=$(grep MemTotal /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
    echo "Total Physical Memory: $total_mem"

    if command_exists dmidecode; then
        echo -e "\nMemory Module Details:"
        sudo dmidecode -t memory | grep -A17 "Memory Device" | grep -E "Size|Type|Speed|Manufacturer|Serial|Part Number" | grep -v "No Module" | head -20
    fi

    if [ -f /proc/meminfo ]; then
        echo -e "\nMemory Information:"
        grep -E "SwapTotal|SwapFree" /proc/meminfo | awk '{printf "%s: %.2f GB\n", $1, $2/1024/1024}'
    fi
fi

# Disk Information
print_header "DISK SPECIFICATIONS"
if [[ "$OS" == "macOS" ]]; then
    # macOS disk specs
    echo "Disk Devices:"
    diskutil list | grep -E '^\/' | awk '{print $1}' | while read -r disk; do
        diskutil info "$disk" | grep -E "Device Model|Protocol|Solid State|Media Name|Disk Size|Device Block Size" | sed 's/^[ \t]*//'
        echo "------------------------"
    done
elif [[ "$OS" == "Linux" ]]; then
    # Linux disk specs
    if command_exists lsblk; then
        echo "Disk Devices:"
        lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,TYPE,ROTA | awk 'NR>1 {
            rotation = $7 == 0 ? "SSD" : "HDD";
            print "Device: /dev/"$1"\nSize: "$2"\nModel: "$3"\nSerial: "$4"\nInterface: "$5"\nType: "$6" ("rotation")";
            print "------------------------"
        }'
    else
        echo "Disk Devices:"
        ls -l /dev/sd* 2>/dev/null | awk '{print $NF}' | while read -r disk; do
            if [ -b "$disk" ]; then
                echo "Device: $disk"
                if command_exists hdparm; then
                    hdparm -I "$disk" 2>/dev/null | grep -E "Model|Serial|Transport|capacity" | sed 's/^[ \t]*//'
                fi
                echo "Size: $(blockdev --getsize64 "$disk" 2>/dev/null | awk '{printf "%.2f GB", $1/1024/1024/1024}')"
                echo "------------------------"
            fi
        done
    fi
fi

# GPU Information
print_header "GPU SPECIFICATIONS"
if [[ "$OS" == "macOS" ]]; then
    # macOS GPU specs
    echo "GPU Information:"
    system_profiler SPDisplaysDataType | grep -A15 "Chipset Model" | grep -E "Chipset Model|Bus|VRAM|Display Type|Resolution|Metal|Vendor" | grep -v "Displays:" | grep -v "^$" | sed 's/^[ \t]*//'
elif [[ "$OS" == "Linux" ]]; then
    # Linux GPU specs
    if command_exists nvidia-smi; then
        echo "NVIDIA GPU Specifications:"
        nvidia-smi --query-gpu=name,memory.total,pci.bus_id,driver_version,vbios_version --format=csv,noheader | sed 's/,/\n/g'
    fi

    if command_exists lspci; then
        echo -e "\nGPU Devices:"
        lspci | grep -i 'vga\|3d\|2d' | while read -r line; do
            echo "$line"
            if command_exists glxinfo; then
                gpu_vendor=$(echo "$line" | grep -ioE 'nvidia|amd|intel|matrox|ati')
                if [ -n "$gpu_vendor" ]; then
                    glxinfo | grep -E "OpenGL vendor|OpenGL renderer|OpenGL version" | grep -i "$gpu_vendor" | head -3
                fi
            fi
            echo "------------------------"
        done
    fi
fi

# Network Information
print_header "NETWORK SPECIFICATIONS"
if [[ "$OS" == "macOS" ]]; then
    # macOS network specs
    echo "Network Interfaces:"
    networksetup -listallhardwareports | awk '/Hardware Port|Device|Ethernet Address/ {print}' | sed 's/^[ \t]*//'

    if command_exists system_profiler; then
        echo -e "\nNetwork Hardware Details:"
        system_profiler SPNetworkDataType | grep -E "Type|Hardware|BSD|Supported|Speed" | grep -v "^$" | sed 's/^[ \t]*//' | head -15
    fi
elif [[ "$OS" == "Linux" ]]; then
    # Linux network specs
    echo "Network Interfaces:"
    if command_exists ip; then
        ip link show | grep -v "lo:" | grep -E "^[0-9]" | while read -r line; do
            interface=$(echo "$line" | awk -F': ' '{print $2}')
            echo "Interface: $interface"

            # MAC Address
            mac=$(ip link show "$interface" | grep "link/ether" | awk '{print $2}')
            if [ -n "$mac" ]; then
                echo "MAC Address: $mac"
            fi

            # IP Address
            ip=$(ip addr show "$interface" | grep -w inet | awk '{print $2}')
            if [ -n "$ip" ]; then
                echo "IP Address: $ip"
            fi

            # Interface Speed
            if [ -f "/sys/class/net/$interface/speed" ]; then
                speed=$(cat "/sys/class/net/$interface/speed" 2>/dev/null)
                if [ -n "$speed" ]; then
                    echo "Speed: $speed Mbps"
                fi
            fi

            # Hardware details if ethtool is available
            if command_exists ethtool; then
                echo "Hardware Details:"
                ethtool -i "$interface" 2>/dev/null | grep -E "driver|version|bus-info|supports|firmware" | head -5 | sed 's/^[ \t]*//'
            fi
            echo "------------------------"
        done
    else
        # Fallback to ifconfig if ip is not available
        ifconfig | grep -E "^[a-z]+" | awk '{print $1}' | sed 's/://' | while read -r interface; do
            if [[ "$interface" != "lo" ]]; then
                echo "Interface: $interface"
                ifconfig "$interface" | grep -E "inet|ether" | sed 's/^[ \t]*//'
                echo "------------------------"
            fi
        done
    fi
fi

echo -e "\nSpecifications scan completed at: $(date)"
