#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Instalação OnlyOffice Document Server    ║${NC}"
echo -e "${BLUE}║       com RabbitMQ Externo                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

# Solicitar informações do RabbitMQ
echo -e "${YELLOW}Informações do RabbitMQ (servidor externo):${NC}"
read -p "IP do servidor RabbitMQ: " RABBITMQ_HOST
read -p "Usuário RabbitMQ [onlyoffice]: " RABBITMQ_USER
RABBITMQ_USER=${RABBITMQ_USER:-onlyoffice}
read -sp "Senha do RabbitMQ: " RABBITMQ_PASS
echo
read -p "VHost do RabbitMQ [onlyoffice_vhost]: " RABBITMQ_VHOST
RABBITMQ_VHOST=${RABBITMQ_VHOST:-onlyoffice_vhost}

echo -e "\n${BLUE}Testando conexão com RabbitMQ...${NC}"
if ! nc -zv $RABBITMQ_HOST 5672 2>&1 | grep -q succeeded; then
    echo -e "${RED}ERRO: Não foi possível conectar ao RabbitMQ em ${RABBITMQ_HOST}:5672${NC}"
    echo -e "${YELLOW}Verifique se o RabbitMQ está rodando e se o firewall está liberado.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Conexão com RabbitMQ OK${NC}\n"

# 1. Atualizar sistema
echo -e "${GREEN}[1/9] Atualizando sistema...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release netcat-openbsd

# 2. Instalar PostgreSQL
echo -e "${GREEN}[2/9] Instalando PostgreSQL...${NC}"
sudo apt install -y postgresql postgresql-contrib

# Configurar banco
sudo -u postgres psql -c "CREATE DATABASE onlyoffice;"
sudo -u postgres psql -c "CREATE USER onlyoffice WITH PASSWORD 'OnlyOffice2025!Secure';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE onlyoffice TO onlyoffice;"

# 3. Instalar dependências do OnlyOffice
echo -e "${GREEN}[3/9] Instalando dependências...${NC}"
sudo apt install -y software-properties-common

# 4. Adicionar repositório OnlyOffice
echo -e "${GREEN}[4/9] Adicionando repositório OnlyOffice...${NC}"
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | sudo gpg --dearmor -o /usr/share/keyrings/onlyoffice.gpg

echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list

# 5. Configurar variáveis de ambiente para RabbitMQ ANTES da instalação
echo -e "${GREEN}[5/9] Configurando RabbitMQ externo...${NC}"

# Criar arquivo de configuração para o instalador
sudo mkdir -p /etc/onlyoffice/documentserver
cat > /tmp/rabbitmq-env.conf <<EOF
AMQP_URI=amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:5672/${RABBITMQ_VHOST}
AMQP_TYPE=rabbitmq
EOF

# 6. Instalar OnlyOffice
echo -e "${GREEN}[6/9] Instalando OnlyOffice Document Server...${NC}"
echo -e "${YELLOW}Nota: O instalador pode mostrar avisos sobre RabbitMQ local - isso é normal.${NC}"

# Configurar para não instalar RabbitMQ local
export DS_RABBITMQ_HOST=$RABBITMQ_HOST
export DS_RABBITMQ_USER=$RABBITMQ_USER
export DS_RABBITMQ_PWD=$RABBITMQ_PASS
export DS_RABBITMQ_VHOST=$RABBITMQ_VHOST

sudo apt update
sudo apt install -y onlyoffice-documentserver

# 7. Configurar banco de dados
echo -e "${GREEN}[7/9] Configurando banco de dados...${NC}"
sudo -u postgres psql -d onlyoffice -f /var/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql

# 8. Gerar JWT Secret
echo -e "${GREEN}[8/9] Gerando JWT Secret...${NC}"
JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# 9. Configurar OnlyOffice com RabbitMQ externo
echo -e "${GREEN}[9/9] Configurando OnlyOffice...${NC}"

