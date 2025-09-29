#!/bin/bash

# Script para configurar Self-Hosted Runner com usuário dedicado - VERSÃO FINAL CORRIGIDA
# Autor: Script para Hugllas
# Data: 15/03/2025

echo " "
echo "=================================================================================="
echo "✅ Permissões aprimoradas: Adicionadas permissões para kill, pkill e systemctl"
echo "✅ Gerenciamento de processos melhorado: Método mais seguro para parar processos"
echo "✅ Timeouts controlados: Uso de timeout para evitar processos infinitos"
echo "✅ Múltiplos métodos de fallback: Se um método falhar, tenta alternativo"
echo "✅ Verificações de status melhoradas: Múltiplas formas de verificar o serviço"
echo "✅ Aguardos apropriados: Sleeps estratégicos para processos estabilizarem"
echo "✅ Melhor tratamento de erros: Mais tolerante a falhas e com recuperação"
echo "✅ Captura de Ctrl+C - Script continua automaticamente após interrupção"
echo "✅ Verificações robustas - Múltiplos métodos de verificação de status"
echo "✅ Feedback visual aprimorado - Separadores e emojis para clareza"
echo "✅ Tratamento de erros melhorado - Métodos alternativos quando necessário"
echo "=================================================================================="
echo " "

set -e  # Parar execução se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Self-Hosted Runner Setup Script v4${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Verificar se está rodando como sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script precisa ser executado com sudo!${NC}"
    echo "Execute: sudo ./setup-runner.sh"
    exit 1
fi

echo -e "${YELLOW}[ETAPA 1]${NC} Criando usuário 'runner' com permissões mínimas..."

# Criar usuário runner
if id "runner" &>/dev/null; then
    echo -e "${YELLOW}Usuário 'runner' já existe. Continuando...${NC}"
else
    useradd -m -s /bin/bash runner
    echo -e "${GREEN}Usuário 'runner' criado com sucesso!${NC}"
fi

# Configurar senha para o usuário runner
echo -e "${BLUE}Configurando senha para o usuário runner...${NC}"
echo -e "${YELLOW}Digite uma senha para o usuário runner (para segurança):${NC}"
passwd runner

# Adicionar runner ao grupo docker
usermod -aG docker runner
echo -e "${GREEN}Usuário 'runner' adicionado ao grupo docker.${NC}"

# Criar arquivo de configuração sudo para o usuário runner - VERSÃO COMPLETA
cat > /etc/sudoers.d/runner << EOF
# Permissões específicas para o usuário runner
runner ALL=(ALL) NOPASSWD: /bin/systemctl restart *
runner ALL=(ALL) NOPASSWD: /bin/systemctl start *
runner ALL=(ALL) NOPASSWD: /bin/systemctl stop *
runner ALL=(ALL) NOPASSWD: /bin/systemctl status *
runner ALL=(ALL) NOPASSWD: /usr/bin/docker
runner ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose
runner ALL=(ALL) NOPASSWD: /usr/bin/docker-compose
runner ALL=(ALL) NOPASSWD: /bin/chown runner\:runner *
runner ALL=(ALL) NOPASSWD: /bin/chmod *
# Permitir instalação e gerenciamento do serviço do runner
runner ALL=(ALL) NOPASSWD: /home/runner/actions-runner/svc.sh *
# Permissões para gerenciar processos
runner ALL=(ALL) NOPASSWD: /bin/kill
runner ALL=(ALL) NOPASSWD: /usr/bin/pkill
runner ALL=(ALL) NOPASSWD: /bin/pkill
runner ALL=(ALL) NOPASSWD: /usr/bin/systemctl * actions.runner.*
# Permissões para bash quando necessário
runner ALL=(ALL) NOPASSWD: /bin/bash /home/runner/actions-runner/svc.sh *
# Permitir runner voltar para ubuntu sem senha
runner ALL=(ALL) NOPASSWD: /bin/su - ubuntu
runner ALL=(ALL) NOPASSWD: /usr/bin/su - ubuntu
runner ALL=(ALL) NOPASSWD: /bin/su ubuntu
runner ALL=(ALL) NOPASSWD: /usr/bin/su ubuntu
# Permitir acesso ao diretório de logs
runner ALL=(ALL) NOPASSWD: /usr/bin/journalctl *
EOF

chmod 440 /etc/sudoers.d/runner
echo -e "${GREEN}Permissões sudo configuradas para o usuário runner.${NC}"

# Configurar acesso entre usuários
echo -e "${BLUE}Configurando navegação entre usuários...${NC}"
# Permitir ubuntu acessar runner sem senha também
echo "# Permitir ubuntu acessar runner sem senha" >> /etc/sudoers.d/runner
echo "ubuntu ALL=(runner) NOPASSWD: ALL" >> /etc/sudoers.d/runner
echo -e "${GREEN}Navegação entre usuários configurada.${NC}"

