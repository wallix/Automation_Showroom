#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import json
import traceback

# OpenShift arbitrary UID fix
if 'HOME' not in os.environ:
    os.environ['HOME'] = '/tmp'

# Attempt to patch pwd.getpwuid if possible
try:
    import pwd
    _original_getpwuid = pwd.getpwuid
    def _mock_getpwuid(uid):
        try:
            return _original_getpwuid(uid)
        except KeyError:
            # Return a dummy struct
            import collections
            StructPwd = collections.namedtuple("struct_passwd", ["pw_name", "pw_passwd", "pw_uid", "pw_gid", "pw_gecos", "pw_dir", "pw_shell"])
            return StructPwd("default", "x", uid, 0, "Default User", "/tmp", "/bin/bash")
    pwd.getpwuid = _mock_getpwuid
except ImportError:
    pass

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.urls import fetch_url

DOCUMENTATION = r'''
---
module: secret
short_description: Retrieve a secret from WALLIX PRIVILEGED ACCESS MANAGEMENT
version_added: "1.0.0"
description:
  - This module retrieves a password or SSH key from WALLIX PRIVILEGED ACCESS MANAGEMENT using the API.
options:
  wallix_url:
    description: URL of the Wallix Bastion.
    required: true
    type: str
  api_key:
    description: API Key for authentication (X-Auth-Token).
    required: false
    type: str
    no_log: true
  username:
    description: Username for Basic Auth.
    required: false
    type: str
  password:
    description: Password for Basic Auth.
    required: false
    type: str
    no_log: true
  validate_certs:
    description: Whether to validate SSL certificates.
    required: false
    type: bool
    default: true
  account:
    description: Name of the account.
    required: true
    type: str
  domain:
    description: Domain of the account.
    required: false
    type: str
    default: ""
  device:
    description: Name of the device.
    required: false
    type: str
  application:
    description: Name of the application.
    required: false
    type: str
  key_format:
    description: The format of the SSH private key returned (openssh, pkcs1, pkcs8, putty).
    required: false
    type: str
  cert_format:
    description: The format of the returned certificate (openssh, ssh.com).
    required: false
    type: str
  authorization:
    description: The name of the authorization.
    required: false
    type: str
  duration:
    description: Optional duration for the checkout (in seconds).
    required: false
    type: int
  key_passphrase:
    description: Passphrase used to encrypt the returned SSH key.
    required: false
    type: str
    no_log: true
<<<<<<< HEAD
  validate_certs:
    description: Verify SSL certificates.
    required: false
    type: bool
    default: false
=======
  state:
    description: The action to perform (checkout, checkin, extend).
    required: false
    default: checkout
    choices: [ checkout, checkin, extend ]
    type: str
  force:
    description: Force the checkin (only for state=checkin).
    required: false
    type: bool
    default: false
  comment:
    description: Comment for forced checkin (required if force=true).
    required: false
    type: str
>>>>>>> 7a88c07 (Update collection to wallix.pam_secret_action and update modules)
author:
  - Wallix Integration Team
'''

EXAMPLES = r'''
- name: Get database password (checkout)
  wallix.pam_secret_action.secret:
    wallix_url: "https://bastion.example.com"
    username: "admin"
    password: "password"
    account: "admin"
    domain: "local"
    device: "prod-db-01"
  register: wallix_secret

- name: Extend checkout duration
  wallix.pam_secret_action.secret:
    wallix_url: "https://bastion.example.com"
    username: "admin"
    password: "password"
    account: "root"
    device: "linux-server"
    key_format: "putty"
  register: ssh_key

- name: Extend checkout duration
  wallix.pam_secret_action.secret:
    wallix_url: "https://bastion.example.com"
    api_key: "my-secret-api-key"
    account: "admin"
    domain: "local"
    device: "prod-db-01"
    state: extend
  register: extend_result

- name: Release the secret (checkin)
  wallix.pam_secret_action.secret:
    wallix_url: "https://bastion.example.com"
    api_key: "my-secret-api-key"
    account: "admin"
    domain: "local"
    device: "prod-db-01"
    state: checkin
'''

RETURN = r'''
password:
  description: The retrieved password or SSH key (only for checkout).
  type: str
  returned: when state is checkout
metadata:
  description: Full response from the API.
  type: dict
  returned: always
'''

import requests
import urllib3

