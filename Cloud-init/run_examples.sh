#!/bin/bash
# Example script for the WALLIX cloud-init generator
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/generated_examples"
GENERATOR="${SCRIPT_DIR}/wallix_cloud_init_generator.py"

# Clean up previous examples
# If there are existing JSON files in the output dir, archive them instead of deleting
if [ -d "${OUTPUT_DIR}" ]; then
    # Enable nullglob so the glob expands to empty array if no matches
    shopt -s nullglob
    json_files=("${OUTPUT_DIR}"/*.json)
    shopt -u nullglob

    if [ ${#json_files[@]} -gt 0 ]; then
        ARCHIVE_DIR="${OUTPUT_DIR}/archives"
        mkdir -p "$ARCHIVE_DIR"
        timestamp=$(date +%Y%m%d_%H%M%S)
        archive_path="${ARCHIVE_DIR}/archive_${timestamp}.tar.gz"

        # Create tar.gz archive of the json files (from OUTPUT_DIR) and remove originals on success
        (cd "$OUTPUT_DIR" && tar -czf "$archive_path" ./*.json) \
            && printf "Archived %d json file(s) to %s\n" "${#json_files[@]}" "$archive_path" \
            || { echo "Failed to create archive at $archive_path"; exit 1; }

        for f in "${json_files[@]}"; do
            rm -f "$f"
        done
    fi
fi
mkdir -p "$OUTPUT_DIR"

function run_example() {
    local config_file="$1"
    local subdir="$2"
    local description="$3"
    echo -e "\n\033[1;36m$description\033[0m"
    echo "📝 Configuration file used: $config_file"
    python3 "$GENERATOR" --config-file "$config_file" --output-dir "$OUTPUT_DIR/$subdir"
    echo "✅ Files generated in: $OUTPUT_DIR/$subdir"
}

# Run examples
echo "🚀 Generating WALLIX cloud-init configuration examples"
echo "===================================================="

# 1. Minimal Bastion
run_example "$SCRIPT_DIR/config_example/config_basic.json" "01_basic" "Example 1: Minimal Bastion (users, password, FR keyboard)"

# 2. Simple Access Manager
run_example "$SCRIPT_DIR/config_example/config_access_manager.json" "02_access_manager" "Example 2: Simple Access Manager"

# 3. Bastion with advanced network configuration
run_example "$SCRIPT_DIR/config_example/config_network.json" "03_network" "Example 3: Bastion with advanced network configuration (DHCP + Static IP)"

# 4. Bastion with load balancer
run_example "$SCRIPT_DIR/config_example/config_loadbalancer.json" "04_loadbalancer" "Example 4: Bastion with load balancer configuration"

# 5. Access Manager with WebAdmin/crypto
run_example "$SCRIPT_DIR/config_example/config_webadminpass_crypto.json" "05_webadmin_crypto" "Example 5: Access Manager with WebAdmin password and crypto key generation"

# 6. Complete Bastion configuration
run_example "$SCRIPT_DIR/config_example/config_bastion_full.json" "06_bastion_full" "Example 6: Complete Bastion with all options"

# 7. Bastion with hashed passwords (enhanced security)
run_example "$SCRIPT_DIR/config_example/config_hashed_passwords.json" "07_hashed_passwords" "Example 7: Bastion with SHA-512 hashed passwords for enhanced security"


# Example with command line options
echo -e "\n\033[1;36mExample 8: Configuration via command line options\033[0m"
echo "📝 Command line options"

CMD="python3 \"$GENERATOR\" \
    --output-dir \"$OUTPUT_DIR/08_cli_options\" \
    --hostname \"wallix-host-cli\" \
    --fqdn \"wallix-host-cli.domain.local\" \
    --set-service-user-password \
    --set-webui-password-and-crypto \
    --set-keyboard-fr \
    --generate-network-config"
echo "$CMD"
eval $CMD

echo "✅ Files generated in: $OUTPUT_DIR/08_cli_options"

# Example with compression and encoding
echo -e "\n\033[1;36mExample 9: Compressed and base64 encoded configuration\033[0m"
echo "📝 Options: --to-gzip --to-base64-encode"

CMD="python3 \"$GENERATOR\" \
    --output-dir \"$OUTPUT_DIR/09_compressed\" \
    --set-service-user-password \
    --to-gzip \
    --to-base64-encode"
echo "$CMD"
eval $CMD

echo "✅ Files generated in: $OUTPUT_DIR/09_compressed"
set x
echo -e "\n\033[1;32m🎉 ALL EXAMPLES GENERATED SUCCESSFULLY!\033[0m"
echo "=========================================="
echo ""
echo "📂 Check the generated directories for output files:"
echo "   • user-data                   - The cloud-init configuration file"
echo "   • generated_passwords.json    - All generated passwords"
echo "   • config.json                 - Configuration used for generation"
echo "   • network-config              - Network configuration (if enabled)"
echo ""
echo "📋 Usage in Terraform (example):"
echo '   data "local_file" "user_data" {'
echo '     filename = "./cloud-init/generated/01_basic/user-data"'
echo '   }'
echo ""
echo '   resource "aws_instance" "wallix_instance" {'
echo '     user_data = data.local_file.user_data.content'
echo '     # ... other configurations'
echo '   }'
echo ""
echo "🚀 For more options:"
echo "   ./wallix_cloud_init_generator.py --help"