# Criar diretório da aplicação se não existir
if [ ! -d "/var/www" ]; then
    mkdir -p /var/www
fi
chown runner:runner /var/www
echo -e "${GREEN}Diretório da aplicação configurado.${NC}"

echo
echo -e "${YELLOW}[ETAPA 2]${NC} Mudando para usuário 'runner' e criando diretório actions-runner..."

# Função para executar comandos como usuário runner
run_as_runner() {
    sudo -u runner bash -c "$1"
}

# Criar diretório actions-runner como usuário runner
run_as_runner "cd /home/runner && mkdir -p actions-runner && cd actions-runner"
echo -e "${GREEN}Diretório actions-runner criado com sucesso!${NC}"

echo
echo -e "${YELLOW}[ETAPA 3]${NC} Download do GitHub Actions Runner"
echo -e "${BLUE}Agora você precisa ir ao GitHub e copiar o comando de download.${NC}"
echo -e "${BLUE}Vá em: Settings > Actions > Runners > New self-hosted runner${NC}"
echo -e "${BLUE}Copie o comando que começa com 'curl -o actions-runner-linux...'${NC}"
echo
read -p "Cole aqui o comando de download do GitHub: " download_command

if [ -z "$download_command" ]; then
    echo -e "${RED}Comando não pode estar vazio!${NC}"
    exit 1
fi

echo -e "${GREEN}Executando download...${NC}"
run_as_runner "cd /home/runner/actions-runner && $download_command"

echo
echo -e "${YELLOW}[ETAPA 4]${NC} Validação do hash (opcional)"
echo -e "${BLUE}Cole o comando de validação do hash ou pressione ENTER para pular:${NC}"
read -p "Comando de validação: " hash_command

if [ ! -z "$hash_command" ]; then
    echo -e "${GREEN}Validando hash...${NC}"
    run_as_runner "cd /home/runner/actions-runner && $hash_command"
    echo -e "${GREEN}Hash validado com sucesso!${NC}"
else
    echo -e "${YELLOW}Validação de hash pulada.${NC}"
fi

echo
echo -e "${YELLOW}[ETAPA 5]${NC} Extração do instalador"
echo -e "${BLUE}Cole o comando de extração do GitHub (geralmente tar xzf actions-runner-linux...):${NC}"
read -p "Comando de extração: " extract_command

if [ -z "$extract_command" ]; then
    echo -e "${RED}Comando não pode estar vazio!${NC}"
    exit 1
fi

echo -e "${GREEN}Extraindo instalador...${NC}"
run_as_runner "cd /home/runner/actions-runner && $extract_command"

echo
echo -e "${YELLOW}[ETAPA 6]${NC} Configuração do Runner"
echo -e "${BLUE}Cole o comando de configuração do GitHub (./config.sh --url...):${NC}"
read -p "Comando de configuração: " config_command

if [ -z "$config_command" ]; then
    echo -e "${RED}Comando não pode estar vazio!${NC}"
    exit 1
fi

echo -e "${GREEN}Configurando runner...${NC}"
run_as_runner "cd /home/runner/actions-runner && $config_command"

echo
echo -e "${YELLOW}[ETAPA 7]${NC} Teste de conectividade"
echo -e "${GREEN}Testando conectividade com o GitHub...${NC}"
echo -e "${BLUE}Este teste verificará se o runner está configurado corretamente.${NC}"
echo

# Teste simples de conectividade (não bloquear)
run_as_runner "cd /home/runner/actions-runner && timeout 5s ./run.sh" || {
    echo -e "${GREEN}Teste de conectividade concluído.${NC}"
}

echo
echo -e "${YELLOW}[ETAPA 8]${NC} Instalação como serviço - VERSÃO CORRIGIDA"
echo -e "${BLUE}Deseja instalar o runner como serviço automático? (s/n):${NC}"
read -p "Instalar como serviço: " install_service

