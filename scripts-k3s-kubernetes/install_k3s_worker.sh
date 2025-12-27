#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: install_k3s_worker.sh
#
# Descrição:
#  Este script automatiza a instalação e configuração de um nó worker do K3s.
#  Ele prepara o sistema operacional, configura a resolução de nomes e junta o
#  nó a um cluster K3s existente usando um token de acesso.
#
#  Funcionalidades:
#  - Prepara o sistema operacional (Debian/Ubuntu) desabilitando swap e
#    configurando módulos do kernel.
#  - Configura o arquivo /etc/hosts para resolução de nomes no cluster.
#  - Instala o K3s como um nó worker, conectando-o ao master especificado.
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
#  - Sistema operacional baseado em Debian (Ubuntu 22.04 LTS recomendado).
#  - Acesso root ou um usuário com privilégios sudo.
#  - Conectividade de rede com o nó master do K3s.
#  - IP estático para o nó worker.
#  - Token de acesso do cluster K3s (gerado no nó master).
#
# Como usar:
#  1. Certifique-se de que os pré-requisitos foram atendidos.
#  2. Dê permissão de execução ao script:
#     chmod +x install_k3s_worker.sh
#  3. Execute o script no nó que será o worker:
#     sudo ./install_k3s_worker.sh
#  4. Siga as instruções, fornecendo o IP do master, o IP deste worker e o
#     token do cluster.
#
# -----------------------------------------------------------------------------

# --- Constantes ---
CONFIG_FILE="k3s_cluster_vars.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONFIG_FILE_PATH="$SCRIPT_DIR/$CONFIG_FILE"

# --- Variáveis de Configuração ---
K3S_CONTROL_PLANE_1_IP=""
K3S_TOKEN=""
NFS_SERVER_IP=""
NFS_SHARE_PATH=""

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
    local is_password="$4"

    if [ -n "$default_value" ]; then
        prompt_message="$prompt_message (Padrão: $default_value)"
    fi

    while true; do
        if [ "$is_password" == "true" ]; then
            read -s -p "$prompt_message: " input_value
            echo # Nova linha após a senha
        else
            read -p "$prompt_message: " input_value
        fi

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

# Função para coletar informações manualmente se o arquivo de configuração não existir
function gather_info() {
    echo "Por favor, forneça as informações solicitadas."
    get_user_input "Digite o IP do k3s-control-plane-1 (endpoint do cluster)" "192.168.10.20" "K3S_CONTROL_PLANE_1_IP"
    get_user_input "Digite o token do K3s obtido do k3s-control-plane-1" "" "K3S_TOKEN"
    get_user_input "Digite o IP do servidor NFS (k3s-storage-nfs)" "192.168.10.24" "NFS_SERVER_IP"
    get_user_input "Digite o caminho do compartilhamento NFS no servidor" "/mnt/k3s-share-nfs/" "NFS_SHARE_PATH"
}

# Função para confirmar as informações
function confirm_info {
    echo -e "\n\e[34m--- Por favor, revise as informações fornecidas ---\e[0m"
    echo "Endpoint do Cluster (Control Plane 1): $K3S_CONTROL_PLANE_1_IP"
    echo "Token do Cluster: $(if [ -n "$K3S_TOKEN" ]; then echo "(definido)"; else echo "(não definido)"; fi)"
    echo "IP do Servidor NFS: $NFS_SERVER_IP"
    echo "Caminho do Compartilhamento NFS: $NFS_SHARE_PATH"
    echo "IP deste Nó Worker: $CURRENT_NODE_IP"
    echo -e "\e[34m---------------------------------------------------\e[0m"

    while true; do
        read -p "As informações acima estão corretas e deseja prosseguir com a instalação? (s/n): " confirm
        case $confirm in
            [Ss]* ) break;;
            [Nn]* ) error_exit "Instalação cancelada. Por favor, ajuste as configurações e tente novamente.";;
            * ) echo "Por favor, responda 's' ou 'n'.";;
        esac
    done
}

# --- Início do Script ---

echo "--- Instalação do K3s Worker Node ---"
echo "Este script irá configurar um nó K3s Worker."

# Tenta carregar o arquivo de configuração
if [ -f "$CONFIG_FILE_PATH" ]; then
    echo -e "\e[32mArquivo de configuração encontrado: $CONFIG_FILE\e[0m"
    echo "Carregando variáveis..."
    source "$CONFIG_FILE_PATH"
    
    # Validação básica
    if [ -z "$K3S_CONTROL_PLANE_1_IP" ] || [ -z "$K3S_TOKEN" ]; then
        echo -e "\e[33mAviso: Variáveis essenciais (K3S_CONTROL_PLANE_1_IP ou K3S_TOKEN) estão vazias no arquivo de configuração.\e[0m"
        gather_info
    fi
else
    echo -e "\e[33mArquivo de configuração não encontrado. Iniciando coleta manual.\e[0m"
    gather_info
fi

CURRENT_NODE_IP=$(hostname -I | awk '{print $1}')

# Confirmação antes de prosseguir
confirm_info

echo " "
echo -e "\n\e[34m--- 1. Preparação do Sistema Operacional ---\e[0m"
echo "Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y
check_command "Falha ao atualizar pacotes."
sudo apt autoremove -y

echo "Desabilitando swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
check_command "Falha ao desabilitar swap."

echo "Configurando módulos do kernel e sysctl..."
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
check_command "Falha ao configurar módulos do kernel/sysctl."

echo "Configurando /etc/hosts..."
# Remover entradas antigas para evitar duplicatas
sudo sed -i '/k3s-control-plane-1/d' /etc/hosts
sudo sed -i '/k3s-control-plane-2/d' /etc/hosts
sudo sed -i '/k3s-worker-1/d' /etc/hosts
sudo sed -i '/k3s-worker-2/d' /etc/hosts
sudo sed -i '/k3s-storage-nfs/d' /etc/hosts

sudo tee -a /etc/hosts <<EOF > /dev/null
$K3S_CONTROL_PLANE_1_IP k3s-control-plane-1
${K3S_CONTROL_PLANE_2_IP:+${K3S_CONTROL_PLANE_2_IP} k3s-control-plane-2}
${K3S_WORKER_1_IP:+${K3S_WORKER_1_IP} k3s-worker-1}
${K3S_WORKER_2_IP:+${K3S_WORKER_2_IP} k3s-worker-2}
$CURRENT_NODE_IP $(hostname)
$NFS_SERVER_IP k3s-storage-nfs
EOF
check_command "Falha ao configurar /etc/hosts."

echo "Desabilitando UFW..."
sudo ufw disable > /dev/null 2>&1
sudo systemctl stop ufw > /dev/null 2>&1
sudo systemctl disable ufw > /dev/null 2>&1
echo "UFW desabilitado (se estava ativo)."

echo -e "\e[34m--- 2. Instalação do K3s Worker ---\e[0m"
if [ -z "$K3S_TOKEN" ]; then
    error_exit "O token do K3s não foi fornecido. Por favor, obtenha o token do k3s-control-plane-1."
fi

echo " "
echo -e "\n\e[34mInstalando K3s como Worker...\e[0m"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://$K3S_CONTROL_PLANE_1_IP:6443 --token $K3S_TOKEN --node-ip $CURRENT_NODE_IP" sh -
check_command "Falha ao instalar K3s Worker."

echo " "
echo -e "\n\e[34m--- Instalação do K3s Worker concluída ---\e[0m"
echo "Este nó worker foi adicionado ao cluster K3s."
echo "Verifique o status do cluster usando 'kubectl get nodes' na sua máquina de administração."
