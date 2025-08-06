#!/bin/bash
#
# create_user_lxc.sh - Script de Configuracao Inicial para Container LXC
#
# - Autor....................: Hugllas R S Lima 
# - Data.....................: 2025-08-04
# - Versão...................: 1.0.0
#
# Etapas:
#    - $ ./create_user_lxc.sh
#        - {Ataualizando e Configurando o Template}
#        - {Instalando "sudo" e "openssh client"}
#        - {Criando e Configurando Novo Usuário}
#        - {Reinicia o Container LXC}
#
# Histórico:
#    - v1.0.0 2025-08-05, Hugllas Lima
#        - Cabeçalho
#        - Discrição
#        - Funções
#
# Uso:
#   - sudo ./create_user_lxc.sh
#
# Licença: GPL-3.0
#

# ------------------------------------------------------------------------------
# Ataualizando e Configurando o Template
# ------------------------------------------------------------------------------

echo "Ajustando o timezone..."
    timedatectl set-timezone America/Sao_Paulo
    echo "Timezone configurado para: $(timedatectl show --property=Timezone --value)"
    sleep 1
echo " "
echo "Atualizando o sistema operacional... "
        apt update && apt upgrade -y
echo " "

# ------------------------------------------------------------------------------
# Instalando "sudo" e "openssh client"
# ------------------------------------------------------------------------------

garante_sudo_e_openssh() {
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[INFO] 'sudo' n  o encontrado. Instalando..."
        apt update && apt install sudo -y
        echo "[INFO] 'sudo' instalado!"
    fi
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        echo "[INFO] 'ssh-keygen' (openssh-client) n  o encontrado. Instalando..."
        apt update && apt install openssh-client -y
        echo "[INFO] 'openssh-client' instalado!"
    else
        echo "[INFO] 'openssh-client' já instalado."
    fi
}

# -----------------------------------------------------------------------------
# Criando e Configurando um Usuario
# -----------------------------------------------------------------------------

# Pergunta o nome do usuário
        read -p "Digite o nome do usuário que deseja criar: " USUARIO
echo " "
# Cria o usuáriO
        sudo adduser $USUARIO
echo " "
# Adiciona o usuário ao grupo "sudo"
        sudo usermod -aG sudo $USUARIO
echo " "
    if getent group lxc >/dev/null; then
        sudo usermod -aG lxc $USUARIO
        echo "Usu  rio $USUARIO adicionado ao grupo lxc."
    elif getent group lxd >/dev/null; then
        sudo usermod -aG lxd $USUARIO
        echo "Usu  rio $USUARIO adicionado ao grupo lxd."
    else
        echo "Atenção: N  o foi encontrado o grupo 'lxc' nem 'lxd'. Verifique se LXC/LXD est  o corretamente instalados."
    fi
# Permite sudo sem senha para o usuário (opcional, recomendado para manutenção de containers LXC)
        echo "$USUARIO ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USUARIO
        echo "Usu  rio $USUARIO criado e configurado com sucesso para administrar containers LXC!"
echo " "

# -----------------------------------------------------------------------------
# Reinicia o Container LXC
# -----------------------------------------------------------------------------
echo " "
read -p "Deseja reiniciar o servidor agora? (s/n): " REINICIAR
   if [ "$REINICIAR" == "s" ]; then
        echo "Reiniciando o servidor..."
        sudo reboot
   else
        echo "Reinicializa    o cancelada. Voc   pode reiniciar manualmente se for necess  rio."
   fi
   
# fim_script
