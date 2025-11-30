# 🐳 Scripts de Instalação do Docker

Este diretório contém scripts para automatizar a instalação e configuração do Docker e Docker Compose em distribuições baseadas em Debian, como Ubuntu e Zorin OS.

## 📜 Estrutura de Diretórios

```
docker/
├── install_docker_full_ubuntu.sh
├── install_docker_full_zorin.sh
└── README.md
```

## 🚀 Scripts Disponíveis

### 1. `install_docker_full_ubuntu.sh`

- **Função**:
  Realiza a instalação completa do Docker e do Docker Compose em servidores **Ubuntu**.

- **Quando Utilizar**:
  Use este script para configurar um ambiente Docker do zero em uma nova instância do Ubuntu Server. Ele garante que todas as dependências e repositórios oficiais sejam corretamente configurados.

- **Recursos Principais**:
  - Atualiza a lista de pacotes do sistema (`apt-get update`).
  - Instala dependências necessárias para adicionar repositórios via HTTPS.
  - Adiciona a chave GPG oficial do Docker para garantir a autenticidade dos pacotes.
  - Configura o repositório oficial do Docker.
  - Instala a última versão estável do Docker Engine (`docker-ce`), CLI (`docker-ce-cli`) e `containerd.io`.
  - Instala o **Docker Compose** para orquestração de contêineres.
  - Adiciona o usuário que executa o script ao grupo `docker`, permitindo a execução de comandos Docker sem `sudo` (requer um novo login para ter efeito).

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x install_docker_full_ubuntu.sh
     ```
  2. **Executar com `sudo`**:
     ```bash
     sudo ./install_docker_full_ubuntu.sh
     ```

### 2. `install_docker_full_zorin.sh`

- **Função**:
  Realiza a instalação completa do Docker e do Docker Compose em sistemas **Zorin OS** e outros derivados do Ubuntu (como Pop!_OS, Linux Mint).

- **Quando Utilizar**:
  Ideal para ambientes de desktop ou desenvolvimento baseados em Zorin OS que precisam de um ambiente Docker funcional. O script adapta os passos de instalação para garantir compatibilidade.

- **Recursos Principais**:
  - Remove versões antigas ou não oficiais do Docker para evitar conflitos.
  - Executa as mesmas etapas do script para Ubuntu, garantindo uma instalação padronizada.
  - Otimiza a configuração para sistemas de desktop, se necessário.

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x install_docker_full_zorin.sh
     ```
  2. **Executar com `sudo`**:
     ```bash
     sudo ./install_docker_full_zorin.sh
     ```

## ⚠️ Pré-requisitos

- **Sistema Operacional**: Ubuntu Server (para `install_docker_full_ubuntu.sh`) ou Zorin OS (para `install_docker_full_zorin.sh`).
- **Acesso**: Permissões de `root` ou um usuário com privilégios `sudo`.
- **Conectividade**: Acesso à internet para download dos pacotes e chaves de repositório.

## 🔒 Notas de Segurança

- **Revisão de Código**: É sempre uma boa prática revisar o conteúdo de qualquer script antes de executá-lo com privilégios de superusuário.
- **Grupo Docker**: Adicionar um usuário ao grupo `docker` concede privilégios equivalentes ao de `root`. Certifique-se de que apenas usuários confiáveis tenham esse acesso. Após a execução do script, é necessário fazer logout e login novamente para que a alteração no grupo tenha efeito.
