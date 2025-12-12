#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: install_nfs_server.sh
#
# Descrição:
#  Este script automatiza a instalação e configuração de um servidor NFS
#  (Network File System) em um sistema baseado em Debian (como Ubuntu). O NFS
#  é usado para compartilhar diretórios através de uma rede e é comumente
#  utilizado em clusters Kubernetes para provisionamento de armazenamento
#  dinâmico (Persistent Volumes).
#
#  Funcionalidades:
#  - Instala os pacotes necessários para o servidor NFS.
#  - Cria um diretório de compartilhamento padrão (/mnt/k3s-share-nfs/).
#  - Configura as permissões do diretório de compartilhamento.
#  - Adiciona uma entrada ao arquivo /etc/exports para permitir o acesso de
#    qualquer cliente na rede (*).
#  - Reinicia o serviço do servidor NFS para aplicar as alterações.
#
# Autor:
#  Hugllas R. S. Lima
#
# Contato:
#  - GitHub: https://github.com/hugllaslima
#  - LinkedIn: https://www.linkedin.com/in/hugllas-lima/
#
# Versão:
#  1.0
#
# Data:
#  24/07/2024
#
# Pré-requisitos:
#  - Sistema operacional baseado em Debian (Ubuntu 22.04 ou 24.04 LTS recomendado).
#  - Acesso root ou um usuário com privilégios sudo.
#  - Conectividade de rede.
#
# Como usar:
#  1. Certifique-se de que os pré-requisitos foram atendidos.
#  2. Dê permissão de execução ao script:
#     chmod +x install_nfs_server.sh
#  3. Execute o script:
#     sudo ./install_nfs_server.sh
#  4. O script executará todas as etapas automaticamente.
#
# -----------------------------------------------------------------------------

# As variáveis de configuração serão solicitadas durante a execução do script.

# --- Funções Auxiliares ---

# Função para exibir mensagens de erro e sair
function error_exit {
    echo "ERRO: $1" >&2
    exit 1
}

# Função para verificar se um comando foi bem-sucedido
function check_command {
    if [ $? -ne 0 ]; then
        error_exit "$1"
    fi
}

# Função para coletar entrada do usuário
function get_user_input {
    local prompt_message="$1"
    local default_value="$2"
    local var_name="$3"
    local is_path_check="$4" # Novo parâmetro para indicar verificação de caminho

    if [ -n "$default_value" ]; then
        prompt_message="$prompt_message (Padrão: $default_value)"
    fi

    while true; do
        read -p "$prompt_message: " input_value
        local final_value=""

        if [ -z "$input_value" ] && [ -n "$default_value" ]; then
            final_value="$default_value"
        elif [ -n "$input_value" ]; then
            final_value="$input_value"
        else
            echo "Entrada não pode ser vazia. Por favor, tente novamente."
            continue
        fi

        # Se for uma verificação de caminho, valide o prefixo
        if [ "$is_path_check" = "true" ]; then
            if [[ "$final_value" != /mnt/* ]]; then
                echo "ERRO: O caminho do compartilhamento deve estar dentro de /mnt/ (ex: /mnt/meu-share)."
                continue # Volta ao início do loop
            fi
        fi

        eval "$var_name=\"$final_value\""
        break
    done
}

# --- Início do Script ---

echo "--- Configuração do Servidor NFS ---"
echo " "
echo "Este script irá configurar o servidor NFS."
echo " "
echo "Por favor, forneça as informações solicitadas."

# Coletar informações do usuário
    get_user_input "Digite o caminho do diretório de compartilhamento NFS" "/mnt/k3s-share-nfs/" "NFS_SHARE_PATH" "true"
    get_user_input "Digite a rede que terá permissão para acessar o NFS (ex: 10.10.0.0/22)" "10.10.0.0/22" "NFS_ALLOWED_NETWORK"

echo " "
echo "--- 1. Preparação do Sistema Operacional ---"
echo " "
echo "Verificando se o sistema operacional é baseado em Debian..."
    if ! grep -iq "Debian" /etc/os-release; then
        error_exit "Este script é projetado para sistemas operacionais baseados em Debian (como Ubuntu)."
    fi

echo " "
echo "Atualizando pacotes..."
echo " "
    sudo apt update && sudo apt upgrade -y
    check_command "Falha ao atualizar pacotes."
    sudo apt autoremove -y

echo " "
echo "--- 2. Instalação do Servidor NFS ---"
echo " "
    sudo apt install -y nfs-kernel-server
    check_command "Falha ao instalar nfs-kernel-server."

echo " "
echo "--- 3. Criando e configurando o diretório de compartilhamento ---"
echo " "
    sudo mkdir -p "$NFS_SHARE_PATH"
    check_command "Falha ao criar o diretório $NFS_SHARE_PATH."
    sudo chown nobody:nogroup "$NFS_SHARE_PATH"
    sudo chmod 777 "$NFS_SHARE_PATH"
    echo "Diretório $NFS_SHARE_PATH criado e permissões configuradas."

echo " "
echo "--- 4. Configurando o arquivo /etc/exports ---"
echo " "
    sudo sed -i "\%$NFS_SHARE_PATH%d" /etc/exports

echo "$NFS_SHARE_PATH $NFS_ALLOWED_NETWORK(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports > /dev/null
    check_command "Falha ao configurar /etc/exports."
echo "Entrada adicionada ao /etc/exports."

echo " "
echo "--- 5. Exportando compartilhamentos e reiniciando o serviço NFS ---"
echo " "
    sudo exportfs -a
    check_command "Falha ao exportar compartilhamentos NFS."
    sudo systemctl restart nfs-kernel-server
    check_command "Falha ao reiniciar o serviço nfs-kernel-server."
    sudo systemctl enable nfs-kernel-server
    check_command "Falha ao habilitar o serviço nfs-kernel-server."
    echo "Serviço NFS configurado e iniciado."

echo " "
echo "--- 6. Verificando o compartilhamento NFS ---"
echo " "
    showmount -e localhost
    check_command "Falha ao verificar o compartilhamento NFS."
echo "Servidor NFS configurado com sucesso!"
