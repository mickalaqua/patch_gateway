#!/bin/bash

target_address="google.com"
max_failures=5
interval=600
failures=0

info() {
    logger -t connection_watchdog "$*"
    echo "$*"
}

showInterfaces() {
    result=$(ifconfig -a)
    info "Network interfaces:"
    info "$result"
}

showRoutingTable() {
    result=$(route -n)
    info "Routing table:"
    info "$result"
}

showDNSConfig() {
    result=$(cat /etc/resolv.conf)
    info "DNS configuration:"
    info "$result"
}

showProcess() {
    result=$(ps w)
    info "Process:"
    info "$result"
}

showPingResults() {
    result=$(ping -c 1 -W 1 "eu1.cloud.thethings.network")
    info "ping -c 1 -W 1 $target_address:"
    info "$result"

    result=$(ping -I tun0 -c 1 -W 1 "eu1.cloud.thethings.network")
    info "ping -I tun0 -c 1 -W 1 $target_address:"
    info "$result"
	
    result=$(ping -I tun1 -c 1 -W 1 "eu1.cloud.thethings.network")
    info "ping -I tun1 -c 1 -W 1 $target_address:"
    info "$result"

    result=$(ping -c 1 -W 1 8.8.8.8)
    info "ping -c 1 -W 1 8.8.8.8:"
    info "$result"

    result=$(ping -I tun0 -c 1 -W 1 8.8.8.8)
    info "ping -I tun0 -c 1 -W 1 8.8.8.8:"
    info "$result"

    result=$(ping -I tun1 -c 1 -W 1 8.8.8.8)
    info "ping -I tun1 -c 1 -W 1 8.8.8.8:"
    info "$result"
}

dumpConnectionsStatus() {
    showInterfaces
    showRoutingTable
    showDNSConfig
    showPingResults
    showProcess
}

function check_connection() {

    while true; do
        if ping -c 1 -W 1 "$target_address" > /dev/null 2>&1; then
            info "Ping to $target_address successful"
            exit
        else
            failures=$((failures + 1))
            info "Ping to $target_address failed ($failures/$max_failures)"

            if [ "$failures" -ge "$max_failures" ]; then
                info "Connection not available, logging connections status then restarting system"
                dumpConnectionsStatus
                info "Rebooting in 10 seconds"
                sleep 10

                info "reboot"
                reboot
                exit  # Exit the script after initiating a reboot
            fi
        fi
        sleep "$interval"
    done
}


function version() {
    echo "v1.0.0"
    # Add your code for Function One here
}

function delete_cron_entry() {
    local executable_name=$1
    # Check if the cron entry exists
    if crontab -l | grep -q -E "\b$executable_name\b"; then
        # If the entry exists, delete the line
        (crontab -l | sed -E "/\b$executable_name\b/d") | crontab -
        echo "Cron entry for $executable_name deleted."
    else
        echo "Cron entry for $executable_name not found."
    fi
}

function update_or_add_cron_entry(){
    local original_executable_name=$1
    local new_executable_name=$1
    local cron_schedule=$1

    # Check if the cron entry exists
    if crontab -l | grep -q -E "\b$executable_name\b"; then
        # If the entry exists, update the line
        echo "Cron entry exist : $(crontab -l | grep -q -E "\b$executable_name\b")"
        (crontab -l | sed -E "/\b$executable_name\b/c$new_executable_name $command") | crontab -
        echo "Cron entry updated with : $(crontab -l | grep -q -E "\b$executable_name\b")"
    else
        # If the entry doesn't exist, add a new one
        (crontab -l; echo "$new_executable_name $command") | crontab -
        echo "New cron entry added for $executable_name."
    fi
}

function configure_cron() {
    # delete alternative cron entry for an alternative script name
    delete_cron_entry "communication_watchdog"
    update_or_add_cron_entry "connection_watchdog" "/etc/connection_watchdog.sh" "*/10 * * * *"
}

# Check the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <function_name>"
    exit 1
fi

# Assign the parameters to variables
function_name=$1

# Run the appropriate function based on the parameter
case $function_name in
    "version")
        version
        ;;
    "configure_cron")
        configure_cron 
        ;;
    "check")
        check_connection
        ;;
    *)
        echo "Invalid function name. Use 'version', 'configure_cron' or 'check'."
        exit 1
        ;;
esac