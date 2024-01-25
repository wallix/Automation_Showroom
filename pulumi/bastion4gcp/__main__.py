"""Deploy Bastion infra on GCP"""

import pulumi_gcp as gcp
import pulumi

PROJECT_CONFIG_KEY = "bastion4gcp" #must be matched in yaml config file
configgcp = pulumi.config.Config("gcp")
configproject = pulumi.config.Config(PROJECT_CONFIG_KEY)
PROJECT_ID = configgcp.get("project")
PROJECT_REGION = configgcp.get("region")
VPC_ROUTING_MODE = configproject.get("VpcRoutingMode")
JUMP_SERVER_SUBNET = configproject.get("JumpCidr")
BASTION_SUBNET_1 = configproject.get("Bastion1Cidr")
BASTION_SUBNET_2 = configproject.get("Bastion2Cidr")
AM_SUBNET = configproject.get("Am1Cidr")
LB_SUBNET = configproject.get("LbCidr")
AVAILABILITY_ZONE_A = configproject.get("Az1")
AVAILABILITY_ZONE_B = configproject.get("Az2")
AVAILABILITY_ZONE_C = configproject.get("Az3")
DEBIAN_IMAGE = gcp.compute.get_image(
                family = "debian-12",
                project = "debian-cloud",
                most_recent = True
)
PROJECT_NAME = configproject.get("Project")
SSH_KEY = configproject.get("SshKey")
SSH_USERNAME = configproject.get("SshUsername")
SOURCE_IP = configproject.get("SourceIp")
BASTION_MACHINE_TYPE = configproject.get("BastionType")
AM_MACHINE_TYPE = configproject.get("AmType")
BASTION_IMAGE = configproject.get("BastionImage")
AM_IMAGE = configproject.get("AmImage")
DB_ROOT_PASSWORD = configproject.get("DbRootSecret")
DB_MACHINE_TYPE = configproject.get("DbMachineType")
DB_USER = configproject.get("DbUser")
DB_USER_PWD = configproject.get("DbUserPwd")
LB_CERT_PATH = configproject.get("LbCertpath")
LB_PRIV_KEY_PATH = configproject.get("LbPrivKeyPath")

##############################
#       NETWORKING           #
##############################

vpc_network = gcp.compute.Network("vpc4Bastion",
                auto_create_subnetworks = False,
                name = f"{PROJECT_NAME}-bastionvpc",
                routing_mode = VPC_ROUTING_MODE
)

jumpsubnet = gcp.compute.Subnetwork("jumpServerSubnet",
                ip_cidr_range = JUMP_SERVER_SUBNET,
                network = vpc_network.id,
                name = f"{PROJECT_NAME}-jumpserversubnet",
                private_ip_google_access = True,
                region = PROJECT_REGION
)

bastionsubnet1 = gcp.compute.Subnetwork("BastionSubnet1",
                ip_cidr_range = BASTION_SUBNET_1,
                network = vpc_network.id,
                name = f"{PROJECT_NAME}-bastionsubnet1",
                private_ip_google_access = True,
                region = PROJECT_REGION
)

bastionsubnet2 = gcp.compute.Subnetwork("BastionSubnet2",
                ip_cidr_range = BASTION_SUBNET_2,
                network = vpc_network.id,
                name = f"{PROJECT_NAME}-bastionsubnet2",
                private_ip_google_access = True,
                region = PROJECT_REGION
)

amsubnet = gcp.compute.Subnetwork("AmSubnet",
                ip_cidr_range = AM_SUBNET,
                network = vpc_network.id,
                name = f"{PROJECT_NAME}-amsubnet",
                private_ip_google_access = True,
                region = PROJECT_REGION
)

lbsubnet = gcp.compute.Subnetwork("LbSubnet",
                ip_cidr_range = LB_SUBNET,
                network = vpc_network.id,
                name = f"{PROJECT_NAME}-lbsubnet",
                private_ip_google_access = True,
                region = PROJECT_REGION
)


db_ip_reserved_range = gcp.compute.GlobalAddress(
                "DbIpRange",
                name = f"{PROJECT_NAME}-dbprivip",
                purpose = "VPC_PEERING",
                address_type = "INTERNAL",
                network = vpc_network.id,
                prefix_length = 16
)