# Configuração principal
cat > /etc/onlyoffice/documentserver/local.json <<EOF
{
  "services": {
    "CoAuthoring": {
      "sql": {
        "type": "postgres",
        "dbHost": "localhost",
        "dbPort": "5432",
        "dbName": "onlyoffice",
        "dbUser": "onlyoffice",
        "dbPass": "OnlyOffice2025!Secure"
      },
      "secret": {
        "inbox": {
          "string": "$JWT_SECRET"
        },
        "outbox": {
          "string": "$JWT_SECRET"
        },
        "session": {
          "string": "$JWT_SECRET"
        }
      },
      "token": {
        "enable": {
          "request": {
            "inbox": true,
            "outbox": true
          },
          "browser": true
        }
      }
    }
  },
  "rabbitmq": {
    "url": "amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:5672/${RABBITMQ_VHOST}"
  },
  "storage": {
    "fs": {
      "secretString": "$JWT_SECRET"
    }
  }
}
EOF

# Configuração adicional do RabbitMQ
cat > /etc/onlyoffice/documentserver/local-production-linux.json <<EOF
{
  "rabbitmq": {
    "url": "amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:5672/${RABBITMQ_VHOST}",
    "login": "${RABBITMQ_USER}",
    "password": "${RABBITMQ_PASS}",
    "host": "${RABBITMQ_HOST}",
    "port": 5672,
    "vhost": "${RABBITMQ_VHOST}"
  }
}
EOF

# Salvar configurações
cat > /root/onlyoffice_config.txt <<EOF
===========================================
    CONFIGURAÇÃO ONLYOFFICE
===========================================

IP OnlyOffice: 10.10.1.228
IP Nextcloud: 10.10.1.229
IP RabbitMQ: ${RABBITMQ_HOST}

--- JWT Secret ---
${JWT_SECRET}

--- RabbitMQ Connection ---
Host: ${RABBITMQ_HOST}
Port: 5672
User: ${RABBITMQ_USER}
VHost: ${RABBITMQ_VHOST}
URL: amqp://${RABBITMQ_USER}:****@${RABBITMQ_HOST}:5672/${RABBITMQ_VHOST}

--- PostgreSQL (Local) ---
Database: onlyoffice
User: onlyoffice
Password: OnlyOffice2025!Secure

===========================================
EOF

chmod 600 /root/onlyoffice_config.txt

# Parar serviços locais do RabbitMQ se existirem
if systemctl is-active --quiet rabbitmq-server; then
    echo -e "${YELLOW}Parando RabbitMQ local (não necessário)...${NC}"
    sudo systemctl stop rabbitmq-server
    sudo systemctl disable rabbitmq-server
fi

# Reiniciar serviços OnlyOffice
echo -e "${BLUE}Reiniciando serviços OnlyOffice...${NC}"
sudo supervisorctl restart all
sleep 5
sudo systemctl restart nginx

# Verificar status
echo -e "\n${GREEN}=== Verificando instalação ===${NC}"

echo -e "\n${BLUE}Status dos serviços OnlyOffice:${NC}"
sudo supervisorctl status

echo -e "\n${BLUE}Status Nginx:${NC}"
sudo systemctl status nginx --no-pager | grep Active

echo -e "\n${BLUE}Status PostgreSQL:${NC}"
sudo systemctl status postgresql --no-pager | grep Active

echo -e "\n${BLUE}Testando healthcheck:${NC}"
HEALTH=$(curl -s http://10.10.1.228/healthcheck)
if [ "$HEALTH" == "true" ]; then
    echo -e "${GREEN}✓ Healthcheck OK: $HEALTH${NC}"
else
    echo -e "${RED}✗ Healthcheck falhou: $HEALTH${NC}"
fi

echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Instalação Concluída com Sucesso!     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Configurações salvas em: /root/onlyoffice_config.txt${NC}\n"
cat /root/onlyoffice_config.txt

echo -e "\n${YELLOW}PRÓXIMOS PASSOS:${NC}"
echo -e "1. Acesse o Nextcloud: http://10.10.1.229"
echo -e "2. Vá em Apps > Office & text"
echo -e "3. Instale o app 'ONLYOFFICE'"
echo -e "4. Configure em Configurações > ONLYOFFICE:"
echo -e "   ${BLUE}Document Server:${NC} http://10.10.1.228/"
echo -e "   ${BLUE}JWT Secret:${NC} ${JWT_SECRET}"
echo -e "\n${GREEN}Instalação finalizada!${NC}"
