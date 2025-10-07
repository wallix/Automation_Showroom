# -*- coding: utf-8 -*-
# Copyright: (c) 2024, WALLIX
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)
from ansible.module_utils._text import to_bytes
from ansible.plugins.become import BecomeBase
__metaclass__ = type

DOCUMENTATION = """
    name: wallix_super
    short_description: WALLIX Bastion privilege escalation using 'super' command
    description:
        - This become plugin allows privilege escalation on WALLIX Bastion systems.
        - It uses the 'super' command to escalate from wabadmin to wabsuper (requires wabsuper password).
        - Then optionally uses 'sudo' to become root or another user (uses same wabsuper password).
        - Designed for multi-hop privilege escalation specific to WALLIX Bastion.
        - Note The become password should be the wabsuper password, not wabadmin.
    author: WALLIX
    version_added: "2.9"
    options:
        become_user:
            description: 
                - User to become after privilege escalation
                - Use 'wabsuper' to become wabsuper only
                - Use 'root' to become wabsuper then root
            ini:
              - section: privilege_escalation
                key: become_user
              - section: wallix_super_become_plugin
                key: user
            vars:
              - name: ansible_become_user
            env:
              - name: ANSIBLE_BECOME_USER
            keyword:
              - name: become_user
        become_exe:
            description:
                - Path to WABSuper executable or wrapper
                - Use /tmp/wabsuper-wrapper.py (Python wrapper with proper stdin handling)
            default: /tmp/wabsuper-wrapper.py
            ini:
              - section: privilege_escalation
                key: become_exe
              - section: wallix_super_become_plugin
                key: executable
            vars:
              - name: ansible_become_exe
            env:
              - name: ANSIBLE_BECOME_EXE
            keyword:
              - name: become_exe
        become_flags:
            description: Options to pass to super/sudo
            default: ''
            ini:
              - section: privilege_escalation
                key: become_flags
              - section: wallix_super_become_plugin
                key: flags
            vars:
              - name: ansible_become_flags
            env:
              - name: ANSIBLE_BECOME_FLAGS
            keyword:
              - name: become_flags
        become_pass:
            description: 
                - Password for privilege escalation (wabsuper password)
                - This is NOT the wabadmin password
                - The wabsuper password is used for both 'super' and 'sudo' commands
            required: False
            vars:
              - name: ansible_become_password
              - name: ansible_become_pass
            env:
              - name: ANSIBLE_BECOME_PASS
    notes:
        - This plugin is specifically designed for WALLIX Bastion systems
        - The escalation path is: wabadmin -> super -> wabsuper -> sudo -> root
        - Password prompts are handled for both 'super' and 'sudo' commands
"""


class BecomeModule(BecomeBase):

    name = 'wallix_super'
    prompt = 'Password:'
    fail = ('Authentication failure',)
    success = ('Success',)

    def build_become_command(self, cmd, shell):
        """
        Build the privilege escalation command for WALLIX Bastion

        Uses WABSuper wrapper (with env var) to become wabsuper:
        - To become wabsuper: ANSIBLE_BECOME_PASS=xxx WABSuper-ansible 'command'
        - To become root: ANSIBLE_BECOME_PASS=xxx WABSuper-ansible 'sudo -i'

        Args:
            cmd: The command to execute with elevated privileges
            shell: Shell object for command building

        Returns:
            Complete command with privilege escalation
        """
        super(BecomeModule, self).build_become_command(cmd, shell)

        # Don't prompt for password - we pass it via env var
        self.prompt = False

        if not cmd:
            return cmd

        # Get options
        become_user = self.get_option('become_user')
        become_exe = self.get_option('become_exe') or \
            '/tmp/wabsuper-wrapper.py'
        become_flags = self.get_option('become_flags') or ''
        become_pass = self.get_option('become_pass')

        # Default to root if not specified
        if not become_user:
            become_user = 'root'

        # Build success command wrapper
        success_cmd = self._build_success_command(cmd, shell)

        # Pass password via environment variable
        env_prefix = ''
        if become_pass:
            # Escape single quotes in password
            safe_pass = become_pass.replace("'", "'\\''")
            env_prefix = "ANSIBLE_BECOME_PASS='%s' " % safe_pass

        # Build the command based on target user
        if become_user == 'wabsuper':
            # WABSuper wrapper becomes wabsuper (password from env var)
            return '%s%s %s %s' % (env_prefix, become_exe, become_flags, shell.quote(success_cmd))

        elif become_user == 'root':
            # Two-step: WABSuper to wabsuper, then sudo to root
            inner_sudo = 'sudo -S -H -i %s' % success_cmd
            return '%s%s %s %s' % (env_prefix, become_exe, become_flags, shell.quote(inner_sudo))

        else:
            # Custom user: wabsuper -> sudo -u <user>
            inner_sudo = 'sudo -S -H -u %s %s' % (become_user, success_cmd)
            return '%s%s %s %s' % (env_prefix, become_exe, become_flags, shell.quote(inner_sudo))

    def check_password_prompt(self, b_output):
        """
        Check if the output contains a password prompt

        Args:
            b_output: Bytes output from the command

        Returns:
            Boolean indicating if a password prompt was detected
        """
        #  Check for sudo password prompt (used by WABSuper wrapper)
        prompts = [
            b'[sudo] password for',
            b'Password:',
            b'password:',
            b'Password for',
            b'super password:',
        ]

        # Check if any prompt appears in the output
        for prompt in prompts:
            if prompt in b_output.lower():
                return True
        return False

    def check_success(self, b_output):
        """
        Check if privilege escalation was successful

        Args:
            b_output: Bytes output from the command

        Returns:
            Boolean indicating success
        """
        # If no failure indicators, assume success
        return not self.check_incorrect_password(b_output)

    def check_incorrect_password(self, b_output):
        """
        Check if the output indicates an incorrect password

        Args:
            b_output: Bytes output from the command

        Returns:
            Boolean indicating if password was incorrect
        """
        incorrect_markers = [
            b'Sorry, try again',
            b'Authentication failure',
            b'Permission denied',
            b'incorrect password',
            b'authentication failed',
            b'Access denied',
            b'sudo: 3 incorrect password attempts',
        ]

        return any(marker in b_output.lower() for marker in incorrect_markers)
