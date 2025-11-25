#!/bin/bash

################################################################################
# Script: install_onlyoffice_server_v2.sh (RECOMENDADO)
#
# Descrição:
#   Este script instala e configura o OnlyOffice Document Server em um sistema
#   Ubuntu Server 24.04 LTS. Ele foi projetado para integrar o OnlyOffice com
#   um servidor RabbitMQ externo e um Nextcloud, utilizando um método de
#   instalação mais estável e robusto que a versão anterior. O script 
#   é interativo e solicita todas as informações necessárias.
#
# Autor:
#   Hugllas R. S. Lima <hugllas.s.lima@gmail.com>
#
# Data de Criação: 2024-08-01
#
# Versão: 2.2
#
# Licença:
#   Este script é distribuído sob a licença GPL-3.0.
#   Veja o arquivo LICENSE para mais detalhes.
#
# Repositório:
#   https://github.com/hugllaslima/proxmox-ve-automation
#
# Uso:
#   sudo ./install_onlyoffice_server_v2.sh
#
# Pré-requisitos:
#   - Sistema Operacional: Ubuntu Server 24.04 LTS.
#   - Acesso root (sudo).
#   - Conexão com a internet para download de pacotes.
#   - Um servidor RabbitMQ externo já configurado.
#
# Notas:
#   - Esta é a versão recomendada para novas instalações.
#   - O script é interativo e guia o usuário em cada etapa.
#   - As configurações são validadas para garantir a integração correta.
#   - Cada informação inserida requer confirmação do usuário.
#
################################################################################

set -e  # Parar execução em caso de erro

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para exibir cabeçalho
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                            ║${NC}"
    echo -e "${BLUE}║           Instalação OnlyOffice Document Server            ║${NC}"
    echo -e "${BLUE}║                 Ubuntu Server 24.04 LTS                    ║${NC}"
    echo -e "${BLUE}║                                                            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

# Função para gerar senha/token aleatório
generate_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
}

# Função para validar IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Função para perguntar sim/não
ask_yes_no() {
    local prompt=$1
    local response
    while true; do
        read -p "$prompt (s/n): " response
        case $response in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor, responda 's' ou 'n'.";;
        esac
    done
}

# Função para confirmar informação
confirm_input() {
    local label=$1
    local value=$2
    local is_password=$3

    if [ "$is_password" == "true" ]; then
        echo -e "${YELLOW}${label}:${NC} ********"
    else
        echo -e "${YELLOW}${label}:${NC} ${CYAN}${value}${NC}"
    fi

    if ask_yes_no "Confirma esta informação?"; then
        return 0
    else
        return 1
    fi
}

# Função para coletar e confirmar IP
get_confirmed_ip() {
    local prompt=$1
    local example=$2
    local ip

    while true; do
        read -p "$prompt: " ip

        if validate_ip "$ip"; then
            echo -e "${GREEN}✓ IP válido: ${ip}${NC}"
            if confirm_input "IP informado" "$ip" "false"; then
                echo "$ip"
                return 0
            else
                echo -e "${YELLOW}Vamos tentar novamente...${NC}\n"
            fi
        else
            echo -e "${RED}✗ IP inválido. Por favor, digite um IP válido (ex: ${example})${NC}"
        fi
    done
}

