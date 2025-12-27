#!/bin/bash

# -----------------------------------------------------------------------------
# Script: install_k3s_management.sh
#
# Descrição:
#   Este script automatiza a configuração de addons essenciais para um cluster
#   Kubernetes (K3s), incluindo a configuração do kubectl, a instalação do Helm
#   e a implantação de componentes como NFS Subdir External Provisioner,
#   MetalLB e Nginx Ingress Controller.
#
#   O script é interativo e solicita as informações necessárias, como IPs
#   do cluster K3s, IP do servidor NFS, caminho do compartilhamento NFS,
#   e caminhos de rede, para personalizar a instalação.
#
# Contato:
#  - https://www.linkedin.com/in/hugllas-r-s-lima/
#  - https://github.com/hugllaslima/proxmox-ve-automation/tree/main/scripts-k3s-kubernetes
#
# Versão:
#   v1.0.0 - 2024-07-29 - Versão inicial do script.
#
# Pré-requisitos:
#   - Um cluster K3s já deve estar instalado e em execução.
#   - O nó control-plane do K3s deve estar acessível via SSH a partir da máquina
#     onde este script será executado.
#   - Um servidor NFS deve estar configurado e acessível na rede.
#   - Acesso à internet para baixar as ferramentas (kubectl, Helm) e as
#     imagens dos addons.
#
# Como usar:
#   1. Dê permissão de execução ao script:
#      chmod +x install_k3s_management.sh
#
#   2. Execute o script:
#      ./install_k3s_management.sh
#
#   3. Siga as instruções no terminal, fornecendo os IPs e as configurações
#      solicitadas. O script usará valores padrão se nenhuma entrada for
#      fornecida.
#
# Onde utilizar:
#   Este script deve ser executado em uma máquina de gerenciamento (como um
#   laptop ou um servidor de administração) que tenha acesso de rede ao
#   cluster Kubernetes e ao servidor NFS. Não é necessário executá-lo
#   diretamente em um dos nós do cluster.
#
# -----------------------------------------------------------------------------

# --- Constantes ---
CONFIG_FILE="k3s_cluster_vars.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONFIG_FILE_PATH="$SCRIPT_DIR/$CONFIG_FILE"

# --- Variáveis de Configuração ---
K3S_CONTROL_PLANE_1_IP=""
NFS_SERVER_IP=""
NFS_SHARE_PATH=""
METALLB_IP_RANGE=""
SSH_USER=""

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

# Função para coletar todas as informações manualmente
function gather_info() {
    get_user_input "Digite o IP do k3s-control-plane-1 (para configurar o kubectl)" "192.168.10.20" "K3S_CONTROL_PLANE_1_IP"
    get_user_input "Digite o usuário SSH para conectar no control-plane-1" "root" "SSH_USER"
    get_user_input "Digite o IP do servidor NFS (k3s-storage-nfs)" "192.168.10.24" "NFS_SERVER_IP"
    get_user_input "Digite o caminho do compartilhamento NFS no servidor" "/mnt/nfs_share" "NFS_SHARE_PATH"
    get_user_input "Digite a faixa de IPs para o MetalLB (ex: 10.10.3.200-10.10.3.250)" "10.10.3.200-10.10.3.250" "METALLB_IP_RANGE"
}

