#!/usr/bin/env bash
set -e

export CLUSTER=$1

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace monitoring

kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

export INGRESS_HOST=$(kubectl get svc -n monitoring ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' )

htpasswd -cb prometheus/auth admin $PROM_PASSWORD

kubectl create secret -n monitoring generic basic-auth \
--save-config \
--dry-run=client \
--from-file=prometheus/auth -o yaml | \
kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prom
  namespace: monitoring
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - admin'
spec:
  ingressClassName: nginx
  rules:
  - host: $INGRESS_HOST
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-server
            port:
              number: 80
EOF