private_network_con = gcp.servicenetworking.Connection(
                "DbPrivateConnection",
                opts = pulumi.ResourceOptions(
                    depends_on = [
                        db_ip_reserved_range
                    ]),
                network = vpc_network.id,
                reserved_peering_ranges = [
                    db_ip_reserved_range.name
                ],
                service = "servicenetworking.googleapis.com"
)

##############################
#       JUMPSERVER VM        #
##############################

externalip = gcp.compute.Address("jumpserverpubip",
                name = f"{PROJECT_NAME}-jumpserverpubip",
                address_type = "EXTERNAL",
                region = PROJECT_REGION
)

jumpserver = gcp.compute.Instance("JumpServer",
                opts = pulumi.ResourceOptions(
                    depends_on= [
                        jumpsubnet
                    ]
                ),
                name = f"{PROJECT_NAME}-jumpserver",
                machine_type = "e2-micro",
                zone = AVAILABILITY_ZONE_A,
                boot_disk = gcp.compute.InstanceBootDiskArgs(
                    auto_delete = True,
                    device_name = "jumpserver",
                    initialize_params = gcp.compute.
                    InstanceBootDiskInitializeParamsArgs(
                        image = DEBIAN_IMAGE.self_link
                        )
                    ),
                network_interfaces = [
                    gcp.compute.InstanceNetworkInterfaceArgs(
                        subnetwork = jumpsubnet.name,
                access_configs = [
                    gcp.compute.
                    InstanceNetworkInterfaceAccessConfigArgs(
                        nat_ip = externalip.address
                             )
                        ]
                    ),
                ],
                metadata = {
                    "ssh-keys": f"{SSH_USERNAME}:{SSH_KEY}"
                }
)

jumpserverip = jumpserver.network_interfaces[0].network_ip

jumpserveripcidr = jumpserverip.apply(lambda
                jumpserverip:
                f"{jumpserverip}/32")

jumpfirewall = gcp.compute.Firewall("jumpserverrules",
                name = f"{PROJECT_NAME}-jumpserverfromhq",
                network = vpc_network.name,
                direction = "INGRESS",
                allows = [
                    gcp.compute.FirewallAllowArgs(
                       protocol = "TCP",
                       ports = [
                           "22"
                       ],
                    )
                ],
                source_ranges = [
                    SOURCE_IP
                ],
                destination_ranges = [
                    jumpserveripcidr
                ]
)

##############################
#       Bastion VMs          #
##############################

bastion1 = gcp.compute.Instance("Bastion1",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  bastionsubnet1
                ]
            ),
              name = f"{PROJECT_NAME}-bastion1",
              machine_type = BASTION_MACHINE_TYPE,
              zone = AVAILABILITY_ZONE_A,
              boot_disk = gcp.compute.InstanceBootDiskArgs(
                  auto_delete = True,
                  device_name = "bastion1",
                  initialize_params = gcp.compute.
                  InstanceBootDiskInitializeParamsArgs(
                      image = BASTION_IMAGE
                  )
              ),
              network_interfaces = [
                  gcp.compute.InstanceNetworkInterfaceArgs(
                      subnetwork = bastionsubnet1.name
                  )
              ],
                metadata = {
                    "ssh-keys": f"{SSH_USERNAME}:{SSH_KEY}"
                }
)


bastion2 = gcp.compute.Instance("Bastion2",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  bastionsubnet2
                ]
            ),
              name = f"{PROJECT_NAME}-bastion2",
              machine_type = BASTION_MACHINE_TYPE,
              zone = AVAILABILITY_ZONE_B,
              boot_disk = gcp.compute.InstanceBootDiskArgs(
                  auto_delete = True,
                  device_name = "bastion2",
                  initialize_params = gcp.compute.
                  InstanceBootDiskInitializeParamsArgs(
                      image = BASTION_IMAGE
                  )
              ),
              network_interfaces = [
                  gcp.compute.InstanceNetworkInterfaceArgs(
                      subnetwork = bastionsubnet2.name
                  )
              ],
                metadata = {
                    "ssh-keys": f"{SSH_USERNAME}:{SSH_KEY}"
                }
)

bastion1ip = bastion1.network_interfaces[0].network_ip

bastion1ipcidr = bastion1ip.apply(lambda
                bastion1ip:
                f"{bastion1ip}/32")
bastion2ip = bastion2.network_interfaces[0].network_ip

bastion2ipcidr = bastion2ip.apply(lambda
                bastion2ip:
                f"{bastion2ip}/32")


