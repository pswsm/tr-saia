#!/usr/bin/env bash

_script="$(readlink -f ${BASH_SOURCE[0]})"
_base="$(dirname $_script)"

fusers="$_base/users.ldif"
fuos="$_base/uos.ldif"
fgroups="$_base/groups.ldif"
fall="$_base/all.ldif"
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
		printf "cn=%s,dc=%s,dc=%s" $adminuser $domainname $tls | sed 's/$//' > $fadmin
		printf "dc=%s,dc=%s" $domainname $tls | sed 's/$//' > $topdn
		printf "%s.%s" $domainname $tls > $dname
		unset domainname tls adminuser
	fi

	clear
	printf "░▒█░░░░█▀▄░█▀▀▄░▄▀▀▄░░░▒█▀▄▀█░█▀▀░█▀▀▄░█░▒█░░░▒█░▒█░█▀▀░█░░▄▀▀▄░█▀▀░█▀▀▄\n░▒█░░░░█░█░█▄▄█░█▄▄█░░░▒█▒█▒█░█▀▀░█░▒█░█░▒█░░░▒█▀▀█░█▀▀░█░░█▄▄█░█▀▀░█▄▄▀\n░▒█▄▄█░▀▀░░▀░░▀░█░░░░░░▒█░░▒█░▀▀▀░▀░░▀░░▀▀▀░░░▒█░▒█░▀▀▀░▀▀░█░░░░▀▀▀░▀░▀▀\n\n"

	printf "\n\t(1) Crear nova UO\n\t(2) Crear un nou grup\n\t(3) Crear un nou usuari\n\t(4) Carregar a LDAP\n\t(5) Sortir\n"
	read choice

	case $choice in
		5 )
		exit 0
			;;
		4 )
		# Load Files
		clear
		printf "Que vols carregar a la Base de Dades?\n"
		printf "\n\t1: Usuaris\n\t2: UOs\n\t3: Grups\n\t4: Tot\n"
		read choice
		case $choice in
			1 )
			#Load users
			printf "Es carregaran els usuaris.\n"
			printf "Escriu la contrasenya d'LDAP:\t"
			read -s contrasenya
			ldapadd -x -w $contrasenya -D $(cat $fadmin) -f $fusers
			read -p "Prem ENTER"
			#rm $fusers
				;;
			2 )
			#Load OUs
			printf "Es carregaran les UOs.\n"
			printf "Escriu la contrasenya d'LDAP:\t"
			read -s contrasenya
			ldapadd -x -w $contrasenya -D $(cat $fadmin) -f $fuos
			read -p "Prem ENTER"
			#rm $fuos
				;;
			3 )
			#Load Groups
			printf "Es carregaran els grups.\n"
			printf "Escriu la contrasenya d'LDAP:\t"
			read -s contrasenya
			ldapadd -x -w $contrasenya -D $(cat $fadmin) -f $fgroups
			read -p "Prem ENTER"
			#rm $fgroups
				;;
			4 )
			#Load All
			printf "Es carregarà tot.\n"
			printf "Escriu la contrasenya d'LDAP:\t"
			read -s contrasenya
			cat $fuos $fgroups $fusers > $fall
			ldapadd -x -w $contrasenya -D $(cat $fadmin) -f $fall
			read -p "Prem ENTER"
			#rm $fuos $fall $fgroups $fusers
				;;
		esac
			;;
		3 )
		# User Creation
		## Get uidnum
		uid=999
		if [[ -f $fusers ]]; then
			uifile=$(grep uidNumber $fusers | cut -d " " -f2 | sort -d | tail -n 1)
			uidb=$(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixAccount)" | grep uidNumber | sort -d | cut -d " " -f2 | tail -n 1)
			((uifile++))
			((uidb++))
			if [ $uifile > $uidb ]; then
				uid=$uifile
			else
				uid=$uidb
			fi
		else
			uid=$(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixAccount)" | grep uidNumber | sort -d | cut -d " " -f2 | tail -n 1)
			((uid++))
		fi
		printf "\nL\'arxiu d\'usuaris es guardarà a %s\nNom i 1r congnom de l\'usuari: " $fusers
		IFS=" " read -a nomcg
		printf "\n\n" >> $fusers
		printf "\ndn: cn=%s %s," ${nomcg[@]} >> $fusers
		printf "\nUbicació de l\'usuari en el domini (Per defecte %s)(uo.domini.tls): " $(cat $dname)
		IFS=. read -a dn
		printf "ou=%s," ${dn[@]::${#dn[@]}-2} >> $fusers
		printf "dc=%s," ${dn[-2]} ${dn[-1]} | sed 's/.$//' >> $fusers
		printf "\ncn: %s %s"  ${nomcg[@]} >> $fusers
		printf "\ngivenName: %s" ${nomcg[0]} >> $fusers
		printf "\nEstà en algún grup? [Y/n] "
		read yn
		case $yn in
			y | Y )
			namefr=( $(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixGroup)" | cut -d ' ' -f2 | cut -d ',' -f1 | sed 's/cn=//' | sed '/posixGroup/d;/top/d;/^[[:space:]]*$/d;/^[[:digit:]]*$/d' | awk '!x[$0]++') )
			gidfor=( $(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixGroup)" | cut -d ' ' -f2 | cut -d ',' -f1 | sed 's/cn=//' | sed '/posixGroup/d;/top/d;/^[[:space:]]*$/d;/[a-zA-Z]/d' | awk '!x[$0]++') )
			paste <(printf "\n%d" ${gidfor[@]}) <(printf "\n%s" ${namefr[@]})
			printf "\n\nEn quin grup està? (Introdueix el gid): "
			read gidUSR
			printf "\ngidNumber: %s" $gidUSR >> $fusers
				;;
			* )
			printf "\nAh bé, tu sabràs manet"
		esac
		# Escriure el homedir
		nomlow=$(printf "%s" ${nomcg[0]} | cut -c1 | tr '[:upper:]' '[:lower:]')
		cognomlow=$(printf "%s" ${nomcg[1]} | tr '[:upper:]' '[:lower:]')
		printf "\nhomeDirectory: /home/users/%s%s" $nomlow $cognomlow >> $fusers
		# sn: Surname
		printf "\nsn: %s" ${nomcg[1]} >> $fusers
		printf "\nloginShell: /bin/sh\nobjectClass: inetOrgPerson\nobjectClass: posixAccount\nobjectClass: top\nuidNumber: %s\nuid: %s%s\n" $uid $nomlow $cognomlow >> $fusers
			;;
		2 )
		# Group Creation
		## Get gidnum
		gid=499
		if [[ -f $fgroups ]]; then
			gifile=$(grep gidNumber $fgroups | cut -d " " -f2 | sort -d | tail -n 1)
			gidb=$(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixGroup)" | grep gidNumber | sort -d | cut -d " " -f2 | tail -n 1)
			((gifile++))
			((gidb++))
			if [ $gifile > $gidb ]; then
				gid=$gifile
			else
				gid=$gidb
			fi
		else
			gid=$(ldapsearch -x -LLL -b $(cat $topdn) "(objectClass=posixGroup)" | grep gidNumber | sort -d | cut -d " " -f2 | tail -n 1)
			((gid++))
		fi
		printf "\nL\'arxiu de grups es guardarà a %s\nNom del grup: " $fgroups
		read nomgr
		printf "\n\n" >> $fgroups
		printf "dn: cn=%s," $nomgr >> $fgroups
		printf "\nUbicació del grup en el domini (Per defecte %s)((uo.)domini.tls): " $(cat $dname)
		IFS=. read -a dn
		printf "ou=%s," ${dn[@]::${#dn[@]}-2} >> $fgroups
		printf "dc=%s," ${dn[-2]} ${dn[-1]} | sed 's/.$//' >> $fgroups
		printf "\ngidNumber: %s" $gid >> $fgroups
		printf "\ncn: %s"  $nomgr >> $fgroups
		printf "\nobjectClass: posixGroup\nobjectClass: top\n" >> $fgroups
			;;
		1 )
		printf "\nL\'arxiu d'UOs es guardarà a %s" $fuos
		printf "\n\n" >> $fuos
		printf "\nUbicació i nom de la UO en el domini (uo.domini.tls): " $(cat $dname)
		IFS=. read -a dn
		printf "dn: " >> $fuos
		printf "ou=%s," ${dn[@]::${#dn[@]}-2} >> $fuos
		printf "dc=%s,dc=%s" ${dn[-2]} ${dn[-1]} >> $fuos
		printf "\nobjectClass: organizationalUnit\nobjectClass: top" >> $fuos
		printf "\nou: %s"  ${dn[0]} >> $fuos
	esac

done
