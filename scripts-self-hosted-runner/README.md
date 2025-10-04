# Scripts para Self-Hosted Runner do GitHub Actions

Este diretório contém scripts para configuração, gerenciamento e limpeza de self-hosted runners do GitHub Actions em sistemas Linux.

## Scripts Disponíveis

### 1. setup_runner.sh
**Objetivo:** Configurar um self-hosted runner do GitHub Actions com usuário dedicado e permissões mínimas.

**Funcionalidades:**
- Criação de usuário `runner` com shell bash
- Configuração de senha para o usuário
- Adição ao grupo Docker
- Configuração de permissões sudo específicas
- Navegação entre usuários (ubuntu ↔ runner)
- Download e instalação do GitHub Actions Runner
- Configuração como serviço systemd
- Validação de hash (opcional)
- Feedback visual aprimorado com cores

### 2. setup_runner_v2.sh
**Objetivo:** Versão aprimorada com melhor tratamento de erros, logging e controle de estado.

**Funcionalidades:**
- Sistema de logging avançado
- Controle de estado da instalação
- Backup automático de configurações
- Tratamento robusto de erros
- Múltiplos métodos de fallback
- Verificações de status melhoradas
- Captura de interrupções (Ctrl+C)
- Interface mais intuitiva

### 3. cleanup_runner.sh
**Objetivo:** Remover completamente todas as configurações do self-hosted runner.

**Funcionalidades:**
- Parada de serviços do runner
- Remoção do usuário `runner` e diretório home
- Limpeza de configurações sudo
- Remoção de serviços systemd
- Opção de remoção do diretório `/var/www`
- Verificação final de limpeza
- Confirmação interativa para segurança

## O que é um Self-Hosted Runner?

Um **Self-Hosted Runner** é um servidor que você configura e gerencia para executar jobs do GitHub Actions. Oferece:

- **Controle total** sobre o ambiente de execução
- **Hardware personalizado** (CPU, RAM, armazenamento)
- **Software específico** pré-instalado
- **Rede privada** para recursos internos
- **Custos reduzidos** para uso intensivo
- **Maior segurança** para código proprietário

## Uso

### Configuração Inicial
```bash
# Executar como usuário com privilégios sudo
sudo ./setup_runner.sh

# Ou usar a versão aprimorada
sudo ./setup_runner_v2.sh
```

### Fluxo de Configuração
1. **Criação de usuário:** Cria usuário `runner` com senha
2. **Configuração de permissões:** Define permissões sudo específicas
3. **Preparação de diretórios:** Cria estrutura necessária
4. **Download do runner:** Solicita comando do GitHub
5. **Validação:** Verifica integridade (opcional)
6. **Extração:** Descompacta arquivos
7. **Configuração:** Registra runner no GitHub
8. **Instalação como serviço:** Configura systemd
9. **Verificação:** Confirma funcionamento

### Limpeza Completa
```bash
# Remover todas as configurações
sudo ./cleanup_runner.sh
```

## Pré-requisitos

### Sistema
- Ubuntu/Debian com systemd
- Usuário com privilégios sudo
- Docker instalado (para jobs que usam containers)
- Conexão com a internet

### GitHub
- Repositório ou organização no GitHub
- Permissões para adicionar runners
- Token de acesso (gerado automaticamente)

## Configuração no GitHub

### Obter Comandos de Instalação
1. Acesse seu repositório no GitHub
2. Vá para **Settings** → **Actions** → **Runners**
3. Clique em **New self-hosted runner**
4. Selecione **Linux** e **x64**
5. Copie os comandos mostrados

### Comandos Necessários
O script solicitará:
```bash
# Comando de download (exemplo)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Comando de validação (opcional)
echo "29fc8cf2dab4c195bb147384e7e2c94cfd4d4022c793b346a6175435265aa278  actions-runner-linux-x64-2.311.0.tar.gz" | shasum -a 256 -c

# Comando de extração
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
```

## Permissões Configuradas

### Usuário Runner
O usuário `runner` recebe permissões específicas via sudo:
```bash
# Gerenciamento de serviços
systemctl restart/start/stop/status *

# Docker
docker (todos os comandos)
docker-compose

# Gerenciamento de arquivos
chown runner:runner *
chmod *

# Navegação de usuários
su - ubuntu (sem senha)

# Logs do sistema
journalctl *

# Serviço do runner
/home/runner/actions-runner/svc.sh *
```

