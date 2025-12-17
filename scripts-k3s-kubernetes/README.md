# ☸️ Automação de Cluster K3s para Proxmox VE

Este diretório contém uma suíte de scripts `bash` para automatizar a implantação e configuração de um cluster Kubernetes leve e de alta disponibilidade usando K3s. O ambiente foi projetado para ser eficiente e rodar em uma infraestrutura modesta, como a fornecida pelo Proxmox VE. 

## 🤔 Por que K3s? Uma Análise Comparativa

A escolha pelo **K3s** para este projeto foi estratégica, visando um equilíbrio ideal entre robustez, simplicidade e eficiência de recursos, especialmente em um ambiente virtualizado como o Proxmox VE.

O K3s é uma distribuição Kubernetes **leve e certificada pela CNCF**, desenvolvida pela Rancher. Ele é projetado para cenários com recursos limitados (como Edge, IoT e desenvolvimento) por ser empacotado em um **único binário com menos de 100MB**. Essa abordagem simplifica drasticamente a instalação e o gerenciamento, mantendo total compatibilidade com as APIs do Kubernetes.

### K3s vs. K8s (Vanilla): Principais Diferenças

Para entender a decisão, veja um comparativo direto entre as duas abordagens:

#### **K8s (Kubernetes "Vanilla" / `kubeadm`)**
- **Implementação Completa**: É a versão oficial e mais abrangente do Kubernetes, contendo todos os componentes tradicionais (API Server, Scheduler, etcd, etc.).
- **Padrão da Indústria**: Considerado o "padrão ouro" que define o ecossistema Kubernetes.
- **Curva de Aprendizagem e Recursos**: A instalação e configuração, mesmo com `kubeadm`, exigem mais recursos de hardware e um conhecimento mais aprofundado da arquitetura.

#### **K3s (Lightweight Kubernetes)**
- **Certificado e 100% Compatível**: Passa em todos os testes de conformidade da CNCF, garantindo que suas aplicações funcionarão como esperado.
- **Otimizado para Leveza**:
    - Remove componentes legados e não essenciais (como drivers de armazenamento *in-tree*).
    - Empacota todos os processos em um **único binário**, o que reduz o *overhead* e a superfície de ataque.
    - Utiliza `containerd` como runtime padrão, que é mais leve e eficiente que o Docker para o contexto do Kubernetes.
- **Banco de Dados Flexível**:
    - Para nós únicos, pode usar **SQLite** embutido, tornando-o extremamente leve.
    - Para alta disponibilidade (HA), suporta bancos de dados externos como **PostgreSQL**, que é a abordagem de alta disponibilidade utilizada neste projeto.

Em resumo, o K3s oferece a mesma funcionalidade e segurança do Kubernetes tradicional, mas com uma fração do custo operacional e da complexidade, tornando-o a escolha ideal para este ambiente.

O cluster resultante é configurado com dois nós de controle (masters), dois nós de trabalho (workers), um servidor NFS para armazenamento persistente e, por fim, um servidor de gerenciamento para execução de comandos `kubectl` e `helm`.

## 🏗️ Arquitetura de Referência Utilizada no Proxmox VE

Este projeto foi desenvolvido e testado com a seguinte arquitetura de Máquinas Virtuais (VMs) no Proxmox VE. Os IPs e nomes são sugestões e podem ser adaptados nos scripts interativos.

| VM | Nome | SO | IP/CIDR | CPU | RAM | Volume |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `k3s-master-1` | Ubuntu 24.04 LTS | `192.168.10.20/24` | 4c | 6GB | 40GB |
| 2 | `k3s-master-2` | Ubuntu 24.04 LTS | `192.168.10.21/24` | 4c | 6GB | 40GB |
| 3 | `k3s-worker-1` | Ubuntu 24.04 LTS | `192.168.10.22/24` | 4c | 6GB | 40GB |
| 4 | `k3s-worker-2` | Ubuntu 24.04 LTS | `192.168.10.23/24` | 4c | 6GB | 40GB |
| 5 | `k3s-storage-nfs` | Ubuntu 24.04 LTS | `192.168.10.24/24` | 4c | 4GB | 100GB |
| 6 | `k3s-management` | Ubuntu 24.04 LTS | `192.168.10.25/24` | 2c | 4GB | 30GB |

## ⚙️ Como o Ambiente Funciona?

Esta seção detalha o papel de cada componente e como eles interagem para formar um cluster funcional e resiliente.

### Papel de Cada VM

- **`k3s-master-1` e `k3s-master-2` (Nós de Controle)**: Gerenciam o estado do cluster, distribui as cargas de trabalho entre os nós de trabalho, agendam aplicações e expõem a API do Kubernetes. A configuração com dois masters e um banco de dados externo (PostgreSQL) garante a **alta disponibilidade (HA)** do *control plane*.
- **`k3s-worker-1` e `k3s-worker-2` (Nós de Trabalho)**: Executam as aplicações e serviços (em Pods) conforme orquestrado pelos nós de controle.
- **`k3s-storage-nfs` (Armazenamento Persistente)**: Atua como um servidor NFS centralizado. Quando uma aplicação precisa de dados persistentes (através de um `PersistentVolumeClaim`), o K3s provisiona um diretório neste servidor. Isso garante que os dados sobrevivam a reinicializações de Pods e possam ser compartilhados entre eles.
- **`k3s-management` (Gerenciamento Centralizado)**: É a VM de onde todos os comandos de gerenciamento (`kubectl`, `helm`) são executados. Centralizar o gerenciamento em um nó dedicado é uma **boa prática de segurança**, pois isola as credenciais de acesso ao cluster.

### O que é Armazenado em Cada Nó?

