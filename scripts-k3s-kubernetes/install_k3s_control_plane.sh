#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: install_k3s_control_plane.sh
#
# Descrição:
#  Este script automatiza a instalação e configuração de um nó Control Plane (Master)
#  do K3s com Datastore embutido (Etcd) para Alta Disponibilidade (HA).
#  Suporta 3 nós de controle:
#   - O primeiro nó inicializa o cluster (--cluster-init).
#   - Os nós subsequentes (2 e 3) ingressam no cluster existente.
#
# Funcionalidades:
#  - Prepara o sistema operacional (Update, Swap, Sysctl).
#  - Configura /etc/hosts e resolução de nomes.
#  - Instala o K3s server com Etcd embarcado.
#  - Gerencia automaticamente firewall (UFW) para API e Etcd.
#
# Contato:
#  - https://www.linkedin.com/in/hugllas-r-s-lima/
#  - https://github.com/hugllaslima/proxmox-ve-automation/tree/main/scripts-k3s-kubernetes
#
# Versão:
#  2.0
#
# Data:
#  27/12/2025
#
# Pré-requisitos:
#  - Ubuntu 22.04/24.04 LTS.
#  - Acesso root/sudo.
#  - IPs estáticos definidos para todos os nós.
#
# Como usar:
#  1. chmod +x install_k3s_control_plane.sh
#  2. sudo ./install_k3s_control_plane.sh
#  3. Siga as instruções interativas.
#
# -----------------------------------------------------------------------------

# --- Constantes ---
CONFIG_FILE="k3s_cluster_vars.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONFIG_FILE_PATH="$SCRIPT_DIR/$CONFIG_FILE"

# --- Funções Auxiliares ---
function error_exit { echo -e "\n\e[31mERRO: $1\e[0m" >&2; exit 1; }
function success_message { echo -e "\e[32mSUCESSO: $1\e[0m"; }
function warning_message { echo -e "\e[33mAviso: $1\e[0m"; }
function check_command { if [ $? -ne 0 ]; then error_exit "$1"; fi; }

# --- Lógica de Configuração ---

# Função para gerar o arquivo de configuração
function generate_config_file() {
    echo "Gerando arquivo de configuração: $CONFIG_FILE..."
    cat > "$CONFIG_FILE_PATH" <<EOF
# Arquivo de configuração gerado pela instalação do K3s
# NÃO adicione este arquivo ao Git.

# --- IPs da Infraestrutura ---
export K3S_CONTROL_PLANE_1_IP="$K3S_CONTROL_PLANE_1_IP"
export K3S_CONTROL_PLANE_2_IP="$K3S_CONTROL_PLANE_2_IP"
export K3S_CONTROL_PLANE_3_IP="$K3S_CONTROL_PLANE_3_IP"
export K3S_WORKER_1_IP="$K3S_WORKER_1_IP"
export K3S_WORKER_2_IP="$K3S_WORKER_2_IP"
export NFS_SERVER_IP="$NFS_SERVER_IP"

# --- Configurações do Cluster ---
export K3S_POD_CIDR="$K3S_POD_CIDR"
export K3S_LAN_CIDR="$K3S_LAN_CIDR"
export NFS_SHARE_PATH="$NFS_SHARE_PATH"

# --- Segredos (NÃO FAÇA COMMIT DESTE ARQUIVO) ---
export K3S_TOKEN="" # Será preenchido após a instalação do primeiro control-plane

# --- Redes de Acesso Permitidas ---
export ADMIN_NETWORK_CIDRS="$ADMIN_NETWORK_CIDRS"
EOF
    chmod 600 "$CONFIG_FILE_PATH"
    success_message "Arquivo de configuração '$CONFIG_FILE' gerado com sucesso."
}

# Função para adicionar o token ao arquivo de configuração
function add_token_to_config() {
    local token="$1"
    # Usa sed com um delimitador diferente para evitar problemas com caracteres especiais no token
    sed -i "s|export K3S_TOKEN=.*|export K3S_TOKEN=\"$token\"|" "$CONFIG_FILE_PATH"
    check_command "Falha ao adicionar o token ao arquivo de configuração."
    success_message "Token do K3s salvo no arquivo de configuração."
}

