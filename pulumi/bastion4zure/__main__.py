"""An Azure RM Python Pulumi program"""

import pulumi_azure_native as azure
import pulumi_azure as azclas
import pulumi

PROJECT_CONFIG_KEY = "bastion4azure"
configproject = pulumi.config.Config(PROJECT_CONFIG_KEY)
configaz = pulumi.config.Config("azure-native")
RESOURCE_GRP = configproject.get("ResourceGroup")
LOCATION = configaz.get("location")
PROJECT_NAME = configproject.get("ProjectName")
PROJECT_OWNER = configproject.get("Owner")
PROJECT_TAG = configproject.get("ProjectTag")
OWNER_TAG = configproject.get("OwnerTag")
VNET_CIDR = configproject.get("VnetCidr")
JUMP_SERVER_SUBNET_CIDR = configproject.get("JumpCidr")
BASTION_SUBNET_1_CIDR = configproject.get("Bastion1Cidr")
BASTION_SUBNET_2_CIDR = configproject.get("Bastion2Cidr")
AM_SUBNET_1_CIDR = configproject.get("Am1Cidr")
AM_SUBNET_2_CIDR = configproject.get("Am2Cidr")
ALB_SUBNET_CIDR = configproject.get("AlbCidr")
DB_SUBNET_CIDR = configproject.get("DbCidr")
SSH_USERNAME = configproject.get("SshUsername")
SSH_PUBLIC_KEY = configproject.get("SshKey")
HQ_SOURCE_IP = configproject.get("SourceIp")
DB_USERNAME = configproject.get("DbUserName")
DB_PASSWORD = configproject.get("DbPassword")
DB_PRIV_ZONE_NAME = configproject.get("DbPrivZoneName")
BASTION_MACHINE_TYPE = configproject.get("BastionType")
AM_MACHINE_TYPE = configproject.get("AmType")
AM_BACKEND_HOSTNAME = configproject.get("AmBackendHostname")
APP_GATEWAY_CERT_PATH = configproject.get("LbCertpath")
APP_GATEWAY_CERT_PASSWORD = configproject.get("LBCertPassword")

##############################
#       Resource Group       #
##############################

resource_group = azure.resources.ResourceGroup("bastion4azRG",
                resource_group_name = RESOURCE_GRP,
                location = LOCATION,
                tags = {
                    PROJECT_TAG : PROJECT_OWNER,
                    PROJECT_TAG: PROJECT_NAME
                }
)

##############################
#       NETWORKING           #
##############################

vnet = azure.network.VirtualNetwork("Bastion4AzVnet",
              resource_group_name = resource_group.name, 
              address_space = azure.network.AddressSpaceArgs(
                  address_prefixes = [
                      VNET_CIDR
                  ]
              ),
              location = LOCATION
)

jumpsubnet = azure.network.Subnet("JumpSubnet",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "jumpsubnet",
            address_prefix = JUMP_SERVER_SUBNET_CIDR
)

bastionsubnet1 = azure.network.Subnet("BastionSubnet1",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "bastionsubnet1",
            address_prefix = BASTION_SUBNET_1_CIDR
)

bastionsubnet2 = azure.network.Subnet("BastionSubnet2",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "bastionsubnet2",
            address_prefix = BASTION_SUBNET_2_CIDR
)

amsubnet1 = azure.network.Subnet("AmSubnet1",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "amsubnet1",
            address_prefix = AM_SUBNET_1_CIDR
)

amsubnet2 = azure.network.Subnet("AmSubnet2",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "amsubnet2",
            address_prefix = AM_SUBNET_2_CIDR
)

albsubnet = azure.network.Subnet("AlbSubnet",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "albsubnet",
            address_prefix = ALB_SUBNET_CIDR
)

dbsubnet = azure.network.Subnet("DbSubnet",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    vnet
                ]
            ),
            resource_group_name = resource_group.name,
            virtual_network_name = vnet.name,
            subnet_name = "dbsubnet",
            address_prefix = DB_SUBNET_CIDR,
            service_endpoints = [azure.network.
                                 ServiceEndpointPropertiesFormatArgs(
                                     service = "Microsoft.Storage"
                                 )],
            delegations = [azure.network.DelegationArgs(
                name = "dbsubnetdelegations",
                service_name = "Microsoft.DBforMySQL/flexibleServers",
                actions= [
                    "Microsoft.Network/virtualNetworks/subnets/join/action"
                    ]
                )
            ]
)

