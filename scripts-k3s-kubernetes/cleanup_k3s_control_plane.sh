#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: cleanup_k3s_control_plane.sh
#
# Descrição:
#  Este script realiza a limpeza completa de um nó que foi configurado como
#  control plane do K3s. Ele desinstala o K3s e reverte as configurações 
#  para um estado limpo.
#
# Funcionalidades:
#  - Executa o script oficial de desinstalação (k3s-uninstall.sh).
#  - Limpa diretórios residuais (/var/lib/rancher, etc).
#  - Remove entradas do /etc/hosts geradas pela instalação.
#  - Reabilita o swap.
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
# Como usar:
#  1. chmod +x cleanup_k3s_control_plane.sh
#  2. sudo ./cleanup_k3s_control_plane.sh
#
# -----------------------------------------------------------------------------

function error_exit { echo -e "\n\e[31mERRO: $1\e[0m" >&2; exit 1; }
function check_command { if [ $? -ne 0 ]; then error_exit "$1"; fi; }

if [ "$EUID" -ne 0 ]; then
  error_exit "Por favor, execute este script como root (sudo)."
fi

echo -e "\e[34m--- Iniciando limpeza do nó Control Plane ---\e[0m"
read -p "TEM CERTEZA que deseja remover COMPLETAMENTE o K3s deste nó? (s/n): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    exit 0
fi

# 1. Desinstalar K3s
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    echo "Executando desinstalador do K3s..."
    /usr/local/bin/k3s-uninstall.sh
else
    echo "Desinstalador não encontrado. Tentando parar serviços manualmente..."
    systemctl stop k3s 2>/dev/null
    systemctl disable k3s 2>/dev/null
    rm -f /usr/local/bin/k3s
    rm -f /etc/systemd/system/k3s.service
    systemctl daemon-reload
fi

# 2. Limpeza de Arquivos
echo "Removendo diretórios e configurações residuais..."
rm -rf /etc/rancher/k3s
rm -rf /var/lib/rancher/k3s
rm -rf /var/lib/kubelet
rm -rf ~/.kube
rm -f /usr/local/bin/kubectl
rm -f /usr/local/bin/crictl

# 3. Limpeza de Hosts
echo "Limpando /etc/hosts..."
sed -i '/k3s-control-plane/d' /etc/hosts
sed -i '/k3s-worker/d' /etc/hosts
sed -i '/k3s-storage-nfs/d' /etc/hosts

# 4. Reabilitar Swap (Opcional, mas volta ao estado original)
# Descomenta linhas de swap no fstab
sed -i '/ swap / s/^#//' /etc/fstab

echo -e "\e[32mLimpeza concluída! O nó está pronto para uma nova instalação ou reinicialização.\e[0m"
