# Scripts de Backup para Proxmox VE

Este diretório contém scripts especializados para backup e proteção de dados no ambiente Proxmox VE, incluindo backup das configurações do sistema e montagem de dispositivos externos.

## 📋 Scripts Disponíveis

### 💾 `backup_full_proxmox_ve.sh`
**Backup completo das configurações do Proxmox VE**

**Objetivo:**
Realizar backup completo de todas as configurações críticas do Proxmox VE, permitindo restauração completa do sistema em caso de falha.

**Funcionalidades:**

#### 📦 **Backup de Configurações Críticas**
- **Cluster PVE:** `/var/lib/pve-cluster` - Configurações do cluster Proxmox
- **Chaves SSH:** `/root/.ssh` - Chaves SSH do usuário root
- **Corosync:** `/etc/corosync` - Configurações do cluster Corosync
- **iSCSI:** `/etc/iscsi` - Configurações de armazenamento iSCSI
- **Sistema:** `/etc` - Configurações gerais do sistema

#### 📋 **Backup de Configurações de Rede**
- **Hosts:** `/etc/hosts` - Arquivo de hosts do sistema
- **Interfaces:** `/etc/network/interfaces` - Configurações de rede

#### 📦 **Backup de Repositórios e Pacotes**
- **APT:** `/etc/apt` - Configurações de repositórios APT
- **Pacotes Instalados:** Lista de todos os pacotes instalados manualmente

#### 🗂️ **Organização Automática**
- Criação de diretório com timestamp (formato: `HOSTNAME.ddmmyy-HHMM`)
- Compactação individual de cada componente em arquivos `.tar.gz`
- Compactação final de todo o backup
- Limpeza automática de arquivos temporários

**Estrutura do Backup:**
```
HOSTNAME.ddmmyy-HHMM/
├── pve-cluster-backup.tar.gz    # Configurações do cluster PVE
├── ssh-backup.tar.gz            # Chaves SSH
├── corosync-backup.tar.gz       # Configurações Corosync
├── iscsi-backup.tar.gz          # Configurações iSCSI
├── etc-backup.tar.gz            # Configurações do sistema
├── apt-backup.tar.gz            # Repositórios APT
├── hosts                        # Arquivo hosts
├── interfaces                   # Configurações de rede
└── pkg.instalados              # Lista de pacotes instalados
```

**Uso:**
```bash
chmod +x backup_full_proxmox_ve.sh
sudo ./backup_full_proxmox_ve.sh
```

**Localização dos Backups:**
- Diretório: `/root/backup/`
- Arquivo final: `HOSTNAME.ddmmyy-HHMM.tar.gz`

**Agendamento Recomendado (Crontab):**
```bash
# Backup todo sábado às 18:40
40 18 * * 6 /root/backup/backup_full_proxmox_ve.sh
```

#### 🔄 **Instruções de Restauração**
Para restaurar o sistema após reinstalação:

1. **Extrair o backup:**
   ```bash
   tar -xzf HOSTNAME.ddmmyy-HHMM.tar.gz
   cd HOSTNAME.ddmmyy-HHMM/
   ```

2. **Restaurar componentes essenciais:**
   ```bash
   # Restaurar configurações PVE (CRÍTICO)
   tar -xzf pve-cluster-backup.tar.gz -C /
   
   # Restaurar chaves SSH
   tar -xzf ssh-backup.tar.gz -C /
   
   # Restaurar Corosync
   tar -xzf corosync-backup.tar.gz -C /
   
   # Restaurar configurações de rede
   cp hosts /etc/hosts
   cp interfaces /etc/network/interfaces
   ```

3. **Reinstalar pacotes:**
   ```bash
   sudo xargs aptitude --schedule-only install < pkg.instalados
   sudo aptitude install
   ```

---

### 🔌 `backups_usb_external.sh`
**Montagem automática de dispositivos USB externos para backup**

**Objetivo:**
Automatizar a montagem de dispositivos USB externos dedicados ao armazenamento de backups, especialmente útil para execução automática na inicialização do sistema.

**Funcionalidades:**

#### 🔧 **Montagem Automática**
- Montagem do dispositivo USB (`/dev/sdc1`) no ponto de montagem padrão do Proxmox (`/mnt/pve/backups-usb`)
- Verificação do status da montagem com `df -h`
- Feedback visual do sucesso da operação

#### 📊 **Verificação de Status**
- Exibição do espaço disponível no dispositivo montado
- Confirmação visual da montagem bem-sucedida

**Uso:**
```bash
chmod +x backups_usb_external.sh
sudo ./backups_usb_external.sh
```

**Configuração Automática (Crontab):**
```bash
# Montar USB automaticamente na inicialização
@reboot /root/Scripts/backups_usb_external.sh
```

**Personalização:**
Para adaptar a diferentes dispositivos USB, edite as variáveis no script:
```bash
# Alterar dispositivo (exemplo: /dev/sdb1, /dev/sdd1)
mount /dev/sdc1 /mnt/pve/backups-usb

# Alterar ponto de montagem se necessário
mount /dev/sdc1 /seu/ponto/de/montagem
```

## 🎯 Estratégia de Backup Recomendada

### 📅 **Agendamento Sugerido**
```bash
# Editar crontab do root
sudo crontab -e

# Backup completo semanal (sábados 18:40)
40 18 * * 6 /root/backup/backup_full_proxmox_ve.sh

# Montagem USB na inicialização
@reboot /root/Scripts/backups_usb_external.sh
```

### 🔄 **Rotação de Backups**
Implemente rotação manual ou automatizada:
```bash
# Manter apenas os últimos 4 backups semanais
find /root/backup/ -name "*.tar.gz" -mtime +28 -delete
```

### 💾 **Armazenamento Múltiplo**
1. **Local:** `/root/backup/` (backup primário)
2. **USB Externo:** `/mnt/pve/backups-usb/` (backup secundário)
3. **Remoto:** Considere rsync ou rclone para backup offsite

## ⚠️ Pré-requisitos

### Para `backup_full_proxmox_ve.sh`:
- Proxmox VE instalado e configurado
- Acesso root
- Espaço suficiente em `/root/backup/`
- Pacote `aptitude` instalado

### Para `backups_usb_external.sh`:
- Dispositivo USB conectado (padrão: `/dev/sdc1`)
- Ponto de montagem criado (`/mnt/pve/backups-usb`)
- Permissões de montagem

## 🔒 Considerações de Segurança

- **Teste de Restauração:** Teste periodicamente a restauração dos backups
- **Criptografia:** Considere criptografar backups sensíveis
- **Acesso:** Mantenha backups em local seguro e com acesso restrito
- **Verificação:** Valide a integridade dos arquivos de backup regularmente

## 📝 Verificações e Troubleshooting

### Verificar espaço disponível:
```bash
df -h /root/backup/
df -h /mnt/pve/backups-usb/
```

### Verificar dispositivos USB:
```bash
lsblk
fdisk -l
```

### Testar montagem manual:
```bash
sudo mount /dev/sdc1 /mnt/pve/backups-usb
sudo umount /mnt/pve/backups-usb
```

### Verificar logs de backup:
```bash
ls -la /root/backup/
tail -f /var/log/syslog | grep backup
```

## 🤝 Contribuição

Para melhorias ou correções:
1. Teste em ambiente de desenvolvimento
2. Mantenha compatibilidade com Proxmox VE
3. Documente mudanças no cabeçalho do script
4. Considere diferentes cenários de hardware

## 📄 Licença

GPL-3.0 - Veja o arquivo LICENSE no diretório raiz.
