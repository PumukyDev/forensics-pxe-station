# PXE Boot Menu Configuration

The boot menu is managed by the SYSLINUX suite. The main configuration file (pxelinux.cfg/default) dictates the options and the kernel command line parameters used to load the operating systems.

## 5.1. Main Boot Menu (pxelinux.cfg/default)

This file defines the boot environment and the specific instructions for Kali Linux and Tails.

```default
DEFAULT kali_live
SAY Welcome to the Secure Boot Server. Select an operating system to boot.

LABEL kali_live
    MENU LABEL ^1. Kali Linux Live
    LINUX kali/vmlinuz
    INITRD kali/initrd.img
    APPEND ip=192.168.56.13::192.168.56.1:255.255.255.0::eth0:off boot=live components splash username=root hostname=kali fetch=http://192.168.56.1:8080/kali-linux-2025.3-live-amd64.iso

LABEL tails_live
    MENU LABEL ^2. Tails Live
    LINUX tails/vmlinuz
    INITRD tails/initrd.img
    APPEND ip=192.168.56.13::192.168.56.1:255.255.255.0::eth0:off boot=live components splash hostname=tails live-media-url=http://192.168.56.1:8080/tails-amd64-7.2.img

INCLUDE pxelinux.cfg/tools

MENU CMDLINEROW 15
MENU COLOR title 1;34;49 #eea0a0ff #cc333355 std
MENU COLOR sel 7;37;40 #ff000000 #bb9999aa all
MENU COLOR border 30;44 #ffffffff #00000000 std
MENU COLOR pwdheader 31;47 #eeff1010 #20ffffff std
MENU COLOR hotkey 35;40 #90ffff00 #00000000 std
MENU COLOR hotsel 35;40 #90000000 #bb9999aa all
MENU COLOR timeout_msg 35;40 #90ffffff #00000000 none
MENU COLOR timeout 31;47 #eeff1010 #00000000 none
MENU ENDROW 24
MENU MARGIN 10
MENU PASSWORDMARGIN 3
MENU PASSWORDROW 11
MENU ROWS 10
MENU TABMSGROW 15
MENU TIMEOUTROW 16
MENU TITLE PXE Boot MENU
MENU WIDTH 80

PROMPT 1
TIMEOUT 50
UI menu.c32
```

## 5.2. Kernel Command Line Breakdown (Kali Example)

The APPEND line is the most crucial part of the configuration, passing instructions to the booted kernel:

* ip=192.168.56.13::192.168.56.1:255.255.255.0::eth0:off: This forces a static IP configuration during the kernel boot process.
    * Client IP: 192.168.56.13
    * Gateway: 192.168.56.1 (The PXE server's IP)
    * Netmask: 255.255.255.0
    * Interface: eth0
    * Boot Protocol: off (disables secondary DHCP within the kernel)
* fetch=http://192.168.56.1:8080/kali-linux-2025.3-live-amd64.iso: Directs the Kali kernel to initiate an HTTP connection to the Nginx server on port 8080 to download the main ISO file.

## 5.3. Tools Sub-Menu (pxelinux.cfg/tools)

The secondary menu provides access to non-OS diagnostic tools, such as memory testers.

```tools
MENU BEGIN tools
MENU TITLE System Diagnostics and Tools

MENU SEPARATOR

LABEL memtest32
    MENU LABEL ^1. Memtest 32-bit (i386)
    KERNEL memtest/memtest32.bin

LABEL memtest64
    MENU LABEL ^2. Memtest 64-bit (x86_64)
    KERNEL memtest/memtest64.bin

# Linea separadora
MENU SEPARATOR

LABEL back
    MENU LABEL ^Return to Main Menu
    MENU GOTO default

MENU END
```

Kernel Usage: For simple bare-metal tools like Memtest, the KERNEL command points directly to the binary file (.bin). No separate INITRD or APPEND parameters are needed, as the binaries execute directly.

---