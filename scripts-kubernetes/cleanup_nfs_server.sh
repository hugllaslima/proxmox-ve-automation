#!/bin/bash

# -----------------------------------------------------------------------------
#
# Script: cleanup_nfs_server.sh
#
# Descrição:
#  Este script automatiza a remoção e limpeza completa de um servidor NFS
#  (Network File System) que foi instalado pelo script "install_nfs_server.sh".
#  Ele reverte todas as configurações, desinstala os pacotes e remove os
#  diretórios criados.
#
#  Funcionalidades:
#  - Para e desabilita o serviço do servidor NFS.
#  - Remove a entrada de compartilhamento do arquivo /etc/exports.
#  - Remove o diretório de compartilhamento criado.
#  - Desinstala os pacotes do servidor NFS e suas dependências não utilizadas.
#
# Autor:
#  Hugllas Lima <hugllas.l@gmail.com>
#  GitHub: https://github.com/hugllas
#  LinkedIn: https://www.linkedin.com/in/hugllas-lima/
#
# Versão:
#  v1.0.0 - 2024-07-29 - Versão inicial do script.
#
# Pré-requisitos:
#  - Acesso root ou um usuário com privilégios sudo.
#
# Como usar:
#  1. Dê permissão de execução ao script:
#     chmod +x cleanup_nfs_server.sh
#  2. Execute o script:
#     sudo ./cleanup_nfs_server.sh
#  3. O script solicitará o caminho do diretório compartilhado para garantir
#     que a limpeza seja feita no local correto.
#
# -----------------------------------------------------------------------------

# --- Variáveis de Configuração ---
NFS_SHARE_PATH="/mnt/k3s-share-nfs/"

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

    if [ -n "$default_value" ]; then
        prompt_message="$prompt_message (Padrão: $default_value)"
    fi

    while true; do
        read -p "$prompt_message: " input_value
        if [ -z "$input_value" ] && [ -n "$default_value" ]; then
            eval "$var_name=\"$default_value\""
            break
        elif [ -n "$input_value" ]; then
            eval "$var_name=\"$input_value\""
            break
        else
            echo "Entrada não pode ser vazia. Por favor, tente novamente."
        fi
    done
}

# --- Início do Script ---
echo " "
echo "--- Limpeza do Servidor NFS ---"
echo " "
echo "Este script irá remover as configurações do servidor NFS."
echo "ATENÇÃO: Esta ação é destrutiva e removerá o compartilhamento e os pacotes."

# Coletar o caminho do compartilhamento para garantir a remoção correta
    get_user_input "Digite o caminho do diretório de compartilhamento NFS que será removido" "$NFS_SHARE_PATH" "NFS_SHARE_PATH"

echo "--- 1. Parando e desabilitando o serviço NFS ---"
echo " "
    sudo systemctl stop nfs-kernel-server
    check_command "Falha ao parar o serviço nfs-kernel-server."
    sudo systemctl disable nfs-kernel-server
    check_command "Falha ao desabilitar o serviço nfs-kernel-server."
    echo "Serviço NFS parado e desabilitado."

echo " "
echo "--- 2. Removendo a configuração do /etc/exports ---"
echo " "
    if [ -f /etc/exports ]; then
        sudo sed -i "\#$NFS_SHARE_PATH#d" /etc/exports
        echo "Entrada para $NFS_SHARE_PATH removida do /etc/exports."
    else
        echo "/etc/exports não encontrado. Pulando esta etapa."
    fi

# Atualizar a tabela de exportação
echo " "
    sudo exportfs -ra
    check_command "Falha ao re-exportar os compartilhamentos."
echo "Tabela de exportação NFS atualizada."

echo " "
echo "--- 3. Removendo o diretório de compartilhamento ---"
echo " "
    if [ -d "$NFS_SHARE_PATH" ]; then
        sudo rm -rf "$NFS_SHARE_PATH"
        check_command "Falha ao remover o diretório $NFS_SHARE_PATH."
        echo "Diretório $NFS_SHARE_PATH removido."
    else
        echo "Diretório $NFS_SHARE_PATH não encontrado. Pulando esta etapa."
    fi

echo " "
echo "--- 4. Desinstalando os pacotes do servidor NFS ---"
echo " "    
sudo apt-get purge -y nfs-kernel-server
check_command "Falha ao desinstalar o nfs-kernel-server."
sudo apt-get autoremove -y --purge
check_command "Falha ao remover pacotes extras."
echo " "
echo "Pacotes do servidor NFS removidos."
echo "--- Limpeza do Servidor NFS concluída com sucesso! ---"
echo " "
