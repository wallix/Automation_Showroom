# Cloud-init Configuration File Examples for WALLIX

This directory contains JSON configuration files for various WALLIX PAM deployment scenarios:

## Available Example Files

- `config_basic.json`: Minimal Bastion configuration (users, passwords, FR keyboard)
- `config_access_manager.json`: Simple Access Manager
- `config_network.json`: Bastion with advanced network configuration (interfaces, VLAN, bonding)
- `config_loadbalancer.json`: Bastion with load balancer configuration
- `config_webadminpass_crypto.json`: Access Manager with WebAdmin password and encryption key
- `config_bastion_full.json`: Full Bastion configuration

## Using the Examples

Each file can be used with the generator by running:

```bash
python3 wallix_cloud_init_generator.py --config-file config_example/config_basic.json --output-dir output/basic
```

## Scenario Examples

### Basic Deployment

```bash
python3 wallix_cloud_init_generator.py --config-file config_example/config_basic.json --output-dir output/basic
```

### Load Balancer Configuration

```bash
python3 wallix_cloud_init_generator.py --config-file config_example/config_loadbalancer.json --output-dir output/lb
```

### Configuration with chpasswd (plain text passwords)

```bash
python3 wallix_cloud_init_generator.py --config-file config_example/config_with_chpasswd.json --output-dir output/chpasswd
```

### Advanced Network Configuration

```bash
python3 wallix_cloud_init_generator.py --config-file config_example/config_network.json --output-dir output/network
```

Refer to each JSON file for more details on specific configurations.
