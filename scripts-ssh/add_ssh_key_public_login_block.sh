#!/bin/bash

#==============================================================================
# Script: add_key_ssh_public.sh
# Descrição: Adiciona uma chave pública SSH ao authorized_keys de um usuário
#            com validação, confirmação interativa e comentário identificando
#            o proprietário.
# Autor: Hugllas Lima
# Data: $(date +%Y-%m-%d)
# Versão: 1.1 (Ajustado para incluir hardening SSH e validação pós-execução)
# Licença: MIT
# Repositório: https://github.com/hugllashml/proxmox-ve-automation
#==============================================================================
#
# ETAPAS DO SCRIPT:
# 1. Selecionar e confirmar usuário alvo
# 2. Informar o proprietário da chave (comentário)
# 3. Preparar diretório .ssh e authorized_keys (permissões e ownership)
# 4. Colar e validar chave pública
# 5. Verificar duplicidade
# 6. Adicionar comentário e chave
# 7. (NOVO) Ajustar configurações SSH (hardening)
# 8. (NOVO) Pausar para validação de acesso SSH
#
# Uso:
#   chmod +x add_key_ssh_public.sh
#   sudo ./add_key_ssh_public.sh
#
# Pré-requisitos:
# - Acesso sudo/root para escrever no home de outros usuários e modificar
#   configurações do SSH do sistema.
# - openssh-client instalado (para validar formato de chave)
#
# Boas práticas:
# - .ssh deve ter permissão 700 e owned pelo usuário alvo
# - authorized_keys deve ter permissão 600 e owned pelo usuário alvo
# - Para adicionar chave a outro usuário, execute com sudo
#
# ATENÇÃO: A desativação do login por senha pode bloquear o acesso se a chave SSH
#          não estiver configurada corretamente. Certifique-se de ter um método
#          alternativo de acesso (ex: console físico/virtual) ou teste
#          cuidadosamente.

# Função para exibir uma mensagem de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

echo " "
echo "---------------------------------------------"
echo "--- Adicionar Chave Pública SSH (interativo) ---"
echo "---------------------------------------------"

# Verifica se o script está sendo executado como root ou com sudo
if [ "$(id -u)" -ne 0 ]; then
    error_exit "Este script precisa ser executado como root (ou com sudo) para gerenciar chaves de outros usuários e ajustar as configurações do SSH do sistema."
fi

# ============================================================================
# ETAPA 1: Selecionar e confirmar usuário alvo
# ============================================================================
while true; do
    # Usa SUDO_USER se o script foi chamado com sudo, senão usa USER
    CURRENT_EFFECTIVE_USER=${SUDO_USER:-$USER}
    read -p "Para qual usuário no servidor a chave pública será adicionada? (Deixe em branco para o usuário atual: $CURRENT_EFFECTIVE_USER): " TARGET_USER_INPUT
    TARGET_USER=${TARGET_USER_INPUT:-$CURRENT_EFFECTIVE_USER} # Se vazio, usa o usuário atual (ou o que chamou sudo)

    echo "Você informou o usuário: '$TARGET_USER'"
    read -p "Esta informação está correta? (s/N): " CONFIRM_TARGET_USER
    if [[ "$CONFIRM_TARGET_USER" =~ ^[Ss]$ ]]; then
        # Obter o diretório home do usuário alvo
        if ! HOME_DIR=$(eval echo "~$TARGET_USER"); then
            echo "Aviso: Usuário '$TARGET_USER' não encontrado ou inacessível. Por favor, tente novamente."
            continue # Volta para o início do loop
        fi
        break # Sai do loop se confirmado e usuário válido
    else
        echo "Por favor, insira o usuário novamente."
    fi
done

# ============================================================================
# ETAPA 2: Informar o proprietário da chave (comentário)
# ============================================================================
while true; do
    echo ""
    read -p "Qual o nome da pessoa ou sistema que está adicionando esta chave? (Ex: 'João da Silva', 'Servidor de Backup'): " KEY_OWNER_NAME
    if [ -z "$KEY_OWNER_NAME" ]; then
        echo "Erro: O nome do proprietário da chave é obrigatório para o comentário. Por favor, tente novamente."
        continue # Volta para o início do loop
    fi

    echo "Você informou o nome: '$KEY_OWNER_NAME'"
    read -p "Esta informação está correta? (s/N): " CONFIRM_KEY_OWNER
    if [[ "$CONFIRM_KEY_OWNER" =~ ^[Ss]$ ]]; then
        break # Sai do loop se confirmado
    else
        echo "Por favor, insira o nome novamente."
    fi
done

SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS_FILE="$SSH_DIR/authorized_keys"
COMMENT_LINE="# Key for: $KEY_OWNER_NAME (added by $CURRENT_EFFECTIVE_USER on $(date +%Y-%m-%d))" # Adiciona mais detalhes ao comentário

echo "A chave será adicionada para o usuário: $TARGET_USER"
echo "Comentário a ser adicionado: $COMMENT_LINE"
echo "Caminho do arquivo authorized_keys: $AUTH_KEYS_FILE"

