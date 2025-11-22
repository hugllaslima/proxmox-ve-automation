# Proxmox VE Automation Scripts

Este repositório contém uma coleção de scripts de automação para Proxmox VE, desenvolvidos para facilitar a configuração, manutenção e gerenciamento de infraestruturas virtualizadas locais.

## 🎯 Objetivo

Automatizar processos repetitivos e padronizar configurações em ambientes Proxmox VE, incluindo:
- Configuração inicial de VMs Ubuntu
- Instalação e configuração do Docker
- Setup de agentes QEMU
- Backup automatizado do Proxmox VE
- Configuração de containers LXC
- Preparação de hosts para Ansible
- Monitoramento com Prometheus
- Setup de Self-Hosted Runners

## 📁 Estrutura do Repositório

### 🖥️ **scripts-vms/**
Scripts para criação e configuração de VMs no Proxmox VE:
- `create_vm.sh` - Criação interativa de VMs via `qm` com validações e ISO opcional
- `create_vm_v2.sh` - Versão aprimorada com interface melhorada e validações robustas
- `ubuntu_full_config_pve.sh` - Configuração inicial completa (versão aprimorada)
- `install_docker_full_ubuntu.sh` - Instalação do Docker e Docker Compose para Ubuntu Server
- `install_docker_full_zorin.sh` - Instalação do Docker para Zorin OS e derivados do Ubuntu
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🔧 **scripts-ansible/**
Scripts para preparação de hosts para automação com Ansible:
- `add_host_ansible.sh` - Prepara usuários existentes para gerenciamento Ansible: checagens opcionais de dependências e atualização do SO, validações robustas de usuário/home, adição de chave pública com comentário incluindo quem adicionou (via `SUDO_USER`) e data/hora, preview e validação de formato, prevenção de duplicidade. Não cria usuário, não altera `sudoers` e não modifica `sshd_config`.
  - Para hardening completo do SSH e `NOPASSWD` opcional, use `scripts-ssh/add_key_ssh_public_login_block.sh`.
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 💾 **scripts-backups/**
Scripts para backup e proteção de dados:
- `backup_full_proxmox_ve.sh` - Backup completo das configurações do Proxmox VE
- `backups_usb_external.sh` - Backup para dispositivos USB externos
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 📦 **scripts-container-lxc/**
Scripts para configuração de containers LXC:
- `create_user_lxc.sh` - Criação e configuração de usuários em containers LXC
- `create_user_lxc_2.sh` - Versão alternativa do script de criação de usuários
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 📊 **scripts-prometheus/**
Scripts para monitoramento:
- `install_node_exporter.sh` - Instalação do Prometheus Node Exporter
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🏃 **scripts-self-hosted-runner/**
Scripts para configuração de runners:
- `setup_runner.sh` - Script padrão (v2.0), robusto e recomendado para produção: logging, checkpoints, validação de comandos, rollback e recuperação, captura de Ctrl+C, verificações de status e interface interativa.
- `setup_runner_legacy.sh` - Versão legada (v1.0), fluxo simples/linear para laboratório e cenários básicos.
- `cleanup_runner.sh` - Limpeza e remoção de runners
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🔑 **scripts-ssh/**
Scripts para configuração de acesso SSH:
- `add_key_ssh_public.sh` - Adiciona chave pública SSH com validação de formato, comentários identificando proprietário, confirmação interativa e preservação de permissões
- `add_key_ssh_public_login_block.sh` - Versão avançada com hardening SSH completo, desabilitação de login por senha, configuração opcional de sudo NOPASSWD, validação robusta de usuário, prévia de chave aprimorada e opções para chaves duplicadas (substituir, excluir ou manter)
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🔌 **Agentes QEMU/**
Scripts para instalação de agentes QEMU:
- `apt_install_agent_qemu.sh` - Instalação do agente QEMU em sistemas baseados em APT
- `yum_install_agent_qemu.sh` - Instalação do agente QEMU em sistemas baseados em YUM
- `README.md` - Documentação detalhada sobre o QEMU Guest Agent e uso dos scripts

### 🖥️ **scripts-applications/**
Este diretório contém scripts para automatizar a instalação e configuração de aplicações em servidores dedicados. Cada script é projetado para ser modular e interativo, facilitando a implantação de serviços como RabbitMQ e OnlyOffice.
- `install_rabbit_mq.sh` - Instala e configura um servidor RabbitMQ dedicado.
- `cleanup_rabbit_mq.sh` - Remove completamente uma instalação do RabbitMQ.
- `install_onlyoffice_server_v2.sh` - Instala o OnlyOffice Document Server (versão recomendada).
- `install_onlyoffice_server.sh` - Instala o OnlyOffice Document Server (versão legada).
- `README.md` - Documentação detalhada sobre os scripts de aplicação.

### 🖥️ **scripts-zorin-os/**
Scripts específicos para a distribuição Zorin OS:
- `read_only_mounted_disk.sh` - Corrige problemas de disco montado como somente leitura
- `README.md` - Documentação detalhada sobre o uso dos scripts

## 🚀 Como Usar

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/hugllaslima/proxmox-ve-automation.git
   cd proxmox-ve-automation
   ```

2. **Navegue até o diretório desejado:**
   ```bash
   cd scripts-vms/
   ```

3. **Torne o script executável:**
   ```bash
   chmod +x nome_do_script.sh
   ```

4. **Execute o script:**
   ```bash
   sudo ./nome_do_script.sh
   ```

## ⚠️ Pré-requisitos

- Proxmox VE instalado e configurado
- Acesso root ou sudo nos sistemas alvo
- Conexão com a internet para download de pacotes
- Backup dos sistemas antes de executar os scripts

## 🔒 Segurança

- **Sempre** faça backup antes de executar qualquer script
- Revise o conteúdo dos scripts antes da execução
- Execute em ambiente de teste primeiro
- Mantenha credenciais em arquivos `.env` (nunca no código)

## 📋 Funcionalidades Principais

### Configuração de VMs Ubuntu e Derivados
- ✅ Ajuste de timezone para America/Sao_Paulo
- ✅ Configuração de usuário sudo
- ✅ Setup completo de SSH com chaves
- ✅ Instalação do Docker e Docker Compose (Ubuntu Server e Zorin OS)
- ✅ Suporte a distribuições baseadas em Ubuntu (Zorin OS, Pop!_OS, Linux Mint, Elementary OS)
- ✅ Instalação do agente QEMU

### Backup e Segurança
- ✅ Backup completo das configurações do Proxmox
- ✅ Backup de chaves SSH e certificados
- ✅ Backup para dispositivos externos

### Monitoramento
- ✅ Instalação do Node Exporter para Prometheus
- ✅ Configuração automática de serviços

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor:
1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a GPL-3.0 - veja o arquivo LICENSE para detalhes.

## 👨‍💻 Autor

**Hugllas R S Lima**
- Email: hugllaslima@gmail.com
- GitHub: [@hugllaslima](https://github.com/hugllaslima)

## 📚 Documentação Adicional

Cada diretório contém seu próprio README.md com instruções detalhadas e específicas para os scripts contidos nele.
