# Forensics PXE Station

## Objective

This project provides a PXE boot environment for digital forensic investigations.  
It allows multiple client machines to boot operating systems and forensic tools over the network without using USBs or DVDs.

Key features:

* PXE/DHCP/TFTP services containerized using Docker (`pxe-dnsmasq`).
* HTTP server for fast OS image and package delivery (`http-server`).
* Automated network boot and installation of forensic OS images (e.g., Kali Linux).
* Fully isolated environment hosted in a Vagrant VM.

## Requirements

* **Vagrant** — To launch the host VM.
* **VirtualBox** — Provider for the Vagrant VM.
* **Docker & Docker Compose** — To run PXE/DHCP/TFTP and HTTP services.

## Setup Instructions

### Clone the Repository

```bash
git clone https://github.com/PumukyDev/forensics-pxe-station.git
cd forensics-pxe-station
```

### Download ISO images, syslinux, pxelinux.0, etc.

```bash
chmod +x ./provision.sh
sudo ./provision.sh
```

### Deploy PXE server

```bash
docker-compose up -d --build
```

### Deploy VM

```bash
vagrant up
```

### Results

![pxe-start](./docs/assets//deployment/pxe-start.png)
![pxe-menu](./docs/assets//deployment/pxe-menu.png)
![kali](./docs/assets/deployment/kali1.png)

## Documentation

You can view the full project documentation in the [web page version](https://pumukydev.github.io/forensics-pxe-station)

## License

This project is under [MIT License](https://github.com/PumukyDev/forensics-pxe-station/blob/main/LICENSE)