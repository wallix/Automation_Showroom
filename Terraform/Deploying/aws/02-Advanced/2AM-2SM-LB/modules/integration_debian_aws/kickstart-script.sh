#!/usr/bin/env bash

enable_rdp_access() {
    for i in {1..10}; do
        if dpkg -l | grep -qw xrdp; then
            break
        else
            echo "xrdp is not installed. Attempt $i of 10."
            sleep 20
        fi
    done
    if ! dpkg -l | grep -qw xrdp; then
        echo "xrdp is still not installed after 3 checks. Skipping installation."
    fi
    adduser xrdp ssl-cert
    groupadd -f tsusers
    adduser rdpuser tsusers
}

install_terraform_and_clone_repo() {
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    apt update && apt install terraform -y

    mkdir -p /home/rdpuser/Documents
    git clone https://github.com/wallix/Automation_Showroom /home/rdpuser/Documents/Automation_Showroom
    chown -R rdpuser:rdpuser /home/rdpuser/Documents
}

enable_rdp_access
install_terraform_and_clone_repo