# ============================================================================
# ETAPA 3: Preparar diretório .ssh e arquivo authorized_keys
# ============================================================================
# Como o script já exige sudo, podemos usar sudo diretamente para todas as operações de arquivo
# relacionadas a .ssh e authorized_keys, garantindo que as permissões e propriedade sejam corretas.

# Criar diretório .ssh e definir permissões/propriedade
if [ ! -d "$SSH_DIR" ]; then
    echo "Criando diretório $SSH_DIR..."
    sudo mkdir -p "$SSH_DIR" || error_exit "Falha ao criar diretório $SSH_DIR."
    sudo chown "$TARGET_USER:$TARGET_USER" "$SSH_DIR" || error_exit "Falha ao definir proprietário para $SSH_DIR."
    sudo chmod 0700 "$SSH_DIR" || error_exit "Falha ao definir permissões para $SSH_DIR."
else
    # Garantir permissões e propriedade corretas se já existir
    sudo chown "$TARGET_USER:$TARGET_USER" "$SSH_DIR" || error_exit "Falha ao definir proprietário para $SSH_DIR."
    sudo chmod 0700 "$SSH_DIR" || error_exit "Falha ao definir permissões para $SSH_DIR."
fi

# Criar arquivo authorized_keys e definir permissões/propriedade
if [ ! -f "$AUTH_KEYS_FILE" ]; then
    echo "Criando arquivo $AUTH_KEYS_FILE..."
    sudo touch "$AUTH_KEYS_FILE" || error_exit "Falha ao criar arquivo $AUTH_KEYS_FILE."
    sudo chown "$TARGET_USER:$TARGET_USER" "$AUTH_KEYS_FILE" || error_exit "Falha ao definir proprietário para $AUTH_KEYS_FILE."
    sudo chmod 0600 "$AUTH_KEYS_FILE" || error_exit "Falha ao definir permissões para $AUTH_KEYS_FILE."
else
    # Garantir permissões e propriedade corretas se já existir
    sudo chown "$TARGET_USER:$TARGET_USER" "$AUTH_KEYS_FILE" || error_exit "Falha ao definir proprietário para $AUTH_KEYS_FILE."
    sudo chmod 0600 "$AUTH_KEYS_FILE" || error_exit "Falha ao definir permissões para $AUTH_KEYS_FILE."
fi


# ============================================================================
# ETAPA 4: Colar e validar chave pública
# ============================================================================
while true; do
    echo ""
    echo "Por favor, cole a chave pública SSH. Após colar, pressione Enter e, em seguida, pressione Enter novamente em uma linha vazia para finalizar."
    echo "Exemplo: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD..."
    KEY_CONTENT=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        KEY_CONTENT+="$line"$'\n'
    done
    # Remover a última quebra de linha se houver, para garantir correspondência exata
    KEY_CONTENT=$(echo -e "$KEY_CONTENT" | sed -e '$!b' -e '/^\s*$/d')

    if [ -z "$KEY_CONTENT" ]; then
        echo "Erro: Nenhuma chave pública foi fornecida. Por favor, tente novamente."
        continue # Volta para o início do loop
    fi

    # Validação básica do formato da chave SSH
    if ! echo "$KEY_CONTENT" | grep -Eq "^(ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-ed25519|sk-ecdsa-sha2-nistp256@openssh.com|sk-ssh-ed25519@openssh.com) [A-Za-z0-9+/]+={0,2}( .*)?$"; then
        echo "Aviso: A chave pública fornecida não parece estar em um formato SSH válido."
        read -p "Deseja continuar mesmo assim? (s/N): " CONFIRM_INVALID
        if [[ ! "$CONFIRM_INVALID" =~ ^[Ss]$ ]]; then
            echo "Por favor, cole a chave pública novamente."
            continue # Volta para o início do loop
        fi
    fi

    # Exibir uma parte da chave para confirmação
    # Melhorar a prévia para chaves muito longas
    KEY_PREVIEW_START=$(echo "$KEY_CONTENT" | head -n 1 | cut -c 1-70)
    KEY_PREVIEW_END=$(echo "$KEY_CONTENT" | tail -n 1 | rev | cut -c 1-50 | rev) # Pega os últimos 50 caracteres
    KEY_PREVIEW="${KEY_PREVIEW_START}...${KEY_PREVIEW_END}"

    echo ""
    echo "Você colou a seguinte chave (prévia):"
    echo "$KEY_PREVIEW"
    read -p "A chave pública está correta? (s/N): " CONFIRM_KEY_CONTENT
    if [[ "$CONFIRM_KEY_CONTENT" =~ ^[Ss]$ ]]; then
        break # Sai do loop se confirmado
    else
        echo "Por favor, cole a chave pública novamente."
    fi
done

# ============================================================================
# ETAPA 5: Verificar duplicidade
# ============================================================================
# Como o script agora sempre é executado com sudo, podemos simplificar a verificação
if sudo grep -qF "$KEY_CONTENT" "$AUTH_KEYS_FILE"; then
    echo "Aviso: A chave pública fornecida já existe no arquivo $AUTH_KEYS_FILE. Nenhuma alteração foi feita."
    exit 0
