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
- `ubuntu_full_config_pve.sh` - Configuração inicial completa (timezone, SSH, Docker)
- `ubuntu_full_config_pve_v2.sh` - Versão aprimorada do script de configuração
- `install_docker_full.sh` - Instalação standalone do Docker e Docker Compose
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🔧 **scripts-ansible/**
Scripts para preparação de hosts para automação com Ansible:
- `add_host_ansible.sh` - Configuração completa de hosts para gerenciamento via Ansible (dependências, SSH, validações)
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
- `setup_runner.sh` - Configuração de Self-Hosted Runner
- `setup_runner_v2.sh` - Versão aprimorada do setup
- `cleanup_runner.sh` - Limpeza e remoção de runners
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🔑 **scripts-ssh/**
Scripts para configuração de acesso SSH:
- `add_key_ssh_public.sh` - Adiciona chave pública SSH com validação de formato, comentários identificando proprietário, confirmação interativa e preservação de permissões
- `add_ssh_key_public_login_block.sh` - Versão avançada com hardening SSH completo, desabilitação de login por senha e configuração opcional de sudo NOPASSWD
- `README.md` - Documentação detalhada sobre o uso dos scripts

### 🔌 **Agentes QEMU/**
Scripts para instalação de agentes QEMU:
- `apt_install_agent_qemu.sh` - Instalação do agente QEMU em sistemas baseados em APT
- `yum_install_agent_qemu.sh` - Instalação do agente QEMU em sistemas baseados em YUM
- `README.md` - Documentação detalhada sobre o QEMU Guest Agent e uso dos scripts

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

### Configuração de VMs Ubuntu
- ✅ Ajuste de timezone para America/Sao_Paulo
- ✅ Configuração de usuário sudo
- ✅ Setup completo de SSH com chaves
- ✅ Instalação do Docker e Docker Compose
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
- GitHub: [@seu-usuario](https://github.com/seu-usuario)

## 📚 Documentação Adicional

Cada diretório contém seu próprio README.md com instruções detalhadas e específicas para os scripts contidos nele.
