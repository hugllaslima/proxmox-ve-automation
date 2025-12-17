#!/bin/bash

# --- Variáveis de Configuração (Serão preenchidas pelo usuário) ---
K3S_MASTER_1_IP=""
K3S_MASTER_2_IP=""
K3S_WORKER_1_IP=""
K3S_WORKER_2_IP=""
K3S_DB_PASSWORD=""
NFS_SERVER_IP=""
NFS_SHARE_PATH=""
K3S_CLUSTER_CIDR=""
K3S_TOKEN="" # Será gerado no master-1 e usado no master-2

# --- Funções Auxiliares ---

# Função para exibir mensagens de erro e sair
function error_exit {
    echo -e "\n\e[31mERRO: $1\e[0m" >&2
    exit 1
}

# Função para exibir mensagens de sucesso
function success_message {
    echo -e "\e[32mSUCESSO: $1\e[0m"
}

# Função para exibir mensagens de aviso
function warning_message {
    echo -e "\e[33mAviso: $1\e[0m"
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

# Função para confirmar as informações
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
    if [ -n "$K3S_TOKEN" ]; then
        echo "K3s Token: (oculto)"
    fi
    echo -e "\e[34m---------------------------------------------------\e[0m"

    while true; do
        read -p "As informações acima estão corretas? (s/n): " confirm
        case $confirm in
            [Ss]* ) break;;
            [Nn]* ) error_exit "Instalação cancelada pelo usuário. Por favor, execute o script novamente com as informações corretas.";;
            * ) echo "Por favor, responda 's' ou 'n'.";;
        esac
    done
}

# --- Início do Script ---

echo -e "\e[34m--- Instalação do K3s Master Node ---\e[0m"
echo "Este script irá configurar um nó K3s Master (Control Plane)."

echo -e "\n\e[33m--- INFORMAÇÕES NECESSÁRIAS ANTES DE COMEÇAR ---\e[0m"
echo "Por favor, tenha em mãos as seguintes informações para a instalação:"
echo "1. Endereço IP do k8s-master-1 (este nó)."
echo "2. Endereço IP do k8s-master-2 (o outro nó master)."
echo "3. Uma senha forte para o banco de dados PostgreSQL do K3s."
echo "4. Endereço IP do servidor NFS (k8s-storage-nfs)."
echo "5. O caminho completo do compartilhamento NFS no servidor (ex: /mnt/k3s-share-nfs/)."
echo "6. Se este for o k8s-master-2, você precisará do K3s Token gerado pelo k8s-master-1."
echo -e "\e[33m--------------------------------------------------\e[0m"

# Coletar informações do usuário
get_user_input "Digite o IP do k3s-master-1" "192.168.10.20" "K3S_MASTER_1_IP"
get_user_input "Digite o IP do k3s-master-2" "192.168.10.21" "K3S_MASTER_2_IP"
get_user_input "Digite o IP do k3s-worker-1" "192.168.10.22" "K3S_WORKER_1_IP"
get_user_input "Digite o IP do k3s-worker-2" "192.168.10.23" "K3S_WORKER_2_IP"
get_user_input "Digite a senha para o banco de dados PostgreSQL do K3s" "" "K3S_DB_PASSWORD" "true"
get_user_input "Digite o IP do servidor NFS (k3s-storage-nfs)" "192.168.10.24" "NFS_SERVER_IP"
get_user_input "Digite o caminho do compartilhamento NFS no servidor" "/mnt/k3s-share-nfs/" "NFS_SHARE_PATH"
get_user_input "Digite o CIDR da rede do cluster K3s" "10.10.0.0/22" "K3S_CLUSTER_CIDR"

CURRENT_NODE_IP=$(hostname -I | awk '{print $1}')
echo -e "\nIP detectado para este nó: \e[36m$CURRENT_NODE_IP\e[0m"

if [ "$CURRENT_NODE_IP" == "$K3S_MASTER_1_IP" ]; then
    NODE_ROLE="MASTER_1"
    echo -e "\e[32mEste nó será configurado como o PRIMEIRO K3s Master.\e[0m"