dbprivdns = azure.network.PrivateZone(
            "DbPrivDns",
            resource_group_name = resource_group.name,
            private_zone_name = DB_PRIV_ZONE_NAME,
            location = "global"
)

privzonelink = azure.network.VirtualNetworkLink(
           "PrivZoneLink",
           opts = pulumi.ResourceOptions(
               depends_on= [
                   vnet,
                   dbprivdns,
                   dbsubnet
               ]
           ),
            private_zone_name = DB_PRIV_ZONE_NAME,
            registration_enabled = False,
            resource_group_name = resource_group.name,
            virtual_network = azure.network.SubResourceArgs(
                id = vnet.id
            ),
            location = "Global",
            virtual_network_link_name = "dbprivzonevnetlink"

)

##############################
#       JUMPSERVER VM        #
##############################

jumpnsg = azure.network.NetworkSecurityGroup("JumpNsg",
            location = LOCATION,
            resource_group_name = resource_group.name,
            network_security_group_name = f"{PROJECT_NAME}-jumpnsg",
            security_rules = [
                azure.network.SecurityRuleArgs(
                    access = "Allow",
                    direction = "Inbound",
                    protocol = "Tcp",
                    destination_port_range = "22",
                    name = "sshfromhq",
                    source_address_prefix= HQ_SOURCE_IP,
                    source_port_range = "*",
                    destination_address_prefix = "*",
                    priority = 100
                )
            ]
)

jumppubip = azure.network.PublicIPAddress("JumpPubIp",
            resource_group_name = resource_group.name,
            public_ip_allocation_method = "Static",
            location = LOCATION,
            delete_option = "Delete",
            sku = azure.compute.PublicIPAddressSkuArgs(
                name = "Standard",
                tier = "Regional"
            )

)

jumpnic = azure.network.NetworkInterface("JumpNic",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    jumpnsg,
                    jumpsubnet,
                    jumppubip
                ]
            ),
                resource_group_name = resource_group.name,
                network_interface_name = "jumpnic",
                location = LOCATION,
                ip_configurations = [
                    azure.network.
                    NetworkInterfaceIPConfigurationArgs(
                        name = "jumpnetconf",
                        subnet = azure.network.SubnetArgs(
                            id = jumpsubnet.id
                        ),
                        public_ip_address = azure.network.
                        PublicIPAddressArgs(
                            id = jumppubip.id
                        )
                    )
                ],
                network_security_group = azure.network.
                NetworkSecurityGroupArgs(
                    id = jumpnsg.id
                )
)

jumpserver = azure.compute.VirtualMachine("JumpServer",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    jumpnic
                ]
            ),
            resource_group_name = resource_group.name,
            vm_name = "jumpserver",
            location = LOCATION,
            hardware_profile = azure.compute.
            HardwareProfileArgs(
                vm_size = "Standard_B1s"
            ),
            network_profile = azure.compute.NetworkProfileArgs(
                network_interfaces = [
                    azure.compute.NetworkInterfaceReferenceArgs(
                        delete_option = "Delete",
                        id = jumpnic.id
                    )
                ]
            ),
            os_profile = azure.compute.OSProfileArgs(
                computer_name = f"{PROJECT_NAME}-jumpserver",
                admin_username = SSH_USERNAME,
                linux_configuration = azure.compute.LinuxConfigurationArgs(
                    ssh = azure.compute.SshConfigurationArgs(
                        public_keys = [
                            azure.compute.SshPublicKeyArgs(
                                key_data = SSH_PUBLIC_KEY,
                                path = f"/home/{SSH_USERNAME}/.ssh/authorized_keys"
                            )
                        ]
                    )
                )
            ),
            storage_profile = azure.compute.StorageProfileArgs(
                image_reference = azure.compute.ImageReferenceArgs(
                    offer = "debian-12",
                    publisher = "debian",
                    sku = "12-gen2",
                    version = "latest"
                ),
                os_disk = azure.compute.OSDiskArgs(
                    create_option = "FromImage",
                    delete_option = "Delete",
                    os_type = "Linux",
                    managed_disk = azure.compute.ManagedDiskParametersArgs(
                        storage_account_type = "STANDARDSSD_LRS"
                    ),
                    caching = "ReadWrite"
                )
            ),
            tags = {
                OWNER_TAG : PROJECT_OWNER,
                PROJECT_TAG: PROJECT_NAME
            }
)

