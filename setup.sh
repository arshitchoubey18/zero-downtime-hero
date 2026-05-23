#!/bin/bash
set -e

echo "=== 1. Create kind cluster ==="
kind create cluster --name zero-downtime --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
EOF

echo "=== 2. Install NGINX Ingress ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

echo "=== 3. Install Prometheus ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace --wait

echo "=== 4. Install Argo Rollouts ==="
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl wait --for=condition=available deployment/argo-rollouts -n argo-rollouts --timeout=120s

echo "=== 5. Deploy demo ==="
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/03-analysis-template.yaml
kubectl apply -f manifests/02-services.yaml
kubectl apply -f manifests/01-rollout-canary.yaml

echo "Done! Run: kubectl argo rollouts get rollout demo-api -n production --watch"
