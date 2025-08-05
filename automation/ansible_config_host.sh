#!/bin/bash
#
# ansible_config_host.sh - Script de Configuracao para Automação com Ansible
#
# - Autor....................: Hugllas R S Lima 
# - Data.....................: 2025-08-05
# - Versão...................: 1.0.0
#
# Etapas:
#    - $ ./ansible_config_host.sh
#        - {}
#        - {}
#        - {}
#        - {}
#
# Histórico:
#    - v1.0.0 2025-08-05, Hugllas Lima
#        - Cabeçalho
#        - Discrição
#        - Funções
#
# Uso:
#   - sudo ./ansible_config_host.sh
#
# Licença: GPL-3.0
#

# ------------------------------------------------------------------------------
# Verificando as Dependências do 
# ------------------------------------------------------------------------------

garante_sudo_e_openssh() {
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[INFO] 'sudo' não encontrado. Instalando..."
        apt update && apt install sudo -y
        echo "[INFO] 'sudo' instalado!"
    fi
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        echo "[INFO] 'ssh-keygen' (openssh-client) não encontrado. Instalando..."
        sudo apt update && sudo apt install openssh-client -y
        echo "[INFO] 'openssh-client' instalado!"
    else
        echo "[INFO] 'openssh-client' já instalado."
    fi
}

# ------------------------------------------------------------------------------
# Ataualizando e Configurando o Template
# ------------------------------------------------------------------------------






# fim_script
