#!/bin/sh

download_folder="/tmp/"
download_url=https://raw.githubusercontent.com/mickalaqua/patch_gateway/latest
patch_path="/etc/patch"

file_name="$(basename "$0")"
log_path="/mnt/mmcblk0p1/patch"
log_file="$log_path/$file_name.log"

version() {
    echo "v1.0.1"
    # Add your code for Function One here
}

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S')[$file_name]: $*" >> $log_file
}

version_compare() {
    local version1="$1"
    local version2="$2"

    if [ "$version1" = "$version2" ]; then
        # Versions are equal
        return 0
    fi

    local IFS=.
    local ver1=""
    local ver2=""
    local num1
    local num2

    # Split version strings into individual components
    while [ -n "$version1" ] || [ -n "$version2" ]; do
        num1="${version1%%.*}"
        version1="${version1#*.}"

        num2="${version2%%.*}"
        version2="${version2#*.}"

        num1="${num1:-0}"
        num2="${num2:-0}"

        if [ "$num1" -gt "$num2" ]; then
            # Version $version1 is greater than $version2
            return 1
        elif [ "$num1" -lt "$num2" ]; then
            # Version $version1 is less than $version2
            return 2
        fi
    done

    # Versions are equal
    return 0
}

download_last_version() {
    # download the last patcher
    # check if the last patcher version is newer than the current one
    # If the download version is newer then run it and abort current script

    mkdir $patch_path
    log "Downloading latest patcher file $download_url/$file_name"
    curl -o $patch_path/patcher.new.sh $download_url/$file_name
    chmod +x $patch_path/patcher.new.sh

    new_patcher_version=$($patch_path/patcher.new.sh version)
    current_patcher_version=$(version)
    version_result=$(version_compare $new_patcher_version $current_patcher_version)
    if [[ $version_result == 1 ]]; then
        log "New file version $new_patcher_version is higher than the current version $current_patcher_version"
        # run the new script in background
        sh $patch_path/patcher.new.sh install &
        # abort the current script 
        exit 0
    fi
}

download_and_install_patch() {
    local file_name=$1

    log "Downloading latest $file_name file $download_url/$file_name"
    curl -o $patch_path/$file_name.new.sh $download_url/$file_name
    new_file_version=$($patch_path/$file_name.new.sh version)

    current_file_exist=0
    version_result=-1
    if [ -e "$patch_path/$file_name" ]; then
        $current_file_exist=1
        current_file_version=$(sh $patch_path/$file_name version)
        version_result="$(version_compare $new_patcher_version $current_patcher_version)"
    fi

    if [ $version_result == 1 ] || [ $current_file_exist == 1 ]; then
        log "New file version $new_patcher_version is higher than the current version $current_patcher_version"
        res="$($patch_path/$file_name install)"
        return $res
    else
        log "No newer version for $file_name"
    fi

}

install_patcher() {
    local file_name=$1

    current_path=$(readlink -f "$file_name" 2>/dev/null || echo "$0")
    expected_path="$patch_path/patcher.sh"
    if [ "$current_path" != "$expected_path" ]; then
        log "moving the installer from $current_path to $expected_path"
        mv "$current_path" "$expected_path"
    fi
}

install() {
    # check install the script at the correct path
    mkdir $log_path
    install_patcher $0
    download_last_version
    download_and_install_patch "connection_watchdog.sh"
    download_and_install_patch "configure_modem.sh"
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
        install $log_file
        ;;
    *)
        echo "Invalid function name. Use 'version' or 'install'."
        exit 1
        ;;
esac