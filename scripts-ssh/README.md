# 🔐 Scripts para Gerenciamento de SSH

Este diretório contém uma coleção de scripts para automatizar a configuração e o gerenciamento de chaves públicas SSH em sistemas Linux, com foco em segurança e usabilidade.

## 🐧 Compatibilidade

Os scripts são projetados para serem executados em sistemas operacionais baseados em Debian e Red Hat que utilizam `bash`.

- **Distribuições Suportadas**:
  - **Baseadas em Debian**:
    - Ubuntu (24.04, 22.04, 20.04)
    - Debian (12, 11, 10)
  - **Baseadas em Red Hat**:
    - CentOS
    - Rocky Linux
    - AlmaLinux

- **Dependências**:
  - `openssh-client`: Necessário para a validação do formato da chave pública (`ssh-keygen`).

## 📜 Estrutura de Diretórios

```
scripts-ssh/
├── add_key_ssh_public.sh
├── add_key_ssh_public_login_block.sh
└── README.md
```

## 🚀 Scripts Disponíveis

### 1. `add_key_ssh_public.sh`

- **Função**:
  Adiciona de forma interativa e segura uma chave pública SSH ao arquivo `authorized_keys` de um usuário específico. O script inclui validações, tratamento de duplicatas e adiciona um comentário detalhado para rastreabilidade.

- **Quando Utilizar**:
  Use este script para conceder acesso SSH a um usuário em um servidor. É ideal para administradores de sistemas que precisam gerenciar chaves de forma organizada e segura.

- **Recursos Principais**:
  - **Seleção de Usuário**: Permite especificar para qual usuário a chave será adicionada.
  - **Validação de Chave**: Verifica se a chave pública colada possui um formato SSH válido.
  - **Tratamento de Duplicatas**: Detecta se a chave já existe e oferece opções para substituir, excluir ou manter a chave existente.
  - **Comentários Detalhados**: Adiciona um comentário ao `authorized_keys` com o nome do proprietário da chave, a data e o usuário que realizou a adição.
  - **Gerenciamento de Permissões**: Garante que o diretório `.ssh` e o arquivo `authorized_keys` tenham as permissões corretas (700 e 600, respectivamente).

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x add_key_ssh_public.sh
     ```
  2. **Executar com `sudo`** (necessário para adicionar chaves para outros usuários):
     ```bash
     sudo ./add_key_ssh_public.sh
     ```
  3. Siga as instruções interativas para fornecer o nome de usuário, o proprietário da chave e a chave pública.

### 2. `add_key_ssh_public_login_block.sh`

- **Função**:
  Uma versão avançada do script anterior que, além de adicionar a chave pública, também desabilita o login por senha para o usuário, forçando o uso exclusivo da autenticação por chave SSH. Essa é uma prática de segurança altamente recomendada.

- **Quando Utilizar**:
  Use este script quando desejar aumentar a segurança de um servidor, garantindo que o acesso SSH para um usuário específico só possa ser feito por meio de sua chave privada.

- **Recursos Principais**:
  - **Todos os recursos do `add_key_ssh_public.sh`**.
  - **Desabilitação de Login por Senha**: Modifica o arquivo `/etc/ssh/sshd_config` para bloquear a autenticação por senha para o usuário especificado usando a diretiva `Match User`.
  - **Backup de Configuração**: Cria um backup do arquivo `sshd_config` antes de fazer qualquer alteração.
  - **Reinicialização do Serviço SSH**: Reinicia o serviço `sshd` para aplicar as novas regras de autenticação.

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x add_key_ssh_public_login_block.sh
     ```
  2. **Executar com `sudo`**:
     ```bash
     sudo ./add_key_ssh_public_login_block.sh
     ```

## ⚠️ Pré-requisitos

- **Acesso**: Um usuário com privilégios `sudo`.
- **Conhecimento Básico de SSH**: Entender o conceito de chaves públicas/privadas é recomendado.

## 🔒 Notas de Segurança

- **Backup**: Embora os scripts criem backups, é sempre uma boa prática ter um backup completo dos seus arquivos de configuração.
- **Teste de Acesso**: Após adicionar uma chave e desabilitar o login por senha, sempre teste o acesso em uma nova janela de terminal antes de fechar a sessão atual para evitar ficar bloqueado para fora do servidor.
