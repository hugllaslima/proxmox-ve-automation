#!/bin/bash

################################################################################
# Script de Correção DEFINITIVA - RabbitMQ OnlyOffice
# Encontra e corrige TODOS os arquivos de configuração
################################################################################

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║   Correção DEFINITIVA - RabbitMQ OnlyOffice               ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado como root (use sudo)${NC}" 
   exit 1
fi

# Dados do RabbitMQ
RABBITMQ_HOST="10.10.1.231"
RABBITMQ_PORT="5672"
RABBITMQ_USER="onlyoffice"
RABBITMQ_PASS="VmCE9TrK70q@TZ&ic#@r"
RABBITMQ_VHOST="onlyoffice_vhost"

echo -e "${YELLOW}Usando configuração:${NC}"
echo -e "  Host: ${CYAN}${RABBITMQ_HOST}:${RABBITMQ_PORT}${NC}"
echo -e "  User: ${CYAN}${RABBITMQ_USER}${NC}"
echo -e "  VHost: ${CYAN}${RABBITMQ_VHOST}${NC}\n"

# Parar TUDO
echo -e "${CYAN}[1/8] Parando TODOS os serviços OnlyOffice...${NC}"
systemctl stop supervisor 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
pkill -9 -f "node.*documentserver" 2>/dev/null || true
pkill -9 -f "docservice" 2>/dev/null || true
pkill -9 -f "converter" 2>/dev/null || true
sleep 5
echo -e "${GREEN}✓ Serviços parados${NC}"

# Encontrar TODOS os arquivos de configuração
echo -e "\n${CYAN}[2/8] Procurando arquivos de configuração...${NC}"
CONFIG_FILES=$(find /etc/onlyoffice /var/www/onlyoffice -name "*.json" 2>/dev/null | grep -E "(local|default|production|config)" | sort)

echo -e "${YELLOW}Arquivos encontrados:${NC}"
echo "$CONFIG_FILES" | while read file; do
    if [ -f "$file" ]; then
        echo -e "  ${CYAN}→${NC} $file"
    fi
done

# Fazer backup
echo -e "\n${CYAN}[3/8] Fazendo backup completo...${NC}"
BACKUP_DIR="/root/onlyoffice_full_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /etc/onlyoffice "$BACKUP_DIR/" 2>/dev/null || true
cp -r /var/www/onlyoffice/documentserver/npm/ds-*/config "$BACKUP_DIR/npm_config" 2>/dev/null || true
echo -e "${GREEN}✓ Backup em: $BACKUP_DIR${NC}"

