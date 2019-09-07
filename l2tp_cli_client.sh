# Debian l2tp vpn cli client v1.0
# Author(s): Connor Sanders
# MIT License
# 9/04/2019


# Get Command Line Arguments from user
for i in "$@"
do
case $i in
    -h=*|--host=*)
    VPN_SERVER_IP="${i#*=}"
    ;;
    -s=*|--sourceport=*)
    VPN_SOURCE_PORT="${i#*=}"
    ;;
    -u=*|--user=*)
    VPN_USER="${i#*=}"
    ;;
    -p=*|--password=*)
    VPN_PASSWORD="${i#*=}"
    ;;
    -i=*|--interface=*)
    VPN_USER_INTERFACE="${i#*=}"
    ;;
    -k=*|--sharedkey=*)
    VPN_IPSEC_PSK="${i#*=}"
    ;;
esac
done


# Ensure apt package dependencies are installed
apt-get -y update && apt-get -y upgrade
apt-get -y install strongswan xl2tpd libstrongswan-standard-plugins libstrongswan-extra-plugins


# Determine the user's machine's local gateway and public ips
GATEW=$(/sbin/ip route |grep '^default' | awk -v "BASEN=$VPN_USER_INTERFACE" "{print \"$BASEN\" \$3}")
PUBIP=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has" | awk '{print $4}')
PRIVATEIP=$(hostname -I)


# Configure ipsec settings file
cat > /etc/ipsec.conf <<EOF
config setup
conn %default
  ikelifetime=60m
  keylife=20m
  rekeymargin=3m
  keyingtries=1
  keyexchange=ikev1
  authby=secret
  leftprotoport=17/%any
  rightprotoport=17/%any

conn VPN1
  keyexchange=ikev1
  left=%defaultroute
  auto=add
  authby=secret
  type=transport
  ike=aes128-sha1-modp1536,aes128-sha1-modp1024,aes128-md5-modp1536,aes128-md5-modp1024,3des-sha1-modp1536,3des-sha1-modp1024,3des-md5-modp1536,3des-md5-modp1024
  esp=aes128-sha1-modp1536,aes128-sha1-modp1024,aes128-md5-modp1536,aes128-md5-modp1024,3des-sha1-modp1536,3des-sha1-modp1024,3des-md5-modp1536,3des-md5-modp1024  
  rightsubnet=10.141.0.253/32
  right=$VPN_SERVER_IP
  nat_traversal=yes
EOF


# Configure ipsec secrets file for VPN PSK and secure it with chmod 600
cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_IPSEC_PSK"
EOF
chmod 600 /etc/ipsec.secrets


# Configure xl2tpd settings file
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = $VPN_SOURCE_PORT
[lac VPN1]
lns = $VPN_SERVER_IP
local ip = $PRIVATEIP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF


# Configure xl2tpd client ppp settings file and secure it with chmod 600
cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1420
mru 1420
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name $VPN_USER
password $VPN_PASSWORD
EOF
chmod 600 /etc/ppp/options.l2tpd.client


# Restart strongswan and xl2tpd services
service strongswan restart
service xl2tpd restart


# Create start-vpn launch bash script file and set it's permissions
cat > /usr/local/bin/start-vpn <<EOF
#!/bin/bash
(service strongswan restart ;
sleep 2 ;
service xl2tpd restart) && (
ipsec up VPN1
echo "c VPN1" > /var/run/xl2tpd/l2tp-control
sleep 5 ;
ip route add $VPN_SERVER_IP via $GATEW ;
ip route add $PUBIP via $GATEW ;
PPPIP=\$(/sbin/ip route | awk '/ppp0/ {print \$1}') ;
ip route add default via \$PPPIP dev ppp0 ;
)
EOF
chmod +x /usr/local/bin/start-vpn


# Create stop-vpn launch bash script file and set it's permissions
cat > /usr/local/bin/stop-vpn <<EOF
#!/bin/bash
(echo "d VPN1" > /var/run/xl2tpd/l2tp-control
ipsec down VPN1) && (
service xl2tpd stop ;
service strongswan stop)
EOF
chmod +x /usr/local/bin/stop-vpn


# Echo to the user the commands to start or stop the vpn once configuration is complete
echo "To start VPN type: start-vpn"
echo "To stop VPN type: stop-vpn"
