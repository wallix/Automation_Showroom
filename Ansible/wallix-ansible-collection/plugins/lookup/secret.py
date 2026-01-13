from __future__ import absolute_import, division, print_function
import urllib3
import requests
import os
from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleError

__metaclass__ = type

DOCUMENTATION = r"""
  name: secret
  author: Wallix Integration Team
  short_description: Look up secrets in WALLIX PRIVILEGED ACCESS MANAGEMENT
  description:
      - This lookup plugin retrieves secrets from WALLIX PRIVILEGED
        ACCESS MANAGEMENT.
  options:
    _terms:
      description: The account identifier (e.g., 'account@domain@device').
      required: True
    wallix_url:
      description: URL of the Wallix Bastion. Can be set via env var WALLIX_API_URL.
      env:
        - name: WALLIX_API_URL
    api_key:
      description: API Key for authentication. Can be set via env var WALLIX_API_KEY.
      env:
        - name: WALLIX_API_KEY
    username:
      description: Username for Basic Auth. Can be set via env var WALLIX_API_USER.
      env:
        - name: WALLIX_API_USER
    password:
      description: Password for Basic Auth. Can be set via env var WALLIX_API_PASSWORD.
      env:
        - name: WALLIX_API_PASSWORD
"""

EXAMPLES = r"""
- name: Retrieve password
  debug:
    msg: "{{ lookup('wallix.pam.secret', 'admin@local@prod-db-01') }}"
"""

RETURN = r"""
  _raw:
    description:
      - The password or SSH key retrieved from Wallix.
"""


# Disable warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        wallix_url = kwargs.get("wallix_url") or os.getenv("WALLIX_API_URL")
        api_key = kwargs.get("api_key") or os.getenv("WALLIX_API_KEY")
        username = kwargs.get("username") or os.getenv("WALLIX_API_USER")
        password = kwargs.get("password") or os.getenv("WALLIX_API_PASSWORD")

        # Handle validate_certs
        validate_certs = kwargs.get("validate_certs", True)
        if isinstance(validate_certs, str):
            validate_certs = validate_certs.lower() in ["true", "yes", "1"]

        if not wallix_url:
            raise AnsibleError("WALLIX_API_URL is required.")

        if not api_key and not (username and password):
            raise AnsibleError(
                "Either WALLIX_API_KEY or username/password are required."
            )

        ret = []

        for term in terms:
            # term is expected to be the account_name string directly
            # e.g. "account@domain@device"

            url = f"{wallix_url.rstrip('/')}/api/targetpasswords/checkout/{term}"
            headers = {"Content-Type": "application/json"}

            auth = None
            if api_key:
                headers["X-Auth-Token"] = api_key
            elif username and password:
                auth = (username, password)

            try:
                response = requests.get(
                    url, headers=headers, auth=auth, verify=validate_certs
                )

                if response.status_code == 200:
                    data = response.json()
                    # Extract secret
                    if "password" in data:
                        ret.append(data["password"])
                    elif "ssh_key" in data:
                        ret.append(data["ssh_key"])
                    elif "key" in data:
                        ret.append(data["key"])
                    else:
                        # Fallback: return the whole JSON as string if we can't identify the field
                        ret.append(str(data))
                else:
                    raise AnsibleError(
                        f"Wallix API Error {response.status_code}: {response.text}"
                    )

            except Exception as e:
                raise AnsibleError(f"Error retrieving secret for {term}: {e}")

        return ret
