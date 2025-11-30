# 📦 Scripts para QEMU Guest Agent

Este diretório contém scripts para gerenciar o **QEMU Guest Agent** em máquinas virtuais (VMs) Linux, facilitando a comunicação e a integração entre o host (hipervisor, como o Proxmox VE) e o guest (VM).

## 📜 Estrutura de Diretórios

```
scripts-qemu-agent/
├── install_qemu_agent_v2.sh
├── install_qemu_agent.sh
└── README.md
```

## 🚀 Scripts Disponíveis

### 1. `install_qemu_agent_v2.sh` (Recomendado)

- **Função**:
  Instala e habilita o QEMU Guest Agent em uma VM Linux (Debian/Ubuntu). Esta é a versão mais completa e segura, com validações e feedback claro.

- **Quando Utilizar**:
  Execute este script em **todas as VMs** que rodam em um hipervisor como o Proxmox VE. A instalação do agente é crucial para habilitar funcionalidades avançadas, como:
  - **Desligamento/Reinicialização Graciosa**: Permite que o hipervisor desligue ou reinicie a VM de forma segura, sem corromper dados.
  - **Obtenção de Informações**: Fornece ao host detalhes sobre a VM, como endereços IP, status do sistema e uso de memória.
  - **Snapshots Consistentes**: Ajuda a "congelar" o sistema de arquivos da VM antes de um snapshot, garantindo a consistência dos dados.
  - **Execução de Comandos**: Permite que o host execute comandos dentro da VM.

- **Recursos Principais**:
  - **Instalação do Pacote**: Instala o pacote `qemu-guest-agent`.
  - **Habilitação do Serviço**: Inicia e habilita o serviço para que ele seja executado na inicialização da VM.
  - **Verificação de Status**: Confirma que o serviço está ativo e funcionando após a instalação.
  - **Saída Informativa**: Exibe mensagens claras sobre o progresso e o resultado da operação.

- **Como Utilizar**:
  1. **Copiar para a VM**: Transfira o script para a máquina virtual que você deseja configurar.
  2. **Tornar o script executável**:
     ```bash
     chmod +x install_qemu_agent_v2.sh
     ```
  3. **Executar com `sudo`**:
     ```bash
     sudo ./install_qemu_agent_v2.sh
     ```

### 2. `install_qemu_agent.sh` (Legado)

- **Função**:
  Versão mais antiga e simplificada do script de instalação. É funcional, mas menos robusta.

- **Quando Utilizar**:
  Pode ser usada como referência ou em scripts de automação mais simples. No entanto, a **versão 2 é recomendada** para garantir uma instalação mais confiável.

- **Recursos Principais**:
  - Instala o pacote e inicia o serviço, mas com menos feedback e sem a etapa de habilitação explícita (`enable`).

## ✅ Verificação no Proxmox VE

Após executar o script na VM, você pode confirmar que o QEMU Guest Agent está funcionando corretamente no painel do Proxmox VE:

1. Selecione a VM na interface web.
2. Vá para a aba **Summary**.
3. Na seção **IPs**, você deverá ver os endereços IP da VM listados. Se a mensagem "No guest agent configured" desapareceu e os IPs são exibidos, a comunicação foi estabelecida com sucesso.

## ⚠️ Pré-requisitos

- **Sistema Operacional da VM**: Debian, Ubuntu ou um derivado.
- **Acesso na VM**: Um usuário com privilégios `sudo`.
- **Configuração no Hipervisor**: O hipervisor (Proxmox VE) deve estar configurado para usar o QEMU Guest Agent. Isso é feito na aba **Options** da VM, marcando a caixa de seleção **QEMU Guest Agent**.

## 💡 Dica

- **Templates de VM**: A melhor prática é instalar o QEMU Guest Agent em uma VM base e, em seguida, convertê-la em um template. Todas as novas VMs criadas a partir deste template já terão o agente instalado e configurado, economizando tempo e garantindo consistência.