# Função para coletar e confirmar texto
get_confirmed_text() {
    local prompt=$1
    local default=$2
    local min_length=$3
    local value

    while true; do
        if [ -n "$default" ]; then
            read -p "$prompt [$default]: " value
            value=${value:-$default}
        else
            read -p "$prompt: " value
        fi

        if [ -n "$min_length" ] && [ ${#value} -lt $min_length ]; then
            echo -e "${RED}✗ Valor muito curto. Mínimo: ${min_length} caracteres.${NC}"
            continue
        fi

        if [ -n "$value" ]; then
            if confirm_input "Valor informado" "$value" "false"; then
                echo "$value"
                return 0
            else
                echo -e "${YELLOW}Vamos tentar novamente...${NC}\n"
            fi
        else
            echo -e "${RED}✗ Este campo não pode estar vazio.${NC}"
        fi
    done
}

# Função para coletar e confirmar senha
get_confirmed_password() {
    local prompt=$1
    local password
    local password_confirm

    while true; do
        read -sp "$prompt: " password
        echo

        if [ -z "$password" ]; then
            echo -e "${RED}✗ A senha não pode estar vazia.${NC}"
            continue
        fi

        read -sp "Confirme a senha: " password_confirm
        echo

        if [ "$password" != "$password_confirm" ]; then
            echo -e "${RED}✗ As senhas não conferem. Tente novamente.${NC}"
            continue
        fi

        if confirm_input "Senha" "$password" "true"; then
            echo "$password"
            return 0
        else
            echo -e "${YELLOW}Vamos tentar novamente...${NC}\n"
        fi
    done
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado como root (use sudo)${NC}" 
   exit 1
fi

print_header

echo -e "${CYAN}Este script irá instalar e configurar o OnlyOffice Document Server.${NC}"
echo -e "${CYAN}Você será guiado através de perguntas interativas.${NC}"
echo -e "${CYAN}Cada informação inserida precisará ser confirmada.${NC}\n"

# ============================================================================
# COLETA DE INFORMAÇÕES - SERVIDOR ONLYOFFICE
# ============================================================================

echo -e "${YELLOW}═══ Configuração do Servidor OnlyOffice ═══${NC}\n"

ONLYOFFICE_IP=$(get_confirmed_ip "Digite o IP deste servidor OnlyOffice" "10.10.1.228")
echo

NEXTCLOUD_IP=$(get_confirmed_ip "Digite o IP do servidor Nextcloud" "10.10.1.229")
echo

# ============================================================================
# COLETA DE INFORMAÇÕES - RABBITMQ
# ============================================================================

echo -e "${YELLOW}═══ Configuração do RabbitMQ (Servidor Externo) ═══${NC}"
echo -e "${CYAN}Informe os dados do servidor RabbitMQ dedicado.${NC}\n"

RABBITMQ_HOST=$(get_confirmed_ip "IP do servidor RabbitMQ" "10.10.1.231")
echo

RABBITMQ_PORT=$(get_confirmed_text "Porta do RabbitMQ" "5672" "")
echo

RABBITMQ_USER=$(get_confirmed_text "Usuário do RabbitMQ" "" "")
echo

RABBITMQ_PASS=$(get_confirmed_password "Senha do RabbitMQ")
echo

RABBITMQ_VHOST=$(get_confirmed_text "VHost do RabbitMQ" "onlyoffice_vhost" "")
echo

# ============================================================================
# TESTAR CONEXÃO COM RABBITMQ
# ============================================================================

echo -e "${BLUE}Testando conexão com RabbitMQ...${NC}"

if ! command -v nc &> /dev/null; then
    apt install -y netcat-openbsd >/dev/null 2>&1
fi

if nc -zv $RABBITMQ_HOST $RABBITMQ_PORT 2>&1 | grep -q succeeded; then
    echo -e "${GREEN}✓ Conexão com RabbitMQ OK${NC}\n"
else
    echo -e "${RED}✗ ERRO: Não foi possível conectar ao RabbitMQ em ${RABBITMQ_HOST}:${RABBITMQ_PORT}${NC}"
    echo -e "${YELLOW}Verifique se:${NC}"
    echo -e "  1. O RabbitMQ está rodando"
    echo -e "  2. O firewall está liberado"
    echo -e "  3. O IP e porta estão corretos"

    if ! ask_yes_no "Deseja continuar mesmo assim?"; then
        exit 1
    fi
    echo
fi

# ============================================================================
# CONFIGURAÇÃO DO POSTGRESQL
# ============================================================================

echo -e "${YELLOW}═══ Configuração do PostgreSQL (Local) ═══${NC}"
echo -e "${CYAN}O OnlyOffice usa PostgreSQL localmente para armazenar metadados.${NC}\n"

if ask_yes_no "Deseja gerar uma senha aleatória para o PostgreSQL?"; then
    POSTGRES_PASS=$(generate_password)
    echo -e "${GREEN}Senha gerada automaticamente.${NC}"
    echo -e "${YELLOW}Senha gerada:${NC} ${POSTGRES_PASS}"
    if ! ask_yes_no "Confirma o uso desta senha?"; then
        echo -e "${YELLOW}Vamos definir uma senha manualmente...${NC}\n"
        POSTGRES_PASS=$(get_confirmed_password "Digite a senha para o usuário PostgreSQL 'onlyoffice'")
    fi
else
    POSTGRES_PASS=$(get_confirmed_password "Digite a senha para o usuário PostgreSQL 'onlyoffice'")
fi
echo

# ============================================================================
# JWT SECRET
# ============================================================================

echo -e "${YELLOW}═══ JWT Secret (Segurança) ═══${NC}"
echo -e "${CYAN}O JWT Secret é usado para autenticação entre Nextcloud e OnlyOffice.${NC}\n"

if ask_yes_no "Deseja gerar um JWT Secret automaticamente?"; then
    JWT_SECRET=$(generate_password)
    echo -e "${GREEN}JWT Secret gerado automaticamente.${NC}"
    echo -e "${YELLOW}JWT Secret:${NC} ${JWT_SECRET}"
    if ! ask_yes_no "Confirma o uso deste JWT Secret?"; then
        echo -e "${YELLOW}Vamos definir um JWT Secret manualmente...${NC}\n"
        JWT_SECRET=$(get_confirmed_text "Digite o JWT Secret" "" "20")
    fi
else
    JWT_SECRET=$(get_confirmed_text "Digite o JWT Secret" "" "20")
fi
echo

# ============================================================================
# CONFIRMAÇÃO FINAL
# ============================================================================

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}           RESUMO FINAL DA CONFIGURAÇÃO${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${BLUE}Servidores:${NC}"
echo -e "  ${CYAN}→${NC} IP OnlyOffice: ${GREEN}${ONLYOFFICE_IP}${NC}"
echo -e "  ${CYAN}→${NC} IP Nextcloud: ${GREEN}${NEXTCLOUD_IP}${NC}"
echo

echo -e "${BLUE}RabbitMQ:${NC}"
echo -e "  ${CYAN}→${NC} Host: ${GREEN}${RABBITMQ_HOST}:${RABBITMQ_PORT}${NC}"
echo -e "  ${CYAN}→${NC} User: ${GREEN}${RABBITMQ_USER}${NC}"
echo -e "  ${CYAN}→${NC} VHost: ${GREEN}${RABBITMQ_VHOST}${NC}"
echo

echo -e "${BLUE}PostgreSQL:${NC}"
echo -e "  ${CYAN}→${NC} User: ${GREEN}onlyoffice${NC}"
echo -e "  ${CYAN}→${NC} Password: ${GREEN}********${NC}"
echo

echo -e "${BLUE}Segurança:${NC}"
echo -e "  ${CYAN}→${NC} JWT Secret: ${GREEN}${JWT_SECRET:0:10}...${NC} (${#JWT_SECRET} caracteres)"
echo

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}\n"

if ! ask_yes_no "Confirma TODAS as configurações acima e deseja iniciar a instalação?"; then
    echo -e "${YELLOW}Instalação cancelada pelo usuário.${NC}"
    exit 0
fi

# ============================================================================
# INSTALAÇÃO
# ============================================================================

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║                    Iniciando Instalação...                 ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Atualizar sistema
echo -e "${GREEN}[1/10] Atualizando sistema...${NC}"
apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release netcat-openbsd software-properties-common

# 2. Instalar PostgreSQL
echo -e "${GREEN}[2/10] Instalando PostgreSQL...${NC}"
apt install -y postgresql postgresql-contrib

# Aguardar PostgreSQL iniciar
sleep 3

# Configurar banco
sudo -u postgres psql -c "CREATE DATABASE onlyoffice;" 2>/dev/null || echo "  Database já existe"
sudo -u postgres psql -c "CREATE USER onlyoffice WITH PASSWORD '${POSTGRES_PASS}';" 2>/dev/null || echo "  Usuário já existe"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE onlyoffice TO onlyoffice;"

# 3. Instalar Erlang (necessário para comunicação com RabbitMQ)
echo -e "${GREEN}[3/10] Instalando Erlang...${NC}"
apt install -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
               erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
               erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools \
               erlang-tftp erlang-tools erlang-xmerl

# 4. Adicionar chave GPG do OnlyOffice
echo -e "${GREEN}[4/10] Adicionando chave GPG do OnlyOffice...${NC}"
mkdir -p /usr/share/keyrings

if ! curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | gpg --dearmor -o /usr/share/keyrings/onlyoffice.gpg 2>/dev/null; then
    echo -e "${YELLOW}Método 1 falhou, tentando alternativo...${NC}"
    gpg --keyserver keyserver.ubuntu.com --recv-keys CB2DE8E5
    gpg --export CB2DE8E5 > /usr/share/keyrings/onlyoffice.gpg
fi

# 5. Adicionar repositório OnlyOffice
echo -e "${GREEN}[5/10] Adicionando repositório OnlyOffice...${NC}"
echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | tee /etc/apt/sources.list.d/onlyoffice.list

# 6. Preparar variáveis de ambiente
echo -e "${GREEN}[6/10] Preparando ambiente...${NC}"
export DS_RABBITMQ_HOST=$RABBITMQ_HOST
export DS_RABBITMQ_USER=$RABBITMQ_USER
export DS_RABBITMQ_PWD=$RABBITMQ_PASS
export DS_RABBITMQ_VHOST=$RABBITMQ_VHOST

# 7. Instalar OnlyOffice
echo -e "${GREEN}[7/10] Instalando OnlyOffice Document Server...${NC}"
echo -e "${YELLOW}Nota: Avisos sobre RabbitMQ local são normais (estamos usando externo).${NC}"

apt update
DEBIAN_FRONTEND=noninteractive apt install -y onlyoffice-documentserver

# 8. Configurar banco de dados
echo -e "${GREEN}[8/10] Configurando banco de dados...${NC}"
sudo -u postgres psql -d onlyoffice -f /var/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql 2>/dev/null || echo "  Schema já aplicado"

# 9. Parar RabbitMQ local se existir
echo -e "${GREEN}[9/10] Desabilitando RabbitMQ local...${NC}"
if systemctl is-active --quiet rabbitmq-server; then
    systemctl stop rabbitmq-server
    systemctl disable rabbitmq-server
fi

# 10. Configurar OnlyOffice
echo -e "${GREEN}[10/10] Configurando OnlyOffice...${NC}"

# Criar diretório de configuração
mkdir -p /etc/onlyoffice/documentserver

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
    "url": "amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}/${RABBITMQ_VHOST}"
  },
  "storage": {
    "fs": {
      "secretString": "${JWT_SECRET}"
    }
  }
}
EOF

