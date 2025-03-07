#!/bin/bash

# Check if a port number was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <port_number>"
    echo "Example: $0 10000"
    exit 1
fi

PORT=$1
echo "Checking which process is using port $PORT..."

# Find the process using the port
PROCESS_INFO=$(lsof -i :$PORT 2>/dev/null)

if [ -z "$PROCESS_INFO" ]; then
    echo "No process found using port $PORT"
    exit 0
fi

echo -e "\n===== Process using port $PORT =====\n"
echo "$PROCESS_INFO"

# Extract the PID
PID=$(echo "$PROCESS_INFO" | awk 'NR>1 {print $2; exit}')

if [ -n "$PID" ]; then
    echo -e "\n===== Application details for PID $PID =====\n"
    ps -p $PID -o pid,ppid,user,comm,args

    # On macOS, try to get the application name if it's a GUI app
    if [[ "$OSTYPE" == "darwin"* ]]; then
        APP_PATH=$(ps -p $PID -o comm | tail -n 1)
        if [[ $APP_PATH == /* ]]; then
            echo -e "\n===== Application bundle info =====\n"
            echo "Application: $(basename "$APP_PATH")"
            if [[ -d "$APP_PATH" && "$APP_PATH" == *".app"* ]]; then
                echo "Bundle name: $(defaults read "$APP_PATH/Contents/Info" CFBundleName 2>/dev/null || echo "N/A")"
                echo "Display name: $(defaults read "$APP_PATH/Contents/Info" CFBundleDisplayName 2>/dev/null || echo "N/A")"
            fi
        fi
    fi
fi
