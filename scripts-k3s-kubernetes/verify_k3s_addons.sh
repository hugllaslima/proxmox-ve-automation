#!/bin/bash
# -----------------------------------------------------------------------------
# Script: verify_k3s_addons.sh
#
# Descrição:
#   Realiza testes funcionais nos addons instalados (NFS, MetalLB, Ingress)
#   para garantir que o cluster está operando corretamente.
#
# O que ele testa:
#   1. Status dos Pods: Verifica se os pods dos addons estão rodando.
#   2. MetalLB/Ingress: Verifica se o LoadBalancer do Ingress recebeu um IP externo.
#   3. NFS: Cria um PVC e um Pod de teste para escrever e validar a persistência.
#
# Como usar:
#   chmod +x verify_k3s_addons.sh
#   ./verify_k3s_addons.sh
#
# -----------------------------------------------------------------------------

echo -e "\e[34m--- Verificação de Addons do K3s ---\e[0m"

# Verifica se o kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    echo -e "\e[31mErro: kubectl não encontrado. Execute este script na máquina de gerenciamento.\e[0m"
    exit 1
fi

# 1. Verificação Visual dos Pods
echo -e "\n\e[34m--- 1. Status dos Pods ---\e[0m"
ALL_HEALTHY=true
for ns in nfs-provisioner metallb-system ingress-nginx; do
    echo "Verificando namespace: $ns"
    # Conta linhas que não sejam cabeçalho e não estejam Running ou Completed
    PROBLEMATIC_PODS=$(kubectl get pods -n "$ns" --no-headers | grep -v "Running\|Completed")
    
    if [ -n "$PROBLEMATIC_PODS" ]; then
        echo -e "\e[33mALERTA: Há pods com problemas em $ns:\e[0m"
        echo "$PROBLEMATIC_PODS"
        ALL_HEALTHY=false
    else
        echo -e "\e[32mOK: Todos os pods em $ns parecem saudáveis.\e[0m"
    fi
    echo ""
done

# 2. Teste MetalLB (via Ingress Service)
echo -e "\e[34m--- 2. Verificação do MetalLB e Ingress ---\e[0m"
echo "Verificando se o Ingress Controller recebeu um IP do MetalLB..."

INGRESS_IP=""
RETRIES=0
MAX_RETRIES=12 # 12 * 5s = 60 segundos

while [ -z "$INGRESS_IP" ] && [ $RETRIES -lt $MAX_RETRIES ]; do
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$INGRESS_IP" ]; then
        echo "Aguardando IP externo... ($RETRIES/$MAX_RETRIES)"
        sleep 5
        ((RETRIES++))
    fi
done

if [ -n "$INGRESS_IP" ]; then
    echo -e "\e[32mSUCESSO: O Ingress Controller recebeu o IP: $INGRESS_IP\e[0m"
    echo "Isso confirma que o MetalLB está funcionando e atribuindo IPs da pool configurada."
else
    echo -e "\e[31mFALHA: O Ingress Controller não recebeu um IP externo após 60 segundos.\e[0m"
    echo "Verifique se a configuração 'IPAddressPool' do MetalLB corresponde à sua rede."
    echo "Comando para debug: kubectl get svc -n ingress-nginx"
fi

# 3. Teste NFS
echo -e "\n\e[34m--- 3. Verificação do Storage (NFS) ---\e[0m"
echo "Criando PVC de teste para validar a gravação de dados..."

# Cria PVC
cat <<EOF | kubectl apply -f - > /dev/null
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-nfs-pvc-verify
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
EOF

echo "Criando Pod de teste para escrever no volume..."
# Cria Pod que escreve um arquivo e sai com sucesso
cat <<EOF | kubectl apply -f - > /dev/null
kind: Pod
apiVersion: v1
metadata:
  name: test-nfs-pod-verify
spec:
  containers:
  - name: test-nfs-pod-verify
    image: busybox
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "echo 'Teste NFS Sucesso' > /mnt/SUCCESS && cat /mnt/SUCCESS && exit 0"
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/mnt"
  restartPolicy: Never
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: test-nfs-pvc-verify
EOF

# Aguarda conclusão do Pod
echo "Aguardando o Pod de teste processar a gravação..."
RETRIES=0
MAX_RETRIES=12
STATUS=""

while [ "$STATUS" != "Succeeded" ] && [ "$STATUS" != "Failed" ] && [ $RETRIES -lt $MAX_RETRIES ]; do
    STATUS=$(kubectl get pod test-nfs-pod-verify -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$STATUS" != "Succeeded" ] && [ "$STATUS" != "Failed" ]; then
        sleep 5
        ((RETRIES++))
    fi
done

if [ "$STATUS" == "Succeeded" ]; then
    echo -e "\e[32mSUCESSO: O Pod de teste conseguiu montar o volume NFS e escrever nele.\e[0m"
elif [ "$STATUS" == "Failed" ]; then
    echo -e "\e[31mFALHA: O Pod de teste falhou ao tentar escrever no NFS.\e[0m"
    echo "Logs do Pod:"
    kubectl logs test-nfs-pod-verify
else
    echo -e "\e[31mTIMEOUT: O Pod de teste demorou muito para responder.\e[0m"
fi

# Limpeza
echo -e "\n\e[34m--- Limpeza dos testes ---\e[0m"
kubectl delete pod test-nfs-pod-verify --ignore-not-found=true --wait=false > /dev/null 2>&1
kubectl delete pvc test-nfs-pvc-verify --ignore-not-found=true --wait=false > /dev/null 2>&1
echo "Recursos temporários de teste removidos."

echo -e "\n\e[34m=== Verificação Concluída ===\e[0m"
