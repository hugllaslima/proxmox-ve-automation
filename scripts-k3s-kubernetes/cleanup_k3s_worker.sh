#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: cleanup_k3s_worker.sh
#
# Descrição:
#  Este script realiza a limpeza completa de um nó que foi configurado como
#  worker do K3s pelo script 'install_k3s_worker.sh'. Ele desinstala o agente
#  K3s e reverte as configurações do sistema para um estado limpo, permitindo
#  a reutilização do servidor.
#
# Funcionalidades:
#  - Desinstala o agente K3s.
#  - Limpa as configurações de rede (/etc/hosts).
#  - Reverte as configurações do kernel (sysctl).
#  - Reabilita o swap.
#
# Contato:
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
#  - Acesso root ou um usuário com privilégios sudo.
#  - O script deve ser executado no nó worker que precisa ser limpo.
#
# Como usar:
#  1. Dê permissão de execução ao script:
#     chmod +x cleanup_k3s_worker.sh
#  2. Execute o script com privilégios de root:
#     sudo ./cleanup_k3s_worker.sh
#  3. Siga as instruções e confirme as ações de limpeza.
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

function check_root {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERRO: Este script precisa ser executado como root ou com sudo." >&2
        exit 1
    fi
}

# --- Início do Script ---

check_root

echo "--------------------------------------------------------------------"
echo "--- Script de Limpeza do K3s Worker ---"
echo "--------------------------------------------------------------------"
echo "Este script irá remover PERMANENTEMENTE o agente K3s e todas as"
echo "configurações relacionadas aplicadas pelo script de instalação."
echo "Esta ação não pode ser desfeita."
echo ""
read -p "Você tem certeza que deseja continuar? (s/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        echo "Limpeza cancelada pelo usuário."
        exit 0
    fi

echo ""
print_info "--- 1. Desinstalando o K3s Agent ---"
    if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
        /usr/local/bin/k3s-agent-uninstall.sh
        print_info "Agente K3s desinstalado com sucesso."
    else
        print_warning "Script de desinstalação do agente K3s não encontrado. Pulando esta etapa."
    fi
# Remove resíduos
    rm -rf /var/lib/rancher/

echo ""
print_info "--- 2. Revertendo Configurações do Sistema ---"

print_info "Limpando /etc/hosts..."
# Remove as entradas específicas do cluster
sed -i '/k3s-control-plane-1/d' /etc/hosts
sed -i '/k3s-control-plane-2/d' /etc/hosts
sed -i '/k3s-control-plane-3/d' /etc/hosts
sed -i '/k3s-worker-1/d' /etc/hosts
sed -i '/k3s-worker-2/d' /etc/hosts
sed -i '/k3s-storage-nfs/d' /etc/hosts
print_info "Entradas do Kubernetes removidas do /etc/hosts."

echo ""
print_info "--- 3. Limpeza de Arquivos e Sistema ---"

print_info "Removendo arquivo de configuração do cluster..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONFIG_FILE_PATH="$SCRIPT_DIR/k3s_cluster_vars.sh"
if [ -f "$CONFIG_FILE_PATH" ]; then
    rm -f "$CONFIG_FILE_PATH"
    print_info "Arquivo de configuração 'k3s_cluster_vars.sh' removido."
fi

print_info "Removendo configurações do kernel para Kubernetes..."
rm -f /etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system > /dev/null 2>&1
print_info "Arquivo de sysctl do Kubernetes removido."

print_info "Reabilitando swap..."
# Remove o comentário da linha de swap no fstab
sed -i '/ swap /s/^#//g' /etc/fstab
swapon -a 2>/dev/null
print_info "Swap reabilitado."

echo ""
print_info "--- 4. Limpeza de Firewall (UFW) ---"
# Limpa regras de Firewall criadas pelo instalador
ufw delete allow 10250/tcp >/dev/null 2>&1
ufw delete allow 8472/udp >/dev/null 2>&1
# Nota: Não removemos a regra SSH (22/tcp) para não bloquear o acesso remoto acidentalmente.
print_info "Regras de firewall do K3s (Kubelet/Flannel) removidas."

echo ""
echo "--------------------------------------------------------------------"
echo "--- Limpeza concluída! ---"
echo "--------------------------------------------------------------------"
echo "É recomendado reiniciar o servidor para garantir que todas as alterações sejam aplicadas corretamente."
echo ""
read -p "Deseja reiniciar agora? (s/n): " REBOOT_CONFIRM
    if [[ "$REBOOT_CONFIRM" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        echo "Reiniciando o servidor..."
        reboot
    else
        echo "Reinicialização cancelada. Por favor, reinicie manualmente."
    fi

exit 0
