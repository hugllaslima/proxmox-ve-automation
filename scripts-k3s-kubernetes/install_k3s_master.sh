#!/bin/bash

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
export K3S_MASTER_1_IP="$K3S_MASTER_1_IP"
export K3S_MASTER_2_IP="$K3S_MASTER_2_IP"
export K3S_WORKER_1_IP="$K3S_WORKER_1_IP"
export K3S_WORKER_2_IP="$K3S_WORKER_2_IP"
export NFS_SERVER_IP="$NFS_SERVER_IP"

# --- Configurações do Cluster ---
export K3S_CLUSTER_CIDR="$K3S_CLUSTER_CIDR"
export NFS_SHARE_PATH="$NFS_SHARE_PATH"

# --- Segredos (NÃO FAÇA COMMIT DESTE ARQUIVO) ---
export K3S_DB_PASSWORD='$K3S_DB_PASSWORD'
export K3S_TOKEN="" # Será preenchido após a instalação do primeiro master
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
    echo -e "\n\e[33m--- INFORMAÇÕES NECESSÁRIAS PARA A PRIMEIRA INSTALAÇÃO ---\e[0m"
    get_user_input "Digite o IP do k3s-master-1" "192.168.10.20" "K3S_MASTER_1_IP"
    get_user_input "Digite o IP do k3s-master-2" "192.168.10.21" "K3S_MASTER_2_IP"
    get_user_input "Digite o IP do k3s-worker-1" "192.168.10.22" "K3S_WORKER_1_IP"
    get_user_input "Digite o IP do k3s-worker-2" "192.168.10.23" "K3S_WORKER_2_IP"
    get_user_input "Digite a senha para o banco de dados PostgreSQL do K3s" "" "K3S_DB_PASSWORD" "true"
    get_user_input "Digite o IP do servidor NFS (k3s-storage-nfs)" "192.168.10.24" "NFS_SERVER_IP"
    get_user_input "Digite o caminho do compartilhamento NFS no servidor" "/mnt/k3s-share-nfs/" "NFS_SHARE_PATH"
    get_user_input "Digite o CIDR da rede do cluster K3s" "10.10.0.0/22" "K3S_CLUSTER_CIDR"
    confirm_info
    generate_config_file
}

