#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Instalação RabbitMQ Server (Dedicado)    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

# Solicitar IP do servidor
read -p "Digite o IP deste servidor RabbitMQ (ex: 10.10.1.230): " RABBITMQ_IP
echo -e "${BLUE}IP configurado: ${RABBITMQ_IP}${NC}\n"

# 1. Atualizar sistema
echo -e "${GREEN}[1/6] Atualizando sistema...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 2. Instalar Erlang (dependência do RabbitMQ)
echo -e "${GREEN}[2/6] Instalando Erlang...${NC}"
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/rabbitmq-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list

# 3. Instalar RabbitMQ Server
echo -e "${GREEN}[3/6] Instalando RabbitMQ Server...${NC}"
echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/rabbitmq.list

sudo apt update
sudo apt install -y rabbitmq-server

# 4. Habilitar e iniciar serviço
echo -e "${GREEN}[4/6] Habilitando serviços...${NC}"
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

# Aguardar serviço iniciar
sleep 5

# 5. Habilitar Management Plugin (Interface Web)
echo -e "${GREEN}[5/6] Habilitando Management Plugin...${NC}"
sudo rabbitmq-plugins enable rabbitmq_management

# 6. Criar usuário para OnlyOffice
echo -e "${GREEN}[6/6] Configurando usuários e permissões...${NC}"

# Gerar senha forte
RABBITMQ_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%' | fold -w 24 | head -n 1)

# Criar usuário admin
sudo rabbitmqctl add_user admin "Admin@RabbitMQ2025"
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

# Criar usuário específico para OnlyOffice
sudo rabbitmqctl add_user onlyoffice "$RABBITMQ_PASS"
sudo rabbitmqctl set_permissions -p / onlyoffice ".*" ".*" ".*"

# Criar vhost para OnlyOffice (opcional, mas recomendado)
sudo rabbitmqctl add_vhost onlyoffice_vhost
sudo rabbitmqctl set_permissions -p onlyoffice_vhost onlyoffice ".*" ".*" ".*"

# Salvar credenciais
cat > /root/rabbitmq_credentials.txt <<EOF
===========================================
    CREDENCIAIS RABBITMQ
===========================================

IP do Servidor: ${RABBITMQ_IP}
Porta AMQP: 5672
Porta Management: 15672

--- Usuário Administrador ---
Usuário: admin
Senha: Admin@RabbitMQ2025

--- Usuário OnlyOffice ---
Usuário: onlyoffice
Senha: ${RABBITMQ_PASS}
VHost: onlyoffice_vhost

--- URLs de Acesso ---
Management Web: http://${RABBITMQ_IP}:15672
AMQP URL: amqp://onlyoffice:${RABBITMQ_PASS}@${RABBITMQ_IP}:5672/onlyoffice_vhost

===========================================
EOF

chmod 600 /root/rabbitmq_credentials.txt

# Configurar firewall (se UFW estiver ativo)
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Configurando firewall...${NC}"
    sudo ufw allow 5672/tcp comment 'RabbitMQ AMQP'
    sudo ufw allow 15672/tcp comment 'RabbitMQ Management'
fi

# Verificar status
echo -e "\n${GREEN}=== Verificando instalação ===${NC}"
sudo systemctl status rabbitmq-server --no-pager | grep Active

echo -e "\n${BLUE}Testando conectividade:${NC}"
sudo rabbitmqctl status | grep "RabbitMQ version"

echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Instalação Concluída com Sucesso!     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Credenciais salvas em: /root/rabbitmq_credentials.txt${NC}\n"
cat /root/rabbitmq_credentials.txt

echo -e "\n${YELLOW}IMPORTANTE:${NC}"
echo -e "1. Anote as credenciais acima"
echo -e "2. Acesse o Management: http://${RABBITMQ_IP}:15672"
echo -e "3. Use estas credenciais na instalação do OnlyOffice"
echo -e "\n${BLUE}Pressione ENTER para continuar...${NC}"
read
