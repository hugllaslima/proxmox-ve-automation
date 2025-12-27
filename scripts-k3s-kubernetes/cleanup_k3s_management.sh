#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: cleanup_k3s_management.sh
#
# Descrição:
#  Este script reverte a configuração realizada pelo 'install_k3s_management.sh'.
#  Ele desinstala os addons (Nginx Ingress, MetalLB, NFS Provisioner) usando
#  o Helm, remove os namespaces associados e limpa a configuração local do
#  kubectl. O objetivo é deixar o cluster em um estado limpo, sem os addons.
#
# Funcionalidades:
#  - Desinstala os charts Helm do Nginx Ingress, MetalLB e NFS Provisioner.
#  - Remove os namespaces 'ingress-nginx', 'metallb-system' e 'nfs-provisioner'.
#  - Remove os repositórios Helm adicionados.
#  - Limpa o arquivo de configuração local do kubectl (~/.kube/config).
#
# Autor:
#  Hugllas R. S. Lima
#
Contato:
#  - https://www.linkedin.com/in/hugllas-r-s-lima/
#  - https://github.com/hugllaslima/proxmox-ve-automation/tree/main/scripts-k3s-kubernetes
#
# Versão:
#  1.0
#
# Data:
#  24/07/2024
#
# Pré-requisitos:
#  - Acesso a um cluster Kubernetes configurado via `kubectl`.
#  - Helm v3 instalado na máquina de gerenciamento.
#  - Permissões para desinstalar charts e deletar namespaces no cluster.
#
# Como usar:
#  1. Dê permissão de execução ao script:
#     chmod +x cleanup_k3s_addons.sh
#  2. Execute o script na sua máquina de gerenciamento:
#     ./cleanup_k3s_addons.sh
#  3. Confirme a ação quando solicitado.
#
# -----------------------------------------------------------------------------

set -e

# --- Funções Auxiliares ---

function print_info {
    echo "INFO: $1"
}

function print_warning {
    echo "AVISO: $1"
}

function check_command_exists {
    if ! command -v $1 &> /dev/null; then
        print_warning "O comando '$1' não foi encontrado. Esta etapa será pulada, mas a limpeza pode ser incompleta."
        return 1
    fi
    return 0
}

# --- Início do Script ---

echo "--------------------------------------------------------------------"
echo "--- Script de Limpeza dos Addons do K3s ---"
echo "--------------------------------------------------------------------"
echo "Este script irá remover PERMANENTEMENTE os addons Nginx, MetalLB,"
echo "e NFS Provisioner, além de limpar a configuração local do kubectl."
echo "Esta ação não pode ser desfeita."
echo ""
read -p "Você tem certeza que deseja continuar? (s/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        echo "Limpeza cancelada pelo usuário."
        exit 0
    fi

echo ""
print_info "--- 1. Desinstalando Addons com Helm ---"

    if check_command_exists helm; then
        print_info "Desinstalando Nginx Ingress Controller..."
        helm uninstall ingress-nginx --namespace ingress-nginx || print_warning "Falha ao desinstalar ingress-nginx. Pode já ter sido removido."

        print_info "Desinstalando MetalLB..."
        helm uninstall metallb --namespace metallb-system || print_warning "Falha ao desinstalar metallb. Pode já ter sido removido."

        print_info "Desinstalando NFS Subdir External Provisioner..."
        helm uninstall nfs-subdir-external-provisioner --namespace nfs-provisioner || print_warning "Falha ao desinstalar nfs-subdir-external-provisioner. Pode já ter sido removido."
    else
        print_warning "Helm não encontrado. Pulando a desinstalação dos addons."
    fi

echo ""
print_info "--- 2. Removendo Namespaces ---"

    if check_command_exists kubectl; then
        print_info "Removendo namespace ingress-nginx..."
        kubectl delete namespace ingress-nginx --ignore-not-found=true

        print_info "Removendo namespace metallb-system..."
        kubectl delete namespace metallb-system --ignore-not-found=true

        print_info "Removendo namespace nfs-provisioner..."
        kubectl delete namespace nfs-provisioner --ignore-not-found=true

        print_info "Aguardando a finalização dos namespaces..."
        sleep 10 # Dá um tempo para os recursos serem terminados
    else
        print_warning "kubectl não encontrado. Pulando a remoção dos namespaces."
    fi

echo ""
print_info "--- 3. Removendo Repositórios Helm ---"

    if check_command_exists helm; then
        print_info "Removendo repositório ingress-nginx..."
        helm repo remove ingress-nginx || print_warning "Repositório 'ingress-nginx' não encontrado."

        print_info "Removendo repositório metallb..."
        helm repo remove metallb || print_warning "Repositório 'metallb' não encontrado."

        print_info "Removendo repositório nfs-subdir-external-provisioner..."
        helm repo remove nfs-subdir-external-provisioner || print_warning "Repositório 'nfs-subdir-external-provisioner' não encontrado."
    else
        print_warning "Helm não encontrado. Pulando a remoção dos repositórios."
    fi

echo ""
print_info "--- 4. Limpando Configuração Local do Kubectl ---"
KUBE_CONFIG="$HOME/.kube/config"
    if [ -f "$KUBE_CONFIG" ]; then
        print_info "Removendo o arquivo de configuração $KUBE_CONFIG..."
        rm -f "$KUBE_CONFIG"
    else
        print_warning "Arquivo de configuração do kubectl não encontrado."
    fi

echo ""
print_warning "Os binários do kubectl e do Helm não foram removidos do sistema."

echo ""
echo "--------------------------------------------------------------------"
echo "--- Limpeza de Addons concluída! ---"
echo "--------------------------------------------------------------------"

exit 0
