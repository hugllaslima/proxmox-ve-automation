# Ubuntu Automation Scripts for Proxmox VE

Scripts de automação para facilitar e padronizar a configuração inicial de VMs Ubuntu Server em ambientes Proxmox VE e virtualização em geral.

📋 Descrição
Este repositório reúne diversos scripts para automação de tarefas administrativas no Ubuntu Server, especialmente ajustados para ambientes virtualizados com Proxmox VE.

Entre os recursos, você encontrará automações para configuração de timezone, SSH, sudo, instalação de Docker/Compose, hardening e outros utilitários para acelerar a preparação de servidores.

:file_folder: Scripts Disponíveis
Script	Descrição resumida
ubuntu_config_pve.sh	Configuração inicial: timezone, SSH seguro, sudo, Docker
instala_zabbix_agent.sh	Automatiza instalação e configuração do Zabbix Agent
hardening_basico.sh	Aplica medidas básicas de segurança no Ubuntu
firewall_padrao.sh	Cria regras padrão de firewall usando UFW
backup_config_ssh.sh	Faz backup e restauração de arquivos de configuração SSH
…	(Inclua todos os scripts adicionados)
 Baixar
 Copiar

⚙️ Pré-requisitos
VM Ubuntu Server (recomendado Ubuntu 22.04 LTS ou superior)
Permissão root ou sudo
Conexão à internet (para scripts que requerem downloads)
🛠️ Instalação
Clone este repositório:

bash
Copiar

git clone https://github.com/seu-usuario/seu-repo.git
cd seu-repo
chmod +x *.sh

🚀 Uso
Cada script possui instruções e parâmetros próprios. Execute, por exemplo:

bash
Copiar

sudo ./ubuntu_config_pve.sh
Consulte o início de cada script para detalhes de uso, pré-requisitos específicos e recomendações.

Muitos scripts exibem prompts customizados para evitar configurações automáticas sem supervisão.
Teste sua conexão SSH após alterações de segurança, especialmente ao modificar autenticação SSH ou firewall.
💡 Organização Recomendada
Coloque cada script na raiz ou em sub-pastas temáticas (proxmox/, monitoramento/, etc).
Mantenha cabeçalhos de autoria, versão, data e descrição em cada script.
Um breve README em cada sub-pasta pode detalhar scripts semelhantes.
📝 Contribuição
Contribuições são muito bem-vindas!

Envie Pull Requests com novos scripts, melhorias ou correções.
Abra uma Issue para sugerir scripts, melhorias ou reportar bugs.
Siga as diretrizes em CONTRIBUTING.md.
📄 Licença
Distribuído sob a licença GPL-3.0.

Consulte o arquivo LICENSE para detalhes.

👤 Autor Principal
Hugllas R S Lima

[Seu LinkedIn ou email]

Atenção: Utilize os scripts por sua conta e risco. Revise cuidadosamente antes de executar em ambientes de produção!


Dica final:

Você pode adicionar badges, exemplos de shell, prints, e links para documentação dos scripts conforme o repositório for crescendo!
