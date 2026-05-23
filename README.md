# Zero-Downtime Deployment Strategies — Zero to Hero

Implements Canary, Blue/Green, and A/B with Argo Rollouts + Prometheus + Flagger.

## Stack
- Kubernetes (kind / EKS / GKE)
- Argo Rollouts v1.8+
- Prometheus (kube-prometheus-stack)
- NGINX Ingress (for traffic splitting) or Istio
- k6 for load testing
- Slack notifications

## Quick start
1. Create cluster
2. Install dependencies
3. Deploy demo app
4. Run canary with auto-rollback
