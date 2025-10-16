# Scripts de Instalação do Agente QEMU

Este diretório contém scripts para instalação automática do `qemu-guest-agent` em máquinas virtuais executando no Proxmox VE.

## Scripts Disponíveis

### 1. apt_install_agent_qemu.sh
**Objetivo:** Instalar o agente QEMU em sistemas baseados em Debian/Ubuntu usando APT.

**Funcionalidades:**
- Instalação automática do `qemu-guest-agent`
- Inicialização do serviço
- Habilitação para inicialização automática
- Reinicialização automática do sistema (com aviso de 10 segundos)

### 2. yum_install_agent_qemu.sh
**Objetivo:** Instalar o agente QEMU em sistemas baseados em Red Hat/CentOS usando YUM.

**Funcionalidades:**
- Instalação automática do `qemu-guest-agent`
- Inicialização do serviço
- Habilitação para inicialização automática
- Reinicialização automática do sistema (com aviso de 10 segundos)

## O que é o QEMU Guest Agent?

O `qemu-guest-agent` é um daemon auxiliar instalado no sistema convidado (VM) que permite:

- **Comunicação bidirecional** entre o host Proxmox VE e a VM
- **Execução de comandos** no sistema convidado a partir do host
- **Sincronização de tempo** mais precisa
- **Shutdown/restart** mais limpo das VMs
- **Informações detalhadas** sobre o sistema convidado
- **Snapshots consistentes** com freeze/unfreeze do filesystem

## Uso

### Para Sistemas Debian/Ubuntu
```bash
# Executar como root
sudo ./apt_install_agent_qemu.sh
```

### Para Sistemas Red Hat/CentOS
```bash
# Executar como root
sudo ./yum_install_agent_qemu.sh
```

### Fluxo de Execução
1. **Aviso inicial:** Exibe mensagem de início da instalação
2. **Instalação:** Instala o pacote `qemu-guest-agent`
3. **Inicialização:** Inicia o serviço imediatamente
4. **Habilitação:** Configura inicialização automática
5. **Aviso de reinicialização:** Conta regressiva de 10 segundos
6. **Reinicialização:** Reinicia o sistema automaticamente

## Pós-Instalação

### Habilitação no Proxmox VE
Após a instalação e reinicialização da VM, você deve habilitar o agente na interface do Proxmox VE:

1. Acesse a interface web do Proxmox VE
2. Selecione a VM
3. Vá para **Options** → **QEMU Guest Agent**
4. Marque **Enabled**
5. Clique em **OK**

### Verificação da Instalação
```bash
# Verificar status do serviço
systemctl status qemu-guest-agent

# Verificar se está rodando
ps aux | grep qemu-guest-agent

# Verificar logs
journalctl -u qemu-guest-agent
```

## Compatibilidade

### Sistemas Suportados

**apt_install_agent_qemu.sh:**
- Ubuntu (todas as versões LTS)
- Debian (8+)
- Linux Mint
- Outros derivados Debian

**yum_install_agent_qemu.sh:**
- CentOS (6+)
- Red Hat Enterprise Linux (RHEL)
- Fedora (versões antigas)
- Oracle Linux

## Considerações Importantes

### Segurança
- O agente permite execução de comandos pelo host
- Use apenas em ambientes confiáveis
- Mantenha o Proxmox VE atualizado

### Reinicialização Automática
⚠️ **Atenção:** Os scripts reiniciam o sistema automaticamente após 10 segundos
- Para cancelar: pressione `Ctrl+C` durante a contagem
- Salve trabalhos importantes antes da execução

### Dependências
- Acesso root na VM
- Conexão com a internet (para download dos pacotes)
- Repositórios do sistema configurados

## Solução de Problemas

### Falha na Instalação
```bash
# Atualizar repositórios
apt update  # ou yum update

# Verificar conectividade
ping 8.8.8.8

# Verificar espaço em disco
df -h
```

### Serviço não Inicia
```bash
# Verificar logs de erro
journalctl -u qemu-guest-agent -f

# Reiniciar manualmente
systemctl restart qemu-guest-agent

# Verificar configuração
systemctl is-enabled qemu-guest-agent
```

### Problemas de Comunicação
- Verifique se o agente está habilitado no Proxmox VE
- Confirme que a VM foi reiniciada após a instalação
- Verifique se não há firewall bloqueando a comunicação

## Benefícios da Instalação

### Para Administradores
- Shutdown mais limpo das VMs
- Informações detalhadas do sistema convidado
- Melhor integração com ferramentas de backup
- Snapshots mais consistentes

### Para Usuários
- Melhor sincronização de tempo
- Operações de sistema mais estáveis
- Melhor experiência geral da VM

## Contribuição

Contribuições são bem-vindas! Por favor:
1. Faça fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## Licença

Este projeto está licenciado sob a GPL - veja o arquivo LICENSE para detalhes.

## Autor

**Hugllas R S Lima**
- Email: hugllaslima@gmail.com
- Data: 20.07.2024
- Versão: 1.0