##############################
#       Bastion VMs          #
##############################

bastionnsg = azure.network.NetworkSecurityGroup("BastionNsg",
            location = LOCATION,
            resource_group_name = resource_group.name,
            network_security_group_name = f"{PROJECT_NAME}-bastionnsg",
)

bastion1nic = azure.network.NetworkInterface("Bastion1Nic",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    bastionnsg,
                    bastionsubnet1,
                ]
            ),
                resource_group_name = resource_group.name,
                network_interface_name = "bastion1nic",
                location = LOCATION,
                ip_configurations = [
                    azure.network.
                    NetworkInterfaceIPConfigurationArgs(
                        name = "bastion1netconf",
                        subnet = azure.network.SubnetArgs(
                            id = bastionsubnet1.id
                        ),
                    )
                ],
                network_security_group = azure.network.
                NetworkSecurityGroupArgs(
                    id = bastionnsg.id
                )
)

bastion2nic = azure.network.NetworkInterface("Bastion2Nic",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    bastionnsg,
                    bastionsubnet2,
                ]
            ),
                resource_group_name = resource_group.name,
                network_interface_name = "bastion2nic",
                location = LOCATION,
                ip_configurations = [
                    azure.network.
                    NetworkInterfaceIPConfigurationArgs(
                        name = "bastion2netconf",
                        subnet = azure.network.SubnetArgs(
                            id = bastionsubnet2.id
                        ),
                    )
                ],
                network_security_group = azure.network.
                NetworkSecurityGroupArgs(
                    id = bastionnsg.id
                )
)

bastion1privip = pulumi.Output.all(resource_group.name, bastion1nic.name).apply(
    lambda args: azure.network.get_network_interface(
        resource_group_name = args[0],
        network_interface_name = args[1],
    ).ip_configurations[0].private_ip_address
)

bastion2privip = pulumi.Output.all(resource_group.name, bastion2nic.name).apply(
    lambda args: azure.network.get_network_interface(
        resource_group_name = args[0],
        network_interface_name = args[1],
    ).ip_configurations[0].private_ip_address
)

bastion1 = azure.compute.VirtualMachine("bastion1",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    bastion1nic
                ]
            ),
            resource_group_name = resource_group.name,
            vm_name = "bastion1",
            location = LOCATION,
            hardware_profile = azure.compute.
            HardwareProfileArgs(
                vm_size = BASTION_MACHINE_TYPE
            ),
            network_profile = azure.compute.NetworkProfileArgs(
                network_interfaces = [
                    azure.compute.NetworkInterfaceReferenceArgs(
                        delete_option = "Delete",
                        id = bastion1nic.id
                    )
                ]
            ),
            os_profile = azure.compute.OSProfileArgs(
                computer_name = f"{PROJECT_NAME}-bastion1",
                admin_username = SSH_USERNAME,
                linux_configuration = azure.compute.LinuxConfigurationArgs(
                    ssh = azure.compute.SshConfigurationArgs(
                        public_keys = [
                            azure.compute.SshPublicKeyArgs(
                                key_data = SSH_PUBLIC_KEY,
                                path = f"/home/{SSH_USERNAME}/.ssh/authorized_keys"
                            )
                        ]
                    )
                )
            ),
            plan = azure.compute.PlanArgs(
                name = "bastion-10",
                product = "wallixbastion",
                publisher = "wallix"
            ),
            storage_profile = azure.compute.StorageProfileArgs(
                image_reference = azure.compute.ImageReferenceArgs(
                    offer = "wallixbastion",
                    publisher = "wallix",
                    sku = "bastion-10",
                    version = "latest"
                ),
                os_disk = azure.compute.OSDiskArgs(
                    disk_size_gb = 50,
                    create_option = "FromImage",
                    delete_option = "Delete",
                    os_type = "Linux",
                    managed_disk = azure.compute.ManagedDiskParametersArgs(
                        storage_account_type = "STANDARDSSD_LRS"
                    ),
                    caching = "ReadWrite"
                )
            ),
            tags = {
                OWNER_TAG : PROJECT_OWNER,
                PROJECT_TAG: PROJECT_NAME
            }
)

