#Primer borrem totes les regles previes:
iptables -Z
iptables -X
iptables -F
iptables -t nat -F
#Ara definim les regles per a que sigui permisiu:
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
#Activem tots els ports necessaris:
iptables -A FORWARD -s 192.168.0.0/24 -m multiport -p tcp --dport 21,22,80,8080,443 -j ACCEPT
#No podran fer ping desde fora ni al firewall ni a la xarxa:
iptables -A INPUT -p ICMP -j DROP
iptables -A FORWARD -d 192.168.0.0/24 -p ICMP -j DROP
#Pero desde dins de la xarxa podran fer ping al exterior:
iptables -A FORWARD -s 192.168.0.0/24 -p ICMP -j ACCEPT
#Desactiva el SSH del Guardia:
iptables -A FORWARD -d 192.168.0.20 -p tcp --dport 22 -j DROP
#Denegar l'accés al OAR tots els ports menys el 443:
iptables -A FORWARD -d 192.168.0.4 -m multiport -p tcp --dport 21,22,80,8080 -j DROP
#Veure resultat:
iptables -L -n
