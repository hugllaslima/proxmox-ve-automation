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
# Remove as entradas específicas do cluster, mas pode deixar a do próprio host
sed -i '/k3s-control-plane-1/d' /etc/hosts
sed -i '/k3s-control-plane-2/d' /etc/hosts
sed -i '/k3s-storage-nfs/d' /etc/hosts
# Remove a entrada do próprio hostname, se existir
sed -i "/$(hostname)/d" /etc/hosts
print_info "Entradas do Kubernetes removidas do /etc/hosts."

print_info "Removendo configurações do kernel para Kubernetes..."
rm -f /etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system
print_info "Arquivo de sysctl do Kubernetes removido."

print_info "Reabilitando swap..."
# Remove o comentário da linha de swap no fstab
sed -i '/ swap /s/^#//g' /etc/fstab
swapon -a
print_info "Swap reabilitado."

echo ""
print_info "--- 3. Firewall (UFW) ---"
print_warning "O script de instalação desabilitou o UFW. Se necessário, reabilite-o manualmente com 'sudo ufw enable'."

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
