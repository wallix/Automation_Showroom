#!/usr/bin/env python3
"""Module to set WEBUI Admin Password and Crypto Key for WALLIX SM"""

import sys
import subprocess
import json
from requests import Session
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def change_admin_password(bastion_ip, user, password, new_password):
    """ Function for changing password"""

    print("Reseting password before setup new one!")
    subprocess.call(["/opt/wab/bin/WABRestoreDefaultAdmin"])

    session = Session()
    auth = (user, password)

    response = session.post(f"https://{bastion_ip}/api",
                            verify=False,
                            auth=auth)

    if response.status_code == 204:
        print("Password is not expired. Do nothing.")
        sys.exit(0)

    response_json = response.json()
    if response.status_code != 401:
        print("Unexpected response code")
        print(json.dumps(response_json, indent=4))
        sys.exit(1)

    if response_json.get("reason") == "wrong_credentials":
        print("Wrong credentials provided")
        sys.exit(1)

    prompt = "Your password has been reset, you must change your password."
    if response_json["prompt"] != prompt:
        print("Failed to reset password, seems the password is not expired")
        sys.exit(1)

    auth = (user, new_password)
    response = session.post(f"https://{bastion_ip}/api",
                            verify=False,
                            auth=auth)
    response_json = response.json()

    prompt = "Please confirm password."
    if response.status_code == 401 and response_json["prompt"] != prompt:
        print("Failed to change password, prompt is not as expected !")
        print(f"Response: {response_json}")
        sys.exit(1)

    response = session.post(f"https://{bastion_ip}/api",
                            verify=False,
                            auth=auth)

    if response.status_code == 401:
        response_json = response.json()
        print("Failed to change password:")
        print(response_json["prompt"])
        sys.exit(1)

    if response.status_code != 204:
        print("Unexpected response code")
        print(json.dumps(response_json, indent=4))
        sys.exit(1)

    print("Password changed successfully")


def set_crypto(bastion_ip, user, password, cryptokey):
    """ Function setting up Cryptokey"""
    session = Session()
    auth = (user, password)
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
          }
    data = {"new_passphrase": cryptokey}
    print("Setting Up Crypto")
    response = session.post(f"https://{bastion_ip}/api",
                            verify=False,
                            auth=auth)

# Check the response
    if response.status_code == 204:
        print("Login with password successful")
        print("Response:", response.text)
    else:
        print("PUT request failed")
        print("Status code:", response.status_code)
        print("Response:", response.text)

    response = session.put(f"https://{bastion_ip}/api/encryption",
                           verify=False,
                           auth=auth,
                           headers=headers,
                           data=json.dumps(data))

# Check the response
    if response.status_code == 204:
        print("Encryption set  successfully!")
    else:
        print("PUT request failed")
        print("Status code:", response.status_code)
        print("Response:", response.text)


def main():
    """Value definition"""
    bastion_ip = "127.0.0.1"
    user = "admin"
    password = "admin"
    new_password = "${webui_password}"
    cryptokey = "${cryptokey_password}"

    change_admin_password(bastion_ip, user, password, new_password)
    set_crypto(bastion_ip, user, new_password, cryptokey)


if __name__ == "__main__":
    main()
