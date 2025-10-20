# Scripts para Containers LXC

Este diretório contém scripts para configuração inicial e criação de usuários em containers LXC no Proxmox VE.

## Scripts Disponíveis

### 1. create_user_lxc.sh
**Objetivo:** Script de configuração inicial para containers LXC com criação de usuário administrativo.

**Funcionalidades:**
- Configuração automática de timezone (America/Sao_Paulo)
- Atualização do sistema operacional
- Instalação automática de dependências (`sudo` e `openssh-client`)
- Criação interativa de usuário com privilégios administrativos
- Adição automática aos grupos `sudo`, `lxc` ou `lxd`
- Configuração de sudo sem senha (para ambientes de laboratório)
- Opção de reinicialização do container

### 2. create_user_lxc_2.sh
**Objetivo:** Versão aprimorada do script de configuração inicial com maior controle interativo.

**Funcionalidades:**
- Configuração de timezone (America/Sao_Paulo)
- Atualização opcional e interativa do sistema
- Instalação opcional de `sudo` e `openssh-client`
- Verificação de existência do usuário antes da criação
- Criação de usuário com privilégios administrativos
- Adição automática aos grupos apropriados (`sudo`, `lxc`, `lxd`)
- Configuração de sudo sem senha
- Tratamento de erros e validações aprimoradas
- Opção de reinicialização do container

## Uso

### Execução Básica
```bash
# Para o script básico
sudo ./create_user_lxc.sh

# Para o script aprimorado
sudo ./create_user_lxc_2.sh
```

### Fluxo Interativo
1. **Configuração de Timezone:** Automática para America/Sao_Paulo
2. **Atualização do Sistema:** Confirmação interativa (apenas no v2)
3. **Instalação de Dependências:** Automática ou opcional
4. **Criação de Usuário:** Inserção do nome do usuário desejado
5. **Configuração de Grupos:** Adição automática aos grupos necessários
6. **Reinicialização:** Confirmação para reiniciar o container

## Casos de Uso

### Configuração Inicial de Container LXC
- Preparação de containers recém-criados
- Padronização de configurações básicas
- Criação de usuários administrativos

### Ambiente de Laboratório
- Configuração rápida para testes
- Criação de usuários com privilégios elevados
- Automação de tarefas repetitivas

## Pré-requisitos

- Container LXC em execução no Proxmox VE
- Acesso root ao container
- Conexão com a internet (para atualizações e instalações)
- Sistema baseado em Debian/Ubuntu

## Diferenças entre Versões

| Característica | create_user_lxc.sh | create_user_lxc_2.sh |
|---|---|---|
| Controle Interativo | Limitado | Completo |
| Verificação de Usuário | Não | Sim |
| Instalação Opcional | Não | Sim |
| Tratamento de Erros | Básico | Avançado |
| Validações | Mínimas | Completas |

## Considerações de Segurança

⚠️ **Importante:** Estes scripts configuram sudo sem senha (`NOPASSWD:ALL`), o que é adequado apenas para:
- Ambientes de laboratório
- Containers de desenvolvimento
- Situações onde a conveniência supera os riscos de segurança

Para ambientes de produção, considere:
- Remover a configuração `NOPASSWD`
- Implementar políticas de senha mais restritivas
- Usar autenticação por chave SSH

## Configuração de Acesso SSH

Após criar o usuário com os scripts deste diretório, você pode configurar o acesso SSH usando o script dedicado:

### Configuração de Chaves SSH
Para adicionar chaves públicas SSH ao usuário criado, utilize:
- **`../scripts-ssh/add_key_ssh_public.sh`** - Script interativo para adicionar chaves SSH com validação completa

**Funcionalidades do script SSH:**
- Validação de existência do usuário alvo
- Confirmação interativa de todas as informações
- Validação do formato da chave SSH
- Verificação de duplicidade automática
- Comentários identificando proprietário, data e quem adicionou
- Configuração automática de permissões (700 para .ssh, 600 para authorized_keys)
- Suporte para adicionar chaves a qualquer usuário (com sudo)

**Uso:**
```bash
# Navegar para o diretório SSH
cd ../scripts-ssh/

# Executar o script
sudo ./add_key_ssh_public.sh
```

## Verificação Pós-Configuração

```bash
# Verificar usuário criado
id nome_usuario

# Verificar grupos
groups nome_usuario

# Verificar sudo
sudo -l -U nome_usuario

# Verificar timezone
timedatectl show --property=Timezone --value

# Verificar configuração SSH (se configurado)
ls -la /home/nome_usuario/.ssh/
cat /home/nome_usuario/.ssh/authorized_keys
```

## Solução de Problemas

### Erro de Permissões
- Execute com `sudo` ou como root
- Verifique se o container tem privilégios suficientes

### Falha na Instalação de Pacotes
- Verifique conectividade com a internet
- Execute `apt update` manualmente
- Verifique espaço em disco disponível

### Usuário Não Criado
- Verifique se o nome do usuário é válido
- Confirme que não existe conflito com usuários existentes
- Verifique logs do sistema (`journalctl` ou `/var/log/`)

## Contribuição

Contribuições são bem-vindas! Por favor:
1. Faça fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## Licença

Este projeto está licenciado sob a GPL-3.0 - veja o arquivo LICENSE para detalhes.

## Autor

**Hugllas R S Lima**
- Versão: 1.0.0
- Data: 2025-08-04