bastionsyncfw = gcp.compute.Firewall("bastion2bastionrules",
                name = f"{PROJECT_NAME}-bastion2bastionsync",
                network = vpc_network.name,
                direction = "INGRESS",
                allows = [
                    gcp.compute.FirewallAllowArgs(
                       protocol = "TCP",
                       ports = [
                           "2242"
                       ],
                    )
                ],
                source_ranges = [
                    bastion1ipcidr,
                    bastion2ipcidr
                ],
                destination_ranges = [
                    bastion1ipcidr,
                    bastion2ipcidr
                ]
)

jump2bastionfw = gcp.compute.Firewall("jump2bastionrules",
                name = f"{PROJECT_NAME}-jump2bastion",
                network = vpc_network.name,
                direction = "INGRESS",
                allows = [
                    gcp.compute.FirewallAllowArgs(
                       protocol = "TCP",
                       ports = [
                           "2242"
                       ],
                    )
                ],
                source_ranges = [
                    jumpserveripcidr,
                ],
                destination_ranges = [
                    bastion1ipcidr,
                    bastion2ipcidr
                ]
)

##############################
#    AccessManager VMs       #
##############################

health_check = gcp.compute.HealthCheck("AmHealthCheck",
                name = f"{PROJECT_NAME}-amhealthcheck",
                check_interval_sec = 45,
                timeout_sec = 5,
                healthy_threshold = 2,
                unhealthy_threshold = 2,
                tcp_health_check = gcp.compute.
                HealthCheckTcpHealthCheckArgs(
                    port = 443
                )
)

am_image = gcp.compute.get_image(name = "accessmanager")

instance_template = gcp.compute.RegionInstanceTemplate("AmInstTmpl",
                machine_type = AM_MACHINE_TYPE,
                region = PROJECT_REGION,
                name = f"{PROJECT_NAME}-instancestmpl",
                disks = [
                    gcp.compute.RegionInstanceTemplateDiskArgs(
                        source_image = am_image.self_link,
                        boot = True,
                        auto_delete = False,
                        disk_size_gb = 20
                    )
                ],
                network_interfaces = [
                    gcp.compute.RegionInstanceTemplateNetworkInterfaceArgs(
                        subnetwork = amsubnet.name
                    )
                ],
                metadata = {
                    "ssh-keys": f"{SSH_USERNAME}:{SSH_KEY}"
                },
                tags = ["jump2amssh",
                        "https-server"]
)

ig_name = f"{PROJECT_NAME}-instancesgrp"

instance_grp = gcp.compute.RegionInstanceGroupManager("AmInstanceGrp",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  instance_template
                ]
            ),
                name = ig_name,
                base_instance_name = f"{PROJECT_NAME}-ig",
                region = PROJECT_REGION,
                distribution_policy_zones = [
                    AVAILABILITY_ZONE_A,
                    AVAILABILITY_ZONE_B,
                    AVAILABILITY_ZONE_C
                    ],
                distribution_policy_target_shape = "even",
                versions = [
                    gcp.compute.
                    RegionInstanceGroupManagerVersionArgs(
                        instance_template = instance_template.self_link,
                    )
                ],
                target_size = 3,
                named_ports = [
                    gcp.compute.
                    RegionInstanceGroupManagerNamedPortArgs(
                        name = "https",
                        port = 443
                    )
                ],
                auto_healing_policies = gcp.compute.
                RegionInstanceGroupManagerAutoHealingPoliciesArgs(
                    health_check = health_check.id,
                    initial_delay_sec = 300
                ),
                update_policy = gcp.compute.
                RegionInstanceGroupManagerUpdatePolicyArgs(
                    instance_redistribution_type = "NONE",
                    minimal_action = "RESTART",
                    type = "OPPORTUNISTIC",
                    max_unavailable_fixed = 3
                ),
                stateful_disks = [
                    gcp.compute.
                    RegionInstanceGroupManagerStatefulDiskArgs(
                        device_name = "persistent-disk-0",
                        delete_rule = "ON_PERMANENT_INSTANCE_DELETION"
                    )
                ],
)

