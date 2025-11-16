# Dnsmasq and Docker Build

## 4.1. Dnsmasq Configuration (dnsmasq.conf)

This configuration snippet is mounted into the pxe-dnsmasq container to set the foundational PXE and TFTP parameters.


```dnsmasq.conf
# Disable DNS Server
port=0

# Enable DHCP logging
log-dhcp

dhcp-boot=pxelinux.0

# Provide network boot option called "Network Boot"
pxe-service=x86PC,"Network Boot",pxelinux

enable-tftp
tftp-root=/var/lib/tftpboot

# Run as root user
user=root
```

**Configuration Details:**

- dhcp-boot=pxelinux.0: This tells the client what file to download first via TFTP.
- tftp-root=/var/lib/tftpboot: Sets the location within the container where all initial boot files must reside.

## 4.2. Docker Build (Dockerfile)

The Dockerfile defines the minimal environment required to run the pxe-dnsmasq service.

```dockerfile
FROM alpine:3.21.3

RUN apk add --no-cache dnsmasq

COPY tftp/ /var/lib/tftpboot

ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.2,proxy"]
```