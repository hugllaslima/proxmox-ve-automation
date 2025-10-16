# Scripts SSH — Adição de Chave Pública

Este diretório contém scripts relacionados à configuração de acesso SSH. Atualmente, o foco é o script `add_key_ssh_public.sh`, que adiciona uma chave pública ao arquivo `authorized_keys` de um usuário alvo com validação, confirmação e comentários.

## Script Disponível

### add_key_ssh_public.sh
**Objetivo:** Automatizar a inclusão segura de chaves públicas no `authorized_keys`, preservando permissões, ownership e evitando duplicidades.

**Principais funcionalidades:**
- Fluxo interativo para escolher o usuário alvo
- Comentário da chave com identificação do proprietário (ex.: “João da Silva”, “Servidor de Backup”)
- Criação do diretório `.ssh` e do arquivo `authorized_keys` (se necessário)
- Ajuste de permissões recomendadas (`.ssh` = 700; `authorized_keys` = 600)
- Validação básica do formato da chave pública (RSA, ED25519, ECDSA, etc.)
- Prévia da chave para confirmação
- Verificação de duplicidade antes de adicionar
- Suporte para execução com `sudo` ao adicionar chave para outro usuário

## Uso

```bash
chmod +x add_key_ssh_public.sh
sudo ./add_key_ssh_public.sh
```

## Fluxo Interativo
1. Informar e confirmar o usuário alvo
2. Informar e confirmar o nome do proprietário da chave (comentário)
3. Preparar `.ssh` e `authorized_keys` com permissões e ownership corretos
4. Colar e validar a chave pública
5. Confirmar a prévia da chave
6. Verificar duplicidade
7. Adicionar comentário + chave ao `authorized_keys`

## Validações e Segurança
- `.ssh` deve ter permissão `700` e ser de propriedade do usuário alvo
- `authorized_keys` deve ter permissão `600` e ser de propriedade do usuário alvo
- Desabilitar `PasswordAuthentication` e habilitar `PubkeyAuthentication` no `sshd_config` é recomendado
- Nunca cole chaves privadas; apenas chaves públicas

## Exemplo de Execução

```text
--- Adicionar Chave Pública SSH (interativo) ---
Para qual usuário no servidor a chave pública será adicionada? (Deixe em branco para o usuário atual: ubuntu): ubuntu
Você informou o usuário: 'ubuntu'
Esta informação está correta? (s/N): s

Qual o nome da pessoa ou sistema que está adicionando esta chave? (Ex: 'João da Silva', 'Servidor de Backup'): João da Silva
Você informou o nome: 'João da Silva'
Esta informação está correta? (s/N): s

Por favor, cole a chave pública SSH...
Exemplo: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID...
(cole e finalize com Enter em linha vazia)

Você colou a seguinte chave (prévia):
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID...abc123
A chave pública está correta? (s/N): s

Adicionando o comentário e a chave pública ao arquivo /home/ubuntu/.ssh/authorized_keys...
Chave pública adicionada com sucesso para o usuário 'ubuntu'!
```

## Solução de Problemas
- Erro de permissões: execute com `sudo` se o usuário alvo for diferente do usuário atual
- Usuário inexistente: crie o usuário antes de rodar o script
- Chave inválida: verifique se começa com `ssh-rsa`, `ssh-ed25519`, `ecdsa-sha2-nistp256`, etc.
- Duplicidade: o script não adiciona novamente se a chave já existir

## Licença

GPL-3.0 — veja o arquivo LICENSE no diretório raiz.

## Autor

**Hugllas R S Lima**
- Email: hugllaslima@gmail.com
- Versão: 1.0
- Data: 2025-10-16