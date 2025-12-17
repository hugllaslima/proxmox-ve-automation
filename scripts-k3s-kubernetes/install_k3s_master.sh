#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: install_k3s_master.sh
#
# Descrição:
#  Este script automatiza a instalação e configuração de um nó master (control
#  plane) do K3s, incluindo a configuração de um banco de dados PostgreSQL
#  externo para alta disponibilidade (HA). O script é interativo e solicita
#  as informações necessárias, como IPs dos nós, senhas e tokens.
#
#  Funcionalidades:
#  - Prepara o sistema operacional (Debian/Ubuntu) desabilitando swap e
#    configurando módulos do kernel.
#  - Configura o arquivo /etc/hosts para resolução de nomes no cluster.
#  - Instala e configura o PostgreSQL no primeiro master para ser usado como
#    datastore do K3s.
#  - Instala o K3s no primeiro master, gera um token de junção e configura o
#    kubectl.
#  - Instala o K3s em um segundo master, juntando-o ao cluster existente.
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
#  - Conectividade de rede entre os nós que farão parte do cluster.
#  - IPs estáticos para todos os nós do cluster.
#
# Como usar:
#  1. Certifique-se de que os pré-requisitos foram atendidos.
#  2. Dê permissão de execução ao script:
#     chmod +x install_k3s_master.sh
#  3. Execute o script no primeiro nó master:
#     sudo ./install_k3s_master.sh
#  4. Siga as instruções, fornecendo os IPs e a senha do banco de dados.
#  5. Copie o token gerado no final da execução.
#  6. Execute o script no segundo nó master, fornecendo o token quando
#     solicitado.
#
# -----------------------------------------------------------------------------

# --- Variáveis de Configuração (Serão preenchidas pelo usuário) ---
K3S_MASTER_1_IP=""
K3S_MASTER_2_IP=""
K3S_DB_PASSWORD=""
NFS_SERVER_IP=""
NFS_SHARE_PATH=""
K3S_TOKEN="" # Será gerado no master-1 e usado no master-2

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

# --- Início do Script ---
echo "--- Instalação do K3s Master Node ---"
echo " "
echo "Este script irá configurar um nó K3s Master (Control Plane)."
echo "Por favor, forneça as informações solicitadas."

# Coletar informações do usuário
get_user_input "Digite o IP do k8s-master-1" "10.10.1.208" "K3S_MASTER_1_IP"
get_user_input "Digite o IP do k8s-master-2" "10.10.1.209" "K3S_MASTER_2_IP"
get_user_input "Digite a senha para o banco de dados PostgreSQL do K3s" "" "K3S_DB_PASSWORD" "true"
get_user_input "Digite o IP do servidor NFS (k8s-storage-nfs)" "10.10.1.212" "NFS_SERVER_IP"
get_user_input "Digite o caminho do compartilhamento NFS no servidor" "/mnt/nfs_share" "NFS_SHARE_PATH"

CURRENT_NODE_IP=$(hostname -I | awk '{print $1}')
echo "IP detectado para este nó: $CURRENT_NODE_IP"

if [ "$CURRENT_NODE_IP" == "$K3S_MASTER_1_IP" ]; then
    NODE_ROLE="MASTER_1"
    echo "Este nó será configurado como o PRIMEIRO K3s Master."
elif [ "$CURRENT_NODE_IP" == "$K3S_MASTER_2_IP" ]; then
    NODE_ROLE="MASTER_2"
    echo "Este nó será configurado como o SEGUNDO K3s Master."
    get_user_input "Digite o token do K3s obtido do k8s-master-1" "" "K3S_TOKEN"
else
    error_exit "O IP deste nó ($CURRENT_NODE_IP) não corresponde ao IP do k8s-master-1 ($K3S_MASTER_1_IP) nem ao IP do k8s-master-2 ($K3S_MASTER_2_IP). Por favor, execute o script no nó correto."
fi

echo "--- 1. Preparação do Sistema Operacional ---"
echo "Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y
check_command "Falha ao atualizar pacotes."
sudo apt autoremove -y

