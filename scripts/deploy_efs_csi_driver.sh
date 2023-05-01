#!/usr/bin/env bash
set -e
export CLUSTER=$1
export AWS_EFS_CSI_DRIVER_CHART_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_efs_csi_driver_chart_version)
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_account_id)

# helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
# helm repo update
helm upgrade aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
      --install \
      --namespace kube-system \
      --version=${AWS_EFS_CSI_DRIVER_CHART_VERSION}

cat <<EOF > efs-csi-driver/service-account.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: aws-efs-csi-driver
  name: efs-csi-controller-sa
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/$CLUSTER-efs-csi-controller-sa
EOF
kubectl apply -f efs-csi-driver/service-account.yaml

# export CLUSTER=$1
# export ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .account_id)
# export EFS_CSI_DRIVER_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_efs_csi_driver_version)
# export CSI_PROVISIONER_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_efs_csi_provisionser_version)
# export LIVENESS_PROBE_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_eks_liveness_probe_version)
# export CSI_NODE_DRIVER_REGISTRAR=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_efs_csi_node_driver_registrar)



# cp tpl/efs-csi-deployment.yaml.tpl efs-csi-driver/deployment.yaml
# cp tpl/efs-csi-daemonset.yaml.tpl efs-csi-driver/daemonset.yaml

# if [[ $(uname) == "Darwin" ]]; then
#   gsed -i "s/EFS_CSI_DRIVER_VERSION/$EFS_CSI_DRIVER_VERSION/g" efs-csi-driver/deployment.yaml
#   gsed -i "s/CSI_PROVISIONER_VERSION/$CSI_PROVISIONER_VERSION/g" efs-csi-driver/deployment.yaml
#   gsed -i "s/LIVENESS_PROBE_VERSION/$LIVENESS_PROBE_VERSION/g" efs-csi-driver/deployment.yaml

#   gsed -i "s/EFS_CSI_DRIVER_VERSION/$EFS_CSI_DRIVER_VERSION/g" efs-csi-driver/daemonset.yaml
#   gsed -i "s/CSI_NODE_DRIVER_REGISTRAR/$CSI_NODE_DRIVER_REGISTRAR/g" efs-csi-driver/daemonset.yaml
#   gsed -i "s/LIVENESS_PROBE_VERSION/$LIVENESS_PROBE_VERSION/g" efs-csi-driver/daemonset.yaml
# else
#   sed -i "s/EFS_CSI_DRIVER_VERSION/$EFS_CSI_DRIVER_VERSION/g" efs-csi-driver/deployment.yaml
#   sed -i "s/CSI_PROVISIONER_VERSION/$CSI_PROVISIONER_VERSION/g" efs-csi-driver/deployment.yaml
#   sed -i "s/LIVENESS_PROBE_VERSION/$LIVENESS_PROBE_VERSION/g" efs-csi-driver/deployment.yaml

#   sed -i "s/EFS_CSI_DRIVER_VERSION/$EFS_CSI_DRIVER_VERSION/g" efs-csi-driver/daemonset.yaml
#   sed -i "s/CSI_NODE_DRIVER_REGISTRAR/$CSI_NODE_DRIVER_REGISTRAR/g" efs-csi-driver/daemonset.yaml
#   sed -i "s/LIVENESS_PROBE_VERSION/$LIVENESS_PROBE_VERSION/g" efs-csi-driver/daemonset.yaml
# fi

# kubectl apply -f efs-csi-driver --recursive
