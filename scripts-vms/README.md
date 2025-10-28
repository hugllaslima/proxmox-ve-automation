# Scripts para VMs no Proxmox VE

Este diretório contém scripts para criação e configuração de máquinas virtuais no Proxmox VE, incluindo criação de VMs, configuração inicial de Ubuntu Server e instalação de Docker.

## 📋 Scripts Disponíveis

### 🐳 `install_docker_full_ubuntu.sh`
**Instalação completa do Docker e Docker Compose para Ubuntu Server**

**Funcionalidades:**
- Atualização completa do sistema Ubuntu
- Instalação de dependências necessárias (apt-transport-https, ca-certificates, curl, software-properties-common)
- Adição da chave GPG oficial do Docker
- Configuração do repositório oficial do Docker
- Instalação do Docker CE (Community Edition)
- Habilitação do serviço Docker para inicialização automática
- Adição do usuário atual ao grupo docker
- Instalação da versão mais recente do Docker Compose
- Configuração de permissões adequadas
- Verificação das versões instaladas

**Uso:**
```bash
chmod +x install_docker_full_ubuntu.sh
sudo ./install_docker_full_ubuntu.sh
```

**Pós-instalação:**
- Faça logout e login novamente para aplicar as permissões do grupo docker
- Teste com: `docker --version` e `docker-compose --version`

### 🐳 `install_docker_full_zorin.sh`
**Instalação completa do Docker e Docker Compose para Zorin OS e derivados do Ubuntu**

**Funcionalidades:**
- Detecção automática da distribuição (Zorin OS, Pop!_OS, Linux Mint, Elementary OS)
- Limpeza completa de instalações anteriores do Docker
- Otimização de mirrors para evitar erros de sincronização
- Atualização completa do sistema
- Instalação de dependências necessárias
- Adição da chave GPG do Docker usando método moderno (keyrings)
- Configuração do repositório Docker baseado na versão Ubuntu correspondente
- Instalação do Docker CE e plugins
- Configuração de permissões do usuário
- Teste automático da instalação
- Limpeza final do sistema

**Uso:**
```bash
chmod +x install_docker_full_zorin.sh
sudo ./install_docker_full_zorin.sh
```

**Sistemas Suportados:**
- Zorin OS Core/Pro (baseado em Ubuntu)
- Pop!_OS
- Linux Mint
- Elementary OS
- Outros derivados do Ubuntu

**Pós-instalação:**
- Faça logout e login novamente para aplicar as permissões do grupo docker
- Teste com: `docker --version` e `docker compose version`

### 🧩 `create_vm.sh`
**Criação interativa de VMs no Proxmox VE (qm)**

**Funcionalidades:**
- Verificação de execução como root
- Coleta interativa de ID, nome, RAM, núcleos de CPU, tamanho de disco
- Seleção de storage para o disco (conteúdo `images`)
- Seleção do tipo de OS (`l26`, `win10`, `other`)
- Anexo opcional de imagem ISO a partir de storages com conteúdo `iso`
- Resumo final e confirmação antes da criação
- Criação via `qm create` com parâmetros padrão (virtio-scsi, virtio net, boot order)

**Uso:**
```bash
chmod +x create_vm.sh
sudo ./create_vm.sh
```

**Pré-requisitos:**
- Proxmox VE com ferramentas CLI: `pvesh`, `pvesm`, `qm`
- `jq` instalado (utilizado para parse de JSON)
- Execução como `root` ou com `sudo`

---

### 🧩 `create_vm_v2.sh`
**Criação interativa de VMs no Proxmox VE - Versão Aprimorada**

**Funcionalidades:**
- Todas as funcionalidades do `create_vm.sh` com melhorias significativas
- Listagem inteligente de storages por tipo de conteúdo (sem dependência obrigatória do `jq`)
- Listagem automática de ISOs disponíveis em cada storage
- Interface mais amigável com confirmações em cada etapa
- Melhor tratamento de erros e validações
- Suporte aprimorado a diferentes tipos de OS com nomes amigáveis
- Validação robusta de formato de tamanho de disco (G/M)
- Verificação automática de duplicidade de VMID
- Processo de configuração mais intuitivo e seguro