# Função para coletar informações do usuário (usada apenas na primeira execução)
function gather_initial_info() {
    echo -e "\n\e[33m--- INFORMAÇÕES NECESSÁRIAS PARA A PRIMEIRA INSTALAÇÃO (ETCD HA) ---\e[0m"
    get_user_input "Digite o IP do k3s-control-plane-1" "192.168.10.20" "K3S_CONTROL_PLANE_1_IP"
    get_user_input "Digite o IP do k3s-control-plane-2" "192.168.10.21" "K3S_CONTROL_PLANE_2_IP"
    get_user_input "Digite o IP do k3s-control-plane-3" "192.168.10.22" "K3S_CONTROL_PLANE_3_IP"
    get_user_input "Digite o IP do k3s-worker-1" "192.168.10.23" "K3S_WORKER_1_IP"
    get_user_input "Digite o IP do k3s-worker-2" "192.168.10.24" "K3S_WORKER_2_IP"
    get_user_input "Digite o IP do servidor NFS (k3s-storage-nfs)" "192.168.10.25" "NFS_SERVER_IP"
    get_user_input "Digite o caminho do compartilhamento NFS no servidor" "/mnt/k3s-share-nfs/" "NFS_SHARE_PATH"
    
    # Separação de redes para evitar conflitos de CNI
    get_user_input "Digite o CIDR da rede de PODS do K3s (NÃO use a rede local)" "10.42.0.0/16" "K3S_POD_CIDR"
    get_user_input "Digite o CIDR da rede LOCAL (LAN do Datacenter)" "10.10.0.0/22" "K3S_LAN_CIDR"

    # Garante que os CIDRs não terminem com um ponto
    K3S_POD_CIDR=${K3S_POD_CIDR%%.}
    K3S_LAN_CIDR=${K3S_LAN_CIDR%%.}

    # Coleta de Redes de Administração
    ADMIN_NETWORK_CIDRS=""
    echo
    read -p "Deseja adicionar uma rede de administração (VPN, etc.) para acesso SSH? (s/n): " add_first_admin_net
    if [[ "$add_first_admin_net" =~ ^[Ss]$ ]]; then
        while true; do
            read -p "  -> Digite o CIDR da rede (ex: 192.168.1.0/24 ou 192.168.1.10/32): " new_cidr
            if [ -n "$new_cidr" ]; then
                ADMIN_NETWORK_CIDRS="$ADMIN_NETWORK_CIDRS $new_cidr"
                echo "     Rede '$new_cidr' adicionada."
            else
                echo "     Entrada vazia, ignorando."
            fi

            read -p "Deseja adicionar OUTRA rede de administração? (s/n): " add_another_net
            if [[ ! "$add_another_net" =~ ^[Ss]$ ]]; then
                break
            fi
        done
    fi
    # Remove o espaço inicial, se houver
    ADMIN_NETWORK_CIDRS=$(echo "$ADMIN_NETWORK_CIDRS" | sed 's/^ *//g')
    echo "Coleta de redes de administração concluída."

    confirm_info
    generate_config_file
}

# --- Funções de Interface do Usuário (get_user_input, confirm_info) ---
function get_user_input {
    local prompt_message="$1"
    local example_value="$2"
    local var_name="$3"
    
    local input_value
    local prompt_string="$prompt_message"

    if [ -n "$example_value" ]; then
        prompt_string+=" (Exemplo: $example_value)"
    fi
    prompt_string+=": "

    while true; do
        read -p "$prompt_string" input_value
        if [ -n "$input_value" ]; then
            eval "$var_name=\"$input_value\""
            break
        else
            echo -e "\e[31mEntrada não pode ser vazia. Por favor, tente novamente.\e[0m"
        fi
    done
}

function confirm_info {
    echo -e "\n\e[34m--- Por favor, revise as informações fornecidas ---\e[0m"
    echo "IP do k3s-control-plane-1: $K3S_CONTROL_PLANE_1_IP"
    echo "IP do k3s-control-plane-2: $K3S_CONTROL_PLANE_2_IP"
    echo "IP do k3s-control-plane-3: $K3S_CONTROL_PLANE_3_IP"
    echo "IP do k3s-worker-1: $K3S_WORKER_1_IP"
    echo "IP do k3s-worker-2: $K3S_WORKER_2_IP"
    echo "IP do servidor NFS: $NFS_SERVER_IP"
    echo "Caminho do compartilhamento NFS: $NFS_SHARE_PATH"
    echo "CIDR da rede de PODS: $K3S_POD_CIDR"
    echo "CIDR da rede LOCAL (LAN): $K3S_LAN_CIDR"
    if [ -n "$ADMIN_NETWORK_CIDRS" ]; then
        echo "Redes de Administração (VPN): $ADMIN_NETWORK_CIDRS"
    fi
    echo -e "\e[34m---------------------------------------------------\e[0m"

    while true; do
        read -p "As informações acima estão corretas? (s/n): " confirm
        case $confirm in
            [Ss]* ) break;;
            [Nn]* ) error_exit "Instalação cancelada. Por favor, execute o script novamente.";;
            * ) echo "Por favor, responda 's' ou 'n'.";;
        esac
    done
}


# --- Início do Script ---

