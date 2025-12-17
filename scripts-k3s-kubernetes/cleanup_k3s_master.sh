#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: cleanup_k3s_master.sh
#
# Descrição:
#  Este script realiza a limpeza completa de um nó que foi configurado como
#  master do K3s pelo script 'install_k3s_master.sh'. Ele desinstala o K3s,
#  remove o PostgreSQL (se aplicável), e reverte as configurações do sistema
#  para um estado limpo, permitindo a reutilização do servidor.
#
# Funcionalidades:
#  - Desinstala o K3s (servidor ou agente).
#  - Remove completamente o PostgreSQL e seus dados.
#  - Limpa as configurações de rede (/etc/hosts).
#  - Reverte as configurações do kernel (sysctl).
#  - Remove arquivos de configuração do kubectl.
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
#  - O script deve ser executado no nó que precisa ser limpo.
#
# Como usar:
#  1. Dê permissão de execução ao script:
#     chmod +x cleanup_k3s_master.sh
#  2. Execute o script com privilégios de root:
#     sudo ./cleanup_k3s_master.sh
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
echo "--- Script de Limpeza do K3s Master ---"
echo "--------------------------------------------------------------------"
echo "Este script irá remover PERMANENTEMENTE o K3s, PostgreSQL e todas as"
echo "configurações relacionadas aplicadas pelo script de instalação."
echo "Esta ação não pode ser desfeita."
echo ""
read -p "Você tem certeza que deseja continuar? (s/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        echo "Limpeza cancelada pelo usuário."
        exit 0
    fi

echo ""
print_info "--- 1. Desinstalando o K3s ---"
    if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
        /usr/local/bin/k3s-uninstall.sh
        print_info "K3s desinstalado com sucesso."
    else
        print_warning "Script de desinstalação do K3s não encontrado. Pulando esta etapa."
    fi

# Remove resíduos
    rm -rf /var/lib/rancher/

echo ""
print_info "--- 2. Removendo PostgreSQL ---"
    if dpkg -l | grep -q postgresql; then
        systemctl stop postgresql
        systemctl disable postgresql
        apt-get purge --auto-remove -y postgresql*
        rm -rf /var/lib/postgresql/
        rm -rf /etc/postgresql/
        print_info "PostgreSQL removido completamente."
    else
        print_warning "PostgreSQL não parece estar instalado. Pulando esta etapa."
    fi

echo ""
print_info "--- 3. Revertendo Configurações do Sistema ---"

print_info "Limpando /etc/hosts..."
sed -i '/k8s-master-1/d' /etc/hosts
sed -i '/k8s-master-2/d' /etc/hosts
sed -i '/k8s-worker-1/d' /etc/hosts
sed -i '/k8s-worker-2/d' /etc/hosts
sed -i '/k8s-storage-nfs/d' /etc/hosts
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
print_info "--- 4. Limpando Configurações de Usuário ---"

# Encontra todos os diretórios home de usuários reais para limpar o .kube
    for user_home in /home/*; do
        if [ -d "$user_home/.kube" ]; then
            print_info "Removendo $user_home/.kube..."
            rm -rf "$user_home/.kube"
        fi
    done
    if [ -d "/root/.kube" ]; then
        print_info "Removendo /root/.kube..."
        rm -rf "/root/.kube"
    fi

echo ""
print_info "--- 5. Firewall (UFW) ---"
print_warning "Este script de limpeza NÃO remove as regras de firewall (UFW) adicionadas durante a instalação."
print_warning "Se desejar reverter o firewall para o padrão, use o comando 'sudo ufw reset'."


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
