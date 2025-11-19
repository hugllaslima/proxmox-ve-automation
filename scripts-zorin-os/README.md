# Scripts para Zorin OS

Este diretório contém scripts específicos para a distribuição Zorin OS.

## 📋 Scripts Disponíveis

### 💾 `read_only_mounted_disk.sh`
**Corrige problemas de disco montado como somente leitura**

**Funcionalidades:**
- Verifica o status do disco
- Tenta remontar o disco com permissões de leitura e escrita
- Fornece feedback sobre o sucesso ou falha da operação

**Uso:**
```bash
chmod +x read_only_mounted_disk.sh
sudo ./read_only_mounted_disk.sh
```