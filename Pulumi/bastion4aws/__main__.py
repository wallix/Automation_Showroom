"""An AWS Python Pulumi program"""

from helpers import (
    execute_cmds_on_remote_host,
    replace_db_host_string,
    create_tgt_grp_attachment,
    get_random_string,
)
import pulumi
import pulumi_aws as aws

config = pulumi.Config()

VPC_CIDR = config.get("VpcCidr")
JUMP_SERVER_CIDR = config.get("JumpCidr")
AM_ZONE_A_CIDR = config.get("AmZoneACidr")
AM_ZONE_B_CIDR = config.get("AmZoneBCidr")
BASTION_ZONE_A_CIDR = config.get("BastionZoneACidr")
BASTION_ZONE_B_CIDR = config.get("BastionZoneBCidr")
LB_CIDR = config.get("LbCidr")
PROJECT_NAME = config.get("Project")
PROJECT_OWNER = config.get("Owner")
DEBIAN_AMI = aws.ec2.get_ami(
            owners = ["136693071363"],
                filters=[
            aws.ec2.GetAmiFilterArgs(
                name="name",
                values=["debian-*"]
            ),
            aws.ec2.GetAmiFilterArgs(
                name="architecture",
                values=["x86_64"]
            )
    ],
            most_recent=True
)
BASTION_AMI = config.get("BastionAmi")
AM_AMI = config.get("AmAmi")
SSH_PUB_KEY = aws.ec2.get_key_pair(
            key_name = config.get("KeyName")
)
ALB_CERT_ARN = config.get("CertArn")
RDS_USERNAME = config.get("RdsUser")
RDS_PWD = config.get("RdsPswd")
AVAIL_ZONE_A = config.get("Az_A")
AVAIL_ZONE_B = config.get("Az_B")
SOURCE_IP = config.get("SourceIp")

##############################
#       NETWORKING           #
##############################

vpc = aws.ec2.Vpc(
            PROJECT_NAME,
            cidr_block = VPC_CIDR,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"vpc-{PROJECT_NAME}"
    }
)
igw = aws.ec2.InternetGateway(
            f"igw-{PROJECT_NAME}",
            vpc_id = vpc.id,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"igw-{PROJECT_NAME}"
    }
)

public_route_tbl = aws.ec2.RouteTable(
            "public_route_table",
            vpc_id = vpc.id,
            routes = [
                aws.ec2.RouteTableRouteArgs(
                    cidr_block = "0.0.0.0/0",
                    gateway_id = igw.id
                )
            ],
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"pubroutetbl-{PROJECT_NAME}"
    }
)

jump_subnet = aws.ec2.Subnet(
            "jump_server_subnet",
            vpc_id = vpc.id,
            cidr_block = JUMP_SERVER_CIDR,
            availability_zone = AVAIL_ZONE_A,
            map_public_ip_on_launch = False,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"jump-sub-{PROJECT_NAME}"
    }
)

lb_subnet = aws.ec2.Subnet(
            "loadbalancer_subnet",
            vpc_id=vpc.id,
            cidr_block=LB_CIDR,
            availability_zone=AVAIL_ZONE_B,
            map_public_ip_on_launch=False,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"lb-sub-{PROJECT_NAME}"
    }
)

bastion_subnet_1 = aws.ec2.Subnet(
                "bastion1_subnet",
                vpc_id = vpc.id,
                cidr_block = BASTION_ZONE_A_CIDR,
                availability_zone = AVAIL_ZONE_A,
                map_public_ip_on_launch = False,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"bastion1-sub-{PROJECT_NAME}"
    }
)

bastion_subnet_2 = aws.ec2.Subnet(
                "bastion2_subnet",
                vpc_id=vpc.id,
                cidr_block=BASTION_ZONE_B_CIDR,
                availability_zone=AVAIL_ZONE_B,
                map_public_ip_on_launch=False,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"bastion2-sub-{PROJECT_NAME}"
    }
)

