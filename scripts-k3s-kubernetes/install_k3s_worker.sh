#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: install_k3s_worker.sh
#
# Descrição:
#  Este script automatiza a instalação e configuração de um nó worker do K3s.
#  Ele prepara o sistema operacional, configura a resolução de nomes, ajusta
#  o firewall (UFW) e junta o nó a um cluster K3s existente.
#
# Funcionalidades:
#  - Prepara o sistema operacional (Update, Swap, Sysctl).
#  - Configura /etc/hosts e resolução de nomes.
#  - Gerencia automaticamente firewall (UFW) para permitir comunicação do cluster.
#  - Instala o K3s como um nó worker, conectando-o ao master especificado.
#
# Contato:
#  - https://www.linkedin.com/in/hugllas-r-s-lima/
#  - https://github.com/hugllaslima/proxmox-ve-automation/tree/main/scripts-k3s-kubernetes
#
# Versão:
#  2.0
#
# Data:
#  28/12/2025
#
# Pré-requisitos:
#  - Ubuntu 22.04/24.04 LTS.
#  - Acesso root/sudo.
#  - Conectividade de rede com o nó master do K3s.
#  - IP estático para o nó worker.
#  - Token de acesso do cluster K3s (gerado no nó master).
#
# Como usar:
#  1. Copie o arquivo 'k3s_cluster_vars.sh' do master para o diretório deste script.
#  2. chmod +x install_k3s_worker.sh
#  3. sudo ./install_k3s_worker.sh
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
ADMIN_NETWORK_CIDRS=""

# --- Funções Auxiliares ---

function error_exit { echo -e "\n\e[31mERRO: $1\e[0m" >&2; exit 1; }
function success_message { echo -e "\e[32mSUCESSO: $1\e[0m"; }
function warning_message { echo -e "\e[33mAviso: $1\e[0m"; }
function check_command { if [ $? -ne 0 ]; then error_exit "$1"; fi; }

# Função para confirmar as informações
function confirm_info {
    echo -e "\n\e[34m--- Por favor, revise as informações fornecidas ---\e[0m"
    echo "Endpoints do Cluster (HA):"
    echo "  - CP1: $K3S_CONTROL_PLANE_1_IP"
    echo "  - CP2: ${K3S_CONTROL_PLANE_2_IP:-N/A}"
    echo "  - CP3: ${K3S_CONTROL_PLANE_3_IP:-N/A}"
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
        error_exit "Variáveis essenciais (K3S_CONTROL_PLANE_1_IP ou K3S_TOKEN) estão vazias no arquivo de configuração."
    fi
    success_message "Variáveis de ambiente carregadas."
else
    error_exit "Arquivo de configuração '$CONFIG_FILE' não encontrado. Por favor, copie este arquivo do k3s-control-plane-1 para este diretório antes de executar o script."
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
success_message "Pacotes atualizados."

echo "Desabilitando swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
check_command "Falha ao desabilitar swap."
success_message "Swap desabilitado."

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
success_message "Módulos do kernel e sysctl configurados."

echo "Configurando /etc/hosts..."
# Remover entradas antigas para evitar duplicatas
sudo sed -i '/k3s-control-plane-1/d' /etc/hosts
sudo sed -i '/k3s-control-plane-2/d' /etc/hosts
sudo sed -i '/k3s-control-plane-3/d' /etc/hosts
sudo sed -i '/k3s-worker-1/d' /etc/hosts
sudo sed -i '/k3s-worker-2/d' /etc/hosts
sudo sed -i '/k3s-storage-nfs/d' /etc/hosts

sudo tee -a /etc/hosts <<EOF > /dev/null
$K3S_CONTROL_PLANE_1_IP k3s-control-plane-1
${K3S_CONTROL_PLANE_2_IP:+${K3S_CONTROL_PLANE_2_IP} k3s-control-plane-2}
${K3S_CONTROL_PLANE_3_IP:+${K3S_CONTROL_PLANE_3_IP} k3s-control-plane-3}
${K3S_WORKER_1_IP:+${K3S_WORKER_1_IP} k3s-worker-1}
${K3S_WORKER_2_IP:+${K3S_WORKER_2_IP} k3s-worker-2}
$CURRENT_NODE_IP $(hostname)
$NFS_SERVER_IP k3s-storage-nfs
EOF
check_command "Falha ao configurar /etc/hosts."
success_message "/etc/hosts configurado."

echo "Desabilitando UFW..."
sudo ufw disable > /dev/null 2>&1
echo "Reconfigurando Firewall (UFW) para Worker..."
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

# Regras básicas
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 10250/tcp comment 'Kubelet'
sudo ufw allow 8472/udp comment 'Flannel VXLAN'

# Redes de Administração
if [ -n "$ADMIN_NETWORK_CIDRS" ]; then
    for cidr in $ADMIN_NETWORK_CIDRS; do
        sudo ufw allow from $cidr to any port 22 comment 'SSH Admin'
    done
fi

sudo ufw --force enable
success_message "Firewall configurado para K3s Worker."

echo " "
echo -e "\e[34m--- 2. Instalação do K3s Worker ---\e[0m"
if [ -z "$K3S_TOKEN" ]; then
    error_exit "O token do K3s não foi fornecido. Por favor, obtenha o token do k3s-control-plane-1."
fi

# Constrói a string de servidores para HA (Failover)
# O K3s Agent suporta --server para o endpoint principal.
# Em teoria, o K3s agent se conecta a um nó e recebe a lista de todos os endpoints.
# No entanto, é boa prática apontar para o IP principal ou usar um Load Balancer se houvesse.
# Como estamos usando DNS/Hosts, vamos garantir que ele aponte para o CP1 inicialmente.
# Se quiser redundância na inicialização, o ideal seria um VIP ou Load Balancer.
# Mas para este setup, apontar para o CP1 é o padrão.
# Opcionalmente, podemos adicionar os outros nós no argumento se usarmos a flag --server repetida (não suportado diretamente no install script dessa forma simples)
# ou confiar que o agente vai descobrir os outros nós após o primeiro join.

echo "Instalando K3s como Worker..."
echo "Conectando ao Control Plane Inicial: $K3S_CONTROL_PLANE_1_IP"

# Nota: O agente K3s automaticamente descobre os outros control planes após o registro inicial.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://$K3S_CONTROL_PLANE_1_IP:6443 --token $K3S_TOKEN --node-ip $CURRENT_NODE_IP" sh -
check_command "Falha ao instalar K3s Worker."

echo " "
echo -e "\n\e[34m--- Instalação do K3s Worker concluída ---\e[0m"
echo "Este nó worker foi adicionado ao cluster K3s."
echo "Verifique o status do cluster usando 'kubectl get nodes' na sua máquina de administração."