# Configuração adicional
cat > /etc/onlyoffice/documentserver/local-production-linux.json <<EOF
{
  "rabbitmq": {
    "url": "amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}/${RABBITMQ_VHOST}",
    "login": "${RABBITMQ_USER}",
    "password": "${RABBITMQ_PASS}",
    "host": "${RABBITMQ_HOST}",
    "port": ${RABBITMQ_PORT},
    "vhost": "${RABBITMQ_VHOST}"
  }
}
EOF

# Reiniciar serviços
echo -e "${BLUE}Reiniciando serviços OnlyOffice...${NC}"
supervisorctl restart all
sleep 5
systemctl restart nginx

# ============================================================================
# SALVAR CONFIGURAÇÕES
# ============================================================================

CONFIG_FILE="/root/onlyoffice_config_$(date +%Y%m%d_%H%M%S).txt"

cat > "$CONFIG_FILE" <<EOF
═══════════════════════════════════════════════════════════════
    CONFIGURAÇÃO ONLYOFFICE DOCUMENT SERVER
═══════════════════════════════════════════════════════════════

Data de Instalação: $(date '+%d/%m/%Y %H:%M:%S')

───────────────────────────────────────────────────────────────
SERVIDORES
───────────────────────────────────────────────────────────────
OnlyOffice IP: ${ONLYOFFICE_IP}
Nextcloud IP: ${NEXTCLOUD_IP}
RabbitMQ IP: ${RABBITMQ_HOST}:${RABBITMQ_PORT}

