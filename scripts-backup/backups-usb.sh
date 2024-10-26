#!/bin/bash
#
# backup-usb.sh - Script Backup USB
#
# Autor: Hugllas R S Lima <hugllaslima@gmail.com>
# Date: 11.01.2023
#
#  ----------------------------------------------------------------------
# |                                                                      |
# | Este script irá montar o HD externo quando o sistema for reiniciado. |
# |                                                                      |
#  ----------------------------------------------------------------------
#
# Exemplo:
#       $ ./backup-usb.sh
#               - {Irá montar o disco externo}
#
# Histórico:
#       v1.0 2023-01-11, Hugllas R S Lima
#               - Versão melhorada no quesito:
#                       - Cabeçalho
#                       - Discrição
#
# Licença: GPL

# Sugestão de Crontab
# @reboot /root/Scripts/backups-usb.sh

 mount /dev/sdc1 /mnt/pve/backups-usb

sleep 1

 df -h

sleep 1

echo " "
echo " < SEU DISCO FOI MONTADO COM SUCESSO > "
echo " "

# fim_do_script
