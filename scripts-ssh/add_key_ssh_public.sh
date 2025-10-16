#!/bin/bash

#==============================================================================
# Script: add_key_ssh_public.sh
# Descrição: Adiciona uma chave pública SSH ao authorized_keys de um usuário,
#            com validação, confirmação interativa e comentário identificando o proprietário.
# Autor: Hugllas Lima
# Data: $(date +%Y-%m-%d)
# Versão: 1.0
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
#
# Uso:
#   chmod +x add_key_ssh_public.sh
#   sudo ./add_key_ssh_public.sh
#
# Pré-requisitos:
# - Acesso sudo/root para escrever no home de outros usuários
# - openssh-client instalado (para validar formato de chave)
#
# Boas práticas:
# - .ssh deve ter permissão 700 e owned pelo usuário alvo
# - authorized_keys deve ter permissão 600 e owned pelo usuário alvo
# - Para adicionar chave a outro usuário, execute com sudo

# Função para exibir uma mensagem de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

echo " "
echo "---------------------------------------------"
echo "--- Adicionar Chave Pública SSH (interativo) ---"
echo "---------------------------------------------"

# ============================================================================
# ETAPA 1: Selecionar e confirmar usuário alvo
# ============================================================================
while true; do
    read -p "Para qual usuário no servidor a chave pública será adicionada? (Deixe em branco para o usuário atual: $USER): " TARGET_USER_INPUT
    TARGET_USER=${TARGET_USER_INPUT:-$USER} # Se vazio, usa o usuário atual

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
COMMENT_LINE="# Key for: $KEY_OWNER_NAME"

echo "A chave será adicionada para o usuário: $TARGET_USER"
echo "Comentário a ser adicionado: $COMMENT_LINE"
echo "Caminho do arquivo authorized_keys: $AUTH_KEYS_FILE"

# ============================================================================
# ETAPA 3: Preparar diretório .ssh e arquivo authorized_keys
# ============================================================================
# Lidar com permissões e ownership cuidadosamente
if [ "$TARGET_USER" != "$USER" ]; then
    # Se o usuário alvo for diferente, provavelmente precisamos de sudo
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "Para adicionar chaves para outro usuário ('$TARGET_USER'), você precisa executar o script com 'sudo'."
    fi
    
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
else
    # Se o usuário alvo for o usuário atual, não é necessário sudo para a configuração inicial
    if [ ! -d "$SSH_DIR" ]; then
        echo "Criando diretório $SSH_DIR..."
        mkdir -p "$SSH_DIR" || error_exit "Falha ao criar diretório $SSH_DIR."
        chmod 0700 "$SSH_DIR" || error_exit "Falha ao definir permissões para $SSH_DIR."
    fi
    if [ ! -f "$AUTH_KEYS_FILE" ]; then
        echo "Criando arquivo $AUTH_KEYS_FILE..."
        touch "$AUTH_KEYS_FILE" || error_exit "Falha ao criar arquivo $AUTH_KEYS_FILE."
        chmod 0600 "$AUTH_KEYS_FILE" || error_exit "Falha ao definir permissões para $AUTH_KEYS_FILE."
    fi
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
    KEY_PREVIEW=$(echo "$KEY_CONTENT" | head -n 1 | cut -c 1-70)...$(echo "$KEY_CONTENT" | tail -n 1 | cut -c $(( $(echo "$KEY_CONTENT" | tail -n 1 | wc -c) - 50 ))- )
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
if [ "$TARGET_USER" != "$USER" ]; then
    # Usar sudo para ler o arquivo se o usuário alvo for diferente
    if sudo grep -qF "$KEY_CONTENT" "$AUTH_KEYS_FILE"; then
        echo "Aviso: A chave pública fornecida já existe no arquivo $AUTH_KEYS_FILE. Nenhuma alteração foi feita."
        exit 0
    fi
else
    if grep -qF "$KEY_CONTENT" "$AUTH_KEYS_FILE"; then
        echo "Aviso: A chave pública fornecida já existe no arquivo $AUTH_KEYS_FILE. Nenhuma alteração foi feita."
        exit 0
    fi
fi

# ============================================================================
# ETAPA 6: Adicionar comentário e chave ao authorized_keys
# ============================================================================
echo "Adicionando o comentário e a chave pública ao arquivo $AUTH_KEYS_FILE..."

# Prepara o conteúdo completo (comentário + chave) para ser escrito
CONTENT_TO_WRITE="$COMMENT_LINE"$'\n'"$KEY_CONTENT"

if [ "$TARGET_USER" != "$USER" ]; then
    # Usar sudo para anexar o conteúdo e, em seguida, reaplicar propriedade/permissões
    echo "$CONTENT_TO_WRITE" | sudo tee -a "$AUTH_KEYS_FILE" > /dev/null || error_exit "Falha ao adicionar a chave pública."
    sudo chown "$TARGET_USER:$TARGET_USER" "$AUTH_KEYS_FILE" || error_exit "Falha ao definir proprietário para $AUTH_KEYS_FILE após adição."
    sudo chmod 0600 "$AUTH_KEYS_FILE" || error_exit "Falha ao definir permissões para $AUTH_KEYS_FILE após adição."
else
    # Anexar diretamente se for o usuário atual
    echo "$CONTENT_TO_WRITE" >> "$AUTH_KEYS_FILE" || error_exit "Falha ao adicionar a chave pública."
fi

echo "Chave pública adicionada com sucesso para o usuário '$TARGET_USER'!"
echo ""
echo "--- Próximo Passo: Testar o Acesso SSH ---"
echo "Por favor, abra uma nova sessão de terminal e tente acessar o servidor via SSH usando a chave que você acabou de adicionar."
echo "Exemplo: ssh $TARGET_USER@seu_servidor_ip"
read -p "Pressione Enter após testar o acesso SSH para finalizar o script."

echo "Script concluído. Verifique se o acesso SSH está funcionando corretamente."
