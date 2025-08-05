ubuntuconfigpve.sh
Configuração automatizada para Ubuntu Server focada em ambientes Proxmox VE.

📜 Descrição
Este script realiza configurações iniciais essenciais para VMs Ubuntu Server preparadas para uso em hosts Proxmox VE, incluindo ajuste de timezone, sudo, SSH seguro, instalação de Docker e Docker Compose.

:rocket: Recursos
Define fuso horário (America/Sao_Paulo)
Habilita sudo sem senha para o usuário padrão
Configura acesso SSH seguro com chaves
Permite (opcionalmente) instalar Docker e Docker Compose
Otimizações para ambiente virtualizado (qemu-guest-agent)
Ajustes de segurança no SSH
⚙️ Pré-requisitos
VM Ubuntu Server (recomendado Ubuntu 22.04 LTS ou superior)
Acesso ROOT (ou via sudo su)
Conexão à internet
🛠️ Instalação
Clone este repositório em sua VM Ubuntu Server:

bash
Copiar

git clone https://github.com/seu-usuario/seu-repo.git
cd seu-repo
chmod +x ubuntu_config_pve.sh
DICA: Sempre revise os scripts antes de executar!

🚀 Uso
Execute o script como root:

bash
Copiar

sudo ./ubuntu_config_pve.sh
Durante a execução:

Será solicitado o fornecimento da chave privada SSH (copie/cole no terminal)
Uma chave pública será gerada automaticamente
Você pode optar por apagar a chave privada após a configuração
Poderá instalar Docker e Docker Compose (opcional)
Ao final, recomenda-se testar o acesso SSH em outra aba/terminal antes de reiniciar.

🔒 Segurança
Chaves privadas nunca devem ser mantidas no servidor após o uso (script oferece opção de exclusão).
Apenas forneça a chave privada se realmente for necessário!
🤝 Contribuindo
Contribuições, issues e sugestões são bem-vindas!

Veja CONTRIBUTING.md para detalhes sobre o processo de contribuição.

📄 Licença
Distribuído sob licença GPL-3.0.

Veja LICENSE para mais informações.

📬 Contato
Autor: Hugllas R S Lima

LinkedIn/Email: [Seu LinkedIn ou email aqui]

Atenção: Este script é destinado ao uso em ambiente controlado e para fins de automação. Sempre revise antes e adapte conforme necessário para seu cenário!


Esse modelo é bem flexível e elegante, pronto para editar e complementar com seus links, badges, prints, contribuições e detalhes técnicos!

Quer uma versão ainda mais enxuta ou com exemplos práticos de execução/output?