echo -e "\e[34m--- Instalação do K3s Control Plane Node (Etcd HA) ---\e[0m"

# Verifica se o arquivo de configuração existe
if [ -f "$CONFIG_FILE_PATH" ]; then
    echo "Arquivo de configuração '$CONFIG_FILE' encontrado. Carregando variáveis..."
    source "$CONFIG_FILE_PATH"
    check_command "Falha ao carregar o arquivo de configuração."
    success_message "Variáveis de ambiente carregadas."
else
    echo "Arquivo de configuração não encontrado."
    warning_message "Esta parece ser a primeira execução em um cluster."
    gather_initial_info
fi

# Determinar o papel do nó
CURRENT_NODE_IP=$(hostname -I | awk '{print $1}')
echo -e "\nIP detectado para este nó: \e[36m$CURRENT_NODE_IP\e[0m"

NODE_ROLE=""
if [ "$CURRENT_NODE_IP" == "$K3S_CONTROL_PLANE_1_IP" ]; then
    NODE_ROLE="CONTROL_PLANE_INITIAL"
    echo -e "\e[32mEste nó será o PRIMEIRO Control Plane (Cluster Init).\e[0m"
elif [ "$CURRENT_NODE_IP" == "$K3S_CONTROL_PLANE_2_IP" ] || [ "$CURRENT_NODE_IP" == "$K3S_CONTROL_PLANE_3_IP" ]; then
    NODE_ROLE="CONTROL_PLANE_JOIN"
    echo -e "\e[32mEste nó será um Control Plane adicional (Join no HA).\e[0m"
    if [ -z "$K3S_TOKEN" ]; then
        error_exit "O K3S_TOKEN está vazio no arquivo de configuração. Por favor, execute o script no k3s-control-plane-1 primeiro."
    fi
else
    error_exit "O IP deste nó ($CURRENT_NODE_IP) não corresponde a nenhum IP de control plane definido no arquivo de configuração."
fi

read -p "$(echo -e '\e[34mPressione ENTER para iniciar a instalação...\e[0m')"

# --- 1. Preparação do Sistema Operacional ---
echo -e "\n\e[34m--- 1. Preparação do Sistema Operacional ---\e[0m"
echo "Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y
check_command "Falha ao atualizar pacotes."
sudo apt autoremove -y
success_message "Pacotes atualizados."

if [ -f /var/run/reboot-required ]; then
    warning_message "Kernel upgrade pendente! É ALTAMENTE RECOMENDADO REINICIAR O SISTEMA AGORA."
    read -p "Deseja reiniciar o sistema agora? (s/n): " reboot_choice
    if [[ "$reboot_choice" =~ ^[Ss]$ ]]; then
        echo "Reiniciando o sistema. Por favor, execute o script novamente após o reboot."
        sudo reboot
        exit 0
    else
        warning_message "Continuando sem reiniciar. Isso pode causar problemas com o Kubernetes se o kernel não estiver atualizado."
    fi
fi

echo "Desabilitando swap..."
sudo sed -i '/ swap / s/^/#/' /etc/fstab
check_command "Falha ao comentar a entrada de swap em /etc/fstab."
sudo swapoff -a
check_command "Falha ao desabilitar swap em tempo de execução."
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
sudo sed -i '/k3s-control-plane/d' /etc/hosts
sudo sed -i '/k3s-worker/d' /etc/hosts
sudo sed -i '/k3s-storage-nfs/d' /etc/hosts

sudo tee -a /etc/hosts <<EOF > /dev/null
$K3S_CONTROL_PLANE_1_IP k3s-control-plane-1
$K3S_CONTROL_PLANE_2_IP k3s-control-plane-2
$K3S_CONTROL_PLANE_3_IP k3s-control-plane-3
$K3S_WORKER_1_IP k3s-worker-1
$K3S_WORKER_2_IP k3s-worker-2
$NFS_SERVER_IP k3s-storage-nfs
EOF
check_command "Falha ao configurar /etc/hosts."
success_message "/etc/hosts configurado."

# --- 2. Instalação e Configuração do K3s ---

echo -e "\n\e[34m--- 2. Instalação do K3s ---\e[0m"
echo "Desativando temporariamente o firewall (UFW) para a instalação..."
sudo ufw disable
check_command "Falha ao desativar o UFW."

export K3S_KUBECONFIG_MODE="644"

