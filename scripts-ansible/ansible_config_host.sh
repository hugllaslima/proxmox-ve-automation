#!/bin/bash

#==============================================================================
# Script: ansible_config_host.sh
# Descrição: Configuração de hosts para automação com Ansible
# Autor: Hugllas Lima (com contribuições de Claude)
# Data: $(date +%Y-%m-%d)
# Versão: 1.1 (Adição de confirmações interativas para dados inseridos)
# Licença: MIT
# Repositório: https://github.com/hugllashml/proxmox-ve-automation
#==============================================================================

# ETAPAS DO SCRIPT:
# 1. Verificação e atualização das dependências do SO
# 2. Criação do usuário Ansible (NOTA: Este script não cria o usuário, apenas o configura)
# 3. Configuração de permissões sudo (NOTA: Este script não configura sudo, apenas adiciona chave)
# 4. Adição da chave pública do usuário Ansible
# 5. Configuração SSH para automação (NOTA: Este script não altera sshd_config, apenas prepara .ssh)
# 6. Instalação de pacotes necessários (já coberto na etapa 1)

# Função para exibir uma mensagem de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

echo " "
echo "----------------------------------------------------"
echo "--- Configuração de Host para Automação com Ansible ---"
echo "----------------------------------------------------"
echo "Este script prepara um usuário existente para receber acesso SSH via chave pública."
echo "Ele NÃO cria usuários, NÃO configura sudoers e NÃO altera o sshd_config."
echo "Para hardening completo e configuração de sudo, use o script 'add_key_ssh_public.sh'."
echo " "

# Verifica se o script está sendo executado como root ou com sudo
if [ "$(id -u)" -ne 0 ]; then
    error_exit "Este script precisa ser executado como root (ou com sudo) para gerenciar chaves de outros usuários."
fi

# ============================================================================
# ETAPA 1: VERIFICAÇÃO E ATUALIZAÇÃO DAS DEPENDÊNCIAS DO SO
# ============================================================================

# Função para garantir sudo e openssh instalados
garante_sudo_e_openssh() {
    echo "[INFO] Verificando 'sudo'..."
    if ! command -v sudo &>/dev/null; then
        echo "[INFO] 'sudo' não encontrado. Instalando..."
        apt update && apt install sudo -y || error_exit "Falha ao instalar 'sudo'."
        echo "[INFO] 'sudo' instalado!"
    else
        echo "[INFO] 'sudo' já está instalado."
    fi

    echo "[INFO] Verificando 'ssh-keygen' (openssh-client)..."
    if ! command -v ssh-keygen &>/dev/null; then
        echo "[INFO] 'ssh-keygen' (openssh-client) não encontrado. Instalando..."
        sudo apt update && sudo apt install openssh-client -y || error_exit "Falha ao instalar 'openssh-client'."
        echo "[INFO] 'openssh-client' instalado!"
    else
        echo "[INFO] 'openssh-client' já está instalado."
    fi
}

# Função para atualizar o sistema operacional
atualiza_sistema() {
    echo "[INFO] Atualizando o sistema (apt update && apt upgrade -y)..."
    sudo apt update && sudo apt upgrade -y || error_exit "Falha ao atualizar o sistema."
    echo "[INFO] Sistema Operacional atualizado."
}

# PRÉ-ETAPA: PERGUNTAR SE VAI CHECAR SUDO E OPENSSH
while true; do
    echo ""
    echo "Deseja verificar se 'sudo' e 'openssh-client' estão instalados?"
    echo "Digite 1 para SIM (verificar e instalar se faltar)"
    echo "Digite 2 para NÃO (pular essa etapa)"
    read -p "Sua escolha: " OPCAO_SUDO_INPUT

    if [[ "$OPCAO_SUDO_INPUT" == "1" || "$OPCAO_SUDO_INPUT" == "2" ]]; then
        read -p "Você escolheu '$OPCAO_SUDO_INPUT'. Está correto? (s/N): " CONFIRM_OPCAO_SUDO
        if [[ "$CONFIRM_OPCAO_SUDO" =~ ^[Ss]$ ]]; then
            OPCAO_SUDO="$OPCAO_SUDO_INPUT"
            break
        else
            echo "Por favor, faça sua escolha novamente."
        fi
    else
        echo "Opção inválida. Por favor, digite 1 ou 2."
    fi
done

if [ "$OPCAO_SUDO" == "1" ]; then
    garante_sudo_e_openssh
else
    echo "[INFO] Etapa de verificação de 'sudo' e 'openssh-client' ignorada conforme solicitado."
fi

