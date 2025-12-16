# ☸️ Automação de Cluster K3s para Proxmox VE

Este diretório contém uma suíte de scripts `bash` para automatizar a implantação e configuração de um cluster Kubernetes leve e de alta disponibilidade usando K3s. O ambiente foi projetado para ser eficiente e rodar em uma infraestrutura modesta, como a fornecida pelo Proxmox VE.

## 🏗️ Arquitetura de Referência

Este projeto foi desenvolvido e testado com a seguinte arquitetura de Máquinas Virtuais (VMs) no Proxmox VE. Os IPs e nomes são sugestões e podem ser adaptados nos scripts interativos.

| VM | Nome | SO | IP/CIDR (Exemplo) | CPU | RAM | Volume |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `k3s-master-1` | Ubuntu 24.04 LTS | `192.168.10.20/24` | 4c | 6GB | 50GB |
| 2 | `k3s-master-2` | Ubuntu 24.04 LTS | `192.168.10.21/24` | 4c | 6GB | 50GB |
| 3 | `k3s-worker-1` | Ubuntu 24.04 LTS | `192.168.10.22/24` | 4c | 6GB | 50GB |
| 4 | `k3s-worker-2` | Ubuntu 24.04 LTS | `192.168.10.23/24` | 4c | 6GB | 50GB |
| 5 | `k3s-storage-nfs` | Ubuntu 24.04 LTS | `192.168.10.24/24` | 4c | 4GB | 100GB |
| 6 | `k3s-management` | Ubuntu 24.04 LTS | `192.168.10.25/24` | 4c | 4GB | 40GB |

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

5.  **Máquina de Gerenciamento (Seu Laptop/PC)**
    - Após o cluster estar no ar, execute o script de configuração dos addons para instalar o `kubectl`, `helm` e os componentes essenciais.
    ```bash
    ./configure_k3s_addons.sh
    ```

## 🧹 Limpeza do Ambiente

Para desmontar o ambiente, utilize os scripts `cleanup_*.sh`. É recomendado seguir a ordem inversa da instalação:

1.  **Na máquina de gerenciamento**: Execute `cleanup_k3s_addons.sh`.
2.  **Nos nós workers**: Execute `cleanup_k3s_worker.sh`.
3.  **Nos nós masters**: Execute `cleanup_k3s_master.sh`.
4.  **Na VM de armazenamento**: Execute `cleanup_nfs_server.sh`.

Isso garantirá que os servidores fiquem em um estado limpo e prontos para serem reutilizados.
