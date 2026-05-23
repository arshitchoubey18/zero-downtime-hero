#!/bin/bash
set -e

echo "=== kind cluster ==="
kind create cluster --name zero-downtime --config=- <<K
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
      - containerPort: 443
        hostPort: 443
K

echo "=== NGINX ingress ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait \
  -n ingress-nginx \
  --for=condition=ready \
  pod \
  -l app.kubernetes.io/component=controller \
  --timeout=180s

echo "=== Minimal Prometheus (128MB) ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade -i prometheus prometheus-community/prometheus \
  -n monitoring \
  --create-namespace \
  --set alertmanager.enabled=false \
  --set pushgateway.enabled=false \
  --set server.persistentVolume.enabled=false \
  --set server.retention=2h \
  --set server.resources.limits.memory=256Mi \
  --set server.resources.requests.memory=128Mi

echo "=== Argo Rollouts ==="
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

kubectl rollout status deployment/argo-rollouts \
  -n argo-rollouts \
  --timeout=120s

echo "=== Deploy demo ==="
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/02-services.yaml
kubectl apply -f manifests/03-analysis-template.yaml

# Prometheus address fix for minimal chart
kubectl -n production patch analysistemplate success-rate \
  --type='json' \
  -p='[
    {"op":"replace","path":"/spec/metrics/0/provider/prometheus/address","value":"http://prometheus-server.monitoring.svc.cluster.local:80"},
    {"op":"replace","path":"/spec/metrics/1/provider/prometheus/address","value":"http://prometheus-server.monitoring.svc.cluster.local:80"}
  ]'

kubectl apply -f manifests/01-rollout-canary.yaml

echo "Done! Run:"
echo "kubectl argo rollouts get rollout demo-api -n production --watch"

