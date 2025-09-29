#!/bin/bash

# Script para configurar Self-Hosted Runner com usuário dedicado
# Autor: Hugllas Lima
# Data: 02/03/2025

set -e  # Parar execução se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Self-Hosted Runner Setup Script${NC}"
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

# Adicionar runner ao grupo docker
  usermod -aG docker runner
  echo -e "${GREEN}Usuário 'runner' adicionado ao grupo docker.${NC}"

# Criar arquivo de configuração sudo para o usuário runner
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
EOF

  chmod 440 /etc/sudoers.d/runner
  echo -e "${GREEN}Permissões sudo configuradas para o usuário runner.${NC}"

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
echo -e "${YELLOW}[ETAPA 7]${NC} Teste inicial do runner"
echo -e "${GREEN}Iniciando runner para teste...${NC}"
echo -e "${BLUE}Pressione Ctrl+C após alguns segundos para parar e continuar com a instalação como serviço.${NC}"
echo

# Executar run.sh em background e aguardar alguns segundos
run_as_runner "cd /home/runner/actions-runner && timeout 10 ./run.sh || true"

echo
echo -e "${YELLOW}[ETAPA 8]${NC} Instalação como serviço"
echo -e "${BLUE}Deseja instalar o runner como serviço automático? (s/n):${NC}"
read -p "Instalar como serviço: " install_service

  if [[ $install_service =~ ^[Ss]$ ]]; then
      echo -e "${GREEN}Instalando runner como serviço...${NC}"
    
      # Parar qualquer instância em execução
      run_as_runner "cd /home/runner/actions-runner && pkill -f './run.sh' || true"
    
      # Instalar e iniciar o serviço
      run_as_runner "cd /home/runner/actions-runner && sudo ./svc.sh install"
      run_as_runner "cd /home/runner/actions-runner && sudo ./svc.sh start"
    
      echo -e "${GREEN}Runner instalado e iniciado como serviço!${NC}"
    
      # Verificar status do serviço
      echo -e "${BLUE}Status do serviço:${NC}"
      run_as_runner "cd /home/runner/actions-runner && sudo ./svc.sh status"
  else
      echo -e "${YELLOW}Runner não foi instalado como serviço.${NC}"
      echo -e "${BLUE}Para iniciar manualmente, use: sudo su - runner && cd actions-runner && ./run.sh${NC}"
  fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Configuração concluída com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}Resumo da configuração:${NC}"
echo "• Usuário 'runner' criado com permissões mínimas"
echo "• Runner instalado em /home/runner/actions-runner"
echo "• Usuário runner adicionado ao grupo docker"
echo "• Permissões sudo específicas configuradas"
echo
echo -e "${BLUE}Para troubleshooting:${NC}"
echo "• Logs do serviço: sudo journalctl -u actions.runner.*"
echo "• Acessar usuário runner: sudo su - runner"
echo "• Status do serviço: sudo su - runner && cd actions-runner && sudo ./svc.sh status"
echo
echo -e "${GREEN}Runner pronto para uso!${NC}"