───────────────────────────────────────────────────────────────
JWT SECRET (use no Nextcloud)
───────────────────────────────────────────────────────────────
${JWT_SECRET}

───────────────────────────────────────────────────────────────
RABBITMQ CONNECTION
───────────────────────────────────────────────────────────────
Host: ${RABBITMQ_HOST}
Port: ${RABBITMQ_PORT}
User: ${RABBITMQ_USER}
VHost: ${RABBITMQ_VHOST}
URL: amqp://${RABBITMQ_USER}:****@${RABBITMQ_HOST}:${RABBITMQ_PORT}/${RABBITMQ_VHOST}

───────────────────────────────────────────────────────────────
POSTGRESQL (Local)
───────────────────────────────────────────────────────────────
Database: onlyoffice
User: onlyoffice
Password: ${POSTGRES_PASS}

───────────────────────────────────────────────────────────────
CONFIGURAÇÃO NO NEXTCLOUD
───────────────────────────────────────────────────────────────
1. Instale o app "ONLYOFFICE" no Nextcloud
2. Vá em: Configurações > ONLYOFFICE
3. Configure:
   Document Server: http://${ONLYOFFICE_IP}/
   JWT Secret: ${JWT_SECRET}

═══════════════════════════════════════════════════════════════
IMPORTANTE: Guarde este arquivo em local seguro!
═══════════════════════════════════════════════════════════════
EOF