# Função para confirmar as informações
function confirm_info {
    echo -e "\n\e[34m--- Por favor, revise as informações fornecidas ---\e[0m"
    echo "Control Plane IP: $K3S_CONTROL_PLANE_1_IP"
    echo "Usuario SSH:      $SSH_USER"
    echo "NFS Server IP:    $NFS_SERVER_IP"
    echo "NFS Share Path:   $NFS_SHARE_PATH"
    echo "MetalLB Range:    $METALLB_IP_RANGE"
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

echo "--- Configuração de Addons do Kubernetes ---"
echo "Este script irá configurar o kubectl e instalar o NFS Provisioner, MetalLB e Nginx Ingress Controller."

# Tenta carregar o arquivo de configuração
if [ -f "$CONFIG_FILE_PATH" ]; then
    echo -e "\e[32mArquivo de configuração encontrado: $CONFIG_FILE\e[0m"
    echo "Carregando variáveis..."
    source "$CONFIG_FILE_PATH"

    # --- Compatibilidade com versões antigas ---
    if [ -z "$K3S_CONTROL_PLANE_1_IP" ] && [ -n "$K3S_MASTER_1_IP" ]; then
        K3S_CONTROL_PLANE_1_IP="$K3S_MASTER_1_IP"
    fi

    # Validação e coleta de dados faltantes
    if [ -z "$METALLB_IP_RANGE" ]; then
        echo -e "\e[33mAviso: A faixa de IP do MetalLB não está definida no arquivo de configuração.\e[0m"
        get_user_input "Digite a faixa de IPs para o MetalLB (ex: 10.10.3.200-10.10.3.250)" "10.10.3.200-10.10.3.250" "METALLB_IP_RANGE"
    fi
     
    # Se ainda faltar algo essencial, pergunta tudo para garantir
    if [ -z "$K3S_CONTROL_PLANE_1_IP" ] || [ -z "$NFS_SERVER_IP" ]; then
         echo -e "\e[33mAviso: Variáveis essenciais (Control Plane ou NFS) faltando. Iniciando coleta manual.\e[0m"
         gather_info
    else
        # Se os IPs vieram do arquivo, ainda precisamos do usuário SSH, pois não é salvo lá
        if [ -z "$SSH_USER" ]; then
             get_user_input "Digite o usuário SSH para conectar no control-plane-1" "root" "SSH_USER"
        fi
    fi
else
    echo -e "\e[33mArquivo de configuração não encontrado. Iniciando coleta manual.\e[0m"
    gather_info
fi

# Confirmação antes de prosseguir
confirm_info

echo "--- 1. Configurando kubectl ---"
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    check_command "Falha ao instalar kubectl."
else
    echo "kubectl já está instalado."
fi

echo "Copiando kubeconfig do k3s-control-plane-1..."
# Assume que você tem acesso SSH configurado para o usuário especificado
echo -e "\e[33mAviso: Será necessário digitar a senha do usuário '$SSH_USER' ou 'root' (via sudo) se solicitado.\e[0m"
ssh "$SSH_USER@$K3S_CONTROL_PLANE_1_IP" "sudo cat /etc/rancher/k3s/k3s.yaml" > "$HOME/.kube/config"
check_command "Falha ao copiar kubeconfig do k3s-control-plane-1. Verifique o acesso SSH."

mkdir -p "$HOME/.kube"
chmod 600 "$HOME/.kube/config"
sed -i "s/127.0.0.1/$K3S_CONTROL_PLANE_1_IP/" "$HOME/.kube/config"
echo "kubectl configurado. Verificando conexão com o cluster..."
kubectl get nodes
check_command "Falha ao conectar ao cluster Kubernetes. Verifique o IP do control-plane e o kubeconfig."

echo "--- 2. Instalando Helm ---"
if ! command -v helm &> /dev/null; then
    echo "Helm não encontrado. Instalando Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    check_command "Falha ao instalar Helm."
else
    echo "Helm já está instalado."
fi

echo "--- 3. Instalando NFS Subdir External Provisioner ---"
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
kubectl create namespace nfs-provisioner --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace nfs-provisioner \
    --set nfs.server="$NFS_SERVER_IP" \
    --set nfs.path="$NFS_SHARE_PATH" \
    --set storageClass.name=nfs-client \
    --set storageClass.defaultClass=true
check_command "Falha ao instalar NFS Subdir External Provisioner."
echo "NFS Subdir External Provisioner instalado."

echo "--- 4. Instalando MetalLB ---"
helm repo add metallb https://metallb.github.io/metallb
helm repo update
kubectl create namespace metallb-system --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install metallb metallb/metallb --namespace metallb-system
check_command "Falha ao instalar MetalLB."
echo "MetalLB instalado. Configurando IPAddressPool..."

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - $METALLB_IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF
check_command "Falha ao configurar IPAddressPool do MetalLB."
echo "MetalLB IPAddressPool configurado."

echo "--- 5. Instalando Nginx Ingress Controller ---"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.service.type=LoadBalancer \
    --set controller.service.externalTrafficPolicy=Local
check_command "Falha ao instalar Nginx Ingress Controller."
echo "Nginx Ingress Controller instalado."

echo "--- Configuração de Addons do Kubernetes concluída ---"
echo "Verifique o status dos componentes:"
echo "kubectl get pods -n nfs-provisioner"
echo "kubectl get pods -n metallb-system"
echo "kubectl get pods -n ingress-nginx"
echo "kubectl get storageclass"
echo "kubectl get svc -n ingress-nginx"