bastion2 = azure.compute.VirtualMachine("bastion2",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    bastion2nic
                ]
            ),
            resource_group_name = resource_group.name,
            vm_name = "bastion2",
            location = LOCATION,
            hardware_profile = azure.compute.
            HardwareProfileArgs(
                vm_size = BASTION_MACHINE_TYPE
            ),
            network_profile = azure.compute.NetworkProfileArgs(
                network_interfaces = [
                    azure.compute.NetworkInterfaceReferenceArgs(
                        delete_option = "Delete",
                        id = bastion2nic.id
                    )
                ]
            ),
            os_profile = azure.compute.OSProfileArgs(
                computer_name = f"{PROJECT_NAME}-bastion2",
                admin_username = SSH_USERNAME,
                linux_configuration = azure.compute.LinuxConfigurationArgs(
                    ssh = azure.compute.SshConfigurationArgs(
                        public_keys = [
                            azure.compute.SshPublicKeyArgs(
                                key_data = SSH_PUBLIC_KEY,
                                path = f"/home/{SSH_USERNAME}/.ssh/authorized_keys"
                            )
                        ]
                    )
                )
            ),
            plan = azure.compute.PlanArgs(
                name = "bastion-10",
                product = "wallixbastion",
                publisher = "wallix"
            ),
            storage_profile = azure.compute.StorageProfileArgs(
                image_reference = azure.compute.ImageReferenceArgs(
                    offer = "wallixbastion",
                    publisher = "wallix",
                    sku = "bastion-10",
                    version = "latest"
                ),
                os_disk = azure.compute.OSDiskArgs(
                    disk_size_gb = 50,
                    create_option = "FromImage",
                    delete_option = "Delete",
                    os_type = "Linux",
                    managed_disk = azure.compute.ManagedDiskParametersArgs(
                        storage_account_type = "STANDARDSSD_LRS"
                    ),
                    caching = "ReadWrite"
                )
            ),
            tags = {
                OWNER_TAG : PROJECT_OWNER,
                PROJECT_TAG: PROJECT_NAME
            }
)

##############################
#    AccessManager VMs       #
##############################

amnsg = azure.network.NetworkSecurityGroup("AmNsg",
            location = LOCATION,
            resource_group_name = resource_group.name,
            network_security_group_name = f"{PROJECT_NAME}-amnsg",
)

am1nic = azure.network.NetworkInterface("Am1Nic",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    amnsg,
                    amsubnet1,
                ]
            ),
                resource_group_name = resource_group.name,
                network_interface_name = "am1nic",
                location = LOCATION,
                ip_configurations = [
                    azure.network.
                    NetworkInterfaceIPConfigurationArgs(
                        name = "am1netconf",
                        subnet = azure.network.SubnetArgs(
                            id = amsubnet1.id
                        ),
                    )
                ],
                network_security_group = azure.network.
                NetworkSecurityGroupArgs(
                    id = amnsg.id
                )
)

am2nic = azure.network.NetworkInterface("Am2Nic",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    amnsg,
                    amsubnet2,
                ]
            ),
                resource_group_name = resource_group.name,
                network_interface_name = "am2nic",
                location = LOCATION,
                ip_configurations = [
                    azure.network.
                    NetworkInterfaceIPConfigurationArgs(
                        name = "am2netconf",
                        subnet = azure.network.SubnetArgs(
                            id = amsubnet2.id
                        ),
                    )
                ],
                network_security_group = azure.network.
                NetworkSecurityGroupArgs(
                    id = amnsg.id
                )
)

