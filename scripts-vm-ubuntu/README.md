# Scripts de Configuração para VMs Ubuntu no Proxmox VE

Este diretório contém scripts especializados para configuração completa de máquinas virtuais Ubuntu Server no ambiente Proxmox VE.

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

### Para Nova VM Ubuntu:
1. **Primeiro:** Execute `ubuntu_full_config_pve_v2.sh` para configuração inicial completa
2. **Alternativo:** Use `ubuntu_full_config_pve.sh` se preferir a versão original

### Para Instalação Apenas do Docker:
1. Execute `install_docker_full.sh` em uma VM já configurada

## ⚠️ Pré-requisitos

- Ubuntu Server 20.04 LTS ou superior
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

### 2°) Execução
$ sudo ./ansible_config_host.sh