fi

# ============================================================================
# ETAPA 6: Adicionar comentário e chave ao authorized_keys
# ============================================================================
echo "Adicionando o comentário e a chave pública ao arquivo $AUTH_KEYS_FILE..."

# Prepara o conteúdo completo (comentário + chave) para ser escrito
CONTENT_TO_WRITE="$COMMENT_LINE"$'\n'"$KEY_CONTENT"

# Usar sudo para anexar o conteúdo e, em seguida, reaplicar propriedade/permissões
echo "$CONTENT_TO_WRITE" | sudo tee -a "$AUTH_KEYS_FILE" > /dev/null || error_exit "Falha ao adicionar a chave pública."
sudo chown "$TARGET_USER:$TARGET_USER" "$AUTH_KEYS_FILE" || error_exit "Falha ao definir proprietário para $AUTH_KEYS_FILE após adição."
sudo chmod 0600 "$AUTH_KEYS_FILE" || error_exit "Falha ao definir permissões para $AUTH_KEYS_FILE após adição."

echo "Chave pública adicionada com sucesso para o usuário '$TARGET_USER'!"

# ============================================================================
# ETAPA 7: Ajustar configurações SSH (hardening)
# ============================================================================
echo ""
echo "--- Ajuste de Configurações SSH (Hardening) ---"
read -p "Deseja desabilitar o login por senha e endurecer as configurações SSH neste servidor? (s/N): " CONFIRM_HARDENING

if [[ "$CONFIRM_HARDENING" =~ ^[Ss]$ ]]; then
    echo "Aplicando ajustes de segurança ao SSH..."

    SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

    # Fazer backup do sshd_config original
    echo "Fazendo backup de $SSHD_CONFIG_FILE para ${SSHD_CONFIG_FILE}.bak_$(date +%Y%m%d%H%M%S)..."
    sudo cp "$SSHD_CONFIG_FILE" "${SSHD_CONFIG_FILE}.bak_$(date +%Y%m%d%H%M%S)" || error_exit "Falha ao fazer backup do sshd_config."

    # Desabilitar PasswordAuthentication
    echo "Desabilitando PasswordAuthentication..."
    sudo sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG_FILE"

    # Desabilitar ChallengeResponseAuthentication
    echo "Desabilitando ChallengeResponseAuthentication..."
    sudo sed -i 's/^#\?ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' "$SSHD_CONFIG_FILE"

    # Restringir PermitRootLogin para chaves (se root login for permitido)
    echo "Configurando PermitRootLogin para 'prohibit-password'..."
    # Primeiro, remove qualquer linha existente de PermitRootLogin que não seja comentada
    sudo sed -i '/^PermitRootLogin/d' "$SSHD_CONFIG_FILE"
    # Em seguida, adiciona a linha desejada ou modifica a comentada
    # Esta regex tenta encontrar e substituir linhas como "PermitRootLogin yes", "PermitRootLogin without-password", etc.
    # Se não encontrar, a linha será adicionada no final.
    if ! sudo sed -i 's/^#\?PermitRootLogin \(yes\|without-password\|forced-commands-only\)/PermitRootLogin prohibit-password/' "$SSHD_CONFIG_FILE"; then
        # Se o sed acima não encontrou uma linha para modificar, adiciona uma nova
        echo "PermitRootLogin prohibit-password" | sudo tee -a "$SSHD_CONFIG_FILE" > /dev/null
    fi

    # Reiniciar o serviço SSH
    echo "Reiniciando o serviço SSH para aplicar as mudanças..."
    if sudo systemctl restart sshd &>/dev/null; then
        echo "Serviço SSH reiniciado com sucesso (systemctl)."
    elif sudo service sshd restart &>/dev/null; then
        echo "Serviço SSH reiniciado com sucesso (service)."
    else
        echo "Aviso: Falha ao reiniciar o serviço SSH. Pode ser necessário reiniciar manualmente para que as mudanças entrem em vigor."
        echo "Comando para reiniciar: sudo systemctl restart sshd ou sudo service sshd restart"
    fi
else
    echo "Ajustes de segurança SSH não aplicados."
fi

echo ""
echo "--- Próximo Passo: Testar o Acesso SSH ---"
echo "A chave pública foi adicionada para o usuário '$TARGET_USER'."
if [[ "$CONFIRM_HARDENING" =~ ^[Ss]$ ]]; then
    echo "As configurações SSH foram endurecidas (login por senha desabilitado)."
    echo "É CRÍTICO que você valide o acesso via chave SSH AGORA."
    echo "Certifique-se de que você consegue fazer login com a chave e que NÃO consegue mais fazer login com senha."
else
    echo "O login por senha ainda está habilitado (se era o padrão)."
fi
echo "Por favor, abra uma NOVA sessão de terminal e tente acessar o servidor via SSH."
echo "Exemplo: ssh $TARGET_USER@<IP_DO_SEU_SERVIDOR>"
read -p "Pressione Enter APÓS validar o acesso SSH para finalizar o script."

echo ""
echo "Script concluído. Verifique se o acesso SSH está funcionando corretamente."
