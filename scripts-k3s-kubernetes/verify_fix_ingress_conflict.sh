#!/bin/bash
# Script: fix_ingress_conflict.sh
# Descrição: Desativa Traefik e ServiceLB para permitir uso de Nginx e MetalLB

echo "--- Ajustando configuração do K3s para desativar Traefik e ServiceLB ---"

CONFIG_FILE="/etc/rancher/k3s/config.yaml"
mkdir -p /etc/rancher/k3s

# Verifica se já existe configuração de disable
if grep -q "disable:" "$CONFIG_FILE" 2>/dev/null; then
    echo "Configuração já existente. Verificando itens..."
else
    echo "disable:" >> "$CONFIG_FILE"
fi

# Adiciona traefik se não estiver listado
if ! grep -q "traefik" "$CONFIG_FILE"; then
    echo "  - traefik" >> "$CONFIG_FILE"
    echo "Traefik desativado no config."
fi

# Adiciona servicelb se não estiver listado
if ! grep -q "servicelb" "$CONFIG_FILE"; then
    echo "  - servicelb" >> "$CONFIG_FILE"
    echo "ServiceLB desativado no config."
fi

echo "Reiniciando serviço K3s..."
systemctl restart k3s

echo "Concluído neste nó."