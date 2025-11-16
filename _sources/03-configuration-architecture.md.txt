# Virtualization and Network Setup

## 3.1. Vagrant Host Configuration (Vagrantfile)

The Vagrantfile provisions a dedicated virtual machine to host the PXE Docker container.

**Vagrant VM Configuration: Vagrantfile**

```ruby
Vagrant.configure("2") do |config|
  config.vm.box='clink15/pxe'

  config.vm.network "private_network", type: "dhcp"

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpus", 8]
    v.customize ["modifyvm", :id, "--memory", 14120]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    v.customize ["modifyvm", :id, "--cableconnected1", "on"]
    v.gui = true
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true
end
```

**Key Features:**

- **Dedicated Resources:** Generous CPU (8) and RAM (14 GB) are allocated to ensure fast performance when serving multiple client boots simultaneously.
- **Network Type:** A private_network is used, which acts as a dedicated internal network for the PXE services, isolating them from the host machine's external network. The VM receives its IP address dynamically via DHCP.

## 3.2. Docker Container Orchestration

The two essential services—PXE/DHCP/TFTP and HTTP—are separated into distinct containers for better modularity and reliability.

```docker-compose.yml
services:

  pxe-dnsmasq:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: pxe-dnsmasq
    network_mode: host
    cap_add:
      - NET_ADMIN
    volumes:
      - ./config/dnsmasq/dnsmasq.conf:/etc/dnsmasq.conf:ro
      - ./config/dnsmasq/default/dnsmasq:/etc/default/dnsmasq:ro
      - ./tftp:/var/lib/tftpboot:ro
    command: --dhcp-range=192.168.56.10,192.168.56.100,255.255.255.0
    restart: unless-stopped

  http-server:
    image: nginx:alpine
    container_name: http-server
    volumes:
      - ./http:/usr/share/nginx/html:ro
    ports:
      - "8080:80"
    restart: unless-stopped
```

**Key Features:**

- **Host Networking (pxe-dnsmasq):** This is mandatory for DHCP and TFTP, which rely on broadcast packets and specific low-level ports that are difficult to expose using standard port mapping.
- **Separation of Concerns:** pxe-dnsmasq handles the fast, low-overhead protocols (DHCP/TFTP), while http-server handles the high-bandwidth HTTP serving for the large OS images.
- **DHCP Range:** The command line for pxe-dnsmasq explicitly sets the range for client IP assignment: 192.168.56.10 to 192.168.56.100.
