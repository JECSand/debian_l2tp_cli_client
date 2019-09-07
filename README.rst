=============================
Debian L2TP CLI Client
=============================

Current Version: v1.0

Version Released: 9/04/2019

Author(s): Connor Sanders

Overview
---------

A l2tp VPN CLI client written in bash. Allows for a user to connect to a l2tp VPN without a GUI in Debian. This VPN client uses the strongswan and xl2tpd apt packages.

*Currently only runs with IKEV1, however IKEV2 and more customizable parameters can easily be added in the future as needed.

*Useful for those annoying instances when you need to connect to a l2tp vpn from a Debian machine, especially when you only have terminal access.

Getting Started for Users
--------------------------

1. Clone the repository:
 $ git clone https://github.com/JECSand/debian_l2tp_cli_client.git

2. Go into the debian_l2tp_cli_client directory
 $ cd debian_l2tp_cli_client

3. Use ip a to determine your system's default interface you wish to route the VPN tunnel's traffic through (i.e. eth0 or enp0s22)
 $ ip a

4. Execute the following script with the correct parameters to configure your VPN settings
 $ sudo sh l2tp_cli_client.sh -h=YOUR_VPN_HOST -s=YOUR_L2TP_SOURCE_PORT -u=YOUR_VPN_USERNAME -p=YOUR_VPN_USERPASS -i=YOUR_USER_DEFAULT_INTERFACE -k=YOUR_VPN_PSK

5. To start the VPN Client run
 $ sudo start-vpn

6. To kill the VPN Client run
 $ sudo stop-vpn

7. You can reconfigure your VPN's setup as needed at anytime using
 $ sudo sh l2tp_cli_client.sh -h=YOUR_NEW_VPN_HOST -s=YOUR_NEW_L2TP_SOURCE_PORT -u=YOUR_NEW_VPN_USERNAME -p=YOUR_NEW_VPN_USERPASS -i=YOUR_NEW_USER_DEFAULT_INTERFACE -k=YOUR_NEW_VPN_PSK

To Configure NAT_T Source UDP Port Setting
-------------------------------------------

1. Open /etc/strongswan.d/charon.conf with a text edits as root
 $ sudo nano /etc/strongswan.d/charon.conf

2. Find the port_nat_t setting, uncomment it and set it to your custom port value.
 *Default value for this UDP Port is 4500.

3. Save the close the file.

4. Reconfigure your VPN Client
 $ cd ~/debian_l2tp_cli_client

 $ sudo sh l2tp_cli_client.sh -h=YOUR_NEW_VPN_HOST -s=YOUR_NEW_L2TP_SOURCE_PORT -u=YOUR_NEW_VPN_USERNAME -p=YOUR_NEW_VPN_USERPASS -i=YOUR_NEW_USER_DEFAULT_INTERFACE -k=YOUR_NEW_VPN_PSK

5. Start VPN
 $ sudo start-vpn