**Melhorias da V2:**
- ✅ Dependência opcional do `jq` (funciona sem ele)
- ✅ Listagem dinâmica de recursos do Proxmox
- ✅ Interface de usuário aprimorada
- ✅ Validações mais rigorosas
- ✅ Melhor documentação e comentários
- ✅ Tratamento de erros mais robusto

**Uso:**
```bash
chmod +x create_vm_v2.sh
sudo ./create_vm_v2.sh
```

**Pré-requisitos:**
- Proxmox VE com ferramentas CLI: `pvesh`, `pvesm`, `qm`
- `jq` (opcional, mas recomendado para melhor performance)
- Execução como `root` ou com `sudo`
- Storages configurados no Proxmox para 'images' e 'iso'

---



### ⚙️ `ubuntu_full_config_pve.sh`
**Versão aprimorada do script de configuração inicial**

**Melhorias:**
- Interface de usuário aprimorada com melhor feedback visual
- Tratamento de erros mais robusto
- Validações adicionais de segurança
- Processo de configuração SSH otimizado
- Melhor gerenciamento de permissões
- Logs mais detalhados das operações

**Funcionalidades:** 
- Melhor tratamento de exceções
- Validações de entrada mais rigorosas
- Feedback visual aprimorado durante a execução

**Uso:**
```bash
chmod +x ubuntu_full_config_pve.sh
sudo ./ubuntu_full_config_pve.sh
```

## 🚀 Fluxo de Uso Recomendado

### Para Criação de Nova VM:
1. **Recomendado:** Execute `create_vm_v2.sh` para criação com interface aprimorada e validações robustas
2. **Alternativo:** Use `create_vm.sh` se preferir a versão original mais simples

### Para Nova VM Ubuntu:
1. **Primeiro:** Execute `create_vm_v2.sh` ou `create_vm.sh` para criar a VM
2. **Segundo:** Execute `ubuntu_full_config_pve.sh` para configuração inicial completa


### Para Instalação Apenas do Docker:
1. **Ubuntu Server:** Execute `install_docker_full_ubuntu.sh` em uma VM Ubuntu já configurada
2. **Zorin OS/Derivados:** Execute `install_docker_full_zorin.sh` em sistemas baseados em Ubuntu (Zorin, Pop!_OS, Mint, etc.)

## ⚠️ Pré-requisitos

- Proxmox VE com ferramentas CLI
- Ubuntu Server 20.04 LTS ou superior (para scripts de configuração de Ubuntu)
- Acesso root ou sudo
- Conexão com a internet
- Chave SSH pública (para configuração SSH no v2)
- VM criada no Proxmox VE

## 🔒 Considerações de Segurança

- **Backup:** Sempre faça snapshot da VM antes de executar os scripts
- **Chaves SSH:** O script v2 solicita chave pública e preserva chaves existentes
- **Teste SSH:** Sempre teste o acesso SSH em outra sessão antes de reiniciar
- **Sudo:** Scripts configuram sudo sem senha apenas para o usuário 'ubuntu'

## 📝 Logs e Troubleshooting

### Verificações Pós-Execução:
```bash
# Verificar timezone
timedatectl

# Verificar serviços
systemctl status qemu-guest-agent
systemctl status docker
systemctl status ssh

# Verificar usuário no grupo docker
groups ubuntu

# Testar Docker
docker --version
docker-compose --version
```

### Arquivos de Configuração Importantes:
- `/etc/ssh/sshd_config` - Configuração SSH
- `/etc/sudoers.d/ubuntu` - Configuração sudo
- `/home/ubuntu/.ssh/` - Chaves SSH do usuário

## 🤝 Contribuição

Para melhorias ou correções:
1. Teste em ambiente de desenvolvimento
2. Documente mudanças no cabeçalho do script
3. Mantenha compatibilidade com versões LTS do Ubuntu

## 📄 Licença

GPL-3.0 - Veja o arquivo LICENSE no diretório raiz.
