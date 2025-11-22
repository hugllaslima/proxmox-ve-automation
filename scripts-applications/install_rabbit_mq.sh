#!/bin/bash

################################################################################
# Script de Instalação do RabbitMQ Server
# Versão: 2.0
# Compatível com: Ubuntu Server 24.04 LTS
# Uso: sudo ./install_rabbit_mq.sh
#
# Este script instala e configura o RabbitMQ Server de forma interativa
# Ideal para ambientes com múltiplos serviços que necessitam de message broker
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
    echo -e "${BLUE}║            Instalação RabbitMQ Server (Dedicado)           ║${NC}"
    echo -e "${BLUE}║                  Ubuntu Server 24.04 LTS                   ║${NC}"
    echo -e "${BLUE}║                                                            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

# Função para gerar senha aleatória
generate_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*' | fold -w 24 | head -n 1
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

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado como root (use sudo)${NC}" 
   exit 1
fi

print_header

echo -e "${CYAN}Este script irá instalar e configurar o RabbitMQ Server.${NC}"
echo -e "${CYAN}Você será guiado através de perguntas interativas.${NC}\n"

# ============================================================================
# COLETA DE INFORMAÇÕES
# ============================================================================

echo -e "${YELLOW}═══ Configuração do Servidor ═══${NC}\n"

# IP do servidor
while true; do
    read -p "Digite o IP deste servidor RabbitMQ: " RABBITMQ_IP
    if validate_ip "$RABBITMQ_IP"; then
        echo -e "${GREEN}✓ IP válido: ${RABBITMQ_IP}${NC}\n"
        break
    else
        echo -e "${RED}✗ IP inválido. Por favor, digite um IP válido (ex: 10.10.1.230)${NC}"
    fi
done

# ============================================================================
# USUÁRIO ADMINISTRADOR
# ============================================================================

echo -e "${YELLOW}═══ Usuário Administrador ═══${NC}"
echo -e "${CYAN}Este usuário terá acesso total ao RabbitMQ Management.${NC}\n"

read -p "Nome do usuário administrador [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

if ask_yes_no "Deseja gerar uma senha aleatória para o admin?"; then
    ADMIN_PASS=$(generate_password)
    echo -e "${GREEN}Senha gerada automaticamente.${NC}"
else
    while true; do
        read -sp "Digite a senha para o usuário admin: " ADMIN_PASS
        echo
        read -sp "Confirme a senha: " ADMIN_PASS_CONFIRM
        echo
        if [ "$ADMIN_PASS" == "$ADMIN_PASS_CONFIRM" ]; then
            break
        else
            echo -e "${RED}As senhas não conferem. Tente novamente.${NC}"
        fi
    done
fi

# ============================================================================
# CONFIGURAÇÃO DE SERVIÇOS (VHOSTS E USUÁRIOS)
# ============================================================================

echo -e "\n${YELLOW}═══ Configuração de Serviços ═══${NC}"
echo -e "${CYAN}Você pode criar usuários e vhosts para seus serviços agora.${NC}"
echo -e "${CYAN}Exemplo: OnlyOffice, Home Assistant, etc.${NC}\n"

declare -a SERVICES
declare -a SERVICE_USERS
declare -a SERVICE_PASSES
declare -a SERVICE_VHOSTS

if ask_yes_no "Deseja criar usuários para serviços agora?"; then
    while true; do
        echo -e "\n${BLUE}--- Novo Serviço ---${NC}"

        read -p "Nome do serviço (ex: onlyoffice, homeassistant): " SERVICE_NAME

        read -p "Nome do usuário [$SERVICE_NAME]: " SERVICE_USER
        SERVICE_USER=${SERVICE_USER:-$SERVICE_NAME}

        if ask_yes_no "Deseja gerar uma senha aleatória para $SERVICE_USER?"; then
            SERVICE_PASS=$(generate_password)
            echo -e "${GREEN}Senha gerada automaticamente.${NC}"
        else
            while true; do
                read -sp "Digite a senha para $SERVICE_USER: " SERVICE_PASS
                echo
                read -sp "Confirme a senha: " SERVICE_PASS_CONFIRM
                echo
                if [ "$SERVICE_PASS" == "$SERVICE_PASS_CONFIRM" ]; then
                    break
                else
                    echo -e "${RED}As senhas não conferem. Tente novamente.${NC}"
                fi
            done
        fi

        read -p "Nome do vhost [${SERVICE_NAME}_vhost]: " SERVICE_VHOST
        SERVICE_VHOST=${SERVICE_VHOST:-${SERVICE_NAME}_vhost}

        SERVICES+=("$SERVICE_NAME")
        SERVICE_USERS+=("$SERVICE_USER")
        SERVICE_PASSES+=("$SERVICE_PASS")
        SERVICE_VHOSTS+=("$SERVICE_VHOST")

        echo -e "${GREEN}✓ Serviço '$SERVICE_NAME' adicionado${NC}"

        if ! ask_yes_no "Deseja adicionar outro serviço?"; then
            break
        fi
    done
