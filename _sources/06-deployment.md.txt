# Deployment, Verification, and Conclusion

## 6.1. Deployment and Startup Sequence

**File Provisioning:** The necessary kernel (vmlinuz), initial RAM disk (initrd.img), and large OS images (.iso, .img) must be downloaded and correctly placed in the ./tftp and ./http directories respectively. Kernel files are extracted from the main OS images.

```bash
chmod +x provision.sh
sudo ./provision.sh
```

![Provision](assets/deployment/provision.png)

**Docker Compose Up:** The two container services are launched.

- pxe-dnsmasq starts listening on port 67 (DHCP) and 69 (TFTP).
- http-server starts Nginx listening on port 8080.

```bash
docker-compose up -d --build
```

![Docker](assets/deployment/docker-compose.png)

**Vagrant Up:** The VM is started and configured with its private network interface.

```bash
vagrant up
```

![Vagrant](assets/deployment/vagrant-up.png)

---

![pxe](assets/deployment/pxe-start.png)
![pxe](assets/deployment/pxe-menu.png)
![kali](assets/deployment/kali1.png)
![kali](assets/deployment/kali2.png)

## 6.4. Video Demonstration

The following video provides a visual walkthrough of the entire deployment process, from launching the containers to the final successful boot of Kali Linux via PXE:

<video controls>
  <source src="pxe-demo.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>
