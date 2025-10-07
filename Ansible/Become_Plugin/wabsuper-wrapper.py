#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WABSuper Wrapper for Ansible Become Plugin
===========================================

This wrapper enables privilege escalation on WALLIX Bastion using the WABSuper
mechanism. It reads the password from an environment variable (ANSIBLE_BECOME_PASS)
to avoid conflicts with Ansible's pipelining feature.

Compatible with:
- WALLIX Bastion 12.0+
- Ansible 2.9+
- Python 3.6+

Usage:
    ANSIBLE_BECOME_PASS='password' /tmp/wabsuper-wrapper.py -u wabsuper whoami
    ANSIBLE_BECOME_PASS='password' /tmp/wabsuper-wrapper.py -u wabsuper -c "command"

Architecture:
    wabadmin (SSH) → wrapper → sudo -u wabsuper → wabsuper context
    wabsuper → sudo -i → root context (if command contains sudo)

Copyright: (c) 2025, WALLIX
License: GNU General Public License v3.0+
"""

import sys
import os
import subprocess
import argparse


def main():
    """Main execution function"""

    # Parse command-line arguments (sudo-style)
    parser = argparse.ArgumentParser(
        description='WABSuper wrapper for Ansible privilege escalation'
    )
    parser.add_argument(
        '-S', '--stdin',
        action='store_true',
        help='Read password from stdin (ignored, uses env var instead)'
    )
    parser.add_argument(
        '-u', '--user',
        default='wabsuper',
        help='Target user for escalation (default: wabsuper)'
    )
    parser.add_argument(
        '-c', '--command',
        help='Command to execute (optional for interactive shell)'
    )
    parser.add_argument(
        'command_args',
        nargs='*',
        help='Command and arguments (alternative to -c)'
    )

    args, unknown = parser.parse_known_args()

    # Get password from environment variable
    password = os.environ.get('ANSIBLE_BECOME_PASS', '')

    if not password:
        sys.stderr.write(
            "Error: ANSIBLE_BECOME_PASS environment variable not set\n"
            "This wrapper requires the password to be passed via environment.\n"
        )
        sys.exit(1)

    # Build the command to execute
    if args.command:
        # Format: wrapper -u user -c "command"
        cmd_to_run = args.command
    elif args.command_args:
        # Format: wrapper -u user command args
        cmd_to_run = ' '.join(args.command_args)
    else:
        # Interactive shell mode
        cmd_to_run = None

    # Build the sudo command for WABSuper escalation
    if cmd_to_run:
        # Execute specific command as target user
        sudo_cmd = [
            'sudo',
            '-u', args.user,
            '-S',  # Read password from stdin
            '/bin/bash',
            '-c', cmd_to_run
        ]
    else:
        # Interactive login shell
        sudo_cmd = [
            'sudo',
            '-u', args.user,
            '-S',
            '/bin/bash',
            '--login'
        ]

    # Execute the sudo command
    process = subprocess.Popen(
        sudo_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Prepare password input
    # Send password once for wabadmin → wabsuper escalation
    password_input = password + '\n'

    # Check if the command contains a nested sudo (for wabsuper → root)
    # If so, send the password twice (once for each sudo)
    if cmd_to_run and 'sudo' in cmd_to_run:
        # Double escalation detected: wabadmin → wabsuper → root
        password_input = password_input + password + '\n'

    # Send password(s) to sudo via stdin
    stdout, stderr = process.communicate(input=password_input.encode('utf-8'))

    # Output the results
    sys.stdout.buffer.write(stdout)
    sys.stderr.buffer.write(stderr)

    # Exit with the same code as the subprocess
    sys.exit(process.returncode)


if __name__ == '__main__':
    main()
