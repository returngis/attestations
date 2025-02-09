# Load the environment variables
source .devcontainer/.env

# Delete in case it already exists
kind delete cluster --name k8s-attestations-demo

# Create kind cluster
kind create cluster --name k8s-attestations-demo

# Install the Helm chart that deploys the Sigstore Policy Controller
helm upgrade policy-controller --install --atomic \
  --create-namespace --namespace artifact-attestations \
  oci://ghcr.io/github/artifact-attestations-helm-charts/policy-controller \
  --version v0.12.0-github10

kubectl get all -n artifact-attestations

# Once the policy controller has been deployed, you need to add the GitHub TrustRoot and a ClusterImagePolicy to your cluster.
helm upgrade trust-policies --install --atomic \
 --namespace artifact-attestations \
 oci://ghcr.io/github/artifact-attestations-helm-charts/trust-policies \
 --version v0.6.2 \
 --set policy.enabled=true \
 --set policy.organization=$ORG_NAME


# helm upgrade trust-policies --install --atomic \
#  --namespace artifact-attestations \
#  oci://ghcr.io/github/artifact-attestations-helm-charts/trust-policies \
#  --version v0.6.2 \
#  --set policy.enabled=true \
#  --set policy.organization=$ORG_NAME \
#  --set-json 'policy.exemptImages=["index.docker.io/library/busybox**"]' \
#  --set-json 'policy.images=["ghcr.io/returngis/**"]'

kubectl get all -n artifact-attestations

kubectl describe clusterimagepolicy.policy.sigstore.dev/github-policy

# Deploy a deployment with NGINX
kubectl create deployment nginx --image=nginx --replicas=3

kubectl get pods -w

# Delete the deployment
kubectl delete deployment nginx

# Now enforce the policy
# Each namespace in your cluster can independently enforce policies. To enable enforcement in a namespace you need to add a label to the namespace.
kubectl label namespace default policy.sigstore.dev/include=true --overwrite

kubectl describe namespace default

# Now, if you try to deploy the NGINX deployment again, it will be blocked by the policy controller.
kubectl create deployment nginx --image=nginx --replicas=3

# Add PAT for GitHub
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USER_NAME \
  --docker-password=$GITHUB_PAT

gh auth login

gh attestation verify oci://ghcr.io/returngis/tour-of-heroes-api:962cb07 --owner returngis


# Apply the deployment inline
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tour-of-heroes-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: tour-of-heroes-api
  template:
    metadata:
      labels:
        app: tour-of-heroes-api
    spec:
      containers:
      - name: tour-of-heroes-api
        image: ghcr.io/returngis/tour-of-heroes-api:962cb07
EOF

kubectl get pods -w

# If you encounter errors, you can check the logs of the policy controller to see why the deployment was blocked.
kubectl get pods -n artifact-attestations

kubectl logs $(kubectl get pods  -n artifact-attestations -o jsonpath='{.items[*].metadata.name}') -n artifact-attestations