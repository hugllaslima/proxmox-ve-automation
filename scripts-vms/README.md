# Scripts para VMs no Proxmox VE

Este diretório contém scripts para criação e configuração de máquinas virtuais no Proxmox VE, incluindo criação de VMs, configuração inicial de Ubuntu Server e instalação de Docker.

## 📋 Scripts Disponíveis

### 🐳 `install_docker_full.sh`
**Instalação completa do Docker e Docker Compose**

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
chmod +x install_docker_full.sh
sudo ./install_docker_full.sh
```

**Pós-instalação:**
- Faça logout e login novamente para aplicar as permissões do grupo docker
- Teste com: `docker --version` e `docker-compose --version`

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
**Configuração inicial completa para Ubuntu Server no Proxmox VE**

**Funcionalidades:**
- **Configuração de Sistema:**
  - Ajuste do timezone para America/Sao_Paulo
  - Atualização completa do sistema operacional
  - Instalação do qemu-guest-agent para integração com Proxmox

- **Configuração de Usuário:**
  - Adição do usuário 'ubuntu' ao grupo sudo
  - Configuração de sudo sem senha para o usuário ubuntu

- **Configuração SSH Avançada:**
  - Criação e configuração do diretório .ssh
  - Entrada manual de chave privada SSH
  - Geração automática da chave pública correspondente
  - Opção de remoção segura da chave privada após configuração
  - Configuração do arquivo authorized_keys

- **Hardening SSH:**
  - Habilitação da autenticação por chave pública
  - Desabilitação da autenticação por senha
  - Desabilitação da autenticação interativa por teclado
  - Backup automático da configuração SSH original
  - Reinicialização do serviço SSH

- **Instalação Opcional do Docker:**
  - Instalação completa do Docker CE e Docker Compose
  - Configuração do usuário ubuntu para usar Docker

**Uso:**
```bash
chmod +x ubuntu_full_config_pve.sh
sudo ./ubuntu_full_config_pve.sh
```

**Importante:**
- Execute como root (sudo su)
- Tenha sua chave SSH privada pronta para inserção
- Teste o acesso SSH em outra sessão antes de reiniciar

---

### ⚙️ `ubuntu_full_config_pve_v2.sh`
**Versão aprimorada do script de configuração inicial**

**Melhorias da v2:**
- Interface de usuário aprimorada com melhor feedback visual
- Tratamento de erros mais robusto
- Validações adicionais de segurança
- Processo de configuração SSH otimizado
- Melhor gerenciamento de permissões
- Logs mais detalhados das operações

**Funcionalidades:** (Mesmas da v1 com melhorias)
- Todas as funcionalidades do script v1
- Melhor tratamento de exceções
- Validações de entrada mais rigorosas
- Feedback visual aprimorado durante a execução

**Uso:**
```bash
chmod +x ubuntu_full_config_pve_v2.sh
sudo ./ubuntu_full_config_pve_v2.sh
```

## 🚀 Fluxo de Uso Recomendado

### Para Criação de Nova VM:
1. **Recomendado:** Execute `create_vm_v2.sh` para criação com interface aprimorada e validações robustas
2. **Alternativo:** Use `create_vm.sh` se preferir a versão original mais simples

### Para Nova VM Ubuntu:
1. **Primeiro:** Execute `create_vm_v2.sh` ou `create_vm.sh` para criar a VM
2. **Segundo:** Execute `ubuntu_full_config_pve_v2.sh` para configuração inicial completa
3. **Alternativo:** Use `ubuntu_full_config_pve.sh` se preferir a versão original

### Para Instalação Apenas do Docker:
1. Execute `install_docker_full.sh` em uma VM já configurada

## ⚠️ Pré-requisitos

- Proxmox VE com ferramentas CLI
- Ubuntu Server 20.04 LTS ou superior (para scripts de configuração de Ubuntu)
- Acesso root ou sudo
- Conexão com a internet
- Chave SSH privada (para scripts de configuração completa)
- VM criada no Proxmox VE

## 🔒 Considerações de Segurança

- **Backup:** Sempre faça snapshot da VM antes de executar os scripts
- **Chaves SSH:** Os scripts oferecem opção de remoção segura da chave privada após configuração
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