am_subnet_1 = aws.ec2.Subnet(
            "am1_subnet",
            vpc_id = vpc.id,
            cidr_block = AM_ZONE_A_CIDR,
            availability_zone = AVAIL_ZONE_A,
            map_public_ip_on_launch = False,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"am1-sub-{PROJECT_NAME}"
    }
)

am_subnet_2 = aws.ec2.Subnet(
            "am2_subnet",
            vpc_id = vpc.id,
            cidr_block = AM_ZONE_B_CIDR,
            availability_zone = AVAIL_ZONE_B,
            map_public_ip_on_launch = False,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"am2-sub-{PROJECT_NAME}"
    }
)

jumpserver_route_assoc = aws.ec2.RouteTableAssociation(
            "jump_sub_rt_tbl_assoc",
            route_table_id = public_route_tbl.id,
            subnet_id = jump_subnet.id
)

lb_route_assoc = aws.ec2.RouteTableAssociation(
            "lb_sub_rt_tbl_assoc",
            route_table_id = public_route_tbl.id,
            subnet_id = lb_subnet.id
)

##############################
#       JUMPSERVER VM        #
##############################

eip = aws.ec2.Eip("jumpserver_EIP",
    domain = "vpc",
    tags = {
        "Project_name": PROJECT_NAME,
        "Project_owner": PROJECT_OWNER,
        "Name": f"jump-eip-{PROJECT_NAME}"
    }
)

jump_security_grp = aws.ec2.SecurityGroup(
                "jumpServer_SG",
                vpc_id = vpc.id,
                ingress = [
                    {
                    "protocol": "tcp",
                    "from_port": "22",
                    "to_port": "22",
                    "cidr_blocks": [SOURCE_IP]
                }
            ],
                egress = [
                    {
                    "protocol": "-1",
                    "from_port": 0,
                    "to_port": 0,
                    "cidr_blocks": ["0.0.0.0/0"],
                    }
                ],
                tags = {
                    "Project_name": PROJECT_NAME,
                    "Project_owner": PROJECT_OWNER,
                    "Name": f"jump-sg-{PROJECT_NAME}"
        }
)

jump_vm = aws.ec2.Instance(
        "jumpServer",
        ami = DEBIAN_AMI.id,
        instance_type = "t2.micro",
        security_groups = [jump_security_grp.id],
        subnet_id = jump_subnet.id,
        key_name = SSH_PUB_KEY.key_name,
        tags = {
            "Project_name": PROJECT_NAME,
            "Project_owner": PROJECT_OWNER,
            "Name": f"jumpserver-{PROJECT_NAME}"
    }
)
eip_assoc = aws.ec2.EipAssociation(
           "jumpServer_ip_assoc",
           instance_id = jump_vm.id,
           allocation_id = eip.id
)

##############################
#       BASTION VMs          #
##############################

bastion_security_grp = aws.ec2.SecurityGroup(
            "bastions_SG",
            vpc_id = vpc.id,
            ingress = [
                {
                    "protocol": "tcp",
                    "from_port": "22",
                    "to_port": "22",
                    "cidr_blocks": ["0.0.0.0/0"]
                },
                {
                    "protocol": "tcp",
                    "from_port": "443",
                    "to_port": "443",
                    "cidr_blocks": ["0.0.0.0/0"]
                },
                {
                    "protocol": "tcp",
                    "from_port": "2242",
                    "to_port": "2242",
                    "cidr_blocks": [pulumi.Output.concat(
                        jump_vm.private_ip, "/32")],
                },
                {
                    "protocol": "tcp",
                    "from_port": "2242",
                    "to_port": "2242",
                    "self": True
                },
                {
                    "protocol": "tcp",
                    "from_port": "3389",
                    "to_port": "3389",
                    "cidr_blocks": ["0.0.0.0/0"]
                },
        ],
            egress = [
                {
                "protocol": "-1",
                "from_port": 0,
                "to_port": 0,
                "cidr_blocks": ["0.0.0.0/0"],
                }
        ],
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"bastion-sg-{PROJECT_NAME}"
    }
)

