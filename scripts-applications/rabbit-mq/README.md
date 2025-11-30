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