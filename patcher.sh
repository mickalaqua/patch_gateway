#!/bin/bash

download_folder="/tmp/"

function version() {
    echo "v1.0.0"
    # Add your code for Function One here
}

function logger() {
    log_file="/mnt/mmcblk0p1/patch.log"
    echo "$(date +'%Y-%m-%d %H:%M:%S'): $*" >> $log_file
}

function download_last_version() {
    # Download 
    https://drive.google.com/file/d/1jsBFTza9uTSlhxVdYuBiMAFUDYvLgyau/view?usp=sharing
    # check the version
    # if higher then rename itself and executes the new version
}

function install_script() {

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
    "install_scripts")
        configure_cron 
        ;;
    "check")
        check_connection
        ;;
    *)
        echo "Invalid function name. Use 'version' or 'install_script'."
        exit 1
        ;;
esac