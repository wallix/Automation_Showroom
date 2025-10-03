"""Tools to deploy WOPAM on AWS"""

from typing import List
import os
import string
import random
import paramiko
from pulumi_aws import lb

def replace_db_host_string(pattern: str,
                           replacement: str,
                           source: str
                           ) -> None:
    """
    Replace db connection string
    in wabam conf file

    Parameters
    ----------
    pattern: str
        Pattern to replace
    replacement: str
        String new pattern to write
    source: str
        filename to manipulate
    """
    os.system(f"sed -i s/{pattern}/{replacement}/g {source}")


def execute_cmds_on_remote_host(ip_addr: str,
                                login: str,
                                pkey: str,
                                commands: List) -> None:
    """
    Execute commands
    on remote VMs

    Parameters
    ----------
    ip_addr: str
        Instance IP address
    login: str
        username to use
    pkey: str
        SSH private key as path
         (i.e /home/user/.ssh/id_rsa)
    command: List
        commands to execute
    """

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy)
    privkey = paramiko.RSAKey(filename=pkey)
    client.connect(hostname=ip_addr, username=login,
                   pkey=privkey)
    for command in commands:
        print(f"Executing remote commands {command}")
        _stdin, _stdout, _stderr = client.exec_command(command)
        print(_stdout.read())
        print("Errors")
        print(_stderr.read())


def get_random_string(length):
    """
    Generate random
    strings for Pulumi resources
    """
    # choose from all lowercase letter
    letters = string.ascii_lowercase
    result_str = ''.join(random.choice(letters) for i in range(length))
    return result_str


def create_tgt_grp_attachment(server_id: str,
                              tgt_grp_arn: str,
                              port: int,
                              name: str) -> None:
    """
    Attach target
    to ALB target group

    Parameters
    ----------
    server_id: str
        AWS instance id
    tgt_grp_arn: str
        ALB target group ARN
    port: int
        Instance port
    name: str
        Pulumi Attachment resouce name
    """
    lb.TargetGroupAttachment(
        resource_name = name,
        target_group_arn = tgt_grp_arn,
        target_id = server_id,
        port = port
    )
