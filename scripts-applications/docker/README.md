### 🐳 **Docker** (`docker/`)

- **`install_docker_full_ubuntu.sh`**:
  - **Função**: Realiza a instalação completa do Docker e do Docker Compose em servidores Ubuntu.
  - **Recursos**: Atualiza o sistema, adiciona o repositório oficial do Docker, instala o Docker CE e o Docker Compose, e adiciona o usuário ao grupo `docker`.
  - **Uso**: `sudo ./install_docker_full_ubuntu.sh`

- **`install_docker_full_zorin.sh`**:
  - **Função**: Instala o Docker e o Docker Compose em sistemas derivados do Ubuntu, como Zorin OS, Pop!_OS e Linux Mint.
  - **Recursos**: Detecta a distribuição, remove instalações antigas, otimiza os espelhos de pacotes e configura o ambiente de forma segura.
  - **Uso**: `sudo ./install_docker_full_zorin.sh`