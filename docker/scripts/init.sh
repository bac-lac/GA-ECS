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
    wait_for_database_service_availability
    create_database_and_credentials
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
# Wait until a given database service becomes available.
# Fail if the database service is not available after a given duration.
# Globals:
#   DB_ADDRESS
# Arguments:
#   None
# Outputs:
#   None
#######################################
function wait_for_database_service_availability() {
    echo "Wait for database"
    # Parameters
    local database_host="$DB_ADDRESS"    
    local database_port="3306"
    local maximum_wait="15"

    # Variables
    local wait_time

    echo "Pinging database service ${database_host}:${database_port} until readiness for a maximum of ${maximum_wait} seconds..."
    wait_time=0
    until mysqladmin ping --host "${database_host}" --port "${database_port}" --silent; do
        if [[ ${wait_time} -ge ${maximum_wait} ]]; then
            echo "The database service did not start within ${wait_time} s. Aborting."
            exit 1
        else
            echo "Waiting for the database service to start (${wait_time} s)..."
            sleep 1
            ((++wait_time))
        fi
    done
    echo "Database service is up and running."
}

#######################################
# Create Database and Credentials
# Globals:
#   ADMIN_DB_PASSWORD
#   ADMIN_DB_USERNAME
#   DB_ADDRESS
#   DB_PASSWORD
#   DB_USERNAME
#   FORCE_REFRESH
# Arguments:
#   None
# Outputs:
#   None
#######################################
function create_database_and_credentials() {
    echo "Create Database"

    # Drop database if FORCE_REFRESH is true
    if [[ "${FORCE_REFRESH^^}" == "TRUE" ]]; then 
        echo "Drop MySQL database..."
        mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" --execute "WARNINGS; DROP DATABASE IF EXISTS \`GADATA\`;"

        echo "Deleting MySQL database user..."
        mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" --execute "WARNINGS; DROP USER IF EXISTS \`$DB_USERNAME\`;"
    fi

    # check if the database already exists
    echo "Check if the database already exists"
    result=$(mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='GADATA'" 2>&1)
    if [[ $result =~ "GADATA" ]]; then 
        echo "Database exists";
    else
        echo "Database does not exists";
        echo "Creating MySQL database if not existing..."
        mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" --execute "WARNINGS; CREATE DATABASE IF NOT EXISTS \`GADATA\` CHARSET=UTF8;"

        echo "Creating MySQL database user if not existing..."
        mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" --execute "WARNINGS; CREATE USER IF NOT EXISTS \`$DB_USERNAME\` IDENTIFIED BY '$DB_PASSWORD';"

        echo "Granting all privileges on MySQL database objects to user..."
        mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" --execute "WARNINGS; GRANT ALL PRIVILEGES ON \`GADATA\`.* TO \`$DB_USERNAME\`;"

        echo "Importing empty database..."
        mysql -h "$DB_ADDRESS" -u"$ADMIN_DB_USERNAME" -p"$ADMIN_DB_PASSWORD" < /temp/mysql_dump.sql
    fi

}

#######################################
# Configure the application
# Globals:
#   DB_ADDRESS
#   DB_PASSWORD
#   DB_USERNAME
#   ECR_IMAGE
#   FRESH_INSTALL
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

    # Copy filesystem only if FRESH_INSTALL is TRUE or if config folder is empty.
    if [[ "${FRESH_INSTALL^^}" == "TRUE" || -z "$( ls -A "${config_folder}" )" ]]; then 
        echo "Copy filesystem"
        cp -Rf /temp/userdata/ "${opt_ga_folder}"/
        cp -Rf /temp/config/ "${etc_ga_folder}"/
        cp -Rf /temp/tomcat/ "${etc_ga_folder}"/
        cp -Rf /temp/logs/ "${opt_ga_folder}"/tomcat/
        cp -Rf /temp/custom/ "${opt_ga_folder}"/ghttpsroot/
    fi

    # Replace move with remove for upgrade file to eliminate CVEs.
    echo "Replace move with remove for upgrade file"
    sed -i "s|mv upgrader/ga_upgrade.jar upgrader/ga_upgrade_complete.jar|rm upgrader/ga_upgrade.jar|g" /temp/entrypoint.sh

    # Update hostname in entrypoint.
    echo "Update hostname in entrypoint"
    sed -i "s/\$HOSTNAME/\$SYSTEM_NAME/g" /temp/entrypoint.sh

    # Update the file database.xml with the correct values.
    echo "Update database config"
    sed -i "s|password\">.*<|password\">$DB_PASSWORD<|g" "${config_folder}"/database.xml
    sed -i "s|username\">.*<|username\">$DB_USERNAME<|g" "${config_folder}"/database.xml
    sed -i "s|url\">.*<|url\">jdbc:mariadb://$DB_ADDRESS:3306/GADATA?useCursorFetch=true\&amp;defaultFetchSize=20\&amp;characterEncoding=utf8\&amp;allowPublicKeyRetrieval=true<|g" "${config_folder}"/database.xml
    sed -i "s|driverClassName\">.*<|driverClassName\">org.mariadb.jdbc.Driver<|g" "${config_folder}"/database.xml
    sed -i "s|passwordIsEncrypted\">.*<|passwordIsEncrypted\">false<|g" "${config_folder}"/database.xml

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