elif [ "$CURRENT_NODE_IP" == "$K3S_MASTER_2_IP" ]; then
    NODE_ROLE="MASTER_2"
    echo -e "\e[32mEste nó será configurado como o SEGUNDO K3s Master.\e[0m"
    get_user_input "Digite o token do K3s obtido do k8s-master-1" "K10a9b8c7d6e5f4g3h2i1j0k" "K3S_TOKEN" "true" # Token é sensível
else
    error_exit "O IP deste nó ($CURRENT_NODE_IP) não corresponde ao IP do k8s-master-1 ($K3S_MASTER_1_IP) nem ao IP do k8s-master-2 ($K3S_MASTER_2_IP). Por favor, execute o script no nó correto."
fi

# Confirmar as informações antes de prosseguir
confirm_info

# Adicionar a pausa aqui
read -p "$(echo -e '\e[34mPressione ENTER para iniciar a instalação...\e[0m')"

echo -e "\n\e[34m--- 1. Preparação do Sistema Operacional ---\e[0m"
echo "Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y
check_command "Falha ao atualizar pacotes."
sudo apt autoremove -y
success_message "Pacotes atualizados."

# Verificar se há kernel upgrade pendente e pedir reboot
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
# Correção da expressão sed para comentar a linha de swap
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
# Remover entradas antigas para evitar duplicatas
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

echo "Desabilitando UFW..."
sudo ufw disable > /dev/null 2>&1
sudo systemctl stop ufw > /dev/null 2>&1
sudo systemctl disable ufw > /dev/null 2>&1
success_message "UFW desabilitado (se estava ativo)."

echo -e "\n\e[34m--- 2. Instalação do K3s ---\e[0m"

if [ "$NODE_ROLE" == "MASTER_1" ]; then
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
    # Adicionar a linha de host se não existir, ou atualizar se existir
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
    sleep 30 # Dar um tempo para o K3s iniciar

    echo "Obtendo K3s token..."
    K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    check_command "Falha ao obter o token do K3s."
    echo -e "\n\e[32m--------------------------------------------------------------------------------\e[0m"
    echo -e "\e[32mK3s Token para juntar outros nós: \e[36m$K3S_TOKEN\e[0m"
    echo -e "\e[32m--------------------------------------------------------------------------------\e[0m"
    echo -e "\e[33mCopie este token e use-o ao executar este script no k8s-master-2 e no script de worker.\e[0m"
    echo -e "\e[33mAguarde o K3s estar completamente pronto antes de prosseguir com o Master 2.\e[0m"

elif [ "$NODE_ROLE" == "MASTER_2" ]; then
    echo "Instalando K3s como o segundo Master..."
    if [ -z "$K3S_TOKEN" ]; then
        error_exit "O token do K3s não foi fornecido. Por favor, execute o script no k8s-master-1 primeiro para obter o token."
    fi
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $K3S_MASTER_2_IP --tls-san $K3S_MASTER_1_IP --tls-san $K3S_MASTER_2_IP --datastore-endpoint=\"postgres://k3s:$K3S_DB_PASSWORD@$K3S_MASTER_1_IP:5432/k3s\" --token $K3S_TOKEN" sh -
    check_command "Falha ao instalar K3s no Master 2."
    success_message "K3s instalado no Master 2."
fi

echo -e "\n\e[34m--- 3. Configuração do kubectl (apenas no Master 1 para cópia) ---\e[0m"
if [ "$NODE_ROLE" == "MASTER_1" ]; then
    echo "Copiando kubeconfig para o diretório do usuário..."
    mkdir -p "$HOME/.kube"
    sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"

    # Ajustar o IP do servidor no kubeconfig para o IP do master-1
    sed -i "s/127.0.0.1/$K3S_MASTER_1_IP/" "$HOME/.kube/config"

    success_message "kubectl configurado para este nó. Você pode copiar $HOME/.kube/config para sua máquina de administração."
    warning_message "Lembre-se de ajustar o IP do servidor no kubeconfig para o IP do master-1 se for usar de fora do cluster."
fi

echo -e "\n\e[32m--- Instalação do K3s Master concluída para $NODE_ROLE ---\e[0m"
echo "Por favor, verifique o status do cluster usando 'kubectl get nodes' na sua máquina de administração."