echo "Desabilitando swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^|$.*$|$/#\1/g' /etc/fstab
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
sudo sed -i '/k8s-master-1/d' /etc/hosts
sudo sed -i '/k8s-master-2/d' /etc/hosts
sudo sed -i '/k8s-worker-1/d' /etc/hosts
sudo sed -i '/k8s-worker-2/d' /etc/hosts
sudo sed -i '/k8s-storage-nfs/d' /etc/hosts

sudo tee -a /etc/hosts <<EOF > /dev/null
$K3S_MASTER_1_IP k8s-master-1
$K3S_MASTER_2_IP k8s-master-2
$NFS_SERVER_IP k8s-storage-nfs
# Adicione os workers aqui se precisar de resolução de nome nos masters
# 10.10.1.210 k8s-worker-1
# 10.10.1.211 k8s-worker-2
EOF
check_command "Falha ao configurar /etc/hosts."

echo "Desabilitando UFW..."
sudo ufw disable > /dev/null 2>&1
sudo systemctl stop ufw > /dev/null 2>&1
sudo systemctl disable ufw > /dev/null 2>&1
echo "UFW desabilitado (se estava ativo)."

echo "--- 2. Instalação do K3s ---"

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
    sudo sed -i "/^# IPv4 local connections:/a host    k3s             k3s             10.10.0.0/22            md5" "$PG_HBA_CONF_PATH"
    check_command "Falha ao configurar PostgreSQL para conexões externas."

    sudo systemctl restart postgresql
    check_command "Falha ao reiniciar PostgreSQL."
    sudo systemctl enable postgresql
    echo "PostgreSQL configurado e iniciado."

    echo "Instalando K3s como o primeiro Master..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip $K3S_MASTER_1_IP --tls-san $K3S_MASTER_1_IP --tls-san $K3S_MASTER_2_IP --datastore-endpoint=\"postgres://k3s:$K3S_DB_PASSWORD@$K3S_MASTER_1_IP:5432/k3s\"" sh -
    check_command "Falha ao instalar K3s no Master 1."

    echo "Aguardando K3s iniciar..."
    sleep 30 # Dar um tempo para o K3s iniciar

    echo "Obtendo K3s token..."
    K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    check_command "Falha ao obter o token do K3s."
    echo "--------------------------------------------------------------------------------"
    echo "K3s Token para juntar outros nós: $K3S_TOKEN"
    echo "--------------------------------------------------------------------------------"
    echo "Copie este token e use-o ao executar este script no k8s-master-2 e no script de worker."
    echo "Aguarde o K3s estar completamente pronto antes de prosseguir com o Master 2."

elif [ "$NODE_ROLE" == "MASTER_2" ]; then
    echo "Instalando K3s como o segundo Master..."
    if [ -z "$K3S_TOKEN" ]; then
        error_exit "O token do K3s não foi fornecido. Por favor, execute o script no k8s-master-1 primeiro para obter o token."
    fi
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $K3S_MASTER_2_IP --tls-san $K3S_MASTER_1_IP --tls-san $K3S_MASTER_2_IP --datastore-endpoint=\"postgres://k3s:$K3S_DB_PASSWORD@$K3S_MASTER_1_IP:5432/k3s\" --token $K3S_TOKEN" sh -
    check_command "Falha ao instalar K3s no Master 2."
fi

echo "--- 3. Configuração do kubectl (apenas no Master 1 para cópia) ---"
if [ "$NODE_ROLE" == "MASTER_1" ]; then
    echo "Copiando kubeconfig para o diretório do usuário..."
    mkdir -p "$HOME/.kube"
    sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"

    # Ajustar o IP do servidor no kubeconfig para o IP do master-1
    sed -i "s/127.0.0.1/$K3S_MASTER_1_IP/" "$HOME/.kube/config"

    echo "kubectl configurado para este nó. Você pode copiar $HOME/.kube/config para sua máquina local."
    echo "Lembre-se de ajustar o IP do servidor no kubeconfig para o IP do master-1 se for usar de fora do cluster."
fi

echo "--- Instalação do K3s Master concluída para $NODE_ROLE ---"
echo "Por favor, verifique o status do cluster usando 'kubectl get nodes' na sua máquina de administração."
