#!/usr/bin/env bash

while : ; do
  clear
  echo -e "Qemu Image creation script\n\t:(1) Create qcow2 image\n\t:(2) Create raw image\n\t:(3) Exit"
  read tria
  case $tria in
    1 )
    type=qcow2
    clear
    echo -e "\nSpecify size (Number only): \c"
    read size
    echo -e "\nPlease, name the file (and directory if you want): \c"
    read nfile
    echo -e "\nqemu-img create -f "$type $nfile $size"G\n"
    qemu-img create -f $type $nfile $size\G
      ;;
    2 )
    type=raw
    clear
    echo -e "\nSpecify size (Number only):"
    read size
    echo -e "\nPlease, name the file (and directory if you want):"
    read nfile
    echo -e "\nqemu-img create -f "$type $nfile $size"G\n"
    qemu-img create -f $type $nfile $size\G
      ;;
    3 )
    clear
    echo -e "\nGoodbye\n"
    exit 0
      ;;
    * )
    echo -e "The options are the options."
    clear
      ;;
  esac
done
