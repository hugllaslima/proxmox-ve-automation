#!/bin/bash
#
# ansible_config_host.sh - Script de Configuracao para Automação com Ansible
#
# - Autor....................: Hugllas RS Lima 
# - Data.....................: 2025-08-05
# - Versão...................: 1.0.0
#
# Etapas:
#    - $ ./ansible_config_host.sh
#        - {Verificando e Ataulizando as Dependências do SO ou Template LXC}
#        - {Adição da Key Publica Usuário "Ansible"}
#        - {}
#
# Histórico:
#    - v1.0.0 2025-08-05, Hugllas Lima
#        - Cabeçalho
#        - Discrição
#        - Funções
#
# Uso:
#   - sudo ./ansible_config_host.sh
#
# Licença: GPL-3.0
#

# ------------------------------------------------------------------------------
# Verificando e Ataulizando as Dependências do SO ou Template LXC
# ------------------------------------------------------------------------------

# Função para garantir sudo e openssh instalados
garante_sudo_e_openssh() {
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[INFO] 'sudo' não encontrado. Instalando..."
        apt update && apt install sudo -y
        echo "[INFO] 'sudo' instalado!"
    else
        echo "[INFO] 'sudo' já está instalado."
    fi

    if ! command -v ssh-keygen >/dev/null 2>&1; then
        echo "[INFO] 'ssh-keygen' (openssh-client) não encontrado. Instalando..."
        sudo apt update && sudo apt install openssh-client -y
        echo "[INFO] 'openssh-client' instalado!"
    else
        echo "[INFO] 'openssh-client' já está instalado."
    fi
}

# Função para atualizar o sistema operacional
atualiza_sistema() {
    echo "[INFO] Atualizando o sistema (apt update && apt upgrade -y)..."
    sudo apt update && sudo apt upgrade -y
    echo "[INFO] Sistema Operacional atualizado."
}

# PRÉ-ETAPA: PERGUNTAR SE VAI CHECAR SUDO E OPENSSH
echo
echo "Deseja verificar se 'sudo' e 'openssh-client' estão instalados?"
echo "Digite 1 para SIM (verificar e instalar se faltar)"
echo "Digite 2 para NÃO (pular essa etapa)"
read -p "Sua escolha: " OPCAO_SUDO

    if [ "$OPCAO_SUDO" == "1" ]; then
        garante_sudo_e_openssh
    else
        echo "[INFO] Etapa ignorada conforme solicitado."
    fi

# PRÉ-ETAPA: PERGUNTAR SE VAI ATUALIZAR O SISTEMA
echo
echo "Deseja atualizar o sistema operacional (apt update/upgrade)?"
echo "Digite 1 para SIM (recomendado em ambientes de manutenção ou inicialização)"
echo "Digite 2 para NÃO (pular essa etapa)"
read -p "Sua escolha: " OPCAO_ATUALIZA

    if [ "$OPCAO_ATUALIZA" == "1" ]; then
        atualiza_sistema
    else
        echo "[INFO] Atualização do SO ignorada conforme solicitado."
    fi

# (AQUI PRA FRENTE SIGA COM O RESTANTE DAS SUAS CONFIGS DE HOST/USUÁRIO/SSH)
# Exemplo:
echo
echo "Continue com a configuração do SSH agora..."

# ------------------------------------------------------------------------------
# Adição da Key Publica "Usuário Ansible"
# ------------------------------------------------------------------------------

echo "Digite o nome do usuário para configurar acesso SSH (ex: ubuntu, debian, ansible, root):"
read USUARIO

# Determina o home do usu  rio, independente de /home, /root, /srv, etc
HOME_USER=$(eval echo "~$USUARIO")

    if [ ! -d "$HOME_USER" ]; then
        echo "[ERRO] Diretório home do usuário '$USUARIO' não encontrado!"
        echo "Certifique-se de que o usuário existe ANTES de rodar este script."
        exit 1
    fi

echo
    echo "Esta máquina é:"
    echo "1) VM Linux (usuário $USUARIO)"
    echo "2) Container LXC (usuário $USUARIO)"
    read -p "Digite 1 ou 2 (só para log/registro): " OPCAO_TIPO
    [ "$OPCAO_TIPO" == "1" ] && TIPOTXT="VM Linux"
    [ "$OPCAO_TIPO" == "2" ] && TIPOTXT="Container LXC"

echo
echo "Cole a chave pública do usuário "ansible" (linha   nica):"
read -r CHAVE_PUB

echo "Preparando ambiente SSH para $USUARIO ($TIPOTXT) em $HOME_USER/.ssh ..."

    sudo mkdir -p "$HOME_USER/.ssh"
    echo "$CHAVE_PUB" | sudo tee -a "$HOME_USER/.ssh/authorized_keys" > /dev/null
    sudo sort -u "$HOME_USER/.ssh/authorized_keys" -o "$HOME_USER/.ssh/authorized_keys"
    sudo chown $USUARIO:$USUARIO "$HOME_USER/.ssh/authorized_keys"
    sudo chmod 600 "$HOME_USER/.ssh/authorized_keys"
    sudo chmod 700 "$HOME_USER/.ssh"
    sudo chown $USUARIO:$USUARIO "$HOME_USER/.ssh"

echo
echo "Chave pública adicionada para o usuário $USUARIO em $HOME_USER/.ssh/authorized_keys"
echo "Ideal para hosts Ansible, manutenção remota e automação."
echo
echo "Lembre-se de garantir:"
echo "  - PasswordAuthentication no"
echo "  - PubkeyAuthentication yes"
echo " "
echo "Caso haja alguma alteração nos arquivos de configuração do SSH, reinicie o serviço com o comando abaixo:"
echo "sudo systemctl restart ssh"
echo " "

echo
echo " ---------- Pronto! ---------- "

echo
echo "Processo concluído! O acesso Ansible já está pronto para o usuário escolhido."
echo "Lembre de garantir as configs de SSH no arquivo /etc/ssh/sshd_config.* para aceitar só chave (PasswordAuthentication no)."

# fim_script
