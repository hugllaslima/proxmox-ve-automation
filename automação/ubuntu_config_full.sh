#!/bin/bash
#
# ubuntu_config_full.sh - Configuração Inicial para Ubuntu Server (Proxmox VE)
#
# - Autor...........: Hugllas R S Lima 
# - Data............: 2025-08-04
# - Versão..........: 1.0.0
#
# Descrição:
#   - Prepara VM Ubuntu Server para Proxmox VE.
#   - Ajusta timezone, sudo, SSH e instala Docker/Compose.
#
# Uso:
#   - sudo ./ubuntu_config_full.sh
#
# Licença: GPL-3.0
#

set -euo pipefail

#=> Funções auxiliares

reiniciar() {
    echo
    echo "ATENÇÃO: Antes de reiniciar, teste o acesso SSH com sua chave em outra aba/terminal!"
    read -p "Deseja reiniciar o servidor agora para aplicar as alterações? (s/n): " RESP_REBOOT
    if [[ "$RESP_REBOOT" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        echo "Reiniciando o servidor..."
        sleep 2
        sudo reboot
    else
        echo "REINICIALIZAÇÃO NÃO EXECUTADA."
        echo "Por favor, execute 'sudo reboot' manualmente quando estiver pronto."
    fi
}

#=> FUNÇÃO: Configuração Inicial (Root)
configuracao_inicial() {
echo "[Configuração Inicial - Root]"
echo "Ajustando o timezone..."
    timedatectl set-timezone America/Sao_Paulo
    echo "Timezone configurado para: $(timedatectl show --property=Timezone --value)"
sleep 1

echo "Adicionando usuário 'ubuntu' ao grupo sudo..."
    usermod -aG sudo ubuntu
    sleep 1

echo "Enable sudo sem senha para ubuntu..."
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ubuntu    
    sleep 1

echo "Atualizando pacotes..."
    apt update && apt upgrade -y    
    sleep 1

echo "Instalando qemu-guest-agent..."
    apt install qemu-guest-agent -y
    systemctl start qemu-guest-agent
    systemctl enable qemu-guest-agent
}

#=> FUNÇÃO: Configuração SSH para Ubuntu
configura_ssh_ubuntu() {
    echo "[SSH para usuário ubuntu]"

    SSH_DIR="/home/ubuntu/.ssh"
    AUTH_KEYS="$SSH_DIR/authorized_keys"
    ID_RSA="$SSH_DIR/id_rsa"
    ID_PUB="$SSH_DIR/id_rsa.pub"

    echo "Criando diretório SSH para o usuário ubuntu..."
    sudo -u ubuntu mkdir -p $SSH_DIR
    sudo chown ubuntu:ubuntu $SSH_DIR
    sudo chmod 700 $SSH_DIR

    # Entrada manual da chave privada (campo oculto)
    echo "Por favor, cole a chave PRIVADA do usuário ubuntu (PEM)."
    echo "Finalize com Ctrl+D numa linha em branco."
    sudo -u ubuntu tee $ID_RSA > /dev/null
    sudo chmod 600 $ID_RSA

    # Gerar chave pública correspondente
    echo "Gerando chave pública a partir da chave privada..."
    sudo -u ubuntu ssh-keygen -y -f $ID_RSA | sudo tee $ID_PUB > /dev/null
    sudo chmod 644 $ID_PUB

    # Adiciona a chave pública ao authorized_keys
    sudo -u ubuntu touch $AUTH_KEYS
    if ! grep -q "$(sudo cat $ID_PUB)" $AUTH_KEYS; then
        sudo cat $ID_PUB | sudo tee -a $AUTH_KEYS > /dev/null
    fi
    sudo chmod 600 $AUTH_KEYS
    sudo chown ubuntu:ubuntu $AUTH_KEYS

    echo "Chaves SSH configuradas para o usuário ubuntu."
}

#=> FUNÇÃO: Ajustes no SSHD
ajusta_sshd() {
    echo "[Ajuste do SSHD]"

    SSHD_CONFIG="/etc/ssh/sshd_config"

    # Backup antes de alterar
    sudo cp $SSHD_CONFIG ${SSHD_CONFIG}.bkp_$(date +%Y%m%d%H%M%S)

    # Descomentar/ajustar parâmetros essenciais
    sudo sed -i \
        -e 's/^#\?\s*PubkeyAuthentication.*/PubkeyAuthentication yes/' \
        -e 's/^#\?\s*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys .ssh\/authorized_keys2/' \
        -e 's/^#\?\s*PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#\?\s*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' \
        $SSHD_CONFIG

    # Ajusta *.conf se necessário (comenta PasswordAuthentication yes)
    for CONF in /etc/ssh/sshd_config.d/*.conf; do
        if [ -f "$CONF" ]; then
            sudo sed -i \
                -e 's/^\s*PasswordAuthentication yes/# PasswordAuthentication yes/g' \
                $CONF
        fi
    done

    echo "Reiniciando sshd..."
    sudo systemctl restart ssh

    echo "Ajustes SSH aplicados. Teste o acesso via SSH em outra janela antes de sair desta sessão!"
}

#=> FUNÇÃO: Instalação Docker e Docker Compose (para ubuntu)
instala_docker() {
    echo "[Docker para usuário ubuntu]"

    read -p "Deseja instalar o Docker e Docker Compose para o usuário ubuntu? (s/n): " INSTALAR_DOCKER
    if [[ "$INSTALAR_DOCKER" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y

        sudo apt update
        sudo apt install docker-ce -y
        sudo systemctl enable docker

        sudo usermod -aG docker ubuntu

        echo "Instalando Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        echo "Versões instaladas:"
        docker --version
        docker-compose --version

        echo "Usuário ubuntu pronto para usar Docker e Docker Compose."
    else
        echo "Instalação do Docker IGNORADA."
    fi
}

###########################
### EXECUÇÃO DO SCRIPT ####
###########################

if [[ $(id -u) -eq 0 ]]; then
    configuracao_inicial
    configura_ssh_ubuntu
    ajusta_sshd
    instala_docker
    reiniciar
else
    echo "Execute este script como ROOT (sudo su)."
    exit 1
fi

# ===== FIM DO SCRIPT =====
