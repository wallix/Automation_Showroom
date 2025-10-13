#!/usr/bin/env python3
# flake8: noqa: E501
"""
WALLIX Cloud-Init Generator - Unified Version
Portable Python script to generate cloud-init configurations for
WALLIX Access Manager and Session Manager
"""

import os
import sys
import json
import base64
import gzip
import argparse
import secrets
import string
import time
import platform
import logging
from datetime import datetime, timezone
from typing import Dict, Optional, Any, List
from pathlib import Path
from passlib.hash import sha512_crypt
import yaml

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)


class WallixCloudInitGenerator:
    """
    Unified WALLIX Cloud-Init Generator
    Combines all functionality in a single script with external templates
    """

    def __init__(self, base_path: Optional[str] = None) -> None:
        """Initialize generator with base path"""
        self.base_path = Path(base_path) if base_path else Path(__file__).parent
        self.templates_path = self.base_path / "templates"
        self.scripts_path = self.base_path / "scripts"
        self.passwords: Dict[str, str] = {}

        # Verify required directories exist
        self._verify_directories()

    def _verify_directories(self) -> None:
        """Verify that required directories and files exist"""
        required_files = [
            self.scripts_path / "webadminpass-crypto.py",
            self.scripts_path / "install_replication.sh"
        ]

        missing_files: List[str] = [str(f)
                                    for f in required_files if not f.exists()]

        if missing_files:
            logging.error("Missing required template/script files:")
            for file in missing_files:
                logging.error(f"   • {file}")
            logging.info("\nExpected structure:\n"
                         "   cloud-init/\n"
                         "   ├── wallix_cloud_init_generator.py\n"
                         "   ├── templates/\n"
                         "   │   ├── cloud-init-conf-WALLIX_UNIFIED.tpl\n"
                         "   │   └── network-config.tpl\n"
                         "   │   └── network-config.tpl\n"
                         "   └── scripts/\n"
                         "       ├── webadminpass-crypto.py\n"
                         "       └── install_replication.sh")
            sys.exit(1)

    def generate_passwords(self) -> Dict[str, str]:
        """Generate all required passwords for WALLIX services"""
        wallix_accounts = ["wabadmin", "wabsuper", "wabupgrade"]

        for account in wallix_accounts:
            self.passwords[f"password_{account}"] = self._generate_secure_password(
            )

        self.passwords["webui_password"] = self._generate_secure_password()
        self.passwords["cryptokey_password"] = self._generate_secure_password()

        return self.passwords

    def _generate_password_hash(self, password: str) -> str:
        """Generate SHA-512 hash for password (compatible with Linux shadow file)"""
        # Use passlib for better cross-platform compatibility and enhanced security
        # Default rounds=656000 provides good security while maintaining compatibility
        return sha512_crypt.hash(password)

    def generate_password_hashes(self) -> Dict[str, str]:
        """Generate hashes for all stored passwords"""
        password_hashes = {}
        if hasattr(self, 'passwords') and self.passwords:
            for key, password in self.passwords.items():
                if password and key.startswith('password_'):
                    # Create hash key: password_wabadmin -> wabadmin_password_hash
                    account = key.replace('password_', '')
                    hash_key = f'{account}_password_hash'
                    password_hashes[hash_key] = self._generate_password_hash(password)
        return password_hashes

    def _get_ssh_public_key(self, ssh_key_path: Optional[str] = None) -> Optional[str]:
        """Load SSH public key from file or return None"""
        if not ssh_key_path:
            return None

        try:
            with open(ssh_key_path, 'r', encoding='utf-8') as f:
                key_content = f.read().strip()
                if key_content:
                    return key_content
        except FileNotFoundError:
            logging.warning(f"SSH key file not found: {ssh_key_path}")
        except Exception as e:
            logging.warning(f"Error reading SSH key file: {e}")

        return None

    def _generate_secure_password(self, length: int = 16) -> str:
        """Generate a secure password with specific constraints"""
        lowercase = string.ascii_lowercase
        uppercase = string.ascii_uppercase
        digits = string.digits
        special = "-_=+"
        all_chars = lowercase + uppercase + digits + special

        password = [
            secrets.choice(lowercase),
            secrets.choice(uppercase),
            secrets.choice(digits),
            secrets.choice(special)
        ]

        password += [secrets.choice(all_chars) for _ in range(length - 4)]
        secrets.SystemRandom().shuffle(password)
        return ''.join(password)

    def _load_template(self, template_name: str) -> str:
        """Load a template file from the templates directory"""
        template_path = self.templates_path / template_name
        try:
            with template_path.open('r', encoding='utf-8') as f:
                return f.read()
        except FileNotFoundError as e:
            logging.error(f"Template file not found: {template_path}")
            sys.exit(1)
        except Exception as e:
            logging.error(f"Error loading template {template_name}: {e}")
            sys.exit(1)

    def _load_script(self, script_name: str) -> str:
        """Load a script file from the scripts directory"""
        script_path = self.scripts_path / script_name
        try:
            with script_path.open('r', encoding='utf-8') as f:
                return f.read()
        except FileNotFoundError as e:
            logging.error(f"Script file not found: {script_path}")
            sys.exit(1)
        except Exception as e:
            logging.error(f"Error loading script {script_name}: {e}")
            sys.exit(1)

    def create_wallix_header(self) -> str:
        """Generate WALLIX-branded header for cloud-init files"""
        current_time = datetime.now(timezone.utc).strftime(
            "%Y-%m-%d %H:%M:%S UTC")
        hostname = platform.node()

        return f"""#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                        WALLIX PAM CLOUD-INIT                                  ║
# ║                     Privileged Access Management Solution                     ║
# ╠═══════════════════════════════════════════════════════════════════════════════╣
# ║ Generated on: {current_time:<54}                                              ║
# ║ Generated by: WALLIX Cloud-Init Generator v1.0                                ║
# ║ Host system:  {hostname:<54}                                                  ║
# ║ Repository:   github.com/wallix/Automation_Showroom                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# This configuration has been generated for WALLIX PAM deployment.
# It contains cloud-init instructions for complete system setup.
#
# ⚠️  WARNING: This file contains sensitive security configurations.
#    Handle with appropriate security measures.
#
# 📚 Documentation: https://doc.wallix.com
# 🔧 Support: support@wallix.com
#

"""

    def create_webui_crypto_script(self, use_webui_crypto: bool = False) -> Optional[str]:
        """Create WebUI and crypto script from template"""
        if not use_webui_crypto:
            return None

        script_template = self._load_script("webadminpass-crypto.py")
        return script_template.replace(
            "${webui_password}", self.passwords['webui_password']
        ).replace(
            "${cryptokey_password}", self.passwords['cryptokey_password']
        )

    def create_replication_script(self, use_replication: bool = False) -> Optional[str]:
        """Load replication script from file"""
        if not use_replication:
            return None

        return self._load_script("install_replication.sh")

    def generate_network_config(self, config_options: Dict[str, Any]) -> str:
        """Generate network-config file for NoCloud datasource"""
        template_vars = self._prepare_network_vars(config_options)
        return self._render_template('network-config.tpl', template_vars)

    def _prepare_network_vars(self, config_options: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare variables for network configuration template"""
        # Network renderer
        renderer = config_options.get('network_renderer', '')
        network_renderer = f"renderer: {renderer.lower()}\n" if renderer else ""

        # Network interfaces
        interfaces = config_options.get('network_interfaces', ['eth0:dhcp4'])
        static_configs = config_options.get('static_ip_config', [])

        # Parse static IP configurations
        static_ip_map = {}
        for static_config in static_configs:
            try:
                parts = static_config.split(':')
                if len(parts) >= 4:
                    interface, ip_mask, gateway, dns_list = parts[0], parts[1], parts[2], parts[3]
                    ip, mask = ip_mask.split('/')
                    dns_servers = dns_list.split(',') if dns_list else []
                    static_ip_map[interface] = {
                        'ip': ip,
                        'netmask': mask,
                        'gateway': gateway,
                        'dns': dns_servers
                    }
            except (ValueError, IndexError):
                logging.warning(
                    f"Invalid static IP configuration: {static_config}")

        # Build interfaces configuration
        interfaces_config = []
        for interface_config in interfaces:
            try:
                interface_name, config_type = interface_config.split(':', 1)
                interface_block = f"  {interface_name}:\n"

                if config_type == 'dhcp4':
                    interface_block += "    dhcp4: true\n"
                elif config_type == 'dhcp6':
                    interface_block += "    dhcp6: true\n"
                elif config_type == 'static' and interface_name in static_ip_map:
                    static_info = static_ip_map[interface_name]
                    interface_block += "    dhcp4: false\n"
                    interface_block += "    addresses:\n"
                    interface_block += f"      - {static_info['ip']}/{static_info['netmask']}\n"
                    if static_info['gateway']:
                        interface_block += "    routes:\n"
                        interface_block += f"      - to: 0.0.0.0/0\n"
                        interface_block += f"        via: {static_info['gateway']}\n"
                    if static_info['dns']:
                        interface_block += "    nameservers:\n"
                        interface_block += "      addresses:\n"
                        for dns in static_info['dns']:
                            if dns.strip():
                                interface_block += f"        - {dns.strip()}\n"
                else:
                    interface_block += "    dhcp4: true\n"  # default fallback

                interfaces_config.append(interface_block)

            except ValueError:
                logging.warning(
                    f"Invalid interface configuration: {interface_config}")
                # Fallback to DHCP
                interfaces_config.append(
                    f"  {interface_config}:\n    dhcp4: true\n")

        # Network bonds
        bonds = config_options.get('network_bonds', [])
        bonds_config = []
        if bonds:
            for bond_config in bonds:
                try:
                    bond_parts = bond_config.split(':')
                    if len(bond_parts) >= 3:
                        bond_name, interfaces_list, mode = bond_parts[0], bond_parts[1], bond_parts[2]
                        bond_interfaces = interfaces_list.split(',')

                        bonds_config.append("bonds:\n")
                        bonds_config.append(f"  {bond_name}:\n")
                        bonds_config.append("    interfaces:\n")
                        for iface in bond_interfaces:
                            bonds_config.append(f"      - {iface.strip()}\n")
                        bonds_config.append("    parameters:\n")
                        bonds_config.append(f"      mode: {mode}\n")
                        bonds_config.append("    dhcp4: true\n")
                        break  # Only support one bond for now
                except (ValueError, IndexError):
                    logging.warning(
                        f"Invalid bond configuration: {bond_config}")

        # Network VLANs
        vlans = config_options.get('network_vlans', [])
        vlans_config = []
        if vlans:
            for vlan_config in vlans:
                try:
                    vlan_parts = vlan_config.split(':')
                    if len(vlan_parts) >= 3:
                        vlan_name, parent_iface, vlan_id = vlan_parts[0], vlan_parts[1], vlan_parts[2]

                        vlans_config.append("vlans:\n")
                        vlans_config.append(f"  {vlan_name}:\n")
                        vlans_config.append(f"    id: {vlan_id}\n")
                        vlans_config.append(f"    link: {parent_iface}\n")
                        vlans_config.append("    dhcp4: true\n")
                        break  # Only support one VLAN for now
                except (ValueError, IndexError):
                    logging.warning(
                        f"Invalid VLAN configuration: {vlan_config}")

        return {
            'network_renderer': network_renderer,
            'network_interfaces': ''.join(interfaces_config),
            'network_bonds': ''.join(bonds_config),
            'network_vlans': ''.join(vlans_config),
            'network_bridges': "",  # Placeholder for future bridge support
            'network_routes': "",   # Placeholder for future global routes
            'network_nameservers': ""  # Placeholder for global nameservers
        }

    def generate_cloud_init_config(self, config_options: Dict[str, Any]) -> str:
        """Generate complete cloud-init configuration"""
        # Generate passwords if required
        if (config_options.get('set_service_user_password', False) or
                config_options.get('set_webui_password_and_crypto', False)):
            self.generate_passwords()

        # Prepare template variables
        template_vars = self._prepare_template_vars(config_options)

        # Select template based on password type
        if config_options.get('use_hashed_passwords', False):
            base_template = 'cloud-init-conf-WALLIX_HASHED.tpl'
            logging.info("Using hashed passwords template for enhanced security")
        else:
            base_template = 'cloud-init-conf-WALLIX_UNIFIED.tpl'
            logging.info("Using plain text passwords template")

        # Generate simple YAML cloud-config (not multipart)
        cloud_config_content = self._render_template(
            base_template, template_vars)

        # Apply compression and encoding if requested
        if config_options.get('to_gzip', False):
            logging.info("Compressing with gzip...")
            cloud_config_content = gzip.compress(
                cloud_config_content.encode('utf-8'))

        if config_options.get('to_base64_encode', False):
            logging.info("Encoding in base64...")
            if isinstance(cloud_config_content, bytes):
                cloud_config_content = base64.b64encode(
                    cloud_config_content).decode('utf-8')
            else:
                cloud_config_content = base64.b64encode(
                    cloud_config_content.encode('utf-8')).decode('utf-8')

        return cloud_config_content if isinstance(cloud_config_content, str) else cloud_config_content.decode('utf-8')

    def _prepare_template_vars(self, config_options: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare variables for template rendering"""
        # Inject all config options as template variables
        template_vars = dict(config_options)
        # Set defaults if missing
        template_vars.setdefault('hostname', 'wallix-host')
        template_vars.setdefault('fqdn', 'wallix-host.domain.local')
        template_vars.setdefault('manage_etc_hosts', 'true')
        template_vars.setdefault('preserve_sources_list', 'true')
        template_vars.setdefault('product_type', 'bastion')

        # Add SSH public key if provided
        ssh_key = self._get_ssh_public_key(
            config_options.get('ssh_public_key_path'))
        if ssh_key:
            template_vars['ssh_public_key'] = ssh_key
        else:
            template_vars['ssh_public_key'] = ''

        # Add passwords if passwords are generated
        if hasattr(self, 'passwords') and self.passwords:
            use_hashed_passwords = config_options.get('use_hashed_passwords', False)
            
            if use_hashed_passwords:
                # Generate and add password hashes
                password_hashes = self.generate_password_hashes()
                template_vars.update(password_hashes)
                # Also add empty plain password fields for compatibility
                for account in ['wabadmin', 'wabsuper', 'wabupgrade']:
                    template_vars[f'{account}_password'] = ''
            else:
                # Add plain text passwords (current behavior)
                for account in ['wabadmin', 'wabsuper', 'wabupgrade']:
                    password = self.passwords.get(f'password_{account}', '')
                    if password:
                        template_vars[f'{account}_password'] = password
                    else:
                        template_vars[f'{account}_password'] = ''
                # Add empty hash fields for compatibility
                for account in ['wabadmin', 'wabsuper', 'wabupgrade']:
                    template_vars[f'{account}_password_hash'] = ''

        # Add additional boot commands
        additional_bootcmd = config_options.get('additional_bootcmd', [])
        template_vars['additional_bootcmd'] = additional_bootcmd if additional_bootcmd else []

        return template_vars

    def _render_template(self, template_name: str, variables: Dict[str, Any]) -> str:
        """Render template with variables, handling dynamic sections"""
        template_path = self.templates_path / template_name
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                template = f.read()

            # Process dynamic sections
            template = self._process_dynamic_sections(template, variables)

            # Replace simple variables
            for key, value in variables.items():
                if not key.endswith('_section'):  # Skip section keys
                    template = template.replace(f'{{{key}}}', str(value))

            return template

        except FileNotFoundError:
            logging.error(f"Template not found: {template_path}")
            return ""

    def _process_dynamic_sections(self, template: str, variables: Dict[str, Any]) -> str:
        """Process dynamic sections like SSH keys, packages, etc."""
        # Handle boot commands section (optional keyboard setup)
        bootcmd_lines = []
        if variables.get('set_keyboard_fr', False):
            bootcmd_lines.append(
                '  - sed -i -e "s/us/fr/g" /etc/default/keyboard')

        additional_bootcmd = variables.get('additional_bootcmd', [])
        if additional_bootcmd:
            bootcmd_lines.extend([f'  - {cmd}' for cmd in additional_bootcmd])

        if bootcmd_lines:
            bootcmd_section = 'bootcmd:\n' + '\n'.join(bootcmd_lines)
        else:
            bootcmd_section = ""
        template = template.replace('{bootcmd_section}', bootcmd_section)

        # Handle preserve sources section (bastion only)
        product_type = variables.get('product_type', 'bastion')
        if product_type == 'bastion':
            preserve_val = variables.get('preserve_sources_list', 'true')
            preserve_sources_section = f"preserve_sources_list: {preserve_val}"
        else:
            preserve_sources_section = ""
        template = template.replace('{preserve_sources_section}',
                                    preserve_sources_section)

        # Handle additional config section (bastion only)
        if product_type == 'bastion':
            additional_config_section = (
                "\n# Additional configuration\npreserve_hostname: false"
            )
        else:
            additional_config_section = ""
        template = template.replace('{additional_config_section}',
                                    additional_config_section)

        # Inject scripts if needed
        write_files = []
        runcmd = []

        # Replication script
        if variables.get('install_replication', False):
            try:
                with open('scripts/install_replication.sh', 'r', encoding='utf-8') as f:
                    script_content = f.read()
                write_files.append({
                    'path': '/root/install_replication.sh',
                    'content': script_content,
                    'permissions': '0755'
                })
                runcmd.append(['/root/install_replication.sh'])
            except Exception as e:
                logging.warning(
                    f"Could not inject install_replication.sh: {e}")

        # Webadminpass-crypto script
        if variables.get('set_webui_password_and_crypto', False):
            try:
                with open('scripts/webadminpass-crypto.py', 'r', encoding='utf-8') as f:
                    script_content = f.read()

                # Replace placeholders with actual passwords
                if hasattr(self, 'passwords') and self.passwords:
                    webui_password = self.passwords.get(
                        'webui_password', 'admin')
                    cryptokey_password = self.passwords.get(
                        'cryptokey_password', 'cryptokey')
                    script_content = script_content.replace(
                        '${webui_password}', webui_password)
                    script_content = script_content.replace(
                        '${cryptokey_password}', cryptokey_password)

                # Place the script in /root for better security and visibility
                write_files.append({
                    'path': '/root/webadminpass-crypto.py',
                    'content': script_content,
                    'permissions': '0700'  # Restrict permissions to root only
                })
                # Add command to run the script and then remove it after use
                runcmd.append(['python3', '/root/webadminpass-crypto.py'])
                runcmd.append(['rm', '-f', '/root/webadminpass-crypto.py'])
            except Exception as e:
                logging.warning(
                    f"Could not inject webadminpass-crypto.py: {e}")

        # Format write_files section
        if write_files:
            wf_lines = ['write_files:']
            for wf in write_files:
                wf_lines.append(f"  - path: {wf['path']}")
                wf_lines.append(f"    permissions: '{wf['permissions']}'")
                wf_lines.append(f"    content: |")
                # Properly indent each line of the script content
                for line in wf['content'].splitlines():
                    wf_lines.append(f"      {line}")
            write_files_section = '\n'.join(wf_lines)
        else:
            write_files_section = ''
        template = template.replace(
            '{write_files_section}', write_files_section)

        # Format runcmd section with all commands
        if runcmd or (variables.get('use_of_lb', False) and variables.get('http_host_trusted_hostnames', '')):
            rc_lines = ['runcmd:']

            # Add all existing commands
            for cmd in runcmd:
                if isinstance(cmd, list):
                    rc_lines.append(f"  - {cmd}")
                else:
                    rc_lines.append(f"  - {cmd}")

            # Add load balancer configuration commands if enabled
            if variables.get('use_of_lb', False) and variables.get('http_host_trusted_hostnames', ''):
                trusted_hostnames = variables.get(
                    'http_host_trusted_hostnames')
                rc_lines.append(
                    f"  - [ sh, -xc, python3, -c, \"from wabconfig import Config; Config('wabengine')['http_host_trusted_hostnames'] = '{trusted_hostnames}'\"]")
                rc_lines.append(
                    f"  - [ sh, -xc, \"/opt/wab/bin/WABVersion | grep Bastion || sed -i -e '$aweb.check.session.origin=false' /var/wab/etc/wabam/wabam.properties\" ]")

            runcmd_section = '\n'.join(rc_lines)
        else:
            runcmd_section = ''
        template = template.replace('{runcmd_section}', runcmd_section)

        return template

    def _create_multipart_config(self, parts: List[Dict[str, Any]], config_options: Dict[str, Any]) -> str:
        """Create multipart cloud-init configuration"""
        timestamp = str(int(time.time()))
        boundary = f"WALLIX_PAM_MULTIPART_BOUNDARY_{timestamp}"

        multipart_content = self.create_wallix_header()
        multipart_content += f'Content-Type: multipart/mixed; boundary="{boundary}"\n'
        multipart_content += "MIME-Version: 1.0\n\n"

        for part in parts:
            multipart_content += f"--{boundary}\n"
            multipart_content += f"Content-Type: {part['content-type']}\n"
            multipart_content += f"Content-Disposition: attachment; filename=\"{part['filename']}\"\n"
            multipart_content += f"# {part['comment']}\n\n"
            multipart_content += part['content']
            multipart_content += "\n\n"

        multipart_content += f"--{boundary}--\n"

        # Apply compression and encoding if requested
        if config_options.get('to_gzip', False):
            logging.info("Compressing with gzip...")
            multipart_content = gzip.compress(
                multipart_content.encode('utf-8'))

        if config_options.get('to_base64_encode', False):
            logging.info("Encoding in base64...")
            if isinstance(multipart_content, bytes):
                multipart_content = base64.b64encode(
                    multipart_content).decode('utf-8')
            else:
                multipart_content = base64.b64encode(
                    multipart_content.encode('utf-8')).decode('utf-8')

        return multipart_content if isinstance(multipart_content, str) else multipart_content.decode('utf-8')

    def save_passwords_to_file(self, output_dir: str) -> None:
        """Save generated passwords to JSON file"""
        passwords_file = Path(output_dir) / "generated_passwords.json"
        with passwords_file.open('w', encoding='utf-8') as f:
            json.dump(self.passwords, f, indent=2)
        logging.info(f"Passwords saved to: {passwords_file}")

    def save_config_to_file(self, config_options: Dict[str, Any], output_dir: str) -> None:
        """Save configuration to JSON file"""
        config_file = Path(output_dir) / "config.json"
        with config_file.open('w', encoding='utf-8') as f:
            json.dump(config_options, f, indent=2)
        logging.info(f"Configuration saved to: {config_file}")


def main() -> int:
    """Main function to parse arguments and generate cloud-init"""
    parser = argparse.ArgumentParser(
        description='WALLIX Cloud-Init Generator - Unified Version',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --set-service-user-password
  %(prog)s --config-file config.json
  %(prog)s --set-service-user-password --use-of-lb --http-host-trusted-hostnames "lb.example.com"
  %(prog)s --set-webui-password-and-crypto --install-replication

Templates and scripts location:
  templates/     - Cloud-init templates (.tpl files)
  scripts/       - Target scripts (.py, .sh files)
        """
    )

    parser.add_argument('--output-dir', '-o', default='./output',
                        help='Output directory for generated files (default: ./output)')
    parser.add_argument('--set-service-user-password', action='store_true',
                        help='Set passwords for WALLIX service users (wabadmin, wabsuper, wabupgrade)')
    parser.add_argument('--use-hashed-passwords', action='store_true',
                        help='Use hashed passwords instead of plain text (more secure)')
    parser.add_argument('--use-of-lb', action='store_true',
                        help='Enable load balancer configuration')
    parser.add_argument('--http-host-trusted-hostnames', default='',
                        help='Trusted hostnames for load balancer (comma-separated)')
    parser.add_argument('--set-webui-password-and-crypto', action='store_true',
                        help='Set WebUI password and crypto key (Session Manager only)')
    parser.add_argument('--install-replication', action='store_true',
                        help='Install replication (Session Manager only)')
    parser.add_argument('--to-gzip', action='store_true',
                        help='Compress output with gzip')
    parser.add_argument('--to-base64-encode', action='store_true',
                        help='Encode output in base64')
    parser.add_argument('--config-file', '-c',
                        help='Load configuration from JSON file')
    parser.add_argument('--base-path',
                        help='Base path for templates and scripts (default: script directory)')

    # New dynamic options
    parser.add_argument('--hostname',
                        default='wallix-host',
                        help='Hostname for the WALLIX instance')
    parser.add_argument('--fqdn',
                        default='wallix-host.domain.local',
                        help='Fully qualified domain name')
    parser.add_argument('--ssh-public-key-path',
                        help='Path to SSH public key file for root user')
    parser.add_argument('--product-type',
                        choices=['bastion', 'access-manager'],
                        default='bastion',
                        help='WALLIX product type (bastion or access-manager)')
    parser.add_argument('--additional-bootcmd',
                        nargs='*',
                        default=[],
                        help='Additional commands to run during boot')
    parser.add_argument('--use-custom-passwords',
                        action='store_true',
                        help='Prompt for custom passwords instead of generating them')
    parser.add_argument('--set-keyboard-fr',
                        action='store_true',
                        help='Set keyboard layout to French (fr) instead of US (us)')

    # Network configuration arguments
    parser.add_argument('--generate-network-config',
                        action='store_true',
                        help='Generate network-config file for NoCloud datasource')
    parser.add_argument('--network-interfaces',
                        nargs='*',
                        default=['eth0:dhcp4'],
                        help='Network interfaces configuration (format: interface:dhcp4/dhcp6/static)')
    parser.add_argument('--network-renderer',
                        choices=['networkd', 'NetworkManager'],
                        help='Network renderer to use (networkd or NetworkManager)')
    parser.add_argument('--static-ip-config',
                        nargs='*',
                        default=[],
                        help='Static IP configuration (format: interface:ip/mask:gateway:dns1,dns2)')
    parser.add_argument('--network-bonds',
                        nargs='*',
                        default=[],
                        help='Network bonding configuration (format: bond0:eth0,eth1:mode)')
    parser.add_argument('--network-vlans',
                        nargs='*',
                        default=[],
                        help='VLAN configuration (format: vlan.100:eth0:100)')

    # Show help if no arguments are provided
    if len(sys.argv) == 1:
        parser.print_help()
        return 0

    args = parser.parse_args()

    logging.info("="*70)
    logging.info("WALLIX PAM CLOUD-INIT GENERATOR v1.0")
    logging.info(
        "Unified Portable Generator for WALLIX Access & Session Manager")
    logging.info("="*70)

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    logging.info(f"Output directory: {output_dir}")

    try:
        generator = WallixCloudInitGenerator(args.base_path)
    except SystemExit:
        return 1

    if args.config_file:
        logging.info(f"Loading configuration from: {args.config_file}")
        try:
            with open(args.config_file, 'r', encoding='utf-8') as f:
                config_options = json.load(f)
        except Exception as e:
            logging.error(f"Error loading config file: {e}")
            return 1
    else:
        config_options = {
            'hostname': args.hostname,
            'fqdn': args.fqdn,
            'product_type': args.product_type,
            'set_service_user_password': args.set_service_user_password,
            'use_hashed_passwords': args.use_hashed_passwords,
            'ssh_public_key_path': args.ssh_public_key_path,
            'use_of_lb': args.use_of_lb,
            'http_host_trusted_hostnames': args.http_host_trusted_hostnames,
            'set_webui_password_and_crypto': args.set_webui_password_and_crypto,
            'install_replication': args.install_replication,
            'additional_bootcmd': args.additional_bootcmd,
            'to_gzip': args.to_gzip,
            'to_base64_encode': args.to_base64_encode,
            'set_keyboard_fr': args.set_keyboard_fr,
            'generate_network_config': args.generate_network_config,
            'network_interfaces': args.network_interfaces,
            'network_renderer': args.network_renderer,
            'static_ip_config': args.static_ip_config,
            'network_bonds': args.network_bonds,
            'network_vlans': args.network_vlans
        }

    if (config_options.get('use_of_lb', False) and
            not config_options.get('http_host_trusted_hostnames', '')):
        logging.error(
            "When using load balancer, you must provide trusted hostnames")
        return 1

    try:
        cloud_init_content = generator.generate_cloud_init_config(
            config_options)

        output_file = output_dir / "user-data"
        with output_file.open('w', encoding='utf-8') as f:
            f.write(cloud_init_content)

        # Generate network-config if requested
        if config_options.get('generate_network_config', False):
            network_config_content = generator.generate_network_config(
                config_options)
            network_config_file = output_dir / "network-config"
            with network_config_file.open('w', encoding='utf-8') as f:
                f.write(network_config_content)
            logging.info(f"Network-config file: {network_config_file}")

        generator.save_passwords_to_file(str(output_dir))
        generator.save_config_to_file(config_options, str(output_dir))

        logging.info("="*70)
        logging.info("Cloud-init configuration generated successfully!")
        logging.info(f"User-data file: {output_file}")
        logging.info(
            f"Passwords file: {output_dir / 'generated_passwords.json'}")
        logging.info(f"Config file: {output_dir / 'config.json'}")
        logging.info("="*70)

        return 0

    except (OSError, ValueError, RuntimeError):
        logging.exception("Error generating cloud-init configuration")
        return 1


if __name__ == "__main__":
    sys.exit(main())
