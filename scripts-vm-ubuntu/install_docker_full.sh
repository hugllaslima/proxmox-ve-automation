#!/bin/bash

# Este script irá instalar o docker + docker composer para o usuário local.

# Atualizar o sistema
echo "Atualizando o sistema..."
    sudo apt update && sudo apt upgrade -y
echo " "
# Instalar dependências
echo "Instalando dependências..."
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
echo " "
# Adicionar a chave GPG do Docker
echo "Adicionando a chave GPG do Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo " "
# Adicionar o repositório do Docker
echo "Adicionando o repositório do Docker..."
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
echo " "
# Instalar o Docker
echo "Instalando o Docker..."
    sudo apt update
    sudo apt install docker-ce -y
echo " "
# Verificar a versão do Docker
echo "Verificando a Versão do Docker..."
    docker --version
echo " "
# Habilitar a inicialização do Docker
echo "Habilitando a inicialização do Docker..."
    sudo systemctl enable docker
echo " "
# Adicionar o usuário ao grupo Docker
USER=$(whoami)
echo "Adicionando o usuário $USER ao grupo Docker..."
    sudo usermod -aG docker $USER
echo " "
# Instalar o Docker Compose
echo "Instalando o Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
echo " "
# Definir permissões para o Docker Compose
echo "Definindo permissões para o Docker Compose..."
    sudo chmod +x /usr/local/bin/docker-compose
echo " "
# Verificar a versão do Docker Compose
echo "Verificando a versão do Docker Compose..."
    docker-compose --version
echo " "
echo "Instalação concluída! O sistema será reiniciado para aplicar as alterações."
echo " "
    sleep 5
    sudo reboot
#fim_script