- **Nós Master**: A configuração e o estado do cluster (objetos Kubernetes como `Deployments`, `Services`, etc.), que são mantidos no banco de dados PostgreSQL.
- **Nós Worker**: As imagens de contêiner das aplicações em execução e dados temporários.
- **Nó de Armazenamento (NFS)**: Todos os dados persistentes das aplicações. É o "disco rígido" do cluster.
- **Nó de Gerenciamento**: Os arquivos de configuração do `kubectl`, charts do Helm e manifestos YAML usados para gerenciar o cluster.

### Onde Encontrar os Logs?

A localização dos logs depende do que você está tentando depurar:

- **Logs das Aplicações (Pods)**
  - **Método Principal**: Use o comando `kubectl` a partir da VM de gerenciamento. Este é o método padrão para ver a saída das suas aplicações.
    ```bash
    kubectl logs <nome-do-pod>
    ```

- **Logs da Infraestrutura (Serviços K3s, NFS, etc.)**
  - **Método Recomendado (`journalctl`)**: Para inspecionar os logs dos serviços K3s nos nós master e worker, o `journalctl` é a ferramenta ideal, pois o K3s roda como um serviço `systemd`.
    ```bash
    # Nos masters ou workers
    journalctl -u k3s
    ```
  - **Arquivos de Log Diretos**: Para inspeção manual ou uso de ferramentas como `grep`, os arquivos de log brutos podem ser encontrados nos seguintes locais:
    - **Nós Master e Worker**: `/var/log/k3s/` (logs específicos do K3s) e `/var/log/` (logs gerais do sistema).
    - **Servidor NFS**: `/var/log/` (para logs do serviço NFS e outros logs do sistema).

## 📜 Scripts Disponíveis

### Scripts de Instalação

- **`install_nfs_server.sh`**: Configura uma VM para atuar como um servidor NFS, que fornecerá armazenamento persistente para o cluster.
- **`install_k3s_master.sh`**: Instala e configura um nó de controle (master) do K3s. Possui lógica para diferenciar o primeiro master (que configura o banco de dados) do segundo, para criar um ambiente de alta disponibilidade (HA).
- **`install_k3s_worker.sh`**: Instala e configura um nó de trabalho (worker) e o junta ao cluster K3s.
- **`configure_k3s_addons.sh`**: Deve ser executado em uma máquina de gerenciamento. Instala `kubectl`, `helm` e implanta addons essenciais: NFS Provisioner (para StorageClasses), MetalLB (para Load Balancers) e Nginx Ingress Controller.

### Scripts de Limpeza

- **`cleanup_nfs_server.sh`**: Reverte a instalação do servidor NFS.
- **`cleanup_k3s_master.sh`**: Desinstala o K3s e limpa todas as configurações de um nó de controle.
- **`cleanup_k3s_worker.sh`**: Desinstala o agente K3s e limpa as configurações de um nó de trabalho.
- **`cleanup_k3s_addons.sh`**: Remove todos os addons (NFS Provisioner, MetalLB, Nginx) e a configuração local do `kubectl`.

## 🚀 Ordem de Execução Sugerida

Para implantar o cluster do zero, siga a ordem abaixo. Lembre-se de dar permissão de execução (`chmod +x *.sh`) a todos os scripts.

1.  **VM de Armazenamento (`k8s-storage-nfs`)**
    - Execute o script para configurar o servidor NFS.
    ```bash
    sudo ./install_nfs_server.sh
    ```

2.  **Primeiro Master (`k8s-master-1`)**
    - Execute o script de instalação do master. Ele irá instalar o PostgreSQL e gerar um token.
    ```bash
    sudo ./install_k3s_master.sh
    ```
    - **Guarde o token** exibido no final da execução.

3.  **Segundo Master (`k8s-master-2`)**
    - Execute o mesmo script, mas forneça o token gerado no passo anterior quando solicitado.
    ```bash
    sudo ./install_k3s_master.sh
    ```

4.  **Nós Workers (`k8s-worker-1`, `k8s-worker-2`)**
    - Em cada nó de trabalho, execute o script de instalação do worker, fornecendo o IP do master e o token.
    ```bash
    sudo ./install_k3s_worker.sh
    ```

5.  **Máquina de Gerenciamento (`k3s-management`)**
    - Após o cluster estar no ar, execute o script de configuração dos addons para instalar `kubectl`, `helm` e os componentes essenciais.
    - **Recomendação**: Voê pode utilizar seu PC/Desktop, mas para maior segurança e isolamento, é preferível utilizar uma VM dedicada (`k3s-management`) para a gerência do cluster, em vez de executar os comandos a partir da sua máquina local.
    ```bash
    sudo ./configure_k3s_addons.sh
    ```

## 🧹 Limpeza do Ambiente

Para desmontar o ambiente, utilize os scripts `cleanup_*.sh`. É recomendado seguir a ordem inversa da instalação:

1.  **Na máquina de gerenciamento**: Execute `sudo ./cleanup_k3s_addons.sh`.
2.  **Nos nós workers**: Execute `sudo ./cleanup_k3s_worker.sh`.
3.  **Nos nós masters**: Execute `sudo ./cleanup_k3s_master.sh`.
4.  **Na VM de armazenamento**: Execute `sudo ./cleanup_nfs_server.sh`.

Isso garantirá que os servidores fiquem em um estado limpo e prontos para serem reutilizados.

## 👨‍💻 Autor

**Hugllas R S Lima**

- **GitHub:** [@hugllaslima](https://github.com/hugllaslima)
- **LinkedIn:** [hugllas-lima](https://www.linkedin.com/in/hugllas-lima/)