am1privip = pulumi.Output.all(resource_group.name, am1nic.name).apply(
    lambda args: azure.network.get_network_interface(
        resource_group_name = args[0],
        network_interface_name = args[1],
    ).ip_configurations[0].private_ip_address
)

am2privip = pulumi.Output.all(resource_group.name, am2nic.name).apply(
    lambda args: azure.network.get_network_interface(
        resource_group_name = args[0],
        network_interface_name = args[1],
    ).ip_configurations[0].private_ip_address
)

am1 = azure.compute.VirtualMachine("am1",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    am1nic
                ]
            ),
            resource_group_name = resource_group.name,
            vm_name = "am1",
            location = LOCATION,
            hardware_profile = azure.compute.
            HardwareProfileArgs(
                vm_size = AM_MACHINE_TYPE
            ),
            network_profile = azure.compute.NetworkProfileArgs(
                network_interfaces = [
                    azure.compute.NetworkInterfaceReferenceArgs(
                        delete_option = "Delete",
                        id = am1nic.id
                    )
                ]
            ),
            os_profile = azure.compute.OSProfileArgs(
                computer_name = f"{PROJECT_NAME}-am1",
                admin_username = SSH_USERNAME,
                linux_configuration = azure.compute.LinuxConfigurationArgs(
                    ssh = azure.compute.SshConfigurationArgs(
                        public_keys = [
                            azure.compute.SshPublicKeyArgs(
                                key_data = SSH_PUBLIC_KEY,
                                path = f"/home/{SSH_USERNAME}/.ssh/authorized_keys"
                            )
                        ]
                    )
                )
            ),
            plan = azure.compute.PlanArgs(
                name = "accessmanager-4",
                product = "wallixaccessmanager",
                publisher = "wallix"
            ),
            storage_profile = azure.compute.StorageProfileArgs(
                image_reference = azure.compute.ImageReferenceArgs(
                    offer = "wallixaccessmanager",
                    publisher = "wallix",
                    sku = "accessmanager-4",
                    version = "latest"
                ),
                os_disk = azure.compute.OSDiskArgs(
                    disk_size_gb = 50,
                    create_option = "FromImage",
                    delete_option = "Delete",
                    os_type = "Linux",
                    managed_disk = azure.compute.ManagedDiskParametersArgs(
                        storage_account_type = "STANDARDSSD_LRS"
                    ),
                    caching = "ReadWrite"
                )
            ),
            tags = {
                OWNER_TAG : PROJECT_OWNER,
                PROJECT_TAG: PROJECT_NAME
            }
)

am2 = azure.compute.VirtualMachine("am2",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    am2nic
                ]
            ),
            resource_group_name = resource_group.name,
            vm_name = "am2",
            location = LOCATION,
            hardware_profile = azure.compute.
            HardwareProfileArgs(
                vm_size = AM_MACHINE_TYPE
            ),
            network_profile = azure.compute.NetworkProfileArgs(
                network_interfaces = [
                    azure.compute.NetworkInterfaceReferenceArgs(
                        delete_option = "Delete",
                        id = am2nic.id
                    )
                ]
            ),
            os_profile = azure.compute.OSProfileArgs(
                computer_name = f"{PROJECT_NAME}-am2",
                admin_username = SSH_USERNAME,
                linux_configuration = azure.compute.LinuxConfigurationArgs(
                    ssh = azure.compute.SshConfigurationArgs(
                        public_keys = [
                            azure.compute.SshPublicKeyArgs(
                                key_data = SSH_PUBLIC_KEY,
                                path = f"/home/{SSH_USERNAME}/.ssh/authorized_keys"
                            )
                        ]
                    )
                )
            ),
            plan = azure.compute.PlanArgs(
                name = "accessmanager-4",
                product = "wallixaccessmanager",
                publisher = "wallix"
            ),
            storage_profile = azure.compute.StorageProfileArgs(
                image_reference = azure.compute.ImageReferenceArgs(
                    offer = "wallixaccessmanager",
                    publisher = "wallix",
                    sku = "accessmanager-4",
                    version = "latest"
                ),
                os_disk = azure.compute.OSDiskArgs(
                    disk_size_gb = 50,
                    create_option = "FromImage",
                    delete_option = "Delete",
                    os_type = "Linux",
                    managed_disk = azure.compute.ManagedDiskParametersArgs(
                        storage_account_type = "STANDARDSSD_LRS"
                    ),
                    caching = "ReadWrite"
                )
            ),
            tags = {
                OWNER_TAG : PROJECT_OWNER,
                PROJECT_TAG: PROJECT_NAME
            }
)

