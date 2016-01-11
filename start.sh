#!/bin/bash

if [ "$DEBUG" == "1" ]; then
  set -x
fi

set -e

echo $OVPN_LOGIN > /etc/openvpn/auth.txt
echo $OVPN_PASSWORD >> /etc/openvpn/auth.txt

cp "/ovpn/$OVPN_FILE" /etc/openvpn/openvpn.conf

sed -i 's/^auth-user-pass$/auth-user-pass \/etc\/openvpn\/auth.txt/' /etc/openvpn/openvpn.conf

# Build runtime arguments array based on environment
ARGS=("--config" "$OPENVPN/openvpn.conf")

source "$OPENVPN/ovpn_env.sh"

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

# When using --net=host, use this to specify nat device.
[ -z "$OVPN_NATDEVICE" ] && OVPN_NATDEVICE=eth0

ip -6 route show default 2>/dev/null
if [ $? = 0 ]; then
    echo "Enabling IPv6 Forwarding"
    # If this fails, ensure the docker container is run with --privileged
    # Could be side stepped with `ip netns` madness to drop privileged flag

    sysctl -w net.ipv6.conf.default.forwarding=1 || echo "Failed to enable IPv6 Forwarding default"
    sysctl -w net.ipv6.conf.all.forwarding=1 || echo "Failed to enable IPv6 Forwarding"
fi

exec /usr/sbin/runsvdir-start