# --- Funções de Interface do Usuário (get_user_input, confirm_info) ---
function get_user_input {
    local prompt_message="$1"
    local example_value="$2"
    local var_name="$3"
    local is_password="$4"

    local input_value
    local prompt_string="$prompt_message"

    if [ -n "$example_value" ]; then
        prompt_string+=" (Exemplo: $example_value)"
    fi
    prompt_string+=": "

    while true; do
        if [ "$is_password" == "true" ]; then
            read -s -p "$prompt_string" input_value
            echo # Nova linha após a senha
        else
            read -p "$prompt_string" input_value
        fi

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
    echo "IP do k3s-master-1: $K3S_MASTER_1_IP"
    echo "IP do k3s-master-2: $K3S_MASTER_2_IP"
    echo "IP do k3s-worker-1: $K3S_WORKER_1_IP"
    echo "IP do k3s-worker-2: $K3S_WORKER_2_IP"
    echo "Senha do PostgreSQL: (oculta)"
    echo "IP do servidor NFS: $NFS_SERVER_IP"
    echo "Caminho do compartilhamento NFS: $NFS_SHARE_PATH"
    echo "CIDR da rede do cluster: $K3S_CLUSTER_CIDR"
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

echo -e "\e[34m--- Instalação do K3s Master Node ---\e[0m"

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

if [ "$CURRENT_NODE_IP" == "$K3S_MASTER_1_IP" ]; then
    NODE_ROLE="MASTER_1"
    echo -e "\e[32mEste nó será configurado como o PRIMEIRO K3s Master.\e[0m"
elif [ "$CURRENT_NODE_IP" == "$K3S_MASTER_2_IP" ]; then
    NODE_ROLE="MASTER_2"
    echo -e "\e[32mEste nó será configurado como o SEGUNDO K3s Master.\e[0m"
    if [ -z "$K3S_TOKEN" ]; then
        error_exit "O K3S_TOKEN está vazio no arquivo de configuração. Por favor, execute o script no k3s-master-1 primeiro para gerar o token."
    fi
else
    error_exit "O IP deste nó ($CURRENT_NODE_IP) não corresponde a nenhum IP de master definido no arquivo de configuração."
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
sudo sed -i '/k3s-master-1/d' /etc/hosts
sudo sed -i '/k3s-master-2/d' /etc/hosts
sudo sed -i '/k3s-worker-1/d' /etc/hosts
sudo sed -i '/k3s-worker-2/d' /etc/hosts
sudo sed -i '/k3s-storage-nfs/d' /etc/hosts

sudo tee -a /etc/hosts <<EOF > /dev/null
$K3S_MASTER_1_IP k3s-master-1
$K3S_MASTER_2_IP k3s-master-2
$K3S_WORKER_1_IP k3s-worker-1
$K3S_WORKER_2_IP k3s-worker-2
$NFS_SERVER_IP k3s-storage-nfs
EOF
check_command "Falha ao configurar /etc/hosts."
success_message "/etc/hosts configurado."

# --- 2. Instalação do K3s (Lógica Principal) ---

echo -e "\n\e[34m--- 2. Instalação do K3s ---\e[0m"

# Renomeia temporariamente o executável do UFW para impedir que o K3s o ative
echo "Movendo temporariamente o executável do UFW para prevenir interferência..."
if [ -f /usr/sbin/ufw ]; then
    sudo mv /usr/sbin/ufw /usr/sbin/ufw.bak
    check_command "Falha ao mover o executável do UFW."
    success_message "UFW temporariamente desabilitado para a instalação do K3s."
else
    warning_message "O executável do UFW não foi encontrado em /usr/sbin/ufw. A instalação continuará, mas isso é inesperado."
fi

if [ "$NODE_ROLE" == "MASTER_1" ]; then
    # --- Instalação do Master 1 ---
    echo "Configurando PostgreSQL para K3s..."
    sudo apt install -y postgresql postgresql-contrib
    check_command "Falha ao instalar PostgreSQL."

    sudo -u postgres psql -c "CREATE USER k3s WITH PASSWORD '$K3S_DB_PASSWORD';"
    check_command "Falha ao criar usuário k3s no PostgreSQL."
    sudo -u postgres psql -c "CREATE DATABASE k3s OWNER k3s;"
    check_command "Falha ao criar banco de dados k3s no PostgreSQL."

    PG_CONF_PATH=$(find /etc/postgresql/ -name "postgresql.conf" | head -n 1)
    PG_HBA_CONF_PATH=$(find /etc/postgresql/ -name "pg_hba.conf" | head -n 1)

    if [ -z "$PG_CONF_PATH" ] || [ -z "$PG_HBA_CONF_PATH" ]; then
        error_exit "Não foi possível encontrar os arquivos de configuração do PostgreSQL."
    fi

    sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF_PATH"
    if ! sudo grep -q "host    k3s             k3s             $K3S_CLUSTER_CIDR            md5" "$PG_HBA_CONF_PATH"; then
        sudo sed -i "/^# IPv4 local connections:/a host    k3s             k3s             $K3S_CLUSTER_CIDR            md5" "$PG_HBA_CONF_PATH"
    fi
    check_command "Falha ao configurar PostgreSQL para conexões externas."

    sudo systemctl restart postgresql
    check_command "Falha ao reiniciar PostgreSQL."
    sudo systemctl enable postgresql
    success_message "PostgreSQL configurado e iniciado."

    echo "Instalando K3s como o primeiro Master..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip $K3S_MASTER_1_IP --tls-san $K3S_MASTER_1_IP --tls-san $K3S_MASTER_2_IP --cluster-cidr $K3S_CLUSTER_CIDR --datastore-endpoint=\"postgres://k3s:$K3S_DB_PASSWORD@$K3S_MASTER_1_IP:5432/k3s\"" sh -
    check_command "Falha ao instalar K3s no Master 1."
    success_message "K3s instalado no Master 1."

    echo "Aguardando K3s iniciar..."
    sleep 30

    echo "Obtendo K3s token e salvando no arquivo de configuração..."
    K3S_TOKEN_VALUE=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    check_command "Falha ao obter o token do K3s."
    add_token_to_config "$K3S_TOKEN_VALUE"
    
    echo -e "\n\e[32m--------------------------------------------------------------------------------\e[0m"
    echo -e "\e[32mK3s Token: \e[36m$K3S_TOKEN_VALUE\e[0m"
    echo -e "\e[32m--------------------------------------------------------------------------------\e[0m"
    warning_message "O token foi salvo em '$CONFIG_FILE'. Copie todo o diretório '$SCRIPT_DIR' para o k3s-master-2 e execute este script novamente lá."

elif [ "$NODE_ROLE" == "MASTER_2" ]; then
    # --- Instalação do Master 2 ---
    echo "Instalando K3s como o segundo Master..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $K3S_MASTER_2_IP --tls-san $K3S_MASTER_1_IP --tls-san $K3S_MASTER_2_IP --datastore-endpoint=\"postgres://k3s:$K3S_DB_PASSWORD@$K3S_MASTER_1_IP:5432/k3s\" --token $K3S_TOKEN" sh -
    check_command "Falha ao instalar K3s no Master 2."
    success_message "K3s instalado no Master 2."
fi

# --- 3. Configuração do kubectl (apenas no Master 1) ---
if [ "$NODE_ROLE" == "MASTER_1" ]; then
    echo -e "\n\e[34m--- 3. Configuração do kubectl ---\e[0m"
    echo "Copiando kubeconfig para o diretório do usuário..."
    mkdir -p "$HOME/.kube"
    sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"
    sed -i "s/127.0.0.1/$K3S_MASTER_1_IP/" "$HOME/.kube/config"
    success_message "kubectl configurado para este nó."
    warning_message "Você pode copiar '$HOME/.kube/config' para sua máquina de administração."
fi

# --- 4. Configuração Final do Firewall ---
echo -e "\n\e[34m--- 4. Configuração Final do Firewall ---\e[0m"

# Restaura o executável do UFW
echo "Restaurando o executável do UFW..."
if [ -f /usr/sbin/ufw.bak ]; then
    sudo mv /usr/sbin/ufw.bak /usr/sbin/ufw
    check_command "Falha ao restaurar o executável do UFW."
    success_message "UFW restaurado."
fi

echo "Configurando e reativando o firewall (UFW)..."
sudo ufw allow 22/tcp comment 'Permitir acesso SSH'
sudo ufw allow 6443/tcp comment 'K3s API Server'
sudo ufw allow 10250/tcp comment 'Kubelet'
sudo ufw allow 8472/udp comment 'Flannel VXLAN'
check_command "Falha ao adicionar regras essenciais do K3s ao firewall."

if [ "$NODE_ROLE" == "MASTER_1" ]; then
    echo "Adicionando regra de firewall para PostgreSQL no Master 1..."
    sudo ufw allow from $K3S_MASTER_2_IP to any port 5432 proto tcp comment 'Acesso do Master 2 ao PostgreSQL'
    check_command "Falha ao adicionar regra do PostgreSQL ao firewall."
fi

# Ativa o firewall de forma não interativa. A regra da porta 22 já foi adicionada.
sudo ufw --force enable
check_command "Falha ao ativar o UFW."

success_message "Regras de firewall adicionadas e UFW reativado."
warning_message "A conexão SSH foi mantida pela regra na porta 22/tcp."


echo -e "\n\e[32m--- Instalação do K3s Master concluída para $NODE_ROLE ---\e[0m"