##############################
#       Database             #
##############################

amdb = azure.dbformysql.Server(
            "AmDb",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    dbprivdns,
                    dbsubnet,
                    privzonelink

                ]
            ),
            resource_group_name = resource_group.name,
            server_name = f"{PROJECT_NAME}-dbwallixam",
            create_mode = "Default",
            location = LOCATION,
            administrator_login = DB_USERNAME,
            administrator_login_password = DB_PASSWORD,
            network = azure.dbformysql.NetworkArgs(
                delegated_subnet_resource_id = dbsubnet.id,
                private_dns_zone_resource_id = dbprivdns.id
                ),
            sku = azure.dbformysql.SkuArgs(
                name = "Standard_D2ds_v4",
                tier = azure.dbformysql.SkuTier(
                    "GeneralPurpose"
                )
            ),
            version = "8.0.21",
            storage = azure.dbformysql.StorageArgs(
                iops = 360,
                storage_size_gb = 20,
                )
)

##############################
#       LoadBalancer         #
##############################

apgwpubip = azure.network.PublicIPAddress(
            "AppGatewayPubIp",
            location = LOCATION,
            public_ip_address_version = "IPv4",
            public_ip_allocation_method = "Static",
            public_ip_address_name = f"{PROJECT_NAME}-appgatewaypubip",
            resource_group_name = resource_group.name,
            sku = azure.network.PublicIPPrefixSkuArgs(
                name = "Standard",
                tier = "Regional"
            )
)

health_probe = azclas.network.ApplicationGatewayProbeArgs(
            name = f"{PROJECT_NAME}-amprobe",
            protocol = "Https",
            host = AM_BACKEND_HOSTNAME,
            port = 443,
            path = "/wabam/global",
            interval = 30,
            timeout = 30,
            unhealthy_threshold = 3,
            match = azclas.network.
            ApplicationGatewayProbeMatchArgs(
                status_codes = ["200-399"]
            )
)

front_port: azclas.network.ApplicationGatewayFrontendPortArgs = [
    azure.network.ApplicationGatewayFrontendPortArgs(
        name = "https",
        port = 443
    )
]

front_ip_conf : azclas.network.ApplicationGatewayFrontendIpConfigurationArgs = [
    azclas.network.ApplicationGatewayFrontendIpConfigurationArgs(
        name = f"{PROJECT_NAME}-frontipconf",
        public_ip_address_id = apgwpubip.id
    )
]

backend_pool : azclas.network.ApplicationGatewayBackendAddressPoolArgs = [
    azclas.network.ApplicationGatewayBackendAddressPoolArgs(
        name = f"{PROJECT_NAME}-ambackendpool",
        ip_addresses = [
        am1privip,
        am2privip
        ]
    )
]

back_http_set: azclas.network.ApplicationGatewayBackendHttpSettingArgs = [
    azclas.network.ApplicationGatewayBackendHttpSettingArgs(
        affinity_cookie_name = "wallixamcookie",
        cookie_based_affinity = "Enabled",
        name = f"{PROJECT_NAME}-ambackendsettings",
        request_timeout = 20,
        port = 443,
        protocol = "Https",
        host_name = AM_BACKEND_HOSTNAME,
        probe_id = health_probe.id,
        probe_name = health_probe.name
    )
]

certfile = open(APP_GATEWAY_CERT_PATH, "r")

ssl_cert : azclas.network.ApplicationGatewaySslCertificateArgs = [
    azclas.network.
    ApplicationGatewaySslCertificateArgs(
        name = f"{PROJECT_NAME}-apgwcert",
        data = certfile.read(),
        password= APP_GATEWAY_CERT_PASSWORD
    )
]