if [ "$NODE_ROLE" == "CONTROL_PLANE_INITIAL" ]; then
    echo "Instalando K3s no PRIMEIRO Control Plane (Cluster Init)..."
    # --cluster-init: Inicializa o cluster embedded etcd
    K3S_EXEC_ARGS="server \
        --cluster-init \
        --node-ip $K3S_CONTROL_PLANE_1_IP \
        --tls-san $K3S_CONTROL_PLANE_1_IP \
        --tls-san $K3S_CONTROL_PLANE_2_IP \
        --tls-san $K3S_CONTROL_PLANE_3_IP \
        --cluster-cidr $K3S_POD_CIDR"

    curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_EXEC="$K3S_EXEC_ARGS" sh -
    check_command "Falha ao instalar binários do K3s (Init)."
    
elif [ "$NODE_ROLE" == "CONTROL_PLANE_JOIN" ]; then
    echo "Instalando K3s em Control Plane ADICIONAL (Join)..."
    # Conecta-se ao primeiro nó para entrar no cluster
    K3S_EXEC_ARGS="server \
        --server https://$K3S_CONTROL_PLANE_1_IP:6443 \
        --token $K3S_TOKEN \
        --node-ip $CURRENT_NODE_IP \
        --tls-san $K3S_CONTROL_PLANE_1_IP \
        --tls-san $K3S_CONTROL_PLANE_2_IP \
        --tls-san $K3S_CONTROL_PLANE_3_IP \
        --cluster-cidr $K3S_POD_CIDR"

    curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_EXEC="$K3S_EXEC_ARGS" sh -
    check_command "Falha ao instalar binários do K3s (Join)."
fi

echo -e "\n\e[34m--- Iniciando o serviço K3s ---\e[0m"
sudo systemctl start k3s
check_command "Falha ao iniciar o serviço K3s."

echo "Aguardando o serviço K3s estabilizar..."
for i in {1..15}; do
    if sudo systemctl is-active --quiet k3s; then
        echo "Serviço K3s está ativo."
        break
    fi
    echo "Aguardando serviço K3s... ($i/15)"
    sleep 5
done

if ! sudo systemctl is-active --quiet k3s; then
    error_exit "O serviço K3s falhou ao iniciar. Verifique 'sudo journalctl -u k3s'."
fi
success_message "K3s iniciado!"


# --- 3. Pós-Instalação: Firewall e Tokens ---

echo -e "\n\e[34m--- 3. Configurando Firewall (UFW) ---\e[0m"

echo "Alterando a política de encaminhamento para ACCEPT..."
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

# Regras básicas
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 6443/tcp comment 'K3s API Server'
sudo ufw allow 10250/tcp comment 'Kubelet'
sudo ufw allow 8472/udp comment 'Flannel VXLAN'

# Regras para Etcd HA (2379: Client, 2380: Peer)
# Permitir tráfego de Etcd apenas entre os nós de Control Plane
echo "Liberando portas do Etcd entre Control Planes..."
for IP in $K3S_CONTROL_PLANE_1_IP $K3S_CONTROL_PLANE_2_IP $K3S_CONTROL_PLANE_3_IP; do
    if [ "$IP" != "$CURRENT_NODE_IP" ]; then
        sudo ufw allow from $IP to any port 2379 proto tcp comment "Etcd Client de $IP"
        sudo ufw allow from $IP to any port 2380 proto tcp comment "Etcd Peer de $IP"
    fi
done

# Redes de Administração
if [ -n "$ADMIN_NETWORK_CIDRS" ]; then
    for cidr in $ADMIN_NETWORK_CIDRS; do
        sudo ufw allow from $cidr to any port 22 comment 'SSH Admin'
    done
else
    # Fallback SSH
    sudo ufw allow 22/tcp
fi

sudo ufw --force enable
success_message "Firewall configurado."

# --- 4. Extração de Token (Apenas no Nó Inicial) ---
if [ "$NODE_ROLE" == "CONTROL_PLANE_INITIAL" ]; then
    echo -e "\n\e[34m--- Obtendo Token do Cluster ---\e[0m"
    TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"
    
    # Aguarda o token existir
    while [ ! -f "$TOKEN_FILE" ]; do
        sleep 2
    done

    K3S_TOKEN_VALUE=$(sudo cat "$TOKEN_FILE")
    add_token_to_config "$K3S_TOKEN_VALUE"
    
    echo -e "\n\e[32m--------------------------------------------------------------------------------\e[0m"
    echo -e "\e[32mCluster Inicializado! Token salvo em $CONFIG_FILE\e[0m"
    echo -e "\e[32m--------------------------------------------------------------------------------\e[0m"
    warning_message "Copie o diretório '$SCRIPT_DIR' para os outros 2 Control Planes e execute este mesmo script neles."
    
    # Configurar kubectl para o usuário atual
    mkdir -p "$HOME/.kube"
    sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"
    echo "kubectl configurado para o usuário atual."
fi

echo -e "\n\e[32m--- Instalação Concluída em $CURRENT_NODE_IP ---\e[0m"
