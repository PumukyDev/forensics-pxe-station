# PXE Communication Protocols and Boot Flow

## 2.1. Protocols Utilized

The PXE boot process relies on a combination of protocols, carefully segmented based on the transfer requirement:

```
┌───────────┐ ┌───────────┐ ┌───────────┐       ┌───────────┐
│ machine 0 │ │ machine 1 │ │ machine 2 │  ...  │ machine N │
└─────┬─────┘ └─────┬─────┘ └─────┬─────┘       └─────┬─────┘
      │             │             │                   │
      │             │             │                   │
      └────────────┬┴───────┬─────┴──┬────────────────┘
                   │        │        │
                   │        │        │
                   │        │        │
                   │        │        │
             ┌─────┼────────┼────────┼────┐
             │ ┌───┴──┐ ┌───┴──┐ ┌───┴──┐ │
             │ │ DHCP │ │ TFTP │ │ HTTP │ │
             │ └──────┘ └──────┘ └──────┘ │
             │       docker-compose       │
             └────────────────────────────┘
```

| Protocol | Layer | Transfer Role |
|---------|--------|----------------|
| DHCP | Application (UDP) | Configuration handshake. Assigns the client an IP address and provides the TFTP server location (IP) and the Network Boot Program (pxelinux.0). |
| TFTP | Application (UDP) | Initial boot files. Transfers small files such as pxelinux.0, menu.c32, vmlinuz, and initrd.img. |
| HTTP | Application (TCP) | Large data transfer. Delivers large forensic distribution images (.iso or .img). |


## 2.2. The PXE Boot Sequence

The entire boot process is segmented into two phases: the PXE handshake (via DHCP/TFTP) and the OS environment loading (via HTTP).

```
┌───────────┐               DHCP request                 ┌────────┐
│ machine N │ ─────────────────────────────────────────► │        │
│           │    send next server IP and boot file name  │  DHCP  │
│           │ ◄───────────────────────────────────────── │        │
│           │                                            └────────┘
│           │                                      
│           │     request boot file and boot config      ┌────────┐
│           │ ─────────────────────────────────────────► │        │
│           │     send boot file and boot config         │  TFTP  │
│           │ ◄───────────────────────────────────────── │        │
│           │                                            └────────┘
│           │                                      
│           │  request automated install instruction     ┌────────┐
│           │ ─────────────────────────────────────────► │        │
│           │     send automated install instruction     │        │
│           │ ◄───────────────────────────────────────── │        │
│           │                                            │  HTTP  │
│           │     request packages, config files...      │        │
│           │ ─────────────────────────────────────────► │        │
│           │       send packages, config files...       │        │
│           │ ◄───────────────────────────────────────── │        │
│           │                                            └────────┘
│  reboot   │
└───────────┘
```

1. Client Request: The client machine's PXE firmware sends a DHCPDISCOVER broadcast on the network.
2. Server Offer (DHCP): The pxe-dnsmasq container (configured as a DHCP server) sends a DHCPOFFER, providing the client its IP address and the essential boot parameters: dhcp-boot=pxelinux.0.
3. NBP Download (TFTP): The client connects to the PXE server's TFTP service and downloads the NBP (pxelinux.0).
4. Menu Loading (TFTP): pxelinux.0 executes and downloads the menu files (pxelinux.cfg/default and menu.c32) via TFTP, displaying the boot menu.
5. Kernel/Initrd Load (TFTP): When a user selects Kali or Tails, the corresponding kernel (vmlinuz) and initial RAM disk (initrd.img) are loaded via TFTP.
6. OS Image Fetch (HTTP): The kernel's command line directs the running kernel to connect to the HTTP server (192.168.56.1:8080) and download the main, large OS image file.

## 2.3. PXE vs USB

If you're already familiar with normal USB installation, here's a comparison with PXE boot installation:

| Normal USB installation                                | PXE boot installation                                                                 |
|--------------------------------------------------------|--------------------------------------------------------------------------------------|
| Boot menu entry specifies the boot partition location | DHCP server provides the TFTP server's IP                                            |
| Boot partition (e.g., /boot) contains the bootloader and config files | TFTP server serves the bootloader and config files                                   |
| User enters options in the installer manually          | Automated boot instructions (kickstart, preseed, ignition config, etc.) are downloaded from the HTTP server |
| Installer copies packages, binaries, and config files from the USB to the target disk | Packages, binaries, and config files are downloaded from the HTTP server             |
