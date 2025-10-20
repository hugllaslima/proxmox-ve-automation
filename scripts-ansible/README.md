# Scripts de Configuração para Automação com Ansible

Este diretório contém scripts para preparar hosts (VMs e containers LXC) para gerenciamento e automação via Ansible no ambiente Proxmox VE.

## 📋 Scripts Disponíveis

### 🔧 `add_host_ansible.sh`
**Configuração de hosts para gerenciamento via Ansible**

**Objetivo:**
Preparar máquinas virtuais e containers LXC para serem gerenciados remotamente pelo Ansible, configurando acesso SSH seguro com chaves públicas.

**Funcionalidades:**

#### 🔍 **Verificação de Dependências (Opcional)**
- Verificação e instalação automática do `sudo`
- Verificação e instalação automática do `openssh-client`
- Opção de pular esta etapa se as dependências já estiverem instaladas

#### 🔄 **Atualização do Sistema (Opcional)**
- Atualização completa do sistema operacional (`apt update && apt upgrade -y`)
- Recomendado para ambientes de inicialização ou manutenção
- Opção de pular para ambientes já atualizados

#### 🔐 **Configuração SSH para Ansible**
- **Detecção automática do diretório home:** Funciona com qualquer usuário (ubuntu, debian, ansible, root, etc.)
- **Suporte a diferentes tipos de host:** VMs Linux e Containers LXC
- **Configuração segura de chaves SSH:**
  - Criação do diretório `.ssh` com permissões adequadas
  - Adição da chave pública ao `authorized_keys`
  - Remoção de duplicatas automática
  - Configuração correta de permissões (600 para authorized_keys, 700 para .ssh)
  - Configuração correta de ownership
  - **Comentários identificando proprietário:** Inclui descrição da chave, quem adicionou e data/hora
  - **Validação de formato SSH:** Verifica se a chave está em formato válido
  - **Confirmação interativa:** Todas as informações são confirmadas antes da execução

#### 🛡️ **Hardening SSH Recomendado**
- Orientações para configuração segura do SSH
- Recomendações para desabilitar autenticação por senha
- Instruções para habilitar apenas autenticação por chave pública

**Uso:**
```bash
chmod +x add_host_ansible.sh
sudo ./add_host_ansible.sh
```

**Fluxo Interativo:**
1. **Verificação de Dependências:** Escolha se deseja verificar/instalar sudo e openssh-client
2. **Atualização do Sistema:** Escolha se deseja atualizar o sistema operacional
3. **Configuração do Usuário:** Informe o usuário que receberá a chave SSH
4. **Tipo de Host:** Identifique se é VM Linux ou Container LXC (para logs)
5. **Descrição da Chave:** Informe uma descrição identificando o proprietário da chave
6. **Chave Pública:** Cole a chave pública do usuário Ansible

**Exemplo de Execução:**
```bash
$ sudo ./add_host_ansible.sh

Deseja verificar se 'sudo' e 'openssh-client' estão instalados?
Digite 1 para SIM (verificar e instalar se faltar)
Digite 2 para NÃO (pular essa etapa)
Sua escolha: 1

Deseja atualizar o sistema operacional (apt update/upgrade)?
Digite 1 para SIM (recomendado em ambientes de manutenção ou inicialização)
Digite 2 para NÃO (pular essa etapa)
Sua escolha: 2

Informe o usuário do HOST que irá receber a chave pública para acesso via SSH (ex: ubuntu, debian, ansible, root).
ubuntu

Esta máquina é:
1) VM Linux (usuário ubuntu)
2) Container LXC (usuário ubuntu)
Digite 1 ou 2 (só para log/registro): 1

Qual a descrição desta chave pública? (Ex: 'Hugllas Lima (Linux)', 'Ansible (Server)', 'Servidor de Backup'):
Ansible Control Node

Cole a chave pública do usuário "ansible" (linha única):
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... ansible@control-node
```

## 🔗 Scripts Relacionados

### Configuração Adicional de SSH
Para configurações mais avançadas de SSH ou adição de chaves a usuários específicos, utilize:
- **`../scripts-ssh/add_key_ssh_public.sh`** - Script dedicado para adição de chaves SSH com validação completa

**Diferenças entre os scripts:**
- **`add_host_ansible.sh`**: Focado na preparação completa de hosts para Ansible (dependências + SSH)
- **`add_key_ssh_public.sh`**: Focado exclusivamente na adição segura de chaves SSH a qualquer usuário

## 🎯 Casos de Uso

### Para Infraestrutura Ansible:
- **Servidor de Controle Ansible:** Configure hosts para serem gerenciados
- **Inventário Dinâmico:** Prepare múltiplos hosts rapidamente
- **Automação em Larga Escala:** Padronize configuração SSH em toda infraestrutura

### Para Administração Remota:
- **Acesso Seguro:** Configure acesso SSH sem senha
- **Manutenção Remota:** Prepare hosts para administração centralizada
- **Backup e Monitoramento:** Configure acesso para scripts automatizados

## ⚠️ Pré-requisitos

- Sistema Ubuntu/Debian (VM ou Container LXC)
- Acesso root ou sudo
- Usuário de destino já criado no sistema
- Chave pública SSH do servidor Ansible/controle

## 🔒 Configuração SSH Recomendada

Após executar o script, configure o SSH para máxima segurança:

### Editar `/etc/ssh/sshd_config`:
```bash
sudo nano /etc/ssh/sshd_config
```

### Configurações recomendadas:
```bash
# Habilitar autenticação por chave pública
PubkeyAuthentication yes

# Desabilitar autenticação por senha
PasswordAuthentication no

# Desabilitar autenticação interativa
KbdInteractiveAuthentication no

# Especificar arquivo de chaves autorizadas
AuthorizedKeysFile .ssh/authorized_keys
```

### Reiniciar o serviço SSH:
```bash
sudo systemctl restart ssh
```

## 📝 Verificações Pós-Configuração

### Testar conexão SSH:
```bash
# Do servidor Ansible/controle
ssh usuario@ip-do-host

# Testar com chave específica
ssh -i /path/to/private/key usuario@ip-do-host
```

### Verificar configurações:
```bash
# Verificar permissões
ls -la ~/.ssh/
ls -la ~/.ssh/authorized_keys

# Verificar conteúdo das chaves
cat ~/.ssh/authorized_keys

# Verificar status SSH
sudo systemctl status ssh
```

## 🚀 Integração com Ansible

### Exemplo de inventário:
```ini
[proxmox_vms]
vm1 ansible_host=192.168.1.10 ansible_user=ubuntu
vm2 ansible_host=192.168.1.11 ansible_user=ubuntu

[proxmox_lxc]
lxc1 ansible_host=192.168.1.20 ansible_user=debian
lxc2 ansible_host=192.168.1.21 ansible_user=debian
```

### Teste de conectividade:
```bash
ansible all -i inventory.ini -m ping
```

## 🤝 Contribuição

Para melhorias ou correções:
1. Teste em ambiente de desenvolvimento
2. Mantenha compatibilidade com Ubuntu/Debian
3. Documente mudanças no cabeçalho do script

## 📄 Licença

GPL-3.0 - Veja o arquivo LICENSE no diretório raiz.
