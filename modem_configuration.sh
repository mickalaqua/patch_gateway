#!/bin/sh

patch_path="/etc/patch"
download_url=https://raw.githubusercontent.com/mickalaqua/patch_gateway/last

file_name="$(basename "$0")"
log_file="/tmp/$filename.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S')[$file_name]: $*" >> $log_file
}

version() {
    echo "v1.0.0"
    # Add your code for Function One here
}

lte_at_port="/dev/ttyATWWAN"
lte_diag_file="/tmp/lte_diag.txt"

start_at_cmd() {
    cat $lte_at_port >> $lte_diag_file &
}

stop_at_cmd() {
    kill -9 $(pgrep -f "cat $lte_at_port")
}

get_autosel() {
    cat $lte_at_port > /tmp/at_cmd.log &
    ret=1
    while [ $ret -eq 1 ]; do
        echo "AT+QMBNCFG=\"AutoSel\"" > $lte_at_port
    	exec_success=$(cat /tmp/at_cmd.log | grep -c OK)
        if [ $exec_success -gt 0 ]; then
            ret=0
        fi
    done
    cat /tmp/at_cmd.log | grep QMBNCFG
    kill -9 $(pgrep -f "cat $lte_at_port")
}

enable_autosel() {
    echo "AT+QMBNCFG=\"AutoSel\",1" > $lte_at_port
}

install() {
    
    # delete alternative cron entry for an alternative script name
    log_file=$1
    log "Installing modem configuration"
    start_at_cmd
    autosel_status=get_autosel 
    if [ $(echo $autosel_status | grep -c 0) -gt 0 ]; then
        log "Autosel is 0, setting autosel to 1"
        enable_autosel
    else
        log "Autosel already set to 1"
    fi
    stop_at_cmd
    exit 0
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
    "install")
        install $2
        ;;
    *)
        echo "Invalid function name. Use 'version' or 'install'."
        exit 1
        ;;
esac