# PRÉ-ETAPA: PERGUNTAR SE VAI ATUALIZAR O SISTEMA
while true; do
    echo ""
    echo "Deseja atualizar o sistema operacional (apt update/upgrade)?"
    echo "Digite 1 para SIM (recomendado em ambientes de manutenção ou inicialização)"
    echo "Digite 2 para NÃO (pular essa etapa)"
    read -p "Sua escolha: " OPCAO_ATUALIZA_INPUT

    if [[ "$OPCAO_ATUALIZA_INPUT" == "1" || "$OPCAO_ATUALIZA_INPUT" == "2" ]]; then
        read -p "Você escolheu '$OPCAO_ATUALIZA_INPUT'. Está correto? (s/N): " CONFIRM_OPCAO_ATUALIZA
        if [[ "$CONFIRM_OPCAO_ATUALIZA" =~ ^[Ss]$ ]]; then
            OPCAO_ATUALIZA="$OPCAO_ATUALIZA_INPUT"
            break
        else
            echo "Por favor, faça sua escolha novamente."
        fi
    else
        echo "Opção inválida. Por favor, digite 1 ou 2."
    fi
done

if [ "$OPCAO_ATUALIZA" == "1" ]; then
    atualiza_sistema
else
    echo "[INFO] Atualização do SO ignorada conforme solicitado."
fi

# ============================================================================
# ETAPA 2: CONFIGURAÇÃO DO USUÁRIO E AMBIENTE SSH
# ============================================================================

echo ""
echo "--- Configuração do Usuário para Acesso SSH ---"

while true; do
    read -p "Informe o usuário do HOST que irá receber a chave pública para acesso via SSH (ex: ubuntu, debian, ansible, root): " USUARIO_INPUT
    if [ -z "$USUARIO_INPUT" ]; then
        echo "Erro: O nome do usuário não pode ser vazio. Por favor, tente novamente."
        continue
    fi

    echo "Você informou o usuário: '$USUARIO_INPUT'"
    read -p "Esta informação está correta? (s/N): " CONFIRM_USUARIO
    if [[ "$CONFIRM_USUARIO" =~ ^[Ss]$ ]]; then
        USUARIO="$USUARIO_INPUT"
        # Determina o home do usuário, independente de /home, /root, /srv, etc
        if ! HOME_USER=$(eval echo "~$USUARIO"); then
            echo "[ERRO] Diretório home do usuário '$USUARIO' não encontrado ou inacessível!"
            echo "Certifique-se de que o usuário existe ANTES de rodar este script."
            continue # Volta para o início do loop de usuário
        fi
        break
    else
        echo "Por favor, insira o usuário novamente."
    fi
done

echo ""
while true; do
    echo "Esta máquina é:"
    echo "1) VM Linux (usuário $USUARIO)"
    echo "2) Container LXC (usuário $USUARIO)"
    read -p "Digite 1 ou 2 (só para log/registro): " OPCAO_TIPO_INPUT

    if [[ "$OPCAO_TIPO_INPUT" == "1" || "$OPCAO_TIPO_INPUT" == "2" ]]; then
        TIPOTXT=""
        [ "$OPCAO_TIPO_INPUT" == "1" ] && TIPOTXT="VM Linux"
        [ "$OPCAO_TIPO_INPUT" == "2" ] && TIPOTXT="Container LXC"

        echo "Você informou: '$TIPOTXT'"
        read -p "Esta informação está correta? (s/N): " CONFIRM_OPCAO_TIPO
        if [[ "$CONFIRM_OPCAO_TIPO" =~ ^[Ss]$ ]]; then
            OPCAO_TIPO="$OPCAO_TIPO_INPUT"
            break
        else
            echo "Por favor, faça sua escolha novamente."
        fi
    else
        echo "Opção inválida. Por favor, digite 1 ou 2."
    fi
done

# ============================================================================
# ETAPA 3: ADIÇÃO DA CHAVE PÚBLICA DO USUÁRIO ANSIBLE
# ============================================================================

