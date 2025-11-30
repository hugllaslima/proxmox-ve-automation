# 🔐 Scripts para Gerenciamento de SSH

Este diretório contém uma coleção de scripts para automatizar a configuração, gerenciamento e segurança do serviço SSH em sistemas baseados em Debian/Ubuntu.

## 📜 Estrutura de Diretórios

```
scripts-ssh/
├── configure_ssh_keep_alive.sh
├── create_ssh_key.sh
├── install_ssh_server.sh
└── README.md
```

## 🚀 Scripts Disponíveis

### 1. `install_ssh_server.sh`

- **Função**:
  Instala e habilita o OpenSSH Server, permitindo que a máquina seja acessada remotamente de forma segura.

- **Quando Utilizar**:
  Use este script em qualquer máquina que precise funcionar como um servidor SSH, seja para administração remota, transferência de arquivos ou tunelamento.

- **Recursos Principais**:
  - **Instalação**: Instala o pacote `openssh-server`.
  - **Habilitação**: Inicia e habilita o serviço `sshd` para que ele seja executado automaticamente na inicialização do sistema.
  - **Feedback**: Exibe o status do serviço após a instalação para confirmar que está funcionando corretamente.

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x install_ssh_server.sh
     ```
  2. **Executar com `sudo`**:
     ```bash
     sudo ./install_ssh_server.sh
     ```

### 2. `create_ssh_key.sh`

- **Função**:
  Gera um novo par de chaves SSH (pública e privada) para autenticação sem senha, aumentando a segurança e a conveniência.

- **Quando Utilizar**:
  Ideal para configurar acesso a servidores remotos, repositórios Git ou qualquer serviço que suporte autenticação baseada em chave, eliminando a necessidade de senhas.

- **Recursos Principais**:
  - **Geração de Chave**: Utiliza o `ssh-keygen` para criar um par de chaves RSA de 4096 bits.
  - **Interativo**: Solicita o caminho para salvar a chave e uma senha (passphrase) para proteger a chave privada. Pressionar Enter sem fornecer um caminho/senha usará os padrões.
  - **Exibição da Chave Pública**: Ao final, exibe a chave pública gerada, pronta para ser copiada para o arquivo `authorized_keys` do servidor remoto.

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x create_ssh_key.sh
     ```
  2. **Executar o script**:
     ```bash
     ./create_ssh_key.sh
     ```
     Siga as instruções para definir o local e a senha da chave.

### 3. `configure_ssh_keep_alive.sh`

- **Função**:
  Configura o cliente e o servidor SSH para manter as conexões ativas, evitando desconexões por inatividade (timeout).

- **Quando Utilizar**:
  Use este script se você enfrenta desconexões frequentes ao deixar uma sessão SSH ociosa, especialmente ao se conectar a servidores remotos através de firewalls ou NAT.

- **Recursos Principais**:
  - **Configuração do Cliente**: Modifica o arquivo `/etc/ssh/ssh_config` para enviar pacotes `ServerAliveInterval` a cada 60 segundos, mantendo a conexão ativa para todas as sessões SSH iniciadas a partir da máquina.
  - **Configuração do Servidor**: Modifica o arquivo `/etc/ssh/sshd_config` para enviar pacotes `ClientAliveInterval` a cada 60 segundos, mantendo as conexões de todos os clientes recebidas pelo servidor.
  - **Backup**: Cria um backup dos arquivos de configuração originais (`.bak`) antes de aplicar as alterações.
  - **Reinicialização do Serviço**: Reinicia o serviço `sshd` para que as novas configurações entrem em vigor.

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x configure_ssh_keep_alive.sh
     ```
  2. **Executar com `sudo`**:
     ```bash
     sudo ./configure_ssh_keep_alive.sh
     ```

## ⚠️ Pré-requisitos

- **Sistema Operacional**: Debian, Ubuntu ou derivados.
- **Acesso**: Um usuário com privilégios `sudo`.

## 🔒 Notas de Segurança

- **Autenticação por Chave**: Sempre prefira a autenticação por chave (`create_ssh_key.sh`) em vez de senhas. Se possível, desabilite a autenticação por senha no seu `sshd_config` (`PasswordAuthentication no`).
- **Firewall**: Certifique-se de que seu firewall (como o UFW) permite conexões na porta SSH (padrão: 22). Considere mudar a porta padrão para uma não convencional para reduzir a exposição a ataques automatizados.
- **Senha da Chave (Passphrase)**: Ao criar uma chave SSH, forneça uma senha forte. Isso adiciona uma camada extra de segurança, exigindo a senha para desbloquear a chave privada antes de usá-la.
