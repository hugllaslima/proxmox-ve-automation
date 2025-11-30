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