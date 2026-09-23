#!/bin/bash

#######################################
# Main function
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
#######################################
function main() {
    echo "Main function"    
    # Exit script when any command fails
    set -e
    # Keep track of the last executed command
    trap 'last_command=${BASH_COMMAND}' DEBUG
    # Echo an error message before exiting
    # shellcheck disable=SC2154
    trap 'echo "\"${last_command}\" command failed with exit code $?." >&2' EXIT

    wait_for_mount_availability
    configure
    configure_fluentbit
    start

    # Remove DEBUG and EXIT trap
    trap - DEBUG
    trap - EXIT
    # Allow script to continue on error.
    set +e
}

#######################################
# Wait until the file service becomes mounted to prevent installation
# failure. Fails if the file service is not mounted after 30 seconds.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
#######################################
function wait_for_mount_availability() {
    echo "Wait for mount"
    readonly MOUNT_MAX_WAIT=30    

    # Local variables
    local mount_ping_statement
    local wait_time

    echo "Checking if file service is mounted..."

    mount_ping_statement="mountpoint -q /opt/Fortra/GoAnywhere/userdata/"

    # Wait for mount readiness.
    wait_time=0
    until ${mount_ping_statement}; do
        if [[ ${wait_time} -ge ${MOUNT_MAX_WAIT} ]]; then
            echo "The file service did not mount within ${wait_time} s. Aborting."
            exit 1
        else
            echo "Waiting for the file service to mount (${wait_time} s)..."
            sleep 1
            ((++wait_time))
        fi
    done
    echo "File service is mounted."
}


#######################################
# Configure the application
# Globals:
#   ECR_IMAGE
# Arguments:
#   None
# Outputs:
#   None
#######################################
function configure() {
    echo "Configure"

    # Variables.
    local etc_ga_folder="/etc/Fortra/GoAnywhere"
    local opt_ga_folder="/opt/Fortra/GoAnywhere"
    local config_folder="${etc_ga_folder}/config"

    # Always copy upgrade file.
    echo "Copy upgrade file"
    cp -Rf /temp/upgrader/ "${opt_ga_folder}"/

    # Copy filesystem only if config folder is empty.
    if [[ -z "$( ls -A "${config_folder}" )" ]]; then 
        echo "Copy filesystem"
        cp -Rf /temp/userdata/ "${opt_ga_folder}"/
        cp -Rf /temp/config/ "${etc_ga_folder}"/
        cp -Rf /temp/tomcat/ "${etc_ga_folder}"/
        cp -Rf /temp/logs/ "${opt_ga_folder}"/tomcat/
        cp -Rf /temp/custom/ "${opt_ga_folder}"/ghttpsroot/
    fi

    # Update the header's page with ECR image.
    echo "Update the header's page with ECR image"
    local meta_param1="<meta name=\"ECR_IMAGE\" content=\"${ECR_IMAGE}\" />"
    sed -i "s|<meta name=\"viewport\"|${meta_param1}<meta name=\"viewport\"|g" "${opt_ga_folder}"/adminroot/WEB-INF/includes/DocumentHead.xhtml

}

#######################################
# Configure the fluent-bit application
# Globals:
#   SYSTEM_NAME
# Arguments:
#   None
# Outputs:
#   None
#######################################
function configure_fluentbit() {
    echo "Configure Fluent-bit"

    # Variables.
    local configuration="/etc/fluent-bit/fluent-bit.conf"
    local container_id
    
    container_id=$(awk -F/ '{print $(NF-1)}' < /proc/1/cpuset)

    # Setting up parameters.
    sed -i "s|{{REGION}}|ca-central-1|g" "${configuration}"
    sed -i "s|{{LOG_GROUP_NAME}}|/ecs/ga-td|g" "${configuration}"
    sed -i "s|{{SYSTEM_NAME}}|${SYSTEM_NAME}/${container_id}/|g" "${configuration}"

    # Starting fluent-bit in a background application.
    fluent-bit -c "${configuration}" &

    sleep 2
}

#######################################
# Start application
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
#######################################
function start() {

    echo "Start application"

    exec /temp/entrypoint.sh
}

main 
