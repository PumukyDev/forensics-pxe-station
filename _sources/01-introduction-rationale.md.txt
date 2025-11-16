# PXE

## 1. Introduction and Project Rationale

The Preboot eXecution Environment (PXE) defines a standard client-server environment that allows a networked device to boot, install, and execute software—typically a complete operating system image—without requiring local storage devices like hard drives, SSDs, or optical media.

This project focuses on deploying a network-based forensic workstation capable of quickly booting various specialized linux distributions, such as Kali Linux and Tails, using PXE.

### 1.1. Advantages for Digital Forensics

In digital forensics, the speed and integrity of the initial access to a target machine are paramount. Deploying a PXE server offers significant operational advantages:

* Tool agility and centralization: a single server can host an extensive library of forensic distributions and recovery tools. This eliminates the operational overhead of managing, updating, and carrying multiple USB drives.
* Immutability: by loading the operating system's kernel and filesystem over the network, the live environment loaded on the client machine is guaranteed to be clean and untampered with for each session.
* Hardware independence: PXE is a feature of the network interface controller (NIC) firmware, providing a standardized boot environment even when a target machine has a damaged optical drive or inaccessible USB ports.

### 1.2. Project Architecture Overview

The forensic PXE server is built using a modern, containerized architecture:

| Component | Role | Technology |
| :--- | :--- | :--- |
| Host Environment | Machine where Kali Live will run. | Vagrant |
| PXE Service | Manages initial handshake (DHCP/TFTP). | Docker |
| HTTP Service | Manages big files transferences of ISO images. |  Docker |


---