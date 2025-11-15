FROM alpine:3.21.3

RUN apk add --no-cache dnsmasq

COPY tftp/ /var/lib/tftpboot

ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.2,proxy"]