echo ""
echo "--- Adição da Chave Pública SSH ---"
while true; do
    echo "Por favor, cole a chave pública do usuário 'ansible' (linha única). Após colar, pressione Enter e, em seguida, pressione Enter novamente em uma linha vazia para finalizar."
    echo "Exemplo: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD..."
    CHAVE_PUB_CONTENT=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        CHAVE_PUB_CONTENT+="$line"$'\n'
    done
    # Remover a última quebra de linha se houver, para garantir correspondência exata
    CHAVE_PUB_CONTENT=$(echo -e "$CHAVE_PUB_CONTENT" | sed -e '$!b' -e '/^\s*$/d')

    if [ -z "$CHAVE_PUB_CONTENT" ]; then
        echo "Erro: Nenhuma chave pública foi fornecida. Por favor, tente novamente."
        continue
    fi

    # Validação básica do formato da chave SSH
    if ! echo "$CHAVE_PUB_CONTENT" | grep -Eq "^(ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-ed25519|sk-ecdsa-sha2-nistp256@openssh.com|sk-ssh-ed25519@openssh.com) [A-Za-z0-9+/]+={0,2}( .*)?$"; then
        echo "Aviso: A chave pública fornecida não parece estar em um formato SSH válido."
        read -p "Deseja continuar mesmo assim? (s/N): " CONFIRM_INVALID
        if [[ ! "$CONFIRM_INVALID" =~ ^[Ss]$ ]]; then
            echo "Por favor, cole a chave pública novamente."
            continue
        fi
    fi

    # Exibir uma parte da chave para confirmação
    KEY_PREVIEW_START=$(echo "$CHAVE_PUB_CONTENT" | head -n 1 | cut -c 1-70)
    KEY_PREVIEW_END=$(echo "$CHAVE_PUB_CONTENT" | tail -n 1 | rev | cut -c 1-50 | rev)
    KEY_PREVIEW="${KEY_PREVIEW_START}...${KEY_PREVIEW_END}"

    echo ""
    echo "Você colou a seguinte chave (prévia):"
    echo "$KEY_PREVIEW"
    read -p "A chave pública está correta? (s/N): " CONFIRM_KEY_CONTENT
    if [[ "$CONFIRM_KEY_CONTENT" =~ ^[Ss]$ ]]; then
        CHAVE_PUB="$CHAVE_PUB_CONTENT"
        break
    else
        echo "Por favor, cole a chave pública novamente."
    fi
done

echo "Preparando ambiente SSH para $USUARIO ($TIPOTXT) em $HOME_USER/.ssh ..."

# Verifica se a chave já existe para evitar duplicidade
if sudo grep -qF "$CHAVE_PUB" "$HOME_USER/.ssh/authorized_keys" 2>/dev/null; then
    echo "Aviso: A chave pública fornecida já existe no arquivo $HOME_USER/.ssh/authorized_keys. Nenhuma alteração foi feita."
else
    sudo mkdir -p "$HOME_USER/.ssh" || error_exit "Falha ao criar diretório $HOME_USER/.ssh."
    echo "$CHAVE_PUB" | sudo tee -a "$HOME_USER/.ssh/authorized_keys" > /dev/null || error_exit "Falha ao adicionar chave ao authorized_keys."
    sudo sort -u "$HOME_USER/.ssh/authorized_keys" -o "$HOME_USER/.ssh/authorized_keys" || error_exit "Falha ao ordenar e remover duplicatas no authorized_keys."
    sudo chown "$USUARIO:$USUARIO" "$HOME_USER/.ssh/authorized_keys" || error_exit "Falha ao definir proprietário para authorized_keys."
    sudo chmod 600 "$HOME_USER/.ssh/authorized_keys" || error_exit "Falha ao definir permissões para authorized_keys."
    sudo chmod 700 "$HOME_USER/.ssh" || error_exit "Falha ao definir permissões para $HOME_USER/.ssh."
    sudo chown "$USUARIO:$USUARIO" "$HOME_USER/.ssh" || error_exit "Falha ao definir proprietário para $HOME_USER/.ssh."
    echo "Chave pública adicionada com sucesso."
fi

# ============================================================================
# ETAPA 4: FINALIZAÇÃO E INSTRUÇÕES
# ============================================================================

echo ""
echo "--- Próximos Passos e Verificações ---"
echo "Chave pública adicionada para o usuário $USUARIO em $HOME_USER/.ssh/authorized_keys"
echo "Ideal para hosts Ansible, manutenção remota e automação."
echo ""
echo "Lembre-se de garantir (verificando o arquivo /etc/ssh/sshd_config e /etc/ssh/sshd_config.d/*):"
echo "  - PasswordAuthentication no"
echo "  - PubkeyAuthentication yes"
echo "  - PermitRootLogin prohibit-password (se for o caso de acesso root)"
echo " "
echo "Caso haja alguma alteração nos arquivos de configuração do SSH, reinicie o serviço com o comando abaixo:"
echo "sudo systemctl restart ssh.service (ou sshd.service, dependendo da sua distribuição)"
echo " "

echo " ---------- Processo Concluído! ---------- "

echo ""
echo "O acesso Ansible já está pronto para o usuário escolhido."
echo "Verifique o acesso SSH para o usuário '$USUARIO' usando a chave configurada."
echo "Exemplo: ssh -i /caminho/para/sua/chave_privada $USUARIO@<IP_DO_HOST>"
echo ""

# fim_script
