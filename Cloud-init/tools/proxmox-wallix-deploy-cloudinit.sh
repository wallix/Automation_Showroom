#!/bin/bash
# Simple Proxmox VM deployment script using generated cloud-init files
# Usage: ./proxmox-wallix-deploy-cloudinit.sh [output_directory]

# --- CONFIGURATION ---
VMID=9003                              # Unique VM ID
VM_NAME="wallix-host-${VMID}"          # VM name
VM_MEMORY=8192                         # Memory (MB)
VM_CORES=4                             # CPU cores
CLOUD_INIT_DIR="${1:-output}"          # Cloud-init directory (default: 'output')
ISO_NAME="bastion-12.0.15.iso"         # ISO image name
STORAGE_NAME="local"                   # Proxmox storage name
CPU_TYPE="host"                        # CPU type (host = use all host CPU features)


# --- PATHS ---
USER_DATA_FILE="$CLOUD_INIT_DIR/user-data"
NETWORK_CONFIG_FILE="$CLOUD_INIT_DIR/network-config"

# --- SIMPLE CHECKS ---
echo "Creating VM $VM_NAME (ID: $VMID) from scratch"
echo "Using cloud-init files from: $CLOUD_INIT_DIR"

# Check if files exist
if [ ! -f "$USER_DATA_FILE" ] || [ ! -f "$NETWORK_CONFIG_FILE" ]; then
    echo "Error: Cloud-init files not found!"
    echo "Generate them first: python3 ../wallix_cloud_init_generator.py --output-dir $CLOUD_INIT_DIR"
    exit 1
fi

# --- CREATE VM ---
echo "1. Creating VM from scratch..."
qm create $VMID --name "$VM_NAME" --memory $VM_MEMORY --cores $VM_CORES
qm set $VMID --scsihw virtio-scsi-single
qm set $VMID --scsi0 $STORAGE_NAME:80
qm set $VMID --ide2 $STORAGE_NAME:cloudinit
qm set $VMID --ide0 $STORAGE_NAME:iso/$ISO_NAME,media=cdrom
qm set $VMID --net0 virtio,bridge=vmbr0
qm set $VMID --boot order=scsi0,ide0
qm set $VMID --cpu $CPU_TYPE

# Set machine type to q35 for better compatibility
echo "Setting machine type to q35 for better compatibility..."
qm set $VMID --machine q35

# Note: The --cpu-flags option was removed as it caused errors
# CPU type is already set to 'host' which provides all host CPU features

echo "2. Setting cloud-init files..."
cp "$USER_DATA_FILE" "/var/lib/vz/snippets/user-data-${VMID}"
cp "$NETWORK_CONFIG_FILE" "/var/lib/vz/snippets/network-config-${VMID}"
qm set $VMID --cicustom "user=$STORAGE_NAME:snippets/user-data-${VMID},network=$STORAGE_NAME:snippets/network-config-${VMID}"

echo "3. Starting VM..."
qm start $VMID

echo "Done! VM $VMID started with cloud-init configuration."