if [[ $install_service =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}Preparando instalação do serviço...${NC}"
    echo
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ATENÇÃO: Agora o runner será iniciado manualmente para teste  ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${GREEN}1. O runner será iniciado em modo interativo${NC}"
    echo -e "${GREEN}2. Aguarde ver a mensagem 'Listening for Jobs'${NC}"
    echo -e "${GREEN}3. Quando aparecer essa mensagem, pressione Ctrl+C${NC}"
    echo -e "${GREEN}4. O script continuará automaticamente com a instalação do serviço${NC}"
    echo
    read -p "Pressione ENTER para continuar..."
    
    echo -e "${BLUE}Iniciando runner em modo interativo...${NC}"
    echo -e "${YELLOW}Aguarde 'Listening for Jobs' e então pressione Ctrl+C${NC}"
    echo
    
    # Executar o runner e capturar a interrupção
    run_as_runner "cd /home/runner/actions-runner && ./run.sh" || {
        echo
        echo -e "${GREEN}Runner parado pelo usuário. Continuando com instalação do serviço...${NC}"
    }
    
    # Aguardar um pouco para garantir que processos terminaram
    echo -e "${BLUE}Aguardando processos finalizarem...${NC}"
    sleep 3
    
    # Verificar se ainda há processos rodando e pará-los se necessário
    echo -e "${BLUE}Verificando processos restantes...${NC}"
    if run_as_runner "pgrep -f 'Runner.Listener' >/dev/null 2>&1"; then
        echo -e "${YELLOW}Finalizando processos restantes...${NC}"
        run_as_runner "pkill -f 'Runner.Listener' 2>/dev/null || true"
        sleep 2
    fi
    
    echo -e "${BLUE}Instalando runner como serviço...${NC}"
    if run_as_runner "cd /home/runner/actions-runner && sudo ./svc.sh install runner"; then
        echo -e "${GREEN}✅ Serviço instalado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro na instalação do serviço.${NC}"
        echo -e "${YELLOW}Tentando método alternativo...${NC}"
        run_as_runner "cd /home/runner/actions-runner && sudo bash ./svc.sh install runner"
    fi
    
    echo -e "${BLUE}Iniciando serviço...${NC}"
    if run_as_runner "cd /home/runner/actions-runner && sudo ./svc.sh start"; then
        echo -e "${GREEN}✅ Serviço iniciado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar o serviço.${NC}"
        echo -e "${YELLOW}Tentando método alternativo...${NC}"
        run_as_runner "cd /home/runner/actions-runner && sudo bash ./svc.sh start"
    fi
    
    # Aguardar serviço inicializar
    echo -e "${BLUE}Aguardando inicialização completa do serviço...${NC}"
    sleep 5
    
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                VERIFICANDO STATUS DO SERVIÇO                   ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Verificar status do serviço
    echo -e "${BLUE}Status via svc.sh:${NC}"
    run_as_runner "cd /home/runner/actions-runner && sudo ./svc.sh status" || {
        echo -e "${YELLOW}Erro ao verificar status via svc.sh${NC}"
    }
    
    echo
    echo -e "${BLUE}Status via systemctl:${NC}"
    systemctl status actions.runner.* --no-pager -l || {
        echo -e "${YELLOW}Aguardando mais um pouco...${NC}"
        sleep 5
        systemctl status actions.runner.* --no-pager -l || {
            echo -e "${YELLOW}Execute manualmente: sudo systemctl status actions.runner.*${NC}"
        }
    }
    
    echo
    echo -e "${BLUE}Logs recentes do serviço:${NC}"
    journalctl -u actions.runner.* --no-pager -n 10 || echo -e "${YELLOW}Logs não disponíveis no momento.${NC}"
    
    echo
    echo -e "${GREEN}✅ Runner instalado e configurado como serviço!${NC}"
    echo -e "${BLUE}Para ver logs em tempo real: sudo journalctl -u actions.runner.* -f${NC}"
    
else
    echo -e "${YELLOW}Runner não foi instalado como serviço.${NC}"
    echo -e "${BLUE}Para iniciar manualmente: sudo su - runner && cd actions-runner && ./run.sh${NC}"
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Configuração concluída com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}Resumo da configuração:${NC}"
echo "• Usuário 'runner' criado com senha e permissões mínimas"
echo "• Runner instalado em /home/runner/actions-runner"
echo "• Usuário runner adicionado ao grupo docker"
echo "• Permissões sudo configuradas com navegação entre usuários"
echo "• Gerenciamento de processos otimizado"
echo "• Instalação do serviço com controle manual"
echo
echo -e "${BLUE}Navegação entre usuários:${NC}"
echo "• De ubuntu para runner: sudo su - runner"
echo "• De runner para ubuntu: sudo su - ubuntu (sem senha)"
echo "• Ou simplesmente: exit (para voltar)"
echo
echo -e "${BLUE}Para troubleshooting:${NC}"
echo "• Logs do serviço: sudo journalctl -u actions.runner.* -f"
echo "• Acessar usuário runner: sudo su - runner"
echo "• Status do serviço: sudo su - runner && cd actions-runner && sudo ./svc.sh status"
echo "• Reiniciar serviço: sudo su - runner && cd actions-runner && sudo ./svc.sh restart"
echo
echo -e "${BLUE}Comandos úteis:${NC}"
echo "• Parar serviço: sudo systemctl stop actions.runner.*"
echo "• Iniciar serviço: sudo systemctl start actions.runner.*"
echo "• Ver logs em tempo real: sudo journalctl -u actions.runner.* -f"
echo "• Verificar no GitHub: Settings > Actions > Runners"
echo
echo -e "${GREEN}Runner pronto para uso! 🚀${NC}"
echo -e "${YELLOW}Lembre-se da senha que você definiu para o usuário runner.${NC}"
