# 🤖 Scripts de Automação para Máquinas Virtuais (VMs) em Proxmox

Este diretório contém scripts para automatizar a criação, configuração e gerenciamento de Máquinas Virtuais (VMs) no ambiente de virtualização **Proxmox VE**.

## 📜 Estrutura de Diretórios

```
scripts-vms/
├── create_vm_ubuntu_server.sh
└── README.md
```

## 🚀 Scripts Disponíveis

### 1. `create_vm_ubuntu_server.sh`

- **Função**:
  Automatiza a criação de uma nova Máquina Virtual (VM) no Proxmox VE, configurada com **Ubuntu Server 22.04 LTS**. O script utiliza a imagem de cloud-init para provisionamento rápido e personalizável.

- **Quando Utilizar**:
  Use este script para provisionar rapidamente novas VMs Ubuntu Server em seu cluster Proxmox. É ideal para criar ambientes de desenvolvimento, teste ou produção de forma padronizada e repetível, economizando tempo e evitando erros manuais.

- **Recursos Principais**:
  - **Criação a partir de Template**: Clona uma VM a partir de um template de cloud-init (ID 9000 por padrão), garantindo consistência.
  - **Coleta Interativa de Dados**: Solicita ao usuário informações essenciais para a nova VM:
    - **VM ID**: O identificador único da nova VM no Proxmox.
    - **Hostname**: O nome da máquina na rede.
    - **Endereço IP**: O endereço IP estático (com CIDR, ex: `192.168.1.100/24`).
    - **Gateway**: O gateway padrão da rede.
  - **Configuração de Hardware**: Define os recursos de hardware da VM:
    - **Memória**: 4 GB de RAM.
    - **Cores**: 2 núcleos de CPU.
    - **Disco**: Redimensiona o disco principal para 50 GB.
  - **Configuração de Cloud-Init**:
    - **Usuário**: Cria um usuário padrão (`hugomrt`) e importa uma chave SSH pública (`~/.ssh/id_rsa.pub`) para acesso sem senha.
    - **Rede**: Configura a interface de rede com o IP estático e gateway fornecidos.
  - **Inicialização Automática**: Inicia a VM automaticamente após a criação.

- **Como Utilizar**:
  1. **Preparar o Template de Cloud-Init**:
     - Antes de usar o script, você precisa de um template de VM com uma imagem de cloud-init do Ubuntu Server. Certifique-se de que este template tenha o **VM ID 9000** (ou altere a variável `TEMPLATE_ID` no script).
     - O template deve ter o `qemu-guest-agent` instalado para comunicação com o host Proxmox.
  2. **Tornar o script executável**:
     ```bash
     chmod +x create_vm_ubuntu_server.sh
     ```
  3. **Executar o script no nó Proxmox**:
     Execute o script diretamente em um dos nós do seu cluster Proxmox via SSH.
     ```bash
     ./create_vm_ubuntu_server.sh
     ```
  4. **Fornecer as Informações**: Responda às perguntas do script para configurar a nova VM.

## ⚠️ Pré-requisitos

- **Ambiente**: Um cluster Proxmox VE funcional.
- **Template de Cloud-Init**: Uma VM template (ID 9000) com uma imagem cloud do Ubuntu Server 22.04 e o `qemu-guest-agent` instalado.
- **Chave SSH**: Uma chave SSH pública (`~/.ssh/id_rsa.pub`) deve existir no host Proxmox para ser injetada na nova VM.
- **Acesso**: O script deve ser executado em um nó do Proxmox com permissões para gerenciar VMs (`qm`).

## 💡 Dicas

- **Personalização**: Modifique as variáveis no início do script (como `TEMPLATE_ID`, `STORAGE`, `BRIDGE`, `CORES`, `MEMORY`) para adaptar a criação da VM às suas necessidades específicas.
- **Automação em Larga Escala**: Este script pode ser integrado a ferramentas de automação como o Ansible para provisionar múltiplas VMs de uma só vez, lendo os parâmetros de um arquivo de inventário em vez de solicitá-los interativamente.
