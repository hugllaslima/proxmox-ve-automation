#!/bin/bash

#==============================================================================
# Script: add_key_ssh_public.sh
# Descrição: Adiciona uma chave pública SSH ao authorized_keys de um usuário
#            com validação, confirmação interativa e comentário identificando
#            o proprietário.
# Autor: Hugllas Lima (com contribuições de Claude)
# Data: $(date +%Y-%m-%d)
# Versão: 1.6 (Ajuste na lógica de NOPASSWD para TARGET_USER, incluindo adição ao grupo sudo,
#            e ajuste no hardening SSH para comentar 'PasswordAuthentication yes' em sshd_config.d/*.conf)
# Licença: MIT
# Repositório: https://github.com/hugllashml/proxmox-ve-automation
#==============================================================================
#
# ETAPAS DO SCRIPT:
# 1. Selecionar e confirmar usuário alvo
# 2. Informar o proprietário da chave (comentário)
# 3. Preparar diretório .ssh e authorized_keys (permissões e ownership)
# 4. Colar e validar chave pública
# 5. Verificar duplicidade da chave
# 6. Adicionar comentário e chave ao authorized_keys
# 7. Ajustar configurações SSH (hardening) - AGORA INCLUI sshd_config.d/
# 8. Configurar sudo NOPASSWD para o usuário alvo (opcional e condicional, com teste e dicas)
# 9. Pausar para validação de acesso SSH
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
# ATENÇÃO:
# - A desativação do login por senha pode bloquear o acesso se a chave SSH
#   não estiver configurada corretamente. Certifique-se de ter um método
#   alternativo de acesso (ex: console físico/virtual) ou teste
#   cuidadosamente.
# - A configuração de 'NOPASSWD' para 'sudo' (se ativada) permite que o usuário
#   alvo execute qualquer comando como root sem senha, o que reduz
#   significativamente a segurança do sistema. Use com extrema cautela.

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
# ETAPA 5: Verificar duplicidade da chave
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
    SSHD_CONFIG_D_DIR="/etc/ssh/sshd_config.d"

    # Fazer backup do sshd_config original
    echo "Fazendo backup de $SSHD_CONFIG_FILE para ${SSHD_CONFIG_FILE}.bak_$(date +%Y%m%d%H%M%S)..."
    sudo cp "$SSHD_CONFIG_FILE" "${SSHD_CONFIG_FILE}.bak_$(date +%Y%m%d%H%M%S)" || error_exit "Falha ao fazer backup do sshd_config."

    # Função para aplicar as alterações em um arquivo de configuração
    apply_hardening_to_file() {
        local config_file="$1"
        local is_main_sshd_config=false
        if [[ "$config_file" == "$SSHD_CONFIG_FILE" ]]; then
            is_main_sshd_config=true
        fi

        echo "Aplicando hardening em: $config_file"

        # 1. PubkeyAuthentication yes (para sshd_config principal)
        if $is_main_sshd_config; then
            # Garante que a linha existe e está descomentada com 'yes'
            sudo sed -i 's/^#\?PubkeyAuthentication \(no\|yes\)/PubkeyAuthentication yes/' "$config_file"
            if ! sudo grep -qE '^PubkeyAuthentication yes' "$config_file"; then
                echo "PubkeyAuthentication yes" | sudo tee -a "$config_file" > /dev/null
            fi
        fi

        # 2. AuthorizedKeysFile .ssh/authorized_keys (para sshd_config principal)
        if $is_main_sshd_config; then
            # Remove linhas existentes para evitar duplicatas ou conflitos
            sudo sed -i '/^AuthorizedKeysFile/d' "$config_file"
            # Adiciona a linha desejada
            echo "AuthorizedKeysFile .ssh/authorized_keys" | sudo tee -a "$config_file" > /dev/null
        fi

        # 3. PasswordAuthentication
        if $is_main_sshd_config; then
            # Para sshd_config principal, define como 'no'
            sudo sed -i 's/^#\?PasswordAuthentication \(yes\|no\)/PasswordAuthentication no/' "$config_file"
            if ! sudo grep -qE '^PasswordAuthentication no' "$config_file"; then
                echo "PasswordAuthentication no" | sudo tee -a "$config_file" > /dev/null
            fi
        else
            # Para arquivos em sshd_config.d/, comenta 'PasswordAuthentication yes'
            # Isso garante que qualquer 'yes' nesses arquivos seja ignorado.
            sudo sed -i 's/^\(PasswordAuthentication yes\)/#\1/' "$config_file"
        fi

        # 4. KbdInteractiveAuthentication no (para sshd_config principal)
        if $is_main_sshd_config; then
            sudo sed -i 's/^#\?KbdInteractiveAuthentication \(yes\|no\)/KbdInteractiveAuthentication no/' "$config_file"
            if ! sudo grep -qE '^KbdInteractiveAuthentication no' "$config_file"; then
                echo "KbdInteractiveAuthentication no" | sudo tee -a "$config_file" > /dev/null
            fi
        fi

        # 5. ChallengeResponseAuthentication no (para ambos, boa prática)
        sudo sed -i 's/^#\?ChallengeResponseAuthentication \(yes\|no\)/ChallengeResponseAuthentication no/' "$config_file"
        if ! sudo grep -qE '^ChallengeResponseAuthentication no' "$config_file"; then
            echo "ChallengeResponseAuthentication no" | sudo tee -a "$config_file" > /dev/null
        fi

        # 6. PermitRootLogin prohibit-password (para ambos, boa prática)
        # Primeiro, remove qualquer linha PermitRootLogin existente que não seja comentada
        sudo sed -i '/^PermitRootLogin/d' "$config_file"
        # Em seguida, adiciona a linha desejada
        echo "PermitRootLogin prohibit-password" | sudo tee -a "$config_file" > /dev/null
    }

    # Aplicar hardening ao arquivo principal sshd_config
    apply_hardening_to_file "$SSHD_CONFIG_FILE"

    # Aplicar hardening a arquivos em sshd_config.d/
    if [ -d "$SSHD_CONFIG_D_DIR" ]; then
        echo "Verificando arquivos em $SSHD_CONFIG_D_DIR/..."
        for conf_file in "$SSHD_CONFIG_D_DIR"/*.conf; do
            if [ -f "$conf_file" ]; then
                # Fazer backup de cada arquivo .conf antes de modificar
                echo "Fazendo backup de $conf_file para ${conf_file}.bak_$(date +%Y%m%d%H%M%S)..."
                sudo cp "$conf_file" "${conf_file}.bak_$(date +%Y%m%d%H%M%S)" || echo "Aviso: Falha ao fazer backup de $conf_file."
                apply_hardening_to_file "$conf_file"
            fi
        done
    else
        echo "Diretório $SSHD_CONFIG_D_DIR/ não encontrado. Nenhuma configuração adicional será verificada."
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

# ============================================================================
# ETAPA 8: Configurar sudo NOPASSWD para o usuário alvo (opcional e condicional)
# ============================================================================
echo ""
echo "--- Configuração de Sudo NOPASSWD para o usuário '$TARGET_USER' ---"

# Verifica se o usuário alvo existe
if ! id "$TARGET_USER" &>/dev/null; then
    echo "Aviso: O usuário '$TARGET_USER' não existe neste sistema. Nenhuma alteração será feita para 'NOPASSWD'."
else
    # Verifica se o usuário já está no grupo sudo
    if ! id -nG "$TARGET_USER" | grep -qw "sudo"; then
        read -p "O usuário '$TARGET_USER' não está no grupo 'sudo'. Deseja adicioná-lo ao grupo 'sudo' agora? (s/N): " CONFIRM_ADD_TO_SUDO_GROUP
        if [[ "$CONFIRM_ADD_TO_SUDO_GROUP" =~ ^[Ss]$ ]]; then
            echo "Adicionando '$TARGET_USER' ao grupo 'sudo'..."
            sudo usermod -aG sudo "$TARGET_USER" || error_exit "Falha ao adicionar '$TARGET_USER' ao grupo 'sudo'."
            echo "'$TARGET_USER' adicionado ao grupo 'sudo' com sucesso."
        else
            echo "Usuário '$TARGET_USER' não adicionado ao grupo 'sudo'. A configuração 'NOPASSWD' pode não funcionar."
        fi
    else
        echo "O usuário '$TARGET_USER' já está no grupo 'sudo'."
    fi

    # Verifica se a configuração NOPASSWD já existe para o usuário alvo
    # Usamos `sudo -l -U $TARGET_USER` para listar as permissões sudo do usuário
    # e verificamos se a string "NOPASSWD: ALL" está presente.
    if sudo -l -U "$TARGET_USER" 2>/dev/null | grep -qE 'NOPASSWD: ALL'; then
        echo "A configuração 'NOPASSWD' para o usuário '$TARGET_USER' já está ativa. Nenhuma alteração é necessária."
    else
        # Se não estiver configurado, perguntamos ao usuário
        read -p "Deseja configurar o usuário '$TARGET_USER' para usar 'sudo' sem senha? (s/N): " CONFIRM_TARGET_USER_NOPASSWD

        if [[ "$CONFIRM_TARGET_USER_NOPASSWD" =~ ^[Ss]$ ]]; then
            SUDOERS_FILE="/etc/sudoers.d/90-${TARGET_USER}-nopasswd"
            TEMP_SUDOERS_FILE=$(mktemp)

            # Conteúdo do arquivo sudoers.d
            echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > "$TEMP_SUDOERS_FILE"

            echo "Validando a sintaxe do arquivo sudoers temporário..."
            # visudo -cf testa a sintaxe do arquivo sem instalá-lo
            if sudo visudo -cf "$TEMP_SUDOERS_FILE"; then
                echo "Sintaxe validada com sucesso."
                echo "Movendo arquivo para $SUDOERS_FILE..."
                sudo mv "$TEMP_SUDOERS_FILE" "$SUDOERS_FILE" || error_exit "Falha ao mover o arquivo sudoers."
                sudo chmod 0440 "$SUDOERS_FILE" || error_exit "Falha ao definir permissões para o arquivo sudoers."
                echo "Configuração 'NOPASSWD' para '$TARGET_USER' adicionada com sucesso."
                echo "AVISO DE SEGURANÇA: O usuário '$TARGET_USER' agora pode executar qualquer comando com 'sudo' sem senha."
                echo "Isso é conveniente para automação, mas reduz a segurança do sistema."

                # Teste imediato da configuração NOPASSWD
                echo "Testando a configuração 'NOPASSWD' para o usuário '$TARGET_USER'..."
                # Invalida o cache do sudo para o usuário alvo antes de testar
                sudo -u "$TARGET_USER" sudo -k &>/dev/null
                if sudo -u "$TARGET_USER" sudo -n true &>/dev/null; then
                    echo "Teste bem-sucedido: O usuário '$TARGET_USER' pode usar 'sudo' sem senha."
                else
                    echo "AVISO: O teste de 'NOPASSWD' para '$TARGET_USER' falhou. O usuário '$TARGET_USER' ainda pode estar pedindo senha para 'sudo'."
                    echo "Isso pode ocorrer devido ao cache de credenciais do 'sudo' ou outras configurações."
                    echo "Tente o seguinte:"
                    echo "  1. Abra uma NOVA sessão de terminal para o usuário '$TARGET_USER'."
                    echo "  2. Na nova sessão, execute 'sudo -k' para limpar o cache de credenciais do sudo."
                    echo "  3. Tente usar 'sudo' novamente (ex: 'sudo ls /root')."
                    echo "  4. Um REINÍCIO DO SERVIDOR GERALMENTE NÃO É NECESSÁRIO para que as mudanças no sudoers.d entrem em vigor."
                fi
            else
                sudo rm "$TEMP_SUDOERS_FILE" # Limpa o arquivo temporário em caso de erro
                error_exit "Falha na validação da sintaxe do arquivo sudoers. Nenhuma alteração foi feita."
            fi
        else
            echo "Configuração 'NOPASSWD' para '$TARGET_USER' não aplicada."
        fi
    fi
fi

# ============================================================================
# ETAPA 9: Pausar para validação de acesso SSH
# ============================================================================
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
echo "Exemplo: ssh $TARGET_USER@<IP_DO_SEU_SERVIDORT>"
read -p "Pressione Enter APÓS validar o acesso SSH para finalizar o script."

echo ""
echo "Script concluído. Verifique se o acesso SSH e o sudo para '$TARGET_USER' estão funcionando corretamente."
