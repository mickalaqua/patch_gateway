#!/bin/sh

target_address="google.com"
max_failures=5
interval=600
failures=0

file_name="$(basename "$0")"
log_file="/tmp/$filename.log"

version() {
    echo "1.0.1"
}

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S')[$file_name]: $*" >> $log_file
}

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

check_connection() {

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


delete_cron_entry() {
    local executable_name=$1
    # Check if the cron entry exists
    if crontab -l | grep -q -E "\b$executable_name\b"; then
        # If the entry exists, delete the line
        (crontab -l | sed -E "/\b$executable_name\b/d") | crontab -
        log "Cron entry for $executable_name deleted."
    else
        log "Cron entry for $executable_name not found."
    fi
}

update_or_add_cron_entry(){
    local original_executable_name=$1
    local new_executable_name=$2
    local cron_schedule=$3

    # Check if the cron entry exists
    if crontab -l | grep -q -E "\b$original_executable_name\b"; then
        # If the entry exists, update the line
        log "Cron entry exist : $(crontab -l | grep -E "\b$original_executable_name\b")"
        (crontab -l | sed -E "/\b$original_executable_name\b/c$cron_schedule $new_executable_name") | crontab -
        log "Cron entry updated with : $(crontab -l | grep "$new_executable_name")"
    else
        # If the entry doesn't exist, add a new one
        (crontab -l; echo "$cron_schedule $new_executable_name") | crontab -
        log "New cron entry added for $new_executable_name."
    fi
}

configure_cron() {
    # delete alternative cron entry for an alternative script name
    log_file=$1
    delete_cron_entry "communication_watchdog"
    update_or_add_cron_entry "connection_watchdog" "/etc/patch/connection_watchdog.sh check" "0 * * * *"
    exit 0
}

# Check the number of arguments
if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    echo "Usage: $0 <function_name>"
    exit 1
fi

function_name=$1

case $function_name in
    "version")
        version
        ;;
    "install")
        configure_cron $2
        ;;
    "check")
        check_connection
        ;;
    *)
        echo "Invalid function name. Use 'version', 'install' or 'check'."
        exit 1
        ;;
esac