fi

# ============================================================================
# CONFIRMAÇÃO
# ============================================================================

echo -e "\n${YELLOW}═══ Resumo da Configuração ═══${NC}"
echo -e "${BLUE}IP do Servidor:${NC} $RABBITMQ_IP"
echo -e "${BLUE}Usuário Admin:${NC} $ADMIN_USER"
echo -e "${BLUE}Porta AMQP:${NC} 5672"
echo -e "${BLUE}Porta Management:${NC} 15672"

if [ ${#SERVICES[@]} -gt 0 ]; then
    echo -e "\n${BLUE}Serviços a serem criados:${NC}"
    for i in "${!SERVICES[@]}"; do
        echo -e "  ${CYAN}$((i+1)).${NC} ${SERVICES[$i]} (usuário: ${SERVICE_USERS[$i]}, vhost: ${SERVICE_VHOSTS[$i]})"
    done
fi

echo

if ! ask_yes_no "Confirma a instalação com estas configurações?"; then
    echo -e "${YELLOW}Instalação cancelada pelo usuário.${NC}"
    exit 0
fi

# ============================================================================
# INSTALAÇÃO
# ============================================================================

echo -e "\n${GREEN}Iniciando instalação...${NC}\n"

# 1. Atualizar sistema
echo -e "${GREEN}[1/6] Atualizando sistema...${NC}"
apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 2. Instalar Erlang
echo -e "${GREEN}[2/6] Instalando Erlang...${NC}"
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | gpg --dearmor -o /usr/share/keyrings/rabbitmq-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/rabbitmq.list

# 3. Instalar RabbitMQ Server
echo -e "${GREEN}[3/6] Instalando RabbitMQ Server...${NC}"
echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/rabbitmq.list

apt update
apt install -y rabbitmq-server

# 4. Habilitar e iniciar serviço
echo -e "${GREEN}[4/6] Habilitando serviços...${NC}"
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Aguardar serviço iniciar
sleep 5

# 5. Habilitar Management Plugin
echo -e "${GREEN}[5/6] Habilitando Management Plugin...${NC}"
rabbitmq-plugins enable rabbitmq_management

# 6. Criar usuários e configurações
echo -e "${GREEN}[6/6] Configurando usuários e permissões...${NC}"

# Remover usuário guest (segurança)
rabbitmqctl delete_user guest 2>/dev/null || true

# Criar usuário admin
rabbitmqctl add_user "$ADMIN_USER" "$ADMIN_PASS"
rabbitmqctl set_user_tags "$ADMIN_USER" administrator
rabbitmqctl set_permissions -p / "$ADMIN_USER" ".*" ".*" ".*"

# Criar usuários dos serviços
for i in "${!SERVICES[@]}"; do
    SERVICE_USER="${SERVICE_USERS[$i]}"
    SERVICE_PASS="${SERVICE_PASSES[$i]}"
    SERVICE_VHOST="${SERVICE_VHOSTS[$i]}"

    echo -e "${CYAN}  Criando usuário para ${SERVICES[$i]}...${NC}"

    # Criar usuário
    rabbitmqctl add_user "$SERVICE_USER" "$SERVICE_PASS"

    # Criar vhost
    rabbitmqctl add_vhost "$SERVICE_VHOST"

    # Dar permissões
    rabbitmqctl set_permissions -p "$SERVICE_VHOST" "$SERVICE_USER" ".*" ".*" ".*"
    rabbitmqctl set_permissions -p / "$SERVICE_USER" ".*" ".*" ".*"
done

# ============================================================================
# CONFIGURAR FIREWALL
# ============================================================================

if command -v ufw &> /dev/null; then
    echo -e "\n${YELLOW}Configurando firewall UFW...${NC}"
    ufw allow 5672/tcp comment 'RabbitMQ AMQP'
    ufw allow 15672/tcp comment 'RabbitMQ Management'
    echo -e "${GREEN}✓ Firewall configurado${NC}"
fi

# ============================================================================
# SALVAR CREDENCIAIS
# ============================================================================

CREDENTIALS_FILE="/root/rabbitmq_credentials_$(date +%Y%m%d_%H%M%S).txt"

cat > "$CREDENTIALS_FILE" <<EOF
═══════════════════════════════════════════════════════════════
    CREDENCIAIS RABBITMQ SERVER
═══════════════════════════════════════════════════════════════

Data de Instalação: $(date '+%d/%m/%Y %H:%M:%S')
IP do Servidor: ${RABBITMQ_IP}
Porta AMQP: 5672
Porta Management: 15672

───────────────────────────────────────────────────────────────
USUÁRIO ADMINISTRADOR
───────────────────────────────────────────────────────────────
Usuário: ${ADMIN_USER}
Senha: ${ADMIN_PASS}

URLs de Acesso:
  Management Web: http://${RABBITMQ_IP}:15672
  AMQP URL: amqp://${ADMIN_USER}:${ADMIN_PASS}@${RABBITMQ_IP}:5672/

EOF

# Adicionar serviços ao arquivo
if [ ${#SERVICES[@]} -gt 0 ]; then
    cat >> "$CREDENTIALS_FILE" <<EOF
───────────────────────────────────────────────────────────────
SERVIÇOS CONFIGURADOS
───────────────────────────────────────────────────────────────

EOF

    for i in "${!SERVICES[@]}"; do
        cat >> "$CREDENTIALS_FILE" <<EOF
▸ ${SERVICES[$i]}
  Usuário: ${SERVICE_USERS[$i]}
  Senha: ${SERVICE_PASSES[$i]}
  VHost: ${SERVICE_VHOSTS[$i]}
  AMQP URL: amqp://${SERVICE_USERS[$i]}:${SERVICE_PASSES[$i]}@${RABBITMQ_IP}:5672/${SERVICE_VHOSTS[$i]}

EOF
    done
fi

cat >> "$CREDENTIALS_FILE" <<EOF
═══════════════════════════════════════════════════════════════
IMPORTANTE: Guarde este arquivo em local seguro!
═══════════════════════════════════════════════════════════════
EOF

chmod 600 "$CREDENTIALS_FILE"

# ============================================================================
# VERIFICAÇÃO FINAL
# ============================================================================

echo -e "\n${GREEN}═══ Verificando instalação ═══${NC}"
systemctl status rabbitmq-server --no-pager | grep Active

echo -e "\n${BLUE}Testando RabbitMQ:${NC}"
rabbitmqctl status | grep "RabbitMQ version"

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║            Instalação Concluída com Sucesso! ✓            ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}Credenciais salvas em:${NC} ${CREDENTIALS_FILE}\n"
cat "$CREDENTIALS_FILE"

echo -e "\n${YELLOW}═══ PRÓXIMOS PASSOS ═══${NC}"
echo -e "1. ${BLUE}Acesse o Management:${NC} http://${RABBITMQ_IP}:15672"
echo -e "2. ${BLUE}Faça login com:${NC} ${ADMIN_USER}"
echo -e "3. ${BLUE}Backup das credenciais:${NC} Copie o arquivo ${CREDENTIALS_FILE}"

if [ ${#SERVICES[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}═══ INTEGRAÇÃO COM SERVIÇOS ═══${NC}"
    echo -e "Use as URLs AMQP acima para configurar seus serviços."
    echo -e "Exemplo para OnlyOffice:"
    echo -e "  ${CYAN}Host:${NC} ${RABBITMQ_IP}"
    echo -e "  ${CYAN}Port:${NC} 5672"
    echo -e "  ${CYAN}User:${NC} [conforme arquivo de credenciais]"
    echo -e "  ${CYAN}VHost:${NC} [conforme arquivo de credenciais]"
fi

echo -e "\n${GREEN}Instalação finalizada!${NC}\n"
