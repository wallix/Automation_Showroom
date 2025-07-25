#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# install_replication.sh
#
# This script automates the initialization and installation of bastion replication
# on a Wallix Bastion server. It is designed to run during cloud-init, handling
# the following tasks:
#   - Ensures the script is executed only once during cloud-init by self-modifying.
#   - Waits for the replication configuration file to be available.
#   - Moves the configuration file to the appropriate location.
#   - Waits for cloud-init completion and unlocks bastion encryption.
#   - Initiates the bastion replication installation process.
#
# All output is logged to /root/replicascript.log for troubleshooting.
# ------------------------------------------------------------------------------

set -x
exec &> /root/replicascript.log

CLOUD_INIT=true
SCRIPT_NEW_PATH="/root/install_replication.sh"


source /root/.bashrc
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/wab/bin:/opt/wab/sbin

if [[ "${CLOUD_INIT}" == "true" ]]; then
    cp "$0" "${SCRIPT_NEW_PATH}"
    sed 's/CLOUD_INIT=true/CLOUD_INIT=false/' "$0" > "${SCRIPT_NEW_PATH}"
    chmod 700 "${SCRIPT_NEW_PATH}"
    nohup "${SCRIPT_NEW_PATH}" >/dev/null 2>&1 &
    exit 0
else
    echo "CLOUD_INIT is not true, continuing..."
fi

timeout=300   # 5 minutes in seconds
interval=10   # check every 10 seconds
src="/home/wabadmin/info_replication.txt"
dst="/root/info_replication.txt"

elapsed=0
while [[ ! -f "${src}" ]] && [[ ${elapsed} -lt ${timeout} ]]; do
    sleep "${interval}"
    elapsed=$((elapsed + interval))
done

if [[ -f "${src}" ]]; then
    # Move the file to the root directory
    echo "File info_replication.txt found, moving to /root"
    mv "${src}" "${dst}"
    # Wait for cloud-init to finish
    cloud-init status --wait
    unlock_timeout=300   # 5 minutes in seconds
    unlock_interval=10   # check every 10 seconds
    unlock_elapsed=0
    while true; do
        unlock_output=$(bastion-unlock-crypto -b)
        if [[ "${unlock_output}" == *"Bastion encryption is already unlocked"* ]]; then
            break
        fi
        if [[ ${unlock_elapsed} -ge ${unlock_timeout} ]]; then
            echo "Timeout: Bastion encryption was not unlocked after 10 minutes. Exiting."
            exit 1
        fi
        sleep "${unlock_interval}"
        unlock_elapsed=$((unlock_elapsed + unlock_interval))
    done
    echo "Starting bastion replication..."
    cd /root || return
    /opt/wab/sbin/bastion-replication --install
else
    echo "File info_replication.txt not found after 5 minutes."
    exit 1
fi