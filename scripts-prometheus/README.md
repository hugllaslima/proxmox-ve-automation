# Script de Instalação do Prometheus Node Exporter

Este diretório contém script para instalação automática do Prometheus Node Exporter em sistemas Ubuntu Server 24.04 LTS.

## Script Disponível

### install_node_exporter.sh
**Objetivo:** Instalar e configurar o Prometheus Node Exporter para coleta de métricas do sistema.

**Funcionalidades:**
- Download automático da versão 1.7.0 do Node Exporter
- Criação de usuário dedicado (`node_exporter`)
- Instalação de dependências (`wget`, `tar`)
- Configuração como serviço systemd
- Configuração automática de firewall (UFW)
- Verificação de status pós-instalação
- Limpeza automática de arquivos temporários

## O que é o Node Exporter?

O **Prometheus Node Exporter** é um exportador oficial do Prometheus que coleta métricas de hardware e sistema operacional de máquinas Unix/Linux, incluindo:

- **CPU:** Utilização, temperatura, frequência
- **Memória:** RAM, swap, buffers, cache
- **Disco:** Uso, I/O, latência
- **Rede:** Tráfego, pacotes, erros
- **Sistema:** Load average, uptime, processos
- **Filesystem:** Espaço usado/livre, inodes

## Uso

### Execução
```bash
# Executar como usuário com privilégios sudo
sudo ./install_node_exporter.sh
```

### Fluxo de Instalação
1. **Verificação de pré-requisitos:** Instala `wget` e `tar` se necessário
2. **Criação de usuário:** Cria usuário `node_exporter` sem shell
3. **Download:** Baixa Node Exporter v1.7.0 do GitHub
4. **Extração e instalação:** Extrai e move binário para `/usr/local/bin`
5. **Configuração de serviço:** Cria arquivo systemd
6. **Inicialização:** Habilita e inicia o serviço
7. **Verificação:** Confirma status do serviço
8. **Firewall:** Configura UFW para porta 9100
9. **Limpeza:** Remove arquivos temporários

## Configurações

### Parâmetros Padrão
- **Versão:** 1.7.0
- **Porta:** 9100
- **Usuário:** node_exporter
- **Diretório de instalação:** /usr/local/bin
- **Arquivo de serviço:** /etc/systemd/system/node_exporter.service

### Personalização
Para alterar configurações, edite as variáveis no início do script:
```bash
NODE_EXPORTER_VERSION="1.7.0"
NODE_EXPORTER_PORT="9100"
NODE_EXPORTER_USER="node_exporter"
```

## Pós-Instalação

### Verificação do Serviço
```bash
# Status do serviço
sudo systemctl status node_exporter

# Logs do serviço
sudo journalctl -u node_exporter -f

# Verificar se está escutando na porta
sudo netstat -tlnp | grep 9100
```

### Acesso às Métricas
```bash
# Via curl local
curl http://localhost:9100/metrics

# Via navegador (substitua pelo IP real)
http://IP_DO_SERVIDOR:9100/metrics
```

### Integração com Prometheus
Adicione ao arquivo `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['IP_DO_SERVIDOR:9100']
```

## Compatibilidade

### Sistemas Suportados
- Ubuntu Server 24.04 LTS (testado)
- Ubuntu Server 22.04 LTS
- Ubuntu Server 20.04 LTS
- Debian 11/12
- Outros sistemas baseados em systemd

### Arquitetura
- x86_64 (AMD64)
- Para outras arquiteturas, altere a URL de download no script

## Segurança

### Usuário Dedicado
- Executa com usuário `node_exporter` sem privilégios
- Sem shell de login (`/bin/false`)
- Princípio do menor privilégio

### Firewall
- Porta 9100 liberada automaticamente no UFW
- Configure outros firewalls manualmente se necessário

### Métricas Expostas
⚠️ **Atenção:** As métricas podem conter informações sensíveis do sistema
- Restrinja acesso à porta 9100
- Use autenticação/autorização no Prometheus
- Configure TLS se necessário

## Solução de Problemas

### Falha no Download
```bash
# Verificar conectividade
ping github.com

# Verificar proxy/firewall
wget -v https://github.com/prometheus/node_exporter/releases/
```

### Serviço não Inicia
```bash
# Verificar logs
sudo journalctl -u node_exporter -n 50

# Verificar permissões
ls -la /usr/local/bin/node_exporter

# Testar execução manual
sudo -u node_exporter /usr/local/bin/node_exporter
```

### Porta em Uso
```bash
# Verificar o que está usando a porta
sudo lsof -i :9100

# Alterar porta no script se necessário
```

### Métricas não Aparecem
```bash
# Verificar se o serviço está rodando
sudo systemctl is-active node_exporter

# Testar conectividade local
curl -I http://localhost:9100/metrics

# Verificar firewall
sudo ufw status
```

## Métricas Principais

### Sistema
- `node_load1`, `node_load5`, `node_load15` - Load average
- `node_uptime_seconds` - Uptime do sistema
- `node_boot_time_seconds` - Tempo de boot

### CPU
- `node_cpu_seconds_total` - Tempo de CPU por modo
- `node_cpu_info` - Informações da CPU

### Memória
- `node_memory_MemTotal_bytes` - Memória total
- `node_memory_MemFree_bytes` - Memória livre
- `node_memory_MemAvailable_bytes` - Memória disponível

### Disco
- `node_filesystem_size_bytes` - Tamanho do filesystem
- `node_filesystem_free_bytes` - Espaço livre
- `node_disk_io_time_seconds_total` - Tempo de I/O

### Rede
- `node_network_receive_bytes_total` - Bytes recebidos
- `node_network_transmit_bytes_total` - Bytes transmitidos

## Desinstalação

```bash
# Parar e desabilitar serviço
sudo systemctl stop node_exporter
sudo systemctl disable node_exporter

# Remover arquivos
sudo rm /etc/systemd/system/node_exporter.service
sudo rm /usr/local/bin/node_exporter

# Remover usuário
sudo userdel node_exporter

# Recarregar systemd
sudo systemctl daemon-reload

# Remover regra de firewall
sudo ufw delete allow 9100/tcp
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

- [Documentação oficial do Node Exporter](https://prometheus.io/docs/guides/node-exporter/)
- [Lista completa de métricas](https://github.com/prometheus/node_exporter#collectors)
- [Prometheus Monitoring Guide](https://prometheus.io/docs/prometheus/latest/getting_started/)

## Autor

**Hugllas R S Lima**
- Versão: 1.0
- Sistema: Ubuntu Server 24.04 LTS