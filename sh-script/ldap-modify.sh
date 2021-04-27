#!/usr/bin/env bash

_script="$(readlink -f ${BASH_SOURCE[0]})"
_base="$(dirname $_script)"

dname="$_base/.dname"
topdn="$_base/.topdn"
fadmin="$_base/.admin"

# Loop Principal
while :
do
	clear
	if [[ ! -f $fadmin  || ! -f $topdn ]]; then
		printf "\nEscriu el teu domnini (example.com):\t\t"
		IFS=. read domainname tls
		printf "\nEscriu l'usuari amb el que s'administra el domini (ex: Admin):\t"
		read adminuser
		printf "cn=%s,dc=%s,dc=%s" $adminuser $domainname $tls > $fadmin
		printf "dc=%s,dc=%s" $domainname $tls > $topdn
		printf "%s.%s" $domainname $tls > $dname
		unset domainname tls adminuser
	fi

	clear
	printf "░▒█░░░░█▀▄░█▀▀▄░▄▀▀▄░░░▒█▀▄▀█░█▀▀░█▀▀▄░█░▒█░░░▒█░▒█░█▀▀░█░░▄▀▀▄░█▀▀░█▀▀▄\n░▒█░░░░█░█░█▄▄█░█▄▄█░░░▒█▒█▒█░█▀▀░█░▒█░█░▒█░░░▒█▀▀█░█▀▀░█░░█▄▄█░█▀▀░█▄▄▀\n░▒█▄▄█░▀▀░░▀░░▀░█░░░░░░▒█░░▒█░▀▀▀░▀░░▀░░▀▀▀░░░▒█░▒█░▀▀▀░▀▀░█░░░░▀▀▀░▀░▀▀\n\n"

	printf "\n\t(1) Canviar el grup principal d'un usuari\n\t(2) Afegir un usuari a un grup\n\t(3) Fer desapareixer un usuari\n\t(4) Sortir\n"
	read choice
  case $choice in
    4 )
    exit 0
      ;;
    3 )
    printf "Segur que vols fer desapareixer un usuari? [y/N]"
    read yn
    case $yn in
      n | N )
      printf "D'acord!"
      exit 0
        ;;
      y | Y )
      printf "Molt bé, quin usuari vols que desaparegui?"
      uidnum=( $(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixAccount)" | grep uid | sed '/^dn:/,$d' | cut -d " " -f2 | sed '/[a-zA-Z]/d' | awk '!x[$0]++') )
      usname=( $(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixAccount)" | grep uid | sed '/^dn:/,$d' | cut -d " " -f2 | sed '/[[:digit:]]/d' | awk '!x[$0]++'))
      paste <(printf "\n%d" ${uidnum[@]}) <(printf "\n%s" ${usname[@]})
      read
        ;;
      * )
      printf "D'acord!"
      exit 0
    esac
      ;;
  esac
done