# Obter JWT e senha PostgreSQL
echo -e "\n${CYAN}[4/8] Recuperando configurações existentes...${NC}"
JWT_SECRET=$(grep -r "string" /etc/onlyoffice/documentserver/*.json 2>/dev/null | grep -oP ':\s*"\K[^"]+' | head -1)
POSTGRES_PASS=$(grep -r "dbPass" /etc/onlyoffice/documentserver/*.json 2>/dev/null | grep -oP ':\s*"\K[^"]+' | head -1)

if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    echo -e "${YELLOW}⚠ JWT_SECRET gerado: ${JWT_SECRET}${NC}"
else
    echo -e "${GREEN}✓ JWT_SECRET recuperado${NC}"
fi

if [ -z "$POSTGRES_PASS" ]; then
    echo -e "${RED}✗ Senha PostgreSQL não encontrada!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Senha PostgreSQL recuperada${NC}"
fi

# Remover TODOS os arquivos de configuração antigos
echo -e "\n${CYAN}[5/8] Removendo configurações antigas...${NC}"
rm -f /etc/onlyoffice/documentserver/*.json
rm -f /etc/onlyoffice/documentserver/*.json.bak
echo -e "${GREEN}✓ Configurações antigas removidas${NC}"

# Criar configuração ÚNICA e DEFINITIVA
echo -e "\n${CYAN}[6/8] Criando configuração definitiva...${NC}"

# Arquivo ÚNICO de configuração
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
        "dbPass": "${POSTGRES_PASS}"
      },
      "secret": {
        "inbox": {
          "string": "${JWT_SECRET}"
        },
        "outbox": {
          "string": "${JWT_SECRET}"
        },
        "session": {
          "string": "${JWT_SECRET}"
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
    "url": "amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}/${RABBITMQ_VHOST}",
    "type": "rabbitmq",
    "host": "${RABBITMQ_HOST}",
    "port": ${RABBITMQ_PORT},
    "login": "${RABBITMQ_USER}",
    "password": "${RABBITMQ_PASS}",
    "vhost": "${RABBITMQ_VHOST}"
  },
  "storage": {
    "fs": {
      "secretString": "${JWT_SECRET}"
    }
  }
}
EOF

# Criar link simbólico para garantir que seja lido
ln -sf /etc/onlyoffice/documentserver/local.json /etc/onlyoffice/documentserver/production.json 2>/dev/null || true
ln -sf /etc/onlyoffice/documentserver/local.json /etc/onlyoffice/documentserver/default.json 2>/dev/null || true

# Ajustar permissões
chown -R ds:ds /etc/onlyoffice/documentserver/ 2>/dev/null || true
chmod 600 /etc/onlyoffice/documentserver/*.json

echo -e "${GREEN}✓ Configuração criada${NC}"

# Configurar variáveis de ambiente do sistema
echo -e "\n${CYAN}[7/8] Configurando variáveis de ambiente...${NC}"

# Criar arquivo de environment para o OnlyOffice
cat > /etc/default/onlyoffice-documentserver <<EOF
DS_RABBITMQ_HOST=${RABBITMQ_HOST}
DS_RABBITMQ_PORT=${RABBITMQ_PORT}
DS_RABBITMQ_USER=${RABBITMQ_USER}
DS_RABBITMQ_PWD=${RABBITMQ_PASS}
DS_RABBITMQ_VHOST=${RABBITMQ_VHOST}
EOF

# Adicionar ao supervisor config se existir
if [ -d "/etc/supervisor/conf.d" ]; then
    # Procurar arquivos do OnlyOffice no supervisor
    for conf in /etc/supervisor/conf.d/ds-*.conf; do
        if [ -f "$conf" ]; then
            # Adicionar variáveis de ambiente
            if ! grep -q "DS_RABBITMQ_HOST" "$conf"; then
                sed -i "/|$program:/a environment=DS_RABBITMQ_HOST=\"${RABBITMQ_HOST}\",DS_RABBITMQ_PORT=\"${RABBITMQ_PORT}\",DS_RABBITMQ_USER=\"${RABBITMQ_USER}\",DS_RABBITMQ_PWD=\"${RABBITMQ_PASS}\",DS_RABBITMQ_VHOST=\"${RABBITMQ_VHOST}\"" "$conf"
            fi
        fi
    done
fi

echo -e "${GREEN}✓ Variáveis de ambiente configuradas${NC}"

# Reiniciar TUDO
echo -e "\n${CYAN}[8/8] Reiniciando serviços...${NC}"

# Iniciar PostgreSQL
systemctl start postgresql
sleep 3

# Iniciar Supervisor
systemctl start supervisor
sleep 5

# Recarregar configurações do supervisor
supervisorctl reread 2>/dev/null
supervisorctl update 2>/dev/null
supervisorctl restart all 2>/dev/null

sleep 10

# Iniciar Nginx
systemctl start nginx

echo -e "${GREEN}✓ Serviços reiniciados${NC}"

# Verificação final
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}            Verificação Final${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Aguardando 30 segundos para inicialização...${NC}"
sleep 30

echo -e "\n${YELLOW}Status dos serviços:${NC}"
supervisorctl status 2>/dev/null || echo "Supervisor não disponível"

echo -e "\n${YELLOW}Últimas 15 linhas do log:${NC}"
tail -15 /var/log/onlyoffice/documentserver/docservice/out.log

echo -e "\n${YELLOW}Testando healthcheck:${NC}"
HEALTH=$(curl -s http://localhost/healthcheck 2>/dev/null)
if [ "$HEALTH" == "true" ]; then
    echo -e "${GREEN}✓✓✓ SUCESSO! OnlyOffice está funcionando! ✓✓✓${NC}"
else
    echo -e "${RED}✗ Healthcheck falhou${NC}"
    echo -e "${YELLOW}Verifique os logs:${NC}"
    echo -e "  ${CYAN}sudo tail -f /var/log/onlyoffice/documentserver/docservice/out.log${NC}"
fi

echo -e "\n${CYAN}Configuração aplicada:${NC}"
cat /etc/onlyoffice/documentserver/local.json | grep -A 8 "rabbitmq"

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Correção Concluída!                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Se ainda houver erro 502:${NC}"
echo -e "1. Verifique o RabbitMQ: ${CYAN}sudo rabbitmqctl list_vhosts${NC} (no servidor 10.10.1.231)"
echo -e "2. Verifique permissões: ${CYAN}sudo rabbitmqctl list_user_permissions onlyoffice${NC}"
echo -e "3. Teste conexão: ${CYAN}telnet 10.10.1.231 5672${NC}"

echo -e "\n${CYAN}Backup salvo em:${NC} $BACKUP_DIR"
