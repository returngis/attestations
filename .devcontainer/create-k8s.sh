# Load the environment variables
source .devcontainer/.env

# Create kind cluster
kind create cluster --name k8s-attestations-demo

# Install the Helm chart that deploys the Sigstore Policy Controller
helm upgrade policy-controller --install --atomic \
  --create-namespace --namespace artifact-attestations \
  oci://ghcr.io/github/artifact-attestations-helm-charts/policy-controller \
  --version v0.10.0-github9


kubectl get all -n artifact-attestations

# Once the policy controller has been deployed, you need to add the GitHub TrustRoot and a ClusterImagePolicy to your cluster.
helm upgrade trust-policies --install --atomic \
 --namespace artifact-attestations \
 oci://ghcr.io/github/artifact-attestations-helm-charts/trust-policies \
 --version v0.6.2 \
 --set policy.enabled=true \
 --set policy.organization=$ORG_NAME

kubectl get all -n artifact-attestations

# Deploy a deployment with NGINX
kubectl create deployment nginx --image=nginx --replicas=3

kubectl get pods

# Delete the deployment
kubectl delete deployment nginx

# Now enforce the policy
# Each namespace in your cluster can independently enforce policies. To enable enforcement in a namespace you need to add a label to the namespace.
kubectl label namespace default policy.sigstore.dev/include=true

# Now, if you try to deploy the NGINX deployment again, it will be blocked by the policy controller.
kubectl create deployment nginx --image=nginx --replicas=3

# Add PAT for GitHub
# ...existing code...

# Add PAT for GitHub
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USER_NAME \
  --docker-password=$GITHUB_PAT

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
        image: ghcr.io/returngis/tour-of-heroes-api:7b11ef9
      imagePullSecrets:
      - name: ghcr-secret
EOF