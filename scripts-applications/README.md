# Scripts para Automação de Aplicações

Este diretório contém scripts para automatizar a instalação e configuração de aplicações complexas, como RabbitMQ e OnlyOffice Document Server, em ambientes de servidor.

## 📖 Estrutura de Diretórios

Os scripts estão organizados em subdiretórios de acordo com a aplicação correspondente:

- **`docker/`**: Scripts para instalação e configuração do Docker e Docker Compose.
- **`onlyoffice-server/`**: Scripts para instalação, limpeza e solução de problemas do OnlyOffice Document Server.
- **`rabbit-mq/`**: Scripts para instalação, reconfiguração e limpeza do RabbitMQ.

## 📜 Scripts Disponíveis

### 🐳 **Docker** (`docker/`)

- **`install_docker_full_ubuntu.sh`**:
  - **Função**: Realiza a instalação completa do Docker e do Docker Compose em servidores Ubuntu.
  - **Recursos**: Atualiza o sistema, adiciona o repositório oficial do Docker, instala o Docker CE e o Docker Compose, e adiciona o usuário ao grupo `docker`.
  - **Uso**: `sudo ./install_docker_full_ubuntu.sh`

- **`install_docker_full_zorin.sh`**:
  - **Função**: Instala o Docker e o Docker Compose em sistemas derivados do Ubuntu, como Zorin OS, Pop!_OS e Linux Mint.
  - **Recursos**: Detecta a distribuição, remove instalações antigas, otimiza os espelhos de pacotes e configura o ambiente de forma segura.
  - **Uso**: `sudo ./install_docker_full_zorin.sh`

### 🏢 **OnlyOffice Document Server** (`onlyoffice-server/`)

- **`install_onlyoffice_server_v2.sh`**:
  - **Função**: Instala e configura o OnlyOffice Document Server, integrando-o com um servidor RabbitMQ externo e um Nextcloud.
  - **Recursos**: Coleta interativa de IPs, geração de senhas, teste de conexão com RabbitMQ e configuração completa.
  - **Uso**: `sudo ./install_onlyoffice_server_v2.sh`
  - **Nota**: Versão recomendada para novas instalações.

- **`install_onlyoffice_server.sh`**:
  - **Função**: Versão anterior do script de instalação do OnlyOffice.
  - **Status**: Legado. Use a `v2` para novas instalações.

- **`cleanup_onlyoffice.sh`**:
  - **Função**: Remove completamente uma instalação do OnlyOffice Document Server, incluindo pacotes, configurações e dados.
  - **Uso**: `sudo ./cleanup_onlyoffice.sh`

- **`onlyoffice_troubleshooting_kit.sh`**:
  - **Função**: Kit de ferramentas para diagnosticar e resolver problemas comuns no OnlyOffice, como falhas de conexão e erros de serviço.
  - **Uso**: `sudo ./onlyoffice_troubleshooting_kit.sh`

### 🐇 **RabbitMQ** (`rabbit-mq/`)

- **`install_rabbit_mq.sh`**:
  - **Função**: Instala e configura um servidor RabbitMQ dedicado.
  - **Recursos**: Criação de administrador e usuários de serviço, habilitação do painel de gerenciamento e configuração de firewall.
  - **Uso**: `sudo ./install_rabbit_mq.sh`

- **`reconfigure_rabbit_mq.sh`**:
  - **Função**: Permite reconfigurar um servidor RabbitMQ existente, adicionando novos usuários e vhosts.
  - **Uso**: `sudo ./reconfigure_rabbit_mq.sh`

- **`cleanup_rabbit_mq.sh`**:
  - **Função**: Remove completamente uma instalação do RabbitMQ.
  - **Uso**: `sudo ./cleanup_rabbit_mq.sh`

## 🚀 Como Usar

1. **Navegue até o diretório da aplicação:**
   ```bash
   cd scripts-applications/docker/
   # ou
   cd scripts-applications/onlyoffice-server/
   # ou
   cd scripts-applications/rabbit-mq/
   ```

2. **Torne o script executável:**
   ```bash
   chmod +x nome_do_script.sh
   ```

3. **Execute o script com `sudo`:**
   ```bash
   sudo ./nome_do_script.sh
   ```

## ⚠️ Pré-requisitos

- **Sistema Operacional**: Ubuntu Server 24.04 LTS (ou compatível).
- **Acesso**: Permissões de `root` ou `sudo`.
- **Conectividade**: Acesso à internet para download de pacotes.
- **Servidores Externos**: Para o OnlyOffice, é necessário um servidor RabbitMQ e um Nextcloud já configurados.

## 🔒 Segurança

- **Revisão**: Sempre revise o conteúdo dos scripts antes de executá-los.
- **Backup**: Faça backup de seus dados antes de qualquer operação.
- **Credenciais**: Os scripts podem salvar informações sensíveis em `/root/`. Mova esses arquivos para um local seguro.
