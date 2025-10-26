#!/bin/bash

#==============================================================================
# Script: install_docker_full.sh
# Descrição: Instalação completa do Docker e Docker Compose
# Autor: Hugllas Lima
# Data: $(date +%Y-%m-%d)
# Versão: 1.2
# Licença: MIT
# Repositório: https://github.com/hugllaslima/proxmox-ve-automation
#==============================================================================

# Ativa modo de erro (para o script se algum comando falhar)
set -e

# Detecta a distribuição base (Ubuntu para derivados)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    
    # Se for Zorin, Pop!_OS, Linux Mint, etc., usa Ubuntu
    case "$OS" in
        zorin|pop|linuxmint|elementary)
            OS="ubuntu"
            ;;
    esac
else
    echo "Não foi possível detectar a distribuição"
    exit 1
fi

echo "Sistema detectado: $OS"
echo " "

# ============================================================================
# ETAPA 1: LIMPEZA DE INSTALAÇÃO ANTERIOR (SE HOUVER)
# ============================================================================
echo "Removendo configurações antigas do Docker (se existirem)..."
  sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg 2>/dev/null || true
  sudo rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null || true
  sudo rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
echo " "

# ============================================================================
# ETAPA 2: ATUALIZAÇÃO DO SISTEMA
# ============================================================================
echo "Atualizando o sistema..."
sudo apt clean
  sudo apt update || {
      echo "⚠️  Erro ao atualizar. Tentando com mirror alternativo..."
      sudo sed -i 's|br.archive.ubuntu.com|archive.ubuntu.com|g' /etc/apt/sources.list
      sudo apt update
  }
sudo apt upgrade -y
echo " "

# ============================================================================
# ETAPA 3: INSTALAÇÃO DE DEPENDÊNCIAS
# ============================================================================
echo "Instalando dependências..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
echo " "

# ============================================================================
# ETAPA 4: ADIÇÃO DA CHAVE GPG DO DOCKER (MÉTODO MODERNO)
# ============================================================================
echo "Adicionando a chave GPG do Docker..."
sudo install -m 0755 -d /etc/apt/keyrings

# Força o uso do repositório Ubuntu
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo " "

# ============================================================================
# ETAPA 5: ADIÇÃO DO REPOSITÓRIO DOCKER
# ============================================================================
echo "Adicionando o repositório do Docker..."

# Pega a versão do Ubuntu base (para Zorin OS)
UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo " "

# ============================================================================
# ETAPA 6: INSTALAÇÃO DO DOCKER
# ============================================================================
echo "Instalando o Docker..."
sudo apt update
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo " "

echo "Verificando a Versão do Docker..."
docker --version
echo " "

echo "Habilitando a inicialização do Docker..."
sudo systemctl enable docker
sudo systemctl start docker
echo " "

# ============================================================================
# ETAPA 7: CONFIGURAÇÃO DE PERMISSÕES DO USUÁRIO
# ============================================================================
USER=$(whoami)
echo "Adicionando o usuário $USER ao grupo Docker..."
sudo usermod -aG docker $USER
echo " "

# ============================================================================
# ETAPA 8: TESTE RÁPIDO
# ============================================================================
echo "Testando Docker com sudo..."
sudo docker run --rm hello-world
echo " "

# ============================================================================
# ETAPA 9: VERIFICAÇÃO DA INSTALAÇÃO
# ============================================================================
echo "Verificando a instalação do Docker Compose (plugin)..."
docker compose version
echo " "

echo "✅ Instalação concluída com sucesso!"
echo " "
echo "📋 Resumo da instalação:"
echo "   - Docker Engine: $(docker --version)"
echo "   - Docker Compose: $(docker compose version)"
echo " "
echo "⚠️  IMPORTANTE: Você precisa fazer logout e login novamente"
echo "    para que as permissões do grupo Docker sejam aplicadas."
echo "    Após isso, você poderá usar Docker sem sudo."
echo " "

read -p "Deseja fazer logout agora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Fazendo logout em 3 segundos..."
    sleep 3
    gnome-session-quit --logout --no-prompt 2>/dev/null || \
    pkill -KILL -u $USER
else
    echo "Lembre-se de fazer logout/login antes de usar Docker sem sudo!"
fi

#fim_script
