#Primer borrem totes les regles prèvies:
iptables -Z
iptables -X
iptables -F
iptables -t nat -F
#Ara definim les regles per a que sigui permissiu:
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
#Activem tots els ports necessaris:
iptables -A FORWARD -s 192.168.0.0/24 -m multiport -p tcp --dport 21,22,80,8080,443 -j ACCEPT
#No podran fer ping desde fora ni al firewall ni a la xarxa:
iptables -A INPUT -p ICMP -j DROP
iptables -A FORWARD -d 192.168.0.0/24 -p ICMP -j DROP
#Pero desde dins de la xarxa podran fer ping al exterior:
iptables -A FORWARD -s 192.168.0.0/24 -p ICMP -j ACCEPT
#No permetre connexions ssh desde l’exterior:
iptables -A INPUT -p tcp --dport 22 -j DROP
#Permetre connexions ssh cap a l'exterior:
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
#Veure resultat:
iptables -L -n

