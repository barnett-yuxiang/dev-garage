#!/bin/bash

# Script to display system performance metrics
# Works on both macOS and Linux (Ubuntu)

# Function to print section headers
print_header() {
    echo -e "\n\033[1;34m$1\033[0m"
    echo "----------------------------------------"
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
echo "Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"

# CPU Information
print_header "CPU INFORMATION"
if [[ "$OS" == "macOS" ]]; then
    # macOS CPU info
    echo "CPU Model: $(sysctl -n machdep.cpu.brand_string)"
    echo "CPU Cores: $(sysctl -n hw.physicalcpu)"
    echo "CPU Threads: $(sysctl -n hw.logicalcpu)"
    echo "CPU Usage:"
    top -l 1 | grep "CPU usage" | awk '{print $3,$4,$5,$6,$7,$8}'
elif [[ "$OS" == "Linux" ]]; then
    # Linux CPU info
    echo "CPU Model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d ':' -f2 | sed 's/^[ \t]*//')"
    echo "CPU Cores: $(grep -c "processor" /proc/cpuinfo)"
    echo "CPU Usage:"
    mpstat 1 1 | grep "Average" | awk '{print "User: " $3 "%, System: " $5 "%, Idle: " $12 "%"}'
fi

# Memory Information
print_header "MEMORY INFORMATION"
if [[ "$OS" == "macOS" ]]; then
    # macOS memory info
    total_mem=$(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')
    echo "Total Physical Memory: $total_mem"

    # Calculate memory in a more readable format
    echo "Memory Details:"
    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1;
                        /Pages free: (\d+)/ and $free=$1;
                        /Pages active: (\d+)/ and $active=$1;
                        /Pages inactive: (\d+)/ and $inactive=$1;
                        /Pages speculative: (\d+)/ and $spec=$1;
                        /Pages wired down: (\d+)/ and $wired=$1;
                        END {
                            $free_mem = $free * $size / 1073741824;
                            $active_mem = $active * $size / 1073741824;
                            $inactive_mem = $inactive * $size / 1073741824;
                            $spec_mem = $spec * $size / 1073741824;
                            $wired_mem = $wired * $size / 1073741824;
                            $used_mem = $active_mem + $wired_mem;
                            $total_calculated = $free_mem + $active_mem + $inactive_mem + $spec_mem + $wired_mem;
                            printf("Free Memory: %.2f GB\n", $free_mem);
                            printf("Used Memory: %.2f GB\n", $used_mem);
                            printf("Active Memory: %.2f GB\n", $active_mem);
                            printf("Inactive Memory: %.2f GB\n", $inactive_mem);
                            printf("Wired Memory: %.2f GB\n", $wired_mem);
                        }'
elif [[ "$OS" == "Linux" ]]; then
    # Linux memory info
    echo "Memory Size and Usage:"
    free -h

    # Get total memory in a more readable format
    total_mem=$(grep MemTotal /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
    echo "Total Physical Memory: $total_mem"
fi

# Disk Information
print_header "DISK INFORMATION"
if [[ "$OS" == "macOS" ]]; then
    # macOS disk info
    echo "Disk Size and Usage:"
    df -h | grep -v "/dev/loop" | grep "/dev/" | awk '{print $1 " - Total: " $2 ", Used: " $3 " (" $5 "), Available: " $4}'

    # Get total disk size
    echo -e "\nTotal Disk Sizes:"
    diskutil list | grep -E '^\/' | awk '{print $1}' | while read -r disk; do
        diskutil info "$disk" | grep "Disk Size" | awk '{print "'$disk'" " - " $3 " " $4}'
    done
elif [[ "$OS" == "Linux" ]]; then
    # Linux disk info
    echo "Disk Size and Usage:"
    df -h | grep -v "/dev/loop" | grep "/dev/" | awk '{print $1 " - Total: " $2 ", Used: " $3 " (" $5 "), Available: " $4}'

    # Get total disk size
    echo -e "\nTotal Disk Sizes:"
    lsblk -d -o NAME,SIZE | grep -v NAME | awk '{print "/dev/" $1 " - " $2}'
fi

# GPU Information
print_header "GPU INFORMATION"
if [[ "$OS" == "macOS" ]]; then
    # macOS GPU info
    echo "GPU Information:"
    system_profiler SPDisplaysDataType | grep -A 10 "Chipset Model" | grep -v "Displays:" | grep -v "^$"
elif [[ "$OS" == "Linux" ]]; then
    # Linux GPU info
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU Information:"
        nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv,noheader
    elif command -v lspci &> /dev/null; then
        echo "GPU Information:"
        lspci | grep -i 'vga\|3d\|2d'
    else
        echo "No GPU information available"
    fi
fi

# Network Information
print_header "NETWORK INFORMATION"
if [[ "$OS" == "macOS" ]]; then
    # macOS network info
    echo "Network Interfaces:"
    ifconfig | grep -E "^[a-z]+" | awk '{print $1}' | sed 's/://' | while read -r interface; do
        if [[ "$interface" != "lo0" && "$interface" != "lo" ]]; then
            echo -n "$interface: "
            ipaddr=$(ifconfig "$interface" | grep "inet " | awk '{print $2}')
            if [[ -n "$ipaddr" ]]; then
                echo "$ipaddr"
            else
                echo "No IP address"
            fi
        fi
    done
elif [[ "$OS" == "Linux" ]]; then
    # Linux network info
    echo "Network Interfaces:"
    ip -4 addr show | grep -v "lo" | grep -v "docker" | grep -v "br-" | grep -v "veth" | grep -E "inet " | awk '{print $NF ": " $2}'
fi

echo -e "\nScript completed at: $(date)"
