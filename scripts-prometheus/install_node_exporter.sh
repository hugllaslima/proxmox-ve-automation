#!/bin/bash

# Script para instalar o Prometheus Node Exporter no Ubuntu Server 24.04 LTS

# --- Configurações ---
NODE_EXPORTER_VERSION="1.7.0"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_PORT="9100"

# --- Funções ---

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "ERRO: $1" >&2
    exit 1
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Início da Instalação ---
echo " "
echo "Iniciando a instalação do Prometheus Node Exporter v${NODE_EXPORTER_VERSION}..."
echo " "

# 1. Verificação de pré-requisitos
echo "Verificando pré-requisitos..."
    if ! command_exists wget; then
        echo "wget não encontrado. Instalando wget..."
        sudo apt update && sudo apt install -y wget || error_exit "Falha ao instalar wget."
    fi

    if ! command_exists tar; then
        echo "tar não encontrado. Instalando tar..."
        sudo apt update && sudo apt install -y tar || error_exit "Falha ao instalar tar."
    fi

# 2. Criação do usuário node_exporter
echo " "
echo "Criando usuário '${NODE_EXPORTER_USER}' para o Node Exporter..."
    if ! id -u "${NODE_EXPORTER_USER}" >/dev/null 2>&1; then
        sudo useradd -rs /bin/false "${NODE_EXPORTER_USER}" || error_exit "Falha ao criar o usuário '${NODE_EXPORTER_USER}'."
        echo "Usuário '${NODE_EXPORTER_USER}' criado com sucesso."
    else
        echo "Usuário '${NODE_EXPORTER_USER}' já existe. Prosseguindo."
    fi
echo " "

# 3. Baixar e extrair o Node Exporter
echo "Baixando Node Exporter de ${NODE_EXPORTER_URL}..."
TEMP_DIR=$(mktemp -d)
wget -q "${NODE_EXPORTER_URL}" -O "${TEMP_DIR}/node_exporter.tar.gz" || error_exit "Falha ao baixar o Node Exporter."
echo "Download concluído. Extraindo..."
tar xvfz "${TEMP_DIR}/node_exporter.tar.gz" -C "${TEMP_DIR}" || error_exit "Falha ao extrair o Node Exporter."
echo " "

# Encontrar o diretório extraído (ex: node_exporter-1.7.0.linux-amd64)
echo " "
EXTRACTED_DIR=$(find "${TEMP_DIR}" -maxdepth 1 -type d -name "node_exporter-*.linux-amd64" | head -n 1)
    if [ -z "${EXTRACTED_DIR}" ]; then
        error_exit "Não foi possível encontrar o diretório extraído do Node Exporter."
    fi
echo " "

# 4. Mover o binário e definir permissões
echo " "
echo "Movendo o binário 'node_exporter' para ${INSTALL_DIR}..."
sudo mv "${EXTRACTED_DIR}/node_exporter" "${INSTALL_DIR}/node_exporter" || error_exit "Falha ao mover o binário."
sudo chown "${NODE_EXPORTER_USER}:${NODE_EXPORTER_USER}" "${INSTALL_DIR}/node_exporter" || error_exit "Falha ao definir permissões para o binário."
echo "Binário movido e permissões definidas."
echo " "

# 5. Criar o arquivo de serviço systemd
echo " "
echo "Criando o arquivo de serviço systemd em ${SERVICE_FILE}..."
sudo bash -c "cat > ${SERVICE_FILE} <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
ExecStart=${INSTALL_DIR}/node_exporter

[Install]
WantedBy=multi-user.target
EOF" || error_exit "Falha ao criar o arquivo de serviço systemd."
echo "Arquivo de serviço systemd criado."
echo " "

# 6. Recarregar systemd, habilitar e iniciar o serviço
echo " "
echo "Recarregando systemd, habilitando e iniciando o serviço Node Exporter..."
sudo systemctl daemon-reload || error_exit "Falha ao recarregar o daemon systemd."
sudo systemctl enable node_exporter || error_exit "Falha ao habilitar o serviço node_exporter."
sudo systemctl start node_exporter || error_exit "Falha ao iniciar o serviço node_exporter."
echo "Serviço Node Exporter habilitado e iniciado."
echo " "

# 7. Verificar o status do Node Exporter
echo " "
echo "Verificando o status do Node Exporter..."
sudo systemctl status node_exporter | grep "Active:"
echo " "

# 8. Configurar o Firewall (UFW)
echo " "
echo "Configurando o firewall (UFW) para permitir a porta ${NODE_EXPORTER_PORT}..."
    if command_exists ufw; then
        sudo ufw allow "${NODE_EXPORTER_PORT}/tcp" || echo "Aviso: Falha ao adicionar regra UFW. Verifique manualmente."
        sudo ufw reload || echo "Aviso: Falha ao recarregar UFW. Verifique manualmente."
        echo "Porta ${NODE_EXPORTER_PORT} liberada no UFW (se o UFW estiver ativo)."
    else
        echo "UFW não encontrado. Por favor, configure seu firewall manualmente para a porta ${NODE_EXPORTER_PORT}."
    fi
echo " "

# 9. Limpar arquivos temporários
echo " "
echo "Limpando arquivos temporários..."
sudo rm -rf "${TEMP_DIR}"
echo " A Limpeza foi concluída com sucesso!"
echo " "

# 10. Final da Instalação
echo "Instalação do Node Exporter concluída com sucesso!"
echo "Você pode verificar as métricas em http://localhost:${NODE_EXPORTER_PORT}/metrics"
echo "Lembre-se de configurar seu Prometheus para raspar as métricas desta máquina na porta ${NODE_EXPORTER_PORT}."
echo " "
