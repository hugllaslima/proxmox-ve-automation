# Scripts para VMs no Proxmox VE

Este diretório contém scripts para criação e configuração de máquinas virtuais no Proxmox VE, incluindo criação de VMs e configuração inicial de Ubuntu Server.

## 📋 Scripts Disponíveis





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
