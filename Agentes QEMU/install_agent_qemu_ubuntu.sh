#!/bin/bash
#
# apt_install_qemu_agent.sh - Script para instalar o agente "qemu" em sistemas Ubuntu e Debian
#
# Autor: Hugllas R S Lima <hugllaslima@gmail.com>
# Date: 20.07.2024 23h56
#
# ---------------------------------------------------------------------------------------------
#
# O "qemu-guest-agent" é um daemon auxiliar, instalado no guest. É usado para trocar
# informações entre o host e o convidado e para executar comandos no convidado. Você tem
# que instalar o agente convidado em cada VM e depois habilitá-lo nas confugrações de sua
# maquina virtual. você pode fazer isso na interface Web Proxmox VE (GUI).
#
# Exemplo:
#       $ apt_install_qemu_agent.sh
#               - {irá realizar instalação do "qemu-guest-agent" no host convidado}
#               - {irá iniciar o serviço automaticamente}
#               - {irá iniciar o serviço automaticamente permanentemente}
#               - {irá reinicar o sistema}
#
# Histórico:
#       v1.0 2024-07-20, Hugllas R S Lima
#               - Versão inicial:
#               - Cabeçalho;
#               - Descrição;
#               - Comando.
#
# Licença: GPL

echo " "
echo " -------------------------------------------------------------- "
echo "|                                                              |"
echo "|    AGUARDE QUE IREMOS INICIAR A INSTALAÇÃO DO AGENTE QEMU    |"
echo "|                                                              |"
echo " -------------------------------------------------------------- "
       sleep 3
echo " "

       # INSTALAÇAO DO "QEMU-GUEST-AGENT" NO HOST CONVIDADO
         apt-get install qemu-guest-agent -y

       # INICIANDO O SERVIÇO
         systemctl start qemu-guest-agent

       # HABILITARÁ O SERVIÇO PARA INICIALIZAÇÃO AUTOMÁTICA
         systemctl start qemu-guest-agent

       sleep 2
echo " "
echo " -------------------------------------------------------------- "
echo "|                                                              |"
echo "|               INSTALAÇÃO CONCLUÍDA COM SUCESSO               |"
echo "|                                                              |"
echo "|                            < | >                             |"
echo "|                                                              |"
echo "|                      #### ATENÇÃO ####                       |"
echo "|                                                              |"
echo "|          SEU SISTEMA SERÁ REINICIADO EM 10 SEGUNDOS          |"
echo "|       PARA CANCELAR A REINICIALIZAÇÃO, DIGITE {CTRL+C}       |"
echo "|                                                              |"
echo " -------------------------------------------------------------- "
echo " "
       sleep 10

       # REINICIARÁ O SISTEMA OPERACIONAL
         reboot

#fim_script
