#!/bin/bash

################################################################################
# Script de Instalação do RabbitMQ Server
# Versão: 2.1 - CORRIGIDO para Ubuntu 24.04
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
    echo -e "${BLUE}║                   Ubuntu Server 24.04 LTS                  ║${NC}"
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
echo -e "${GREEN}[1/7] Atualizando sistema...${NC}"
apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release wget

# 2. Instalar Erlang via repositório oficial do Team RabbitMQ
echo -e "${GREEN}[2/7] Instalando Erlang (via Launchpad PPA)...${NC}"

# Adicionar repositório Erlang Solutions
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | gpg --dearmor -o /usr/share/keyrings/erlang-solutions-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/erlang-solutions-archive-keyring.gpg] https://packages.erlang-solutions.com/ubuntu $(lsb_release -sc) contrib" | tee /etc/apt/sources.list.d/erlang.list

apt update
apt install -y erlang

# 3. Adicionar chave GPG do RabbitMQ
echo -e "${GREEN}[3/7] Adicionando chave GPG do RabbitMQ...${NC}"
curl -fsSL https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA | gpg --dearmor -o /usr/share/keyrings/com.rabbitmq.team.gpg

# 4. Adicionar repositório do RabbitMQ via Packagecloud
echo -e "${GREEN}[4/7] Adicionando repositório RabbitMQ...${NC}"

# Criar arquivo de repositório
cat > /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides RabbitMQ
deb [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu $(lsb_release -sc) main
deb-src [signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu $(lsb_release -sc) main
EOF

# 5. Instalar RabbitMQ Server
echo -e "${GREEN}[5/7] Instalando RabbitMQ Server...${NC}"
apt update
apt install -y rabbitmq-server

# 6. Habilitar e iniciar serviço
echo -e "${GREEN}[6/7] Habilitando serviços...${NC}"
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Aguardar serviço iniciar
echo -e "${CYAN}Aguardando RabbitMQ inicializar...${NC}"
sleep 10

# 7. Habilitar Management Plugin e configurar usuários
echo -e "${GREEN}[7/7] Configurando RabbitMQ...${NC}"

# Habilitar Management Plugin
rabbitmq-plugins enable rabbitmq_management

# Aguardar plugin inicializar
sleep 5

# Remover usuário guest (segurança)
rabbitmqctl delete_user guest 2>/dev/null || true

# Criar usuário admin
echo -e "${CYAN}  Criando usuário administrador...${NC}"
rabbitmqctl add_user "$ADMIN_USER" "$ADMIN_PASS"
rabbitmqctl set_user_tags "$ADMIN_USER" administrator
rabbitmqctl set_permissions -p / "$ADMIN_USER" ".*" ".*" ".*"

# Criar usuários dos serviços
if [ ${#SERVICES[@]} -gt 0 ]; then
    for i in "${!SERVICES[@]}"; do
        SERVICE_USER="${SERVICE_USERS[$i]}"
        SERVICE_PASS="${SERVICE_PASSES[$i]}"
        SERVICE_VHOST="${SERVICE_VHOSTS[$i]}"

        echo -e "${CYAN}  Criando usuário para ${SERVICES[$i]}...${NC}"

        # Criar usuário
        rabbitmqctl add_user "$SERVICE_USER" "$SERVICE_PASS"

        # Criar vhost
        rabbitmqctl add_vhost "$SERVICE_VHOST"

        # Dar permissões no vhost específico
        rabbitmqctl set_permissions -p "$SERVICE_VHOST" "$SERVICE_USER" ".*" ".*" ".*"

        # Dar permissões no vhost padrão também
        rabbitmqctl set_permissions -p / "$SERVICE_USER" ".*" ".*" ".*"
    done
fi

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

echo -e "\n${BLUE}Status do serviço:${NC}"
systemctl status rabbitmq-server --no-pager | grep Active

echo -e "\n${BLUE}Versão do RabbitMQ:${NC}"
rabbitmqctl version

echo -e "\n${BLUE}Plugins habilitados:${NC}"
rabbitmq-plugins list | grep enabled

echo -e "\n${BLUE}Usuários criados:${NC}"
rabbitmqctl list_users

echo -e "\n${BLUE}VHosts criados:${NC}"
rabbitmqctl list_vhosts

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║            Instalação Concluída com Sucesso! ✓             ║${NC}"
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