bastion1 = aws.ec2.Instance(
          "bastion1",
          ami = BASTION_AMI,
          instance_type = "t2.medium",
          security_groups = [bastion_security_grp.id],
          subnet_id = bastion_subnet_1.id,
          key_name = SSH_PUB_KEY.key_name,
          tags = {
               "Project_name": PROJECT_NAME,
               "Project_owner": PROJECT_OWNER,
               "Name": f"bastion1-{PROJECT_NAME}"
    }
)

bastion2 = aws.ec2.Instance(
          "bastion2",
          ami = BASTION_AMI,
          instance_type = "t2.medium",
          security_groups = [bastion_security_grp.id],
          subnet_id = bastion_subnet_2.id,
          key_name = SSH_PUB_KEY.key_name,
          tags = {
               "Project_name": PROJECT_NAME,
               "Project_owner": PROJECT_OWNER,
               "Name": f"bastion2-{PROJECT_NAME}"
    }
)

##############################
#      ACCESSMANAGER VMs     #
##############################

accessmanager_security_grp = aws.ec2.SecurityGroup(
            "AccessManager_SG",
            vpc_id = vpc.id,
            ingress = [
                {
                    "protocol": "tcp",
                    "from_port": "443",
                    "to_port": "443",
                    "cidr_blocks": ["0.0.0.0/0"]
                },
                {
                    "protocol": "tcp",
                    "from_port": "2242",
                    "to_port": "2242",
                    "cidr_blocks": [pulumi.Output.concat(
                        jump_vm.private_ip, "/32")],
                },
        ],
            egress = [
                {
                "protocol": "-1",
                "from_port": 0,
                "to_port": 0,
                "cidr_blocks": ["0.0.0.0/0"],
                }
        ],
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"am-sg-{PROJECT_NAME}"
        }
)

am1 = aws.ec2.Instance(
          "accessmanager1",
          ami = AM_AMI,
          instance_type = "t2.medium",
          security_groups = [accessmanager_security_grp.id],
          subnet_id = am_subnet_1.id,
          key_name = SSH_PUB_KEY.key_name,
          tags = {
               "Project_name": PROJECT_NAME,
               "Project_owner": PROJECT_OWNER,
               "Name": f"am1-{PROJECT_NAME}"
    }
)

am2 = aws.ec2.Instance(
          "accessmanager2",
          ami = AM_AMI,
          instance_type = "t2.medium",
          security_groups = [accessmanager_security_grp.id],
          subnet_id = am_subnet_2.id,
          key_name = SSH_PUB_KEY.key_name,
          tags = {
               "Project_name": PROJECT_NAME,
               "Project_owner": PROJECT_OWNER,
               "Name": f"am2-{PROJECT_NAME}"
    }
)

##############################
#       RDS DATABASE         #
##############################

subnet_grp = aws.rds.SubnetGroup(
            "sub_grp",
            subnet_ids = [
                am_subnet_1.id,
                am_subnet_2.id
               ]
)

rds_security_grp = aws.ec2.SecurityGroup(
                "rdsSG",
                vpc_id = vpc.id,
                ingress = [
                     {
                    "protocol": "tcp",
                    "from_port": "3306",
                    "to_port": "3306",
                    "cidr_blocks": [AM_ZONE_A_CIDR, AM_ZONE_B_CIDR]
                }
            ],
                egress = [
                    {
                    "protocol": "-1",
                    "from_port": 0,
                    "to_port": 0,
                    "cidr_blocks": ["0.0.0.0/0"],
                }
            ],
                tags = {
                    "Project_name": PROJECT_NAME,
                    "Project_owner": PROJECT_OWNER,
                    "Name": f"rds-sg-{PROJECT_NAME}"
                }
)

