#!/bin/bash

################################################################################
# Script: cleanup_rabbit_mq.sh
#
# Descrição:
#   Este script realiza uma limpeza completa de instalações anteriores ou
#   com falha do RabbitMQ Server. Ele remove pacotes, diretórios de dados,
#   logs, configurações, usuários e repositórios associados ao RabbitMQ e Erlang.
#   É ideal para preparar um sistema para uma nova instalação limpa.
#
# Autor:
#   Hugllas R. S. Lima <hugllas.s.lima@gmail.com>
#
# Data de Criação: 2024-08-01
#
# Versão: 1.0
#
# Licença:
#   Este script é distribuído sob a licença GPL-3.0.
#   Veja o arquivo LICENSE para mais detalhes.
#
# Repositório:
#   https://github.com/hugllaslima/proxmox-ve-automation
#
# Uso:
#   sudo ./cleanup_rabbit_mq.sh
#
# Pré-requisitos:
#   - Acesso root (sudo).
#   - O script deve ser executado no servidor onde a limpeza é necessária.
#
# Notas:
#   - Este script é destrutivo e removerá todos os dados do RabbitMQ.
#   - Use com cuidado e apenas quando tiver certeza de que deseja apagar
#     completamente a instalação existente.
#
################################################################################

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                                                            ║${NC}"
echo -e "${YELLOW}║          Script de Limpeza - Instalação RabbitMQ           ║${NC}"
echo -e "${YELLOW}║                                                            ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado como root (use sudo)${NC}" 
   exit 1
fi

echo -e "${CYAN}Este script irá remover completamente o RabbitMQ e suas dependências.${NC}"
echo -e "${RED}ATENÇÃO: Esta ação não pode ser desfeita!${NC}\n"

read -p "Deseja continuar? (digite 'SIM' para confirmar): " CONFIRM

if [ "$CONFIRM" != "SIM" ]; then
    echo -e "${YELLOW}Limpeza cancelada.${NC}"
    exit 0
fi

echo -e "\n${GREEN}Iniciando limpeza...${NC}\n"

# 1. Parar serviços
echo -e "${BLUE}[1/8] Parando serviços RabbitMQ...${NC}"
systemctl stop rabbitmq-server 2>/dev/null || true
systemctl disable rabbitmq-server 2>/dev/null || true

# 2. Remover pacotes RabbitMQ
echo -e "${BLUE}[2/8] Removendo pacotes RabbitMQ...${NC}"
apt remove --purge -y rabbitmq-server 2>/dev/null || true
apt autoremove -y

# 3. Remover Erlang (opcional - comente se quiser manter)
echo -e "${BLUE}[3/8] Removendo Erlang...${NC}"
apt remove --purge -y erlang* 2>/dev/null || true

# 4. Remover diretórios de dados
echo -e "${BLUE}[4/8] Removendo diretórios de dados...${NC}"
rm -rf /var/lib/rabbitmq
rm -rf /var/log/rabbitmq
rm -rf /etc/rabbitmq

# 5. Remover usuário e grupo
echo -e "${BLUE}[5/8] Removendo usuário e grupo...${NC}"
userdel -r rabbitmq 2>/dev/null || true
groupdel rabbitmq 2>/dev/null || true

# 6. Remover repositórios
echo -e "${BLUE}[6/8] Removendo repositórios...${NC}"
rm -f /etc/apt/sources.list.d/rabbitmq.list
rm -f /etc/apt/sources.list.d/erlang.list

# 7. Remover chaves GPG
echo -e "${BLUE}[7/8] Removendo chaves GPG...${NC}"
rm -f /usr/share/keyrings/rabbitmq-archive-keyring.gpg
rm -f /usr/share/keyrings/erlang-solutions-archive-keyring.gpg
rm -f /usr/share/keyrings/com.rabbitmq.team.gpg

# 8. Limpar cache do apt
echo -e "${BLUE}[8/8] Limpando cache do apt...${NC}"
apt clean
apt update

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║              Limpeza Concluída com Sucesso! ✓              ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}O sistema está limpo e pronto para uma nova instalação.${NC}"
echo -e "${YELLOW}Próximo passo: Execute o script de instalação corrigido.${NC}\n"
