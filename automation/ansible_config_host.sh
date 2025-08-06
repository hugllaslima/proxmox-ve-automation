#!/bin/bash
#
# ansible_config.sh - Script de Configuracao para Automação com Ansible
#
# - Autor....................: Hugllas R S Lima 
# - Data.....................: 2025-08-05
# - Versão...................: 1.0.0
#
# Etapas:
#    - $ ./ansible_config.sh
#        - {Verificando as Dependências do SO}
#        - {Ataualizando e Configurando o Template}
#        - {Adição da Key Publica Usuário "ansible"}
#        - {}
#
# Histórico:
#    - v1.0.0 2025-08-05, Hugllas Lima
#        - Cabeçalho
#        - Discrição
#        - Funções
#
# Uso:
#   - sudo ./ansible_config.sh
#
# Licença: GPL-3.0
#

# ------------------------------------------------------------------------------
# Verificando as Dependências do SO 
# ------------------------------------------------------------------------------

garante_sudo_e_openssh() {
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[INFO] 'sudo' não encontrado. Instalando..."
        apt update && apt install sudo -y
        echo "[INFO] 'sudo' instalado!"
    fi
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        echo "[INFO] 'ssh-keygen' (openssh-client) não encontrado. Instalando..."
        sudo apt update && sudo apt install openssh-client -y
        echo "[INFO] 'openssh-client' instalado!"
    else
        echo "[INFO] 'openssh-client' já instalado."
    fi
}

# ------------------------------------------------------------------------------
# Ataualizando e Configurando o Template
# ------------------------------------------------------------------------------

    apt update && apt upgrade -y 

# ------------------------------------------------------------------------------
# Adição da Key Publica "Usuário Ansible"
# ------------------------------------------------------------------------------

echo "Digite o nome do usuário em que irá configurar o acesso (ex: ubuntu, debian, ansible, root):"
    read USUARIO

echo
    echo "Esta máquina é:"
    echo "1) VM Linux (usuário $USUARIO)"
    echo "2) Container LXC (usuário root)"
    read -p "Digite 1 ou 2: " OPCAO_TIPO

echo
echo "Cole AQUI a chave pública do usuário Ansible (línea única, ex: ssh-ed25519 AAAAC3...):"
    read -r CHAVE_PUB

    if [ "$OPCAO_TIPO" == "1" ]; then
    # Usuário específico em VM
    echo "Preparando ambiente SSH para $USUARIO em /home/$USUARIO/.ssh..."
        sudo mkdir -p /home/$USUARIO/.ssh
        echo "$CHAVE_PUB" | sudo tee /home/$USUARIO/.ssh/authorized_keys > /dev/null
        sudo chown $USUARIO:$USUARIO /home/$USUARIO/.ssh/authorized_keys
        sudo chmod 600 /home/$USUARIO/.ssh/authorized_keys
        sudo chmod 700 /home/$USUARIO/.ssh
        sudo chown $USUARIO:$USUARIO /home/$USUARIO/.ssh
        echo "Chave pública adicionada para $USUARIO em VM Linux!"
    elif [ "$OPCAO_TIPO" == "2" ]; then
    # Usuário root em LXC
    echo "Preparando ambiente SSH para root em /root/.ssh..."
        sudo mkdir -p /root/.ssh
        echo "$CHAVE_PUB" | sudo tee /root/.ssh/authorized_keys > /dev/null
        sudo chmod 600 /root/.ssh/authorized_keys
        sudo chmod 700 /root/.ssh
        echo "Chave pública adicionada para root em Container LXC!"
    else
        echo "Opção inválida. Saindo."
        exit 1
    fi

echo
echo "Processo concluído! O acesso Ansible já está pronto para o usuário escolhido."
echo "Lembre de garantir as configs de SSH no arquivo /etc/ssh/sshd_config.* para aceitar só chave (PasswordAuthentication no)."

# fim_script
