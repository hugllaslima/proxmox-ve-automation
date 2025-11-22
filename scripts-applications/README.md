# Scripts para Automação de Aplicações

Este diretório contém scripts para automatizar a instalação e configuração de aplicações complexas, como RabbitMQ e OnlyOffice Document Server, em ambientes de servidor.

## 📜 Scripts Disponíveis

### 🐇 **RabbitMQ**

- **`install_rabbit_mq.sh`**:
  - **Função**: Instala e configura um servidor RabbitMQ dedicado.
  - **Recursos**:
    - Interativo: Coleta informações de IP, usuários e senhas.
    - Criação de administrador e usuários de serviço com vhosts.
    - Habilita o painel de gerenciamento (`rabbitmq_management`).
    - Configura o firewall (UFW) para as portas necessárias.
    - Salva as credenciais em um arquivo seguro.
  - **Uso**: `sudo ./install_rabbit_mq.sh`

- **`cleanup_rabbit_mq.sh`**:
  - **Função**: Remove completamente uma instalação do RabbitMQ, incluindo pacotes, diretórios de dados, usuários e repositórios.
  - **Recursos**:
    - Confirmação de segurança para evitar remoção acidental.
    - Limpeza completa para uma reinstalação limpa.
  - **Uso**: `sudo ./cleanup_rabbit_mq.sh`

### 🏢 **OnlyOffice Document Server**

- **`install_onlyoffice_server_v2.sh`**:
  - **Função**: Instala e configura o OnlyOffice Document Server, integrando-o com um servidor RabbitMQ externo e um Nextcloud.
  - **Recursos**:
    - Coleta interativa de IPs (OnlyOffice, Nextcloud, RabbitMQ) e credenciais.
    - Geração automática de senhas e JWT secrets.
    - Testa a conexão com o RabbitMQ antes de prosseguir.
    - Configura o PostgreSQL local para o OnlyOffice.
    - Desabilita o RabbitMQ local para usar a instância externa.
    - Salva todas as configurações e credenciais em um arquivo.
  - **Uso**: `sudo ./install_onlyoffice_server_v2.sh`

- **`install_onlyoffice_server.sh`**:
  - **Função**: Versão anterior do script de instalação do OnlyOffice.
  - **Status**: Legado. Recomenda-se o uso da `v2` para novas instalações.

## 🚀 Como Usar

1. **Navegue até o diretório:**
   ```bash
   cd scripts-applications/
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
- **Conectividade**: Acesso à internet para download de pacotes e dependências.
- **Servidores Externos**: Para o OnlyOffice, é necessário um servidor RabbitMQ e um Nextcloud já configurados e acessíveis pela rede.

## 🔒 Segurança

- **Revisão**: Sempre revise o conteúdo dos scripts antes de executá-los em produção.
- **Backup**: Faça backup de seus dados e configurações antes de iniciar uma nova instalação.
- **Credenciais**: Os scripts salvam informações sensíveis em arquivos de texto no diretório `/root/`. Certifique-se de movê-los para um local seguro após a instalação.