chmod 600 "$CONFIG_FILE"

# ============================================================================
# VERIFICAÇÃO FINAL
# ============================================================================

echo -e "\n${GREEN}═══ Verificando instalação ═══${NC}"

echo -e "\n${BLUE}Status dos serviços OnlyOffice:${NC}"
supervisorctl status

echo -e "\n${BLUE}Status Nginx:${NC}"
systemctl status nginx --no-pager | grep Active

echo -e "\n${BLUE}Status PostgreSQL:${NC}"
systemctl status postgresql --no-pager | grep Active

echo -e "\n${BLUE}Testando healthcheck:${NC}"
sleep 3
HEALTH=$(curl -s http://${ONLYOFFICE_IP}/healthcheck)
if [ "$HEALTH" == "true" ]; then
    echo -e "${GREEN}✓ Healthcheck OK: $HEALTH${NC}"
else
    echo -e "${RED}✗ Healthcheck falhou: $HEALTH${NC}"
    echo -e "${YELLOW}Aguarde alguns segundos e teste novamente com:${NC}"
    echo -e "  curl http://${ONLYOFFICE_IP}/healthcheck"
fi

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║            Instalação Concluída com Sucesso! ✓             ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}Configurações salvas em:${NC} ${CONFIG_FILE}\n"
cat "$CONFIG_FILE"

echo -e "\n${YELLOW}═══ PRÓXIMOS PASSOS ═══${NC}"
echo -e "1. ${BLUE}Acesse o Nextcloud:${NC} http://${NEXTCLOUD_IP}"
echo -e "2. ${BLUE}Vá em:${NC} Apps > Office & text"
echo -e "3. ${BLUE}Instale o app:${NC} ONLYOFFICE"
echo -e "4. ${BLUE}Configure em:${NC} Configurações > ONLYOFFICE"
echo -e "   ${CYAN}Document Server:${NC} http://${ONLYOFFICE_IP}/"
echo -e "   ${CYAN}JWT Secret:${NC} (conforme arquivo de configuração)"

echo -e "\n${YELLOW}═══ TROUBLESHOOTING ═══${NC}"
echo -e "Ver logs: ${CYAN}sudo tail -f /var/log/onlyoffice/documentserver/docservice/out.log${NC}"
echo -e "Reiniciar: ${CYAN}sudo supervisorctl restart all${NC}"
echo -e "Status: ${CYAN}sudo supervisorctl status${NC}"

echo -e "\n${GREEN}Instalação finalizada!${NC}\n"