backend_service = gcp.compute.BackendService("AmBackend",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  health_check,
                  instance_grp
                ]
            ),
                name = f"{PROJECT_NAME}-backendsvc",
                session_affinity = "GENERATED_COOKIE",
                affinity_cookie_ttl_sec = 3600,
                backends = [
                    gcp.compute.BackendServiceBackendArgs(
                        group = "https://www.googleapis.com/compute/v1/projects/" + \
                                f"{PROJECT_ID}/regions/{PROJECT_REGION}/instanceGroups/" + \
                                f"{ig_name}",
                        balancing_mode = "UTILIZATION",
                        max_utilization = 0.8,
                        capacity_scaler = 1.0
                    )
                ],
                load_balancing_scheme = "EXTERNAL_MANAGED",
                protocol = "HTTPS",
                port_name = "https",
                health_checks = health_check.id

)

certificate = gcp.compute.SSLCertificate("LBCertificate",
                name = f"{PROJECT_NAME}-sslcertificate",
                certificate = (lambda path: open(path).read())(LB_CERT_PATH),
                private_key = (lambda path: open(path).read())(LB_PRIV_KEY_PATH)
)

url_map = gcp.compute.URLMap("AmUrlMap",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  backend_service
                ]
            ),
                default_service = backend_service.self_link,
                name = f"{PROJECT_NAME}-alb",

)

cert_url = f"projects/{PROJECT_ID}/global/sslCertificates/wallix-sslcertificate"

target_https_proxy = gcp.compute.TargetHttpsProxy("TargetHttpsProxy",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  url_map,
                  certificate
                ]
            ),
                name = f"{PROJECT_NAME}-https-proxy",
                url_map = url_map.self_link,
                ssl_certificates = [
                    certificate.id
                ]
)

forwarding_rule = gcp.compute.GlobalForwardingRule("ForwardingRule",
              opts = pulumi.ResourceOptions(
              depends_on= [
                  target_https_proxy,
                ]
            ),
                name = f"{PROJECT_NAME}-forwardrule",
                target = target_https_proxy.self_link,
                port_range = "443",
                load_balancing_scheme = "EXTERNAL_MANAGED",
)

jump2amfw = gcp.compute.Firewall("jump2amrules",
                opts = pulumi.ResourceOptions(
                    depends_on= [
                        jumpserver
                    ]
                ),                                 
                name = f"{PROJECT_NAME}-jump2am",
                network = vpc_network.name,
                direction = "INGRESS",
                allows = [
                    gcp.compute.FirewallAllowArgs(
                       protocol = "TCP",
                       ports = [
                           "22"
                       ],
                    )
                ],
                source_ranges = [
                    jumpserveripcidr,
                ],
                target_tags = [
                    "jump2amssh"
                ]
)

loadbalancerfw = gcp.compute.Firewall("loadbalancerrules",
                name = f"{PROJECT_NAME}-lbamrules",
                network = vpc_network.name,
                direction = "INGRESS",
                allows = [
                    gcp.compute.FirewallAllowArgs(
                       protocol = "TCP",
                       ports = [
                           "443"
                       ],
                    )
                ],
                source_ranges = [
                    "0.0.0.0/0"
                ],
                target_tags = [
                    "https-server"
                ]
)

##############################
#       Database             #
##############################

database = gcp.sql.DatabaseInstance("amdatabase",
                opts = pulumi.ResourceOptions(
                    depends_on= [
                        db_ip_reserved_range,
                        private_network_con,
                    ]
                ),
              name = f"{PROJECT_NAME}-amdatabase",
              database_version = "MYSQL_8_0",
              root_password = DB_ROOT_PASSWORD,
              settings = gcp.sql.DatabaseInstanceSettingsArgs(
                  tier = DB_MACHINE_TYPE,
                  availability_type = "ZONAL",
                  edition = "ENTERPRISE",
                  deletion_protection_enabled = False,
                  ip_configuration = gcp.sql.
                  DatabaseInstanceSettingsIpConfigurationArgs(
                      private_network = vpc_network.id,
                      ipv4_enabled = False,
                      enable_private_path_for_google_cloud_services = True
                ),
              )
)

dbuser = gcp.sql.User("Dbuser",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    database
                ]
            ),
            instance = database.name,
            host = "%",
            name = DB_USER,
            password = DB_USER_PWD
)

pulumi.export("Jumpserver", externalip.address)
pulumi.export("Bastion1", bastion1.network_interfaces[0].network_ip)
pulumi.export("Bastion2", bastion2.network_interfaces[0].network_ip)
pulumi.export("LoadBalancer", forwarding_rule.ip_address)
