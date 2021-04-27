#!/usr/bin/env bash

_script="$(readlink -f ${BASH_SOURCE[0]})"
_base="$(dirname $_script)"

fUsers="$_base/users.ldif"
fUos="$_base/uos.ldif"
fGroups="$_base/groups.ldif"
dnBase="$_base/.dn_base"
fAdmin="$_base/.admin"

while :
do
	clear

	if [[ ! -f $fAdmin ]]; then
		echo -e "\nQuin és l'usuari administrador d'LDAP?"
		read admin
		echo -e "\nQuin és el domini? (domain.xyz)"
		IFS=. read dn1 dn2
		echo -e "cn="$admin",dn="$dn1",dn="$dn2"\n" > $fAdmin
	fi

	echo -e "\nLDAP: Menu d'usuari\nSelecciona l'acció desitjada\n\t(1) Crear nova UO\n\t(2) Crear un nou grup\n\t(3) Crear un nou usuari\n\t(4) Carregar a LDAP\n\t(5) Sortir"
	read -p ":	" num

	case $num in
		5)
			exit 0
		;;
		4)
			# Carregar a la DB
			carregar=true
		while [[ $carregar=true ]]; do
			clear
			echo -e "Quins fitxer vols carregar?"
			echo -e "\n\t1: Usuaris\n\t2: UOs\n\t3: Grups\n\t4: Tot"
			read tria
			case $tria in
				1)
					echo -e "Es carregaran els usuaris\n"
					read -s -p "Escriu la contrasenya de la DB: " contrasenya
					ldapadd -x -w $contrasenya -D $fAdmin -f $fUsers
					;;
				2)
					echo -e "Es carregaran les UO\n"
					read -s -p "Escriu la contrasenya de la DB: " contrasenya
					ldapadd -x -w $contrasenya -D $fAdmin -f $fUos
					;;
				3)
					echo -e "Es carregaran els Grups\n"
					read -s -p "Escriu la contrasenya de la DB: " contrasenya
					ldapadd -x -w $contrasenya -D $fAdmin -f $fGroups
					;;
				4)
					echo -e "Es carregaran tots els fitxers\n"
					read -s -p "Escriu la contrasenya de la DB: " contrasenya
					ldapadd -x -w $contrasenya -D $fAdmin -f $fUos
					ldapadd -x -w $contrasenya -D $fAdmin -f $fGroups
					ldapadd -x -w $contrasenya -D $fAdmin -f $fUsers
					;;
				*)
					echo -e "Germà, entre l'1 i el 4."
			esac
			echo -e "Vols fer algo més? [y/N]"
			read yn
			case $yn in
				y | Y)
					continue
					;;
				n | N | *)
					exit 0
					;;
			esac
		done
		;;
		3)
			# Crear Usuaris
			clear
			#DEBUG:
			#echo -e "\n"$fUsers"\n"
			echo -e "És guradarà a "$fUsers
			echo -e "\nCreador d'Usuaris\n"
			echo -e "\nUbicació de l'usuari ((uo.)domain.xyz):\t"
			IFS=. read ou dn1 dn2
			if [[ -z $dn2 ]]; then
				#statements
				dn2=$dn1
				dn1=$ou
				unset $cn
			fi

			# Treure el gidNumber
			gid=499
			if [ -f $fUsers ]; then
				gidFile=$(grep uidNumber $fUsers | cut -d " " -f2 | sort -d | tail -n 1)
				((gidFile++))
				gidDB=$(ldapsearch -x -LLL -b dc=edt,dc=org "(objectClass=inetOrgPerson)" | grep uidNumber | sort -d | cut -d " " -f2 | tail -n 1)
				((gidDB++))
				if [ $gidFile > $gidDB ]; then
					gid=$gidFile
				else
					gid=$gidDB
				fi
			else
				gid=$(ldapsearch -x -LLL -b dc=edt,dc=org "(objectClass=inetOrgPerson)" | grep uidNumber | sort -d | cut -d " " -f2 | tail -n 1)
				((gid++))
			fi

			printf "El gid serà %s.\nNom del usuari: " $gid
			read nuser
			if [[ -f "$fUsers" ]]; then
				printf "\nEl fitxer existeix, vols sobreescriure'l? [Y/n]\t"
				read yn
				case $yn in
					y | Y | *)
						printf "cn:%s,dn=%s,dn=%s\ngidNumber: %s\ncn: %s\nobjectClass: inetOrgPerson\nobjectClass: top\n" $nuser $dn1 $dn2 $cn > $fUsers
						;;
					n | N)
						echo -e "El contingut serà afegit al final del fitxer.\n"
						echo -e "cn: "$nuser",dn="$dn1",dn="$dn2"\ngidNumber: "$gid"\ncn: "$cn"\nobjectClass: inetOrgPerson\nobjectClass: top\n" >> $fUsers
						;;
				esac
			else
				echo -e "cn: "$nuser",dn="$dn1",dn="$dn2"\ngidNumber: "$gid"\ncn: "$cn"\nobjectClass: inetOrgPerson\nobjectClass: top\n" > $fUsers
			fi
			;;
		2)
			# Crear Grups
			clear
			#DEBUG:
			#echo -e "\n"$file"\n"
			echo -e "\nCreador de Grups\n"
			echo -e "\nNom de domini (ou=X,dc=Y,dc=tld):\t"
			read ub

			# Treure el gidNumber
			if [ -f $fGroups ]; then
				gidFile=$(grep gid $fGroups | cut -d " " -f2 | sort -d | tail -n 1)
				((gidFile++))
				gidDB=$(ldapsearch -x -LLL -b dc=edt,dc=org "(objectClass=posixGroup)" | grep gid | sort -d | cut -d " " -f2 | tail -n 1)
				((gidDB++))
				if [ $gidFile > $gidDB ]; then
					gid=$gidFile
				else
					gid=$gidDB
				fi
			else
				gid=$(ldapsearch -x -LLL -b dc=edt,dc=org "(objectClass=posixGroup)" | grep gid | sort -d | cut -d " " -f2 | tail -n 1)
			fi

			echo -e "El gid serà "$gid"."
			echo -e "\nNom del grup (cn=Nom):\t"
			read cn
			if [ -f "$fGroups" ]; then
				echo -e "\nEl fitxer existeix, vols sobreescriure'l? [Y/n]\t"
				read yn
				case $yn in
					y | Y)
						echo -e "dn: "$cn","$ub"\ngidNumber: "$gid"\ncn: "$cn"\nobjectClass: posixGroup\nobjectClass: top\n" > $fGroups
						;;
					n | N)
						echo -e "El contingut serà afegit al final del fitxer.\n"
						echo -e "dn: "$cn","$ub"\ngidNumber: "$gid"\ncn: "$cn"\nobjectClass: posixGroup\nobjectClass: top\n" >> $fGroups
						;;
						*)
						echo -e "dn: "$cn","$ub"\ngidNumber: "$gid"\ncn: "$cn"\nobjectClass: posixGroup\nobjectClass: top\n" > $fGroups
				esac
			else
				echo -e "dn: "$cn","$ub"\ngidNumber: "$gid"\ncn: "$cn"\nobjectClass: posixGroup\nobjectClass: top\n" > $fGroups
			fi
			# $_base/assistent.sh
			# El fitxer assistent conte tot el que hi ha en aquest 2n cas
			;;
		1)
			#Crear UOs
			clear
			echo -e "\nCreador d'UO\n"
			echo -e "\nNom de domini (dc=X,dc=tld):\t"
			read dn
			echo -e $dn >> $dnBase

			echo -e "\nNom de la UO (ou=UO):\t"
			read uo
			echo -e $uo","$dn >> $dnBase

			if [ -f "$fUos" ]; then
				echo -e "\nEl fitxer existeix, vols sobreescriure'l? [Y/n]\t"
				read yn
				case $yn in
					y | Y)
						echo -e "dn: "$uo","$dn"\nobjectClass: organizationalUnit\nobjectClass: top\nou: "$uo"\n" > $fUos
						;;
					n | N)
						echo -e "\ndn: "$uo","$dn"\nobjectClass: organizationalUnit\nobjectClass: top\nou: "$uo"\n" >> $fUos
						;;
					*)
						echo -e "dn: "$uo","$dn"\nobjectClass: organizationalUnit\nobjectClass: top\nou: "$uo"\n" > $fUos
						;;
				esac
			else
				echo -e "dn: "$uo","$dn"\nobjectClass: organizationalUnit\nobjectClass: top\nou: "$uo"\n" > $fUos
			fi
			# $_base/assistent.sh
			# El fitxer assistent conte tot el que hi ha en aquest 2n cas
			;;
		*)
		clear
		echo -e "Germà, has de posar algun dels numeros que està entre parentesis."
		;;
	esac
done