http_list : azclas.network.ApplicationGatewayHttpListenerArgs = [
    azclas.network.ApplicationGatewayHttpListenerArgs(
        name = f"{PROJECT_NAME}-apgwlistener",
        frontend_ip_configuration_name = "frontipconf",
        frontend_port_name = front_port[0].name,
        protocol = "Https",
        ssl_certificate_id = ssl_cert[0].id,
        ssl_certificate_name = ssl_cert[0].name
    )
]

amagw = azclas.network.ApplicationGateway("AmAgw",
            opts = pulumi.ResourceOptions(
                depends_on= [
                    am1,
                    am2,
                    vnet,
                    albsubnet,
                    apgwpubip
                ]
            ),
            name = f"{PROJECT_NAME}-amapgw",
            resource_group_name = resource_group.name,
            gateway_ip_configurations = [
                azclas.network.
                ApplicationGatewayGatewayIpConfigurationArgs(
                name = "amgwipconf",
                subnet_id = albsubnet.id
                )
            ],
            location = LOCATION,
            sku = azclas.network.ApplicationGatewaySkuArgs(
                capacity = 2,
                name = "Standard_v2",
                tier = "Standard_v2"
            ),
            backend_address_pools = [
                azclas.network.
                ApplicationGatewayBackendAddressPoolArgs(
                    name = backend_pool[0].name,
                    ip_addresses= backend_pool[0].ip_addresses
                )
            ],
            frontend_ip_configurations = [
                azclas.network.
                ApplicationGatewayFrontendIpConfigurationArgs(
                    name = front_ip_conf[0].name,
                    public_ip_address_id = front_ip_conf[0].public_ip_address_id
                )
            ],
            frontend_ports = [
                azclas.network.
                ApplicationGatewayFrontendPortArgs(
                    name = front_port[0].name,
                    port = front_port[0].port
                )
            ],
            backend_http_settings = [
                azclas.network.
                ApplicationGatewayBackendHttpSettingArgs(
                    name = back_http_set[0].name,
                    cookie_based_affinity = back_http_set[0].cookie_based_affinity,
                    port = back_http_set[0].port,
                    protocol = back_http_set[0].protocol,
                    probe_id = back_http_set[0].probe_id,
                    probe_name = back_http_set[0].probe_name
                )
            ],
            http_listeners = [
                azclas.network.
                ApplicationGatewayHttpListenerArgs(
                    name = http_list[0].name,
                    frontend_ip_configuration_name = http_list[0].
                    frontend_ip_configuration_name,
                    frontend_port_name = http_list[0].frontend_port_name,
                    protocol = http_list[0].protocol,
                    ssl_certificate_id = http_list[0].ssl_certificate_id,
                    ssl_certificate_name = http_list[0].ssl_certificate_name
                )
            ],
            request_routing_rules = [
                azclas.network.
                ApplicationGatewayRequestRoutingRuleArgs(
                    name = "appgwrule",
                    http_listener_name = http_list[0].name,
                    rule_type = "Basic",
                    backend_address_pool_name = backend_pool[0].name,
                    backend_http_settings_name = back_http_set[0].name,
                    priority = 1
                )
            ],
            ssl_certificates = [
                azclas.network.ApplicationGatewaySslCertificateArgs(
                    name = ssl_cert[0].name,
                    data = ssl_cert[0].data,
                    password = ssl_cert[0].password
                )
            ],
            probes = [
                azclas.network.ApplicationGatewayProbeArgs(
                    interval = health_probe.interval,
                    name = health_probe.name,
                    path = health_probe.path,
                    protocol = health_probe.protocol,
                    timeout = health_probe.timeout,
                    unhealthy_threshold = health_probe.unhealthy_threshold,
                    match = health_probe.match,
                    port = health_probe.port,
                    host = health_probe.host
                )
            ]
)

pulumi.export("JumpServer", jumppubip.ip_address)
pulumi.export("LoadBalancer", apgwpubip.ip_address)
pulumi.export("AccessManager1", am1privip)
pulumi.export("AccessManager2", am2privip)
pulumi.export("Bastion1", bastion1privip)
pulumi.export("Bastion2", bastion2privip)