# Disable warnings for self-signed certificates if necessary
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def run_module():
    module_args = dict(
        wallix_url=dict(type='str', required=True),
        api_key=dict(type='str', required=False, no_log=True),
        username=dict(type='str', required=False),
        password=dict(type='str', required=False, no_log=True),
        account=dict(type='str', required=True),
        domain=dict(type='str', required=False, default=""),
        device=dict(type='str', required=False),
        application=dict(type='str', required=False),
        key_format=dict(type='str', required=False),
        cert_format=dict(type='str', required=False),
        authorization=dict(type='str', required=False),
        duration=dict(type='int', required=False),
        key_passphrase=dict(type='str', required=False, no_log=True),
        state=dict(type='str', required=False, default='checkout', choices=['checkout', 'checkin', 'extend']),
        force=dict(type='bool', required=False, default=False),
        comment=dict(type='str', required=False),
        validate_certs=dict(type='bool', required=False, default=True)
    )

    result = dict(
        changed=False,
        password='',
        metadata={}
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True,
        required_one_of=[['api_key', 'username']]
    )

    if module.check_mode:
        module.exit_json(**result)

    # Construct account_name
    account = module.params['account']
    domain = module.params['domain']
    device = module.params['device']
    application = module.params['application']

    if device:
        if domain:
            account_name = f"{account}@{domain}@{device}"
        else:
            account_name = f"{account}@{device}"
    elif application:
        if domain:
            account_name = f"{account}@{domain}@{application}"
        else:
            account_name = f"{account}@{application}"
    elif domain:
        account_name = f"{account}@{domain}"
    else:
        account_name = account

    base_url = module.params['wallix_url'].rstrip('/')
    state = module.params['state']
    api_key = module.params['api_key']
    username = module.params['username']
    password = module.params['password']
    
    headers = {
        "Content-Type": "application/json"
    }
    
    auth = None
    if api_key:
        headers["X-Auth-Token"] = api_key
    elif username and password:
        auth = (username, password)
    else:
        module.fail_json(msg="Either api_key or username/password must be provided", **result)

    # DEBUG: Print headers to fail_json for debugging (remove later)
    # module.fail_json(msg=f"DEBUG HEADERS: {headers}", **result)

    try:
        if state == 'checkout':
            url = f"{base_url}/api/targetpasswords/checkout/{account_name}"
            params = {}
            if module.params['key_format']:
                params['key_format'] = module.params['key_format']
            if module.params['cert_format']:
                params['cert_format'] = module.params['cert_format']
            if module.params['authorization']:
                params['authorization'] = module.params['authorization']
            if module.params['duration']:
                params['duration'] = module.params['duration']
            
            if module.params['key_passphrase']:
                headers['X-Key-Passphrase'] = module.params['key_passphrase']

            response = requests.get(url, params=params, headers=headers, auth=auth, verify=module.params['validate_certs'])

        elif state == 'extend':
            url = f"{base_url}/api/targetpasswords/extendcheckout/{account_name}"
            params = {}
            if module.params['authorization']:
                params['authorization'] = module.params['authorization']
            
            response = requests.get(url, params=params, headers=headers, auth=auth, verify=module.params['validate_certs'])
            
        elif state == 'checkin':
            url = f"{base_url}/api/targetpasswords/checkin/{account_name}"
            params = {}
            if module.params['authorization']:
                params['authorization'] = module.params['authorization']
            if module.params['force']:
                params['force'] = 'true'
                if not module.params['comment']:
                    module.fail_json(msg="Comment is required when force is true", **result)
                params['comment'] = module.params['comment']
            
            response = requests.get(url, params=params, headers=headers, auth=auth, verify=module.params['validate_certs'])

        # Handle Response
        if response.status_code == 200:
            data = response.json()
            result['metadata'] = data
            result['changed'] = True # Assuming any successful API call is a change or access
            
            if state == 'checkout':
                if 'login' in data:
                    result['login'] = data['login']
                if 'password' in data:
                    result['password'] = data['password']
                elif 'ssh_key' in data:
                    result['password'] = data['ssh_key']
                    result['ssh_key'] = data['ssh_key']
                elif 'key' in data:
                    result['password'] = data['key']
        else:
            module.fail_json(msg=f"API Error {response.status_code}: {response.text}", **result)

    except Exception as e:
        module.fail_json(msg=f"Request failed: {str(e)}", **result)

    module.exit_json(**result)

def main():
    run_module()

if __name__ == '__main__':
    main()
