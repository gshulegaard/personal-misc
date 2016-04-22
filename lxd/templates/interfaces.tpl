# The primary network interface
auto eth0
iface eth0 inet {% if config_get("user.network_mode", "") == "link-local" %}manual{% else %}dhcp{% endif %}
#iface eth0 inet static
#address		100.100.100.2
#gateway		100.100.100.1
#netmask		255.255.255.0
#network		100.100.100.0/24
#broadcast	100.100.100.255
#dns-nameservers	8.8.8.8 8.8.4.4
