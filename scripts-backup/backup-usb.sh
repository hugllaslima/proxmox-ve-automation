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
#	$ ./backup-usb.sh
#		- {Irá montar o disco externo para realização de backups}
#
# Histórico:
#	v2.0 2023-01-18, Hugllas R S Lima
#		- Versão melhorada no quesito:
#			- Cabeçalho
#			- Discrição
#
# Licença: GPL
#
# Sugestão de Crontab
# @reboot /root/scripts/backup-usb.sh
#
# Sugestão de Permissão
# chmod 775 backup-usb.sh

mount /dev/sdc1 /mnt/backup-usb

sleep 3

 df -h

sleep 5

echo " "
echo " < SEU DISCO FOI MONTADO COM SUCESSO > "
echo " "

# fim_do_script

