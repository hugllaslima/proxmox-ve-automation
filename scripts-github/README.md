# Scripts para Automação de Tarefas do Git/GitHub

Este diretório contém uma coleção de scripts Bash projetados para automatizar e simplificar tarefas comuns relacionadas ao controle de versão com Git e GitHub. Cada script foi criado para resolver um problema específico, desde a sincronização de branches até o gerenciamento de múltiplas contas de usuário em um mesmo ambiente de desenvolvimento.

## Estrutura de Diretórios

```
scripts-github/
├── git_switcher.sh
├── sync_branchs.sh
└── README.md
```

## Scripts Disponíveis

Abaixo estão os detalhes sobre cada script, incluindo suas funcionalidades, pré-requisitos e instruções de uso.

### 1. `git_switcher.sh`

O `git_switcher.sh` é um script robusto para gerenciar e alternar entre múltiplas contas Git/GitHub em um repositório local. É ideal para desenvolvedores que trabalham com contas pessoais e profissionais em uma mesma máquina.

#### Funcionalidades Principais

- **Gerenciamento de Contas**: Adicione, remova e liste múltiplas contas Git, armazenando `user.name`, `user.email`, `github_user` e o caminho para a chave SSH.
- **Configuração de Repositório**: Alterne a configuração `user.name` e `user.email` de um repositório Git local para uma das contas pré-configuradas.
- **Gerenciamento de Chaves SSH**: Atualiza automaticamente a URL do `remote 'origin'` para usar um host SSH específico da conta, garantindo que a chave SSH correta seja usada para autenticação.
- **Configuração Automatizada do `~/.ssh/config`**: Adiciona, atualiza e remove de forma segura as configurações de host SSH necessárias no arquivo `~/.ssh/config`, preservando outras configurações manuais.

#### Pré-requisitos

1. **Chaves SSH**: Você deve ter um par de chaves SSH (pública e privada) gerado para cada conta GitHub que deseja gerenciar.
2. **Chaves no GitHub**: As chaves públicas (`.pub`) correspondentes devem ser adicionadas às suas respectivas contas no GitHub.

#### Como Utilizar

1. **Tornar o script executável**:
   ```bash
   chmod +x git_switcher.sh
   ```

2. **Executar o script**:
   Execute o script de qualquer diretório. Para configurar um repositório, navegue até a pasta raiz do projeto antes de executar.
   ```bash
   ./git_switcher.sh
   ```

3. **Siga as Instruções**:
   O script oferece um menu interativo para:
   - **Listar contas salvas**.
   - **Adicionar uma nova conta**.
   - **Remover uma conta existente**.
   - **Configurar o repositório atual** para usar uma das contas.

### 2. `sync_branchs.sh`

O `sync_branchs.sh` é um script simples e eficiente para sincronizar as branches `main` e `develop` com seus respectivos remotos (`origin`).

#### Funcionalidades Principais

- **Sincronização Rápida**: Atualiza as branches `main` e `develop` com um único comando.
- **Feedback Visual**: Exibe mensagens claras sobre o status da sincronização.
- **Verificação Final**: Lista as branches e seus commits mais recentes para confirmar a atualização.

#### Quando Utilizar

Use este script no início do seu dia de trabalho ou sempre que precisar garantir que suas branches locais principais estejam alinhadas com o repositório remoto.

#### Como Utilizar

1. **Tornar o script executável**:
   ```bash
   chmod +x sync-branchs.sh
   ```

2. **Executar o script**:
   Navegue até a pasta raiz do seu repositório Git e execute o script.
   ```bash
   ./sync-branchs.sh
   ```

## Contribuições

Contribuições são bem-vindas! Se você tiver ideias para novos scripts, melhorias ou correções, sinta-se à vontade para abrir uma *issue* ou enviar um *pull request*.
