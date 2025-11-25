#!/bin/bash

################################################################################
# Script de Limpeza - OnlyOffice Document Server
# Versão: 2.0 - ROBUSTA
# Remove completamente o OnlyOffice e suas dependências
# Uso: sudo ./cleanup_onlyoffice.sh
#
# ATENÇÃO: Este script remove TUDO relacionado ao OnlyOffice!
################################################################################

# Desabilitar exit on error para continuar mesmo com erros
set +e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Função para exibir cabeçalho
print_header() {
    echo -e "\n${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║        Script de Limpeza - OnlyOffice Server              ║${NC}"
    echo -e "${RED}║        ATENÇÃO: Remoção Completa do Sistema               ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}\n"
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

# Função para executar comando com tratamento de erro
safe_execute() {
    local description=$1
    shift
    local command="$@"

    if eval "$command" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado como root (use sudo)${NC}" 
   exit 1
fi

print_header

echo -e "${YELLOW}Este script irá remover COMPLETAMENTE:${NC}"
echo -e "  ${CYAN}•${NC} OnlyOffice Document Server"
echo -e "  ${CYAN}•${NC} PostgreSQL e banco de dados 'onlyoffice'"
echo -e "  ${CYAN}•${NC} Nginx (configurações do OnlyOffice)"
echo -e "  ${CYAN}•${NC} Supervisor e processos relacionados"
echo -e "  ${CYAN}•${NC} Todos os arquivos de configuração"
echo -e "  ${CYAN}•${NC} Todos os arquivos de log"
echo -e "  ${CYAN}•${NC} Repositórios e chaves GPG"
echo -e "  ${CYAN}•${NC} Usuários e grupos criados"
echo

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  ATENÇÃO: Esta ação NÃO pode ser desfeita!                ║${NC}"
echo -e "${RED}║  Todos os dados do OnlyOffice serão PERMANENTEMENTE       ║${NC}"
echo -e "${RED}║  removidos do sistema.                                    ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Confirmação dupla
read -p "Digite 'REMOVER' (em maiúsculas) para confirmar: " CONFIRM

if [ "$CONFIRM" != "REMOVER" ]; then
    echo -e "${YELLOW}Limpeza cancelada. Nenhuma alteração foi feita.${NC}"
    exit 0
fi

echo
if ! ask_yes_no "Tem certeza absoluta que deseja continuar?"; then
    echo -e "${YELLOW}Limpeza cancelada. Nenhuma alteração foi feita.${NC}"
    exit 0
fi

echo -e "\n${GREEN}Iniciando limpeza do sistema...${NC}\n"

# ============================================================================
# BACKUP DE CONFIGURAÇÕES (OPCIONAL)
# ============================================================================

BACKUP_DIR=""
if ask_yes_no "Deseja fazer backup das configurações antes de remover?"; then
    BACKUP_DIR="/root/onlyoffice_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${BLUE}[BACKUP] Criando backup em: ${BACKUP_DIR}${NC}"

    mkdir -p "$BACKUP_DIR" 2>/dev/null || true

    # Backup de configurações
    [ -d "/etc/onlyoffice" ] && cp -r /etc/onlyoffice "$BACKUP_DIR/" 2>/dev/null || true

    # Backup de logs recentes
    if [ -d "/var/log/onlyoffice" ]; then
        mkdir -p "$BACKUP_DIR/logs" 2>/dev/null || true
        find /var/log/onlyoffice -name "*.log" -mtime -7 -exec cp {} "$BACKUP_DIR/logs/" \; 2>/dev/null || true
    fi

    # Backup de arquivos de credenciais
    find /root -name "onlyoffice_config_*.txt" -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null || true

    chmod 600 -R "$BACKUP_DIR" 2>/dev/null || true
    echo -e "${GREEN}✓ Backup criado em: ${BACKUP_DIR}${NC}\n"
fi

# ============================================================================
# PARAR SERVIÇOS
# ============================================================================

echo -e "${BLUE}[1/15] Parando serviços OnlyOffice...${NC}"

# Parar supervisor de forma mais agressiva
if command -v supervisorctl &> /dev/null; then
    echo -e "  ${CYAN}→${NC} Parando processos via Supervisor..."
    timeout 10 supervisorctl stop all 2>/dev/null || true
    sleep 2
    timeout 5 systemctl stop supervisor 2>/dev/null || true
fi

# Parar Nginx
echo -e "  ${CYAN}→${NC} Parando Nginx..."
systemctl stop nginx 2>/dev/null || true

# Matar processos OnlyOffice manualmente
echo -e "  ${CYAN}→${NC} Finalizando processos OnlyOffice..."
pkill -9 -f "onlyoffice" 2>/dev/null || true
pkill -9 -f "documentserver" 2>/dev/null || true
pkill -9 -f "ds-" 2>/dev/null || true
pkill -9 -f "converter" 2>/dev/null || true
pkill -9 -f "docservice" 2>/dev/null || true

# Matar processos Node.js relacionados
pkill -9 -f "node.*onlyoffice" 2>/dev/null || true

sleep 3
echo -e "${GREEN}✓ Serviços parados${NC}"

# ============================================================================
# REMOVER PACOTES
# ============================================================================

echo -e "${BLUE}[2/15] Removendo pacotes OnlyOffice...${NC}"

# Remover OnlyOffice
DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y onlyoffice-documentserver 2>/dev/null || true

# Remover dependências órfãs
apt-get autoremove -y 2>/dev/null || true

echo -e "${GREEN}✓ Pacotes removidos${NC}"

# ============================================================================
# REMOVER POSTGRESQL E BANCO DE DADOS
# ============================================================================

echo -e "${BLUE}[3/15] Removendo banco de dados PostgreSQL...${NC}"

if command -v psql &> /dev/null; then
    echo -e "  ${CYAN}→${NC} Removendo banco de dados 'onlyoffice'..."

    # Parar conexões ativas
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'onlyoffice';" 2>/dev/null || true

    sleep 2

    # Remover banco de dados
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS onlyoffice;" 2>/dev/null || true

    # Remover usuário
    sudo -u postgres psql -c "DROP USER IF EXISTS onlyoffice;" 2>/dev/null || true

    echo -e "${GREEN}✓ Banco de dados removido${NC}"

    # Perguntar se deseja remover PostgreSQL completamente
    if ask_yes_no "Deseja remover o PostgreSQL completamente? (Cuidado: pode afetar outros serviços)"; then
        systemctl stop postgresql 2>/dev/null || true
        apt-get remove --purge -y postgresql postgresql-* 2>/dev/null || true
        rm -rf /var/lib/postgresql 2>/dev/null || true
        rm -rf /etc/postgresql 2>/dev/null || true
        echo -e "${GREEN}✓ PostgreSQL removido completamente${NC}"
    else
        echo -e "${YELLOW}⊘ PostgreSQL mantido no sistema${NC}"
    fi
else
    echo -e "${YELLOW}⊘ PostgreSQL não encontrado${NC}"
fi

# ============================================================================
# REMOVER NGINX
# ============================================================================

echo -e "${BLUE}[4/15] Removendo configurações Nginx...${NC}"

# Remover configurações do OnlyOffice
rm -f /etc/nginx/conf.d/ds.conf 2>/dev/null || true
rm -f /etc/nginx/conf.d/onlyoffice* 2>/dev/null || true
rm -f /etc/nginx/sites-enabled/ds 2>/dev/null || true
rm -f /etc/nginx/sites-available/ds 2>/dev/null || true
rm -rf /etc/nginx/includes/onlyoffice* 2>/dev/null || true

# Perguntar se deseja remover Nginx completamente
if ask_yes_no "Deseja remover o Nginx completamente? (Cuidado: pode afetar outros serviços)"; then
    systemctl stop nginx 2>/dev/null || true
    apt-get remove --purge -y nginx nginx-* 2>/dev/null || true
    rm -rf /etc/nginx 2>/dev/null || true
    rm -rf /var/log/nginx 2>/dev/null || true
    echo -e "${GREEN}✓ Nginx removido completamente${NC}"
else
    # Apenas recarregar configuração
    systemctl reload nginx 2>/dev/null || systemctl restart nginx 2>/dev/null || true
    echo -e "${YELLOW}⊘ Nginx mantido (apenas configurações OnlyOffice removidas)${NC}"
fi

# ============================================================================
# REMOVER SUPERVISOR
# ============================================================================

echo -e "${BLUE}[5/15] Removendo Supervisor...${NC}"

if command -v supervisorctl &> /dev/null; then
    systemctl stop supervisor 2>/dev/null || true
    systemctl disable supervisor 2>/dev/null || true

    if ask_yes_no "Deseja remover o Supervisor completamente? (Cuidado: pode afetar outros serviços)"; then
        apt-get remove --purge -y supervisor 2>/dev/null || true
        rm -rf /etc/supervisor 2>/dev/null || true
        rm -rf /var/log/supervisor 2>/dev/null || true
        echo -e "${GREEN}✓ Supervisor removido completamente${NC}"
    else
        # Apenas remover configurações OnlyOffice
        rm -f /etc/supervisor/conf.d/ds* 2>/dev/null || true
        rm -f /etc/supervisor/conf.d/onlyoffice* 2>/dev/null || true
        supervisorctl reread 2>/dev/null || true
        supervisorctl update 2>/dev/null || true
        echo -e "${YELLOW}⊘ Supervisor mantido (apenas configurações OnlyOffice removidas)${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Supervisor não encontrado${NC}"
fi

# ============================================================================
# REMOVER DIRETÓRIOS DE INSTALAÇÃO
# ============================================================================

echo -e "${BLUE}[6/15] Removendo diretórios de instalação...${NC}"

# Diretórios principais
rm -rf /var/www/onlyoffice 2>/dev/null || true
rm -rf /var/lib/onlyoffice 2>/dev/null || true
rm -rf /usr/share/onlyoffice 2>/dev/null || true
rm -rf /opt/onlyoffice 2>/dev/null || true

echo -e "${GREEN}✓ Diretórios de instalação removidos${NC}"

# ============================================================================
# REMOVER DIRETÓRIOS DE CONFIGURAÇÃO
# ============================================================================

echo -e "${BLUE}[7/15] Removendo diretórios de configuração...${NC}"

rm -rf /etc/onlyoffice 2>/dev/null || true

echo -e "${GREEN}✓ Configurações removidas${NC}"

# ============================================================================
# REMOVER LOGS
# ============================================================================

echo -e "${BLUE}[8/15] Removendo logs...${NC}"

rm -rf /var/log/onlyoffice 2>/dev/null || true

echo -e "${GREEN}✓ Logs removidos${NC}"

# ============================================================================
# REMOVER CACHE E TEMPORÁRIOS
# ============================================================================

echo -e "${BLUE}[9/15] Removendo cache e arquivos temporários...${NC}"

rm -rf /var/cache/onlyoffice 2>/dev/null || true
rm -rf /tmp/onlyoffice* 2>/dev/null || true
rm -rf /tmp/ds* 2>/dev/null || true
rm -rf /run/onlyoffice* 2>/dev/null || true

echo -e "${GREEN}✓ Cache removido${NC}"

# ============================================================================
# REMOVER USUÁRIOS E GRUPOS
# ============================================================================

echo -e "${BLUE}[10/15] Removendo usuários e grupos...${NC}"

# Remover usuário ds
if id "ds" &>/dev/null; then
    # Matar processos do usuário primeiro
    pkill -9 -u ds 2>/dev/null || true
    sleep 1
    userdel -r ds 2>/dev/null || userdel ds 2>/dev/null || true
    echo -e "${GREEN}✓ Usuário 'ds' removido${NC}"
else
    echo -e "${YELLOW}⊘ Usuário 'ds' não encontrado${NC}"
fi

# Remover grupo ds
if getent group ds &>/dev/null; then
    groupdel ds 2>/dev/null || true
    echo -e "${GREEN}✓ Grupo 'ds' removido${NC}"
else
    echo -e "${YELLOW}⊘ Grupo 'ds' não encontrado${NC}"
fi

# ============================================================================
# REMOVER REPOSITÓRIOS
# ============================================================================

echo -e "${BLUE}[11/15] Removendo repositórios...${NC}"

rm -f /etc/apt/sources.list.d/onlyoffice.list 2>/dev/null || true

echo -e "${GREEN}✓ Repositórios removidos${NC}"

# ============================================================================
# REMOVER CHAVES GPG
# ============================================================================

echo -e "${BLUE}[12/15] Removendo chaves GPG...${NC}"

rm -f /usr/share/keyrings/onlyoffice.gpg 2>/dev/null || true

echo -e "${GREEN}✓ Chaves GPG removidas${NC}"

# ============================================================================
# REMOVER ERLANG (OPCIONAL)
# ============================================================================

echo -e "${BLUE}[13/15] Verificando Erlang...${NC}"

if ask_yes_no "Deseja remover o Erlang? (Necessário apenas se não usar RabbitMQ local)"; then
    apt-get remove --purge -y erlang* 2>/dev/null || true
    rm -f /etc/apt/sources.list.d/erlang.list 2>/dev/null || true
    rm -f /usr/share/keyrings/erlang-solutions-archive-keyring.gpg 2>/dev/null || true
    echo -e "${GREEN}✓ Erlang removido${NC}"
else
    echo -e "${YELLOW}⊘ Erlang mantido no sistema${NC}"
fi

# ============================================================================
# LIMPAR SYSTEMD
# ============================================================================

echo -e "${BLUE}[14/15] Limpando serviços systemd...${NC}"

# Remover links simbólicos
rm -f /etc/systemd/system/multi-user.target.wants/ds* 2>/dev/null || true
rm -f /lib/systemd/system/ds* 2>/dev/null || true
rm -f /usr/lib/systemd/system/ds* 2>/dev/null || true
rm -f /etc/systemd/system/ds* 2>/dev/null || true

# Recarregar systemd
systemctl daemon-reload 2>/dev/null || true

echo -e "${GREEN}✓ Serviços systemd limpos${NC}"

# ============================================================================
# LIMPAR APT CACHE
# ============================================================================

echo -e "${BLUE}[15/15] Limpando cache do sistema...${NC}"

apt-get clean 2>/dev/null || true
apt-get autoclean 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
apt-get update 2>/dev/null || true

echo -e "${GREEN}✓ Cache limpo${NC}"

# ============================================================================
# VERIFICAÇÃO FINAL
# ============================================================================

echo -e "\n${GREEN}═══ Verificando limpeza ═══${NC}\n"

# Verificar se ainda existem processos
PROCESSES=$(ps aux | grep -i onlyoffice | grep -v grep | grep -v cleanup | wc -l)
if [ $PROCESSES -eq 0 ]; then
    echo -e "${GREEN}✓ Nenhum processo OnlyOffice em execução${NC}"
else
    echo -e "${YELLOW}⚠ Ainda existem $PROCESSES processo(s) OnlyOffice em execução${NC}"
    echo -e "${CYAN}  Processos:${NC}"
    ps aux | grep -i onlyoffice | grep -v grep | grep -v cleanup
fi

# Verificar diretórios
DIRS_REMAINING=0
for dir in /var/www/onlyoffice /var/lib/onlyoffice /etc/onlyoffice /var/log/onlyoffice /opt/onlyoffice; do
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}⚠ Diretório ainda existe: $dir${NC}"
        DIRS_REMAINING=$((DIRS_REMAINING + 1))
    fi
done

if [ $DIRS_REMAINING -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os diretórios removidos${NC}"
fi

# Verificar usuários
if id "ds" &>/dev/null; then
    echo -e "${YELLOW}⚠ Usuário 'ds' ainda existe${NC}"
else
    echo -e "${GREEN}✓ Usuário 'ds' removido${NC}"
fi

# Verificar pacotes
if dpkg -l | grep -q onlyoffice; then
    echo -e "${YELLOW}⚠ Pacotes OnlyOffice ainda instalados:${NC}"
    dpkg -l | grep onlyoffice
else
    echo -e "${GREEN}✓ Nenhum pacote OnlyOffice instalado${NC}"
fi

# ============================================================================
# RELATÓRIO FINAL
# ============================================================================

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║        Limpeza Concluída com Sucesso! ✓                   ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}Resumo da limpeza:${NC}"
echo -e "  ${GREEN}✓${NC} OnlyOffice Document Server removido"
echo -e "  ${GREEN}✓${NC} Banco de dados PostgreSQL limpo"
echo -e "  ${GREEN}✓${NC} Configurações removidas"
echo -e "  ${GREEN}✓${NC} Logs removidos"
echo -e "  ${GREEN}✓${NC} Cache limpo"
echo -e "  ${GREEN}✓${NC} Repositórios removidos"

if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo -e "\n${BLUE}Backup das configurações salvo em:${NC}"
    echo -e "  ${BACKUP_DIR}"
fi

echo -e "\n${YELLOW}═══ PRÓXIMOS PASSOS ═══${NC}"
echo -e "1. ${CYAN}O sistema está limpo e pronto para nova instalação${NC}"
echo -e "2. ${CYAN}Execute o script de instalação quando estiver pronto${NC}"
echo -e "3. ${CYAN}Considere reiniciar o servidor para garantir limpeza completa:${NC}"
echo -e "   ${BLUE}sudo reboot${NC}"

echo -e "\n${GREEN}Limpeza finalizada!${NC}\n"

# Perguntar se deseja reiniciar
if ask_yes_no "Deseja reiniciar o servidor agora? (Recomendado)"; then
    echo -e "${YELLOW}Reiniciando em 5 segundos... (Ctrl+C para cancelar)${NC}"
    sleep 5
    reboot
fi