rds = aws.rds.Instance(
          "rds",
          identifier = f"rds-{PROJECT_NAME}",
          engine = "mysql",
          engine_version = "8.0.35",
          multi_az = False,
          username = RDS_USERNAME,
          password = RDS_PWD,
          instance_class = "db.m5.large",
          storage_type = "standard",
          allocated_storage = 10,
          availability_zone = AVAIL_ZONE_A,
          publicly_accessible = False,
          db_subnet_group_name = subnet_grp.name,
          vpc_security_group_ids = [rds_security_grp.id],
          skip_final_snapshot = True,
          tags = {
               "Project_name": PROJECT_NAME,
               "Project_owner": PROJECT_OWNER,
               "Name": f"rds-{PROJECT_NAME}"
    }
)

##############################
#  APPLICATION LOADBALANCER  #
##############################

alb_security_grp = aws.ec2.SecurityGroup(
                "albSG",
                vpc_id = vpc.id,
                ingress = [
                    {
                    "protocol": "tcp",
                    "from_port": "443",
                    "to_port": "443",
                    "cidr_blocks": [SOURCE_IP]
                }
            ],
                egress = [
                    {
                    "protocol": "-1",
                    "from_port": 0,
                    "to_port": 0,
                    "cidr_blocks": ["0.0.0.0/0"],
                    }
                ],
                tags = {
                    "Project_name": PROJECT_NAME,
                    "Project_owner": PROJECT_OWNER,
                    "Name": f"alb-sg-{PROJECT_NAME}"
            }
)

alb = aws.lb.LoadBalancer(
       "am_alb",
       internal = False,
       name = f"am-lb-{PROJECT_NAME}",
       ip_address_type = "ipv4",
       load_balancer_type = "application",
       subnets = [jump_subnet.id, lb_subnet.id],
       security_groups = [alb_security_grp.id],
        tags = {
            "Project_name": PROJECT_NAME,
            "Project_owner": PROJECT_OWNER,
            "Name": f"alb-{PROJECT_NAME}"
    }
)

target_group = aws.lb.TargetGroup(
            "am_tgt_grp",
            name = f"am-target-grp-{PROJECT_NAME}",
            target_type = "instance",
            protocol = "HTTPS",
            port = 443,
            protocol_version = "HTTP1",
            vpc_id = vpc.id,
            health_check = aws.lb.TargetGroupHealthCheckArgs(
                           protocol = "HTTPS",
                           healthy_threshold=5,
                           interval = 45,
                           unhealthy_threshold = 3,
                           timeout = 10,
                           matcher = "200-399",
                           port = "traffic-port",
                           path = "/wabam/global"
                            ),
            stickiness = aws.lb.TargetGroupStickinessArgs(
                          type = "lb_cookie",
                          enabled = True

                        ),
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"targetgrp-{PROJECT_NAME}"
        }
)

#Register multiple targets to ALB TargetGroup
am_instances_list = [am1.id, am2.id]
for instance in am_instances_list:
    create_tgt_grp_attachment(instance,
                              target_group.arn,
                              443,
                              get_random_string(8)
)

listener = aws.lb.Listener(
            "alb_listener",
            load_balancer_arn = alb.arn,
            port = 443,
            protocol = "HTTPS",
            default_actions = [aws.lb.ListenerDefaultActionArgs(
                              type = "forward",
                              target_group_arn = target_group.arn,
                            )
                        ],
            certificate_arn = ALB_CERT_ARN,
            tags = {
                "Project_name": PROJECT_NAME,
                "Project_owner": PROJECT_OWNER,
                "Name": f"alb-listener-{PROJECT_NAME}"
        }
)

pulumi.export("jumpServer_IP", eip.public_ip)
pulumi.export("bastion1", bastion1.private_ip)
pulumi.export("bastion2", bastion2.private_ip)
pulumi.export("am1", am1.private_ip)
pulumi.export("am2", am2.private_ip)
pulumi.export("rds endpoint", rds.endpoint)
pulumi.export("alb endpoint", alb.dns_name)