## Navegação entre Usuários

### De ubuntu para runner
```bash
sudo su - runner
```

### De runner para ubuntu
```bash
sudo su - ubuntu  # Sem senha
# ou simplesmente
exit
```

## Gerenciamento do Serviço

### Comandos Básicos
```bash
# Como usuário runner
cd /home/runner/actions-runner

# Status do serviço
sudo ./svc.sh status

# Parar serviço
sudo ./svc.sh stop

# Iniciar serviço
sudo ./svc.sh start

# Reiniciar serviço
sudo ./svc.sh restart
```

### Comandos Systemd
```bash
# Status
sudo systemctl status actions.runner.*

# Logs em tempo real
sudo journalctl -u actions.runner.* -f

# Parar/Iniciar
sudo systemctl stop actions.runner.*
sudo systemctl start actions.runner.*
```

## Estrutura de Arquivos

```
/home/runner/
├── actions-runner/          # Diretório principal do runner
│   ├── config.sh           # Script de configuração
│   ├── run.sh              # Execução manual
│   ├── svc.sh              # Gerenciamento de serviço
│   ├── bin/                # Binários do runner
│   └── _work/              # Diretório de trabalho dos jobs
└── .bashrc                 # Configurações do shell

/var/www/                   # Diretório para aplicações (opcional)
/etc/sudoers.d/runner       # Permissões sudo
```

## Segurança

### Princípios Aplicados
- **Usuário dedicado** com permissões mínimas
- **Sudo específico** apenas para comandos necessários
- **Isolamento** do usuário principal
- **Senha obrigatória** para o usuário runner

### Considerações
⚠️ **Importante:**
- O runner pode executar código de pull requests
- Configure branch protection rules
- Use secrets do GitHub para informações sensíveis
- Monitore logs regularmente

### Recomendações
- Use em ambiente isolado/dedicado
- Configure firewall adequadamente
- Mantenha o sistema atualizado
- Monitore uso de recursos

## Solução de Problemas

### Runner Offline
```bash
# Verificar status do serviço
sudo systemctl status actions.runner.*

# Verificar logs
sudo journalctl -u actions.runner.* -n 50

# Reiniciar serviço
sudo su - runner
cd actions-runner
sudo ./svc.sh restart
```

### Falha na Configuração
```bash
# Verificar conectividade
ping github.com

# Verificar token
# Gerar novo token no GitHub se necessário

# Reconfigurar
cd /home/runner/actions-runner
./config.sh remove
./config.sh
```

### Problemas de Permissão
```bash
# Verificar usuário
id runner

# Verificar grupos
groups runner

# Verificar sudo
sudo -l -U runner
```

### Jobs Falhando
```bash
# Verificar Docker
docker --version
sudo usermod -aG docker runner

# Verificar espaço em disco
df -h

# Verificar logs do job
sudo journalctl -u actions.runner.* -f
```

## Monitoramento

### Status do Runner
- Interface do GitHub: Settings → Actions → Runners
- Status deve aparecer como "Online 🟢"
- Última atividade deve ser recente

### Logs Importantes
```bash
# Logs do serviço
sudo journalctl -u actions.runner.* -f

# Logs do sistema
sudo journalctl -f

# Logs de jobs específicos
ls /home/runner/actions-runner/_diag/
```

### Recursos do Sistema
```bash
# CPU e memória
htop

# Espaço em disco
df -h

# Processos do runner
ps aux | grep runner
```

## Desinstalação Completa

### Usando o Script
```bash
sudo ./cleanup_runner.sh
```

### Manual
```bash
# Parar serviços
sudo systemctl stop actions.runner.*

# Remover do GitHub
cd /home/runner/actions-runner
./config.sh remove

# Remover usuário
sudo userdel -r runner

# Remover configurações
sudo rm /etc/sudoers.d/runner

# Limpar serviços
sudo systemctl daemon-reload
```

## Contribuição

Contribuições são bem-vindas! Por favor:
1. Faça fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## Licença

Este projeto está licenciado sob a GPL-3.0 - veja o arquivo LICENSE para detalhes.

## Recursos Adicionais

- [Documentação oficial do GitHub Actions](https://docs.github.com/en/actions)
- [Self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Configuração de runners](https://docs.github.com/en/actions/hosting-your-own-runners/configuring-the-self-hosted-runner-application-as-a-service)

## Autor

**Hugllas R S Lima**
- Data: 15/03/2025
- Versão: 2.0