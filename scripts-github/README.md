# 🐙 Scripts de Automação para Git e GitHub

Este diretório contém scripts projetados para simplificar e automatizar tarefas comuns de gerenciamento de repositórios Git e GitHub, como a troca de perfis de usuário e a sincronização de branches.

## 📜 Estrutura de Diretórios

```
scripts-github/
├── github_switcher.sh
├── sync-branchs.sh
└── README.md
```

## 🚀 Scripts Disponíveis

### 1. `github_switcher.sh`

- **Função**:
  Gerencia e alterna entre múltiplas contas Git/GitHub em uma mesma máquina. O script automatiza a configuração do `user.name`, `user.email` e da chave SSH associada a cada perfil.

- **Quando Utilizar**:
  Indispensável para desenvolvedores que trabalham com contas pessoais e profissionais (ou de clientes) na mesma máquina. Ele evita a necessidade de reconfigurar manualmente o Git a cada troca de projeto, prevenindo commits com a identidade errada.

- **Recursos Principais**:
  - **Menu Interativo**: Oferece uma lista de perfis pré-configurados para seleção.
  - **Configuração Global e Local**: Aplica as configurações de usuário (`user.name`, `user.email`) tanto globalmente quanto no repositório local, se aplicável.
  - **Gerenciamento de Chaves SSH**:
    - Verifica se o `ssh-agent` está em execução e o inicia, se necessário.
    - Remove identidades SSH antigas.
    - Adiciona a chave SSH correta (`~/.ssh/<chave>`) para o perfil selecionado.
  - **Validação de Conexão**: Testa a conexão com o GitHub para confirmar que a autenticação foi bem-sucedida.
  - **Flexibilidade**: Permite adicionar facilmente novos perfis editando o script.

- **Como Utilizar**:
  1. **Configurar Perfis**: Edite o script e adicione suas contas na seção `case "$choice" in`.
     ```bash
     # Exemplo de um novo perfil
     "Pessoal")
         USER_NAME="Seu Nome"
         USER_EMAIL="seu-email@pessoal.com"
         SSH_KEY="id_rsa_pessoal"
         ;;
     ```
  2. **Tornar o script executável**:
     ```bash
     chmod +x github_switcher.sh
     ```
  3. **Executar o script**:
     ```bash
     ./github_switcher.sh
     ```
     Selecione o perfil desejado no menu.

### 2. `sync-branchs.sh`

- **Função**:
  Sincroniza as branches `main` e `develop` de um repositório local com seus respectivos remotos (`origin`).

- **Quando Utilizar**:
  Use este script para manter suas branches de longa duração atualizadas com as últimas alterações do repositório remoto. É uma forma rápida de garantir que seu ambiente de desenvolvimento local não esteja defasado antes de iniciar um novo trabalho.

- **Recursos Principais**:
  - **Atualização Segura**: Executa `git fetch` para buscar as alterações do `origin`.
  - **Sincronização de `main`**: Faz o checkout da branch `main` e aplica as alterações remotas usando `git pull`.
  - **Sincronização de `develop`**: Faz o mesmo para a branch `develop`.
  - **Retorno à Branch Original**: Ao final, retorna para a branch em que você estava trabalhando antes de executar o script.

- **Como Utilizar**:
  1. **Tornar o script executável**:
     ```bash
     chmod +x sync-branchs.sh
     ```
  2. **Executar a partir da raiz do seu repositório Git**:
     ```bash
     ./sync-branchs.sh
     ```

## ⚠️ Pré-requisitos

- **Git**: O Git deve estar instalado e configurado no sistema.
- **SSH**: O `ssh-agent` deve estar funcional, e as chaves SSH para cada perfil do `git_switcher.sh` devem ser geradas e adicionadas à sua conta do GitHub.
- **Estrutura do Repositório**: O script `sync-branchs.sh` assume que o repositório possui as branches `main` e `develop` e que o remoto se chama `origin`.

## 💡 Dicas

- **Alias de Shell**: Para facilitar o uso, crie aliases em seu arquivo de configuração de shell (como `.bashrc` ou `.zshrc`).
  ```bash
  # Exemplo de aliases
  alias switcher='~/caminho/para/scripts-github/git_switcher.sh'
  alias sync='~/caminho/para/scripts-github/sync-branchs.sh'
  ```
