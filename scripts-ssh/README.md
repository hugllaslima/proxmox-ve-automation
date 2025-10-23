# Scripts SSH — Adição de Chaves e Endurecimento

Este diretório contém scripts para configurar acesso SSH de forma segura em servidores.

## Scripts Disponíveis

### add_key_ssh_public.sh
Objetivo: adicionar uma chave pública ao `authorized_keys` de um usuário de forma segura.

Principais funcionalidades:
- Fluxo interativo para escolher e confirmar o usuário alvo
- Comentário identificando o proprietário da chave
- Criação/ajuste do diretório `.ssh` e do arquivo `authorized_keys`
- Permissões recomendadas (`.ssh` = 700; `authorized_keys` = 600)
- Validação básica do formato da chave pública (RSA, ED25519, ECDSA)
- Prévia da chave para confirmação
- Verificação de duplicidade antes de adicionar

Uso:
```bash
chmod +x add_key_ssh_public.sh
sudo ./add_key_ssh_public.sh
```

---

### add_key_ssh_public_login_block.sh (versão atual)
Objetivo: adicionar chave pública com validações robustas e aplicar hardening completo ao SSH.

Principais funcionalidades (novas e aprimoradas):
- Validação robusta da existência do usuário alvo (`id -u`/`getent`) e home
- Comentário detalhado com proprietário e usuário executor
- Detecção e tratamento de chaves duplicadas com opções: substituir, excluir ou manter
- Prévia aprimorada da chave (início e fim) para confirmação
- Hardening de SSH incluindo `sshd_config` e `sshd_config.d/`
  - `PubkeyAuthentication yes`
  - `PasswordAuthentication no`
  - `KbdInteractiveAuthentication no`
  - `ChallengeResponseAuthentication no`
  - `PermitRootLogin prohibit-password`
  - `AuthorizedKeysFile .ssh/authorized_keys` com `Match User` para o usuário alvo
- Reinício robusto do serviço SSH, detectando `ssh.service` vs `sshd.service`
- Configuração opcional de `sudo NOPASSWD` para o usuário alvo (com checagens e avisos)
- Backups automáticos dos arquivos de configuração antes de alterações

Uso:
```bash
chmod +x add_key_ssh_public_login_block.sh
sudo ./add_key_ssh_public_login_block.sh
```

Atenção:
- Desabilitar login por senha sem chave válida pode bloquear o acesso (lockout)
- `NOPASSWD` reduz a segurança; use apenas se estritamente necessário
- Garanta acesso alternativo (console/IPMI) ao aplicar hardening

---

## Qual script devo usar?
- Use `add_key_ssh_public.sh` para apenas adicionar chaves com segurança.
- Use `add_key_ssh_public_login_block.sh` quando, além de adicionar a chave, você quiser endurecer o SSH e opcionalmente configurar `sudo NOPASSWD`.

## Licença
GPL-3.0 — veja o arquivo `LICENSE.md` no diretório raiz.

## Autor
**Hugllas R S Lima**
- Email: hugllaslima@gmail.com