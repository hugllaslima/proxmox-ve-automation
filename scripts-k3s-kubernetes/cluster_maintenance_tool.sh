#!/bin/bash
# -----------------------------------------------------------------------------
#
# Script: cluster_maintenance_tool.sh
#
# Descrição:
#   Ferramenta interativa para manutenção do cluster Kubernetes (K3s).
#   Permite visualizar e remover recursos "presos" ou obsoletos de forma segura.
#
# Funcionalidades:
#   - Listar e Excluir Nós (Nodes) - útil para remover workers antigos.
#   - Listar e Excluir Pods (Forçar exclusão) - útil para pods em 'Terminating'.
#   - Listar e Excluir Namespaces.
#   - Drenar Nós (Drain) - prepara um nó para manutenção.
#
# Contato:
#   - https://www.linkedin.com/in/hugllas-r-s-lima/
#   - https://github.com/hugllaslima/proxmox-ve-automation/tree/main/scripts-k3s-kubernetes
#
# Versão:
#   1.0
#
# Pré-requisitos:
#   - Acesso kubectl configurado (executar no Control Plane ou máquina com kubeconfig).
#   - Permissões de administrador no cluster.
#
# -----------------------------------------------------------------------------

# --- Cores e Formatação ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_header {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

function success_message {
    echo -e "${GREEN}SUCESSO: $1${NC}"
}

function warning_message {
    echo -e "${YELLOW}AVISO: $1${NC}"
}

function error_message {
    echo -e "${RED}ERRO: $1${NC}"
}

# --- Checagem Inicial ---
if ! command -v kubectl &> /dev/null; then
    error_message "kubectl não encontrado. Execute este script em um nó Control Plane ou máquina gerenciadora."
    exit 1
fi

# --- Funções de Operação ---

function manage_nodes {
    while true; do
        print_header "Gerenciamento de Nós"
        echo "Listando nós atuais..."
        kubectl get nodes -o wide
        echo ""
        echo "Opções:"
        echo "1) Excluir um nó (Delete Node)"
        echo "2) Drenar um nó (Drain Node)"
        echo "3) Desmarcar nó como não agendável (Uncordon)"
        echo "0) Voltar ao menu principal"
        
        read -p "Escolha uma opção: " opt_node
        case $opt_node in
            1)
                read -p "Digite o NOME do nó para excluir: " node_name
                if [ -z "$node_name" ]; then continue; fi
                
                warning_message "Isso removerá o nó '$node_name' do registro do Kubernetes."
                warning_message "Se o servidor físico ainda estiver rodando o agente K3s, ele pode tentar voltar."
                read -p "Tem certeza? (s/n): " confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    kubectl delete node "$node_name"
                fi
                ;;
            2)
                read -p "Digite o NOME do nó para drenar: " node_name
                if [ -z "$node_name" ]; then continue; fi
                
                echo "Drenando nó (ignorando DaemonSets)..."
                kubectl drain "$node_name" --ignore-daemonsets --delete-emptydir-data
                ;;
            3)
                read -p "Digite o NOME do nó para liberar (Uncordon): " node_name
                kubectl uncordon "$node_name"
                ;;
            0) break ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione ENTER para continuar..."
    done
}

function manage_pods {
    while true; do
        print_header "Gerenciamento de Pods"
        read -p "Digite o Namespace para listar (pressione ENTER para 'default' ou 'all' para todos): " ns
        
        if [ "$ns" == "all" ]; then
            kubectl get pods -A
            ns_flag="-A"
        elif [ -z "$ns" ]; then
            kubectl get pods
            ns_flag="" # default
        else
            kubectl get pods -n "$ns"
            ns_flag="-n $ns"
        fi
        
        echo ""
        echo "Opções:"
        echo "1) Excluir Pod (Graceful delete)"
        echo "2) Forçar exclusão de Pod (Force delete - útil para 'Terminating')"
        echo "0) Voltar ao menu principal"
        
        read -p "Escolha uma opção: " opt_pod
        case $opt_pod in
            1)
                read -p "Digite o NOME do Pod: " pod_name
                read -p "Digite o Namespace do Pod (vazio para default): " pod_ns
                [ -z "$pod_ns" ] && pod_ns="default"
                kubectl delete pod "$pod_name" -n "$pod_ns"
                ;;
            2)
                read -p "Digite o NOME do Pod travado: " pod_name
                read -p "Digite o Namespace do Pod (vazio para default): " pod_ns
                [ -z "$pod_ns" ] && pod_ns="default"
                warning_message "Forçando exclusão imediata (grace-period=0)..."
                kubectl delete pod "$pod_name" -n "$pod_ns" --grace-period=0 --force
                ;;
            0) break ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione ENTER para continuar..."
    done
}

function manage_namespaces {
    while true; do
        print_header "Gerenciamento de Namespaces"
        kubectl get namespaces
        echo ""
        echo "Opções:"
        echo "1) Excluir Namespace (Remove TUDO dentro dele)"
        echo "0) Voltar ao menu principal"
        
        read -p "Escolha uma opção: " opt_ns
        case $opt_ns in
            1)
                read -p "Digite o NOME do Namespace para EXCLUIR: " ns_name
                if [ "$ns_name" == "kube-system" ] || [ "$ns_name" == "default" ]; then
                    error_message "Não é permitido excluir namespaces do sistema por este script."
                    continue
                fi
                
                warning_message "ATENÇÃO: Isso excluirá TODOS os recursos dentro de '$ns_name'."
                read -p "Tem certeza absoluta? (s/n): " confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    kubectl delete namespace "$ns_name"
                fi
                ;;
            0) break ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione ENTER para continuar..."
    done
}

# --- Loop Principal ---
while true; do
    clear
    print_header "Ferramenta de Manutenção do Cluster K3s"
    echo "1) Gerenciar Nós (Listar/Excluir/Drenar)"
    echo "2) Gerenciar Pods (Listar/Excluir/Forçar)"
    echo "3) Gerenciar Namespaces"
    echo "4) Verificar Saúde do Cluster (Health Check)"
    echo "0) Sair"
    echo ""
    read -p "Escolha uma opção: " option

    case $option in
        1) manage_nodes ;;
        2) manage_pods ;;
        3) manage_namespaces ;;
        4) 
           if [ -f "./verify_k3s_cluster_health.sh" ]; then
               ./verify_k3s_cluster_health.sh
               read -p "Pressione ENTER para voltar..."
           else
               error_message "Script 'verify_k3s_cluster_health.sh' não encontrado no diretório atual."
               read -p "Pressione ENTER..."
           fi
           ;;
        0) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida." ;;
    esac
done
