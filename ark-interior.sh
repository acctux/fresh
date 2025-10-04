#!/bin/bash

# Start a background loop that prints "it worked"
while true; do
    echo "it worked"
    sleep 0.1
done &

# Capture the PID of the background loop
loop_pid=$!

# Wait for Enter key
read -r -p "Press Enter to stop..."

# Kill the background loop
kill "$loop_pid"
