#!/bin/bash
#
# Script de backup / export full das configs dos nodes
# do proxmox; por cgomes at unesp.br em 200917
#
# sugestao cron todo sabado
# 40 18 * * 6 /root/backup/bkpPmx.sh


# strings de identificacao do host e data
NOME_ARQ=`date +'%d%m%y-%H%M'`
DIR_BK=/root/backup/$HOSTNAME.$NOME_ARQ
HOJE=$HOSTNAME.$NOME_ARQ

cd /root/backup/
mkdir -p $HOJE

#compacta os arquivos criticos de reconstrucao
tar -zcf $DIR_BK/pve-cluster-backup.tar.gz /var/lib/pve-cluster
tar -zcf $DIR_BK/ssh-backup.tar.gz /root/.ssh
tar -zcf $DIR_BK/corosync-backup.tar.gz /etc/corosync
tar -zcf $DIR_BK/iscsi-backup.tar.gz /etc/iscsi
tar -zcf $DIR_BK/etc-backup.tar.gz /etc

#compacta repositorios ativos
tar -zcf $DIR_BK/apt-backup.tar.gz /etc/apt 

#salva configuracoes de rede
cp /etc/hosts $DIR_BK/hosts
cp /etc/network/interfaces $DIR_BK/interfaces

#salva pacotes instalados
aptitude --display-format '%p' search '?installed!?automatic' > $DIR_BK/pkg.instalados

#compacta pasta com a data corrente e apaga
tar -zcf $HOJE.tar.gz $HOJE
rm -rf $HOJE 

## pra reinstalar depois:
## sudo xargs aptitude --schedule-only install < instalados ; sudo aptitude install

## pra restaurar precisa destas, sugerida no wiki
#    /root/pve-cluster-backup.tar.gz
#    /root/ssh-backup.tar.gz
#    /root/corosync-backup.tar.gz
#    /root/hosts
#    /root/interfaces


# echo de resultado
#echo "Backup foi realizado com sucesso."
#echo "Diretório: $HOJE";
exit 0

#fin_script
