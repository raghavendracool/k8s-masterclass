# Kubernetes Masterclass – 18‑Day Instructor Program

> **Repo:** [https://github.com/raghavendracool/k8s‑masterclass.git](https://github.com/raghavendracool/k8s‑masterclass.git)
>
> **New!** *Day 0 – AWS & CLI Bootstrapping* section added so students can start from a fresh AWS account and an empty workstation.

```text
k8s‑masterclass/
├── README.md  # master instructions (this file)
├── day00-aws-bootstrapping/  # NEW
│   ├── aws-cli-install.sh
│   └── ec2-provision.md
├── day01‑cluster‑setup/
│   ├── minikube‑start.sh
│   └── kind‑3node.yaml
│   ... (unchanged folders) ...
```

---

## Day 0 – AWS & CLI Bootstrapping (Prep)

*Goal: provide complete onboarding commands for cloud setup before touching Kubernetes.*

### 0.1  Sign‑Up / Login

```text
1. Browse https://aws.amazon.com/ and create a free‑tier account (credit card required).
2. Sign in as **root** user → IAM → ☑️ *Activate MFA* (best practice).
```

### 0.2  Create An Admin IAM User (Console)

```text
IAM → Users → "Add user"
• User name: k8s‑admin
• Access type: ✔ Programmatic & AWS Management Console
• Permissions: Attach policy → AdministratorAccess (for lab simplicity)
• Create user → Download .csv with AccessKey & Secret
```

> **Alternative – CLI**  (requires a bootstrap profile):

```bash
aws iam create-user --user-name k8s-admin
aws iam attach-user-policy             \
  --user-name k8s-admin                \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name k8s-admin
```

### 0.3  Install & Configure AWS CLI v2 (Workstation)

`day00-aws-bootstrapping/aws-cli-install.sh` contains:

```bash
#!/usr/bin/env bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
# Verify
aws --version
```

Run **configure**:

```bash
aws configure
# → AWS Access Key ID [None]: <AccessKey>
# → AWS Secret Access Key [None]: <SecretKey>
# → Default region name [None]: us-east-1
# → Default output format [None]: json
```

### 0.4  Provision an EC2 Instance (CLI)

`day00-aws-bootstrapping/ec2-provision.md`:

```bash
# replace subnet‑id & sg‑id with your values
KEYNAME="k8s-lab-key"
aws ec2 create-key-pair --key-name $KEYNAME --query "KeyMaterial" --output text > ${KEYNAME}.pem
chmod 400 ${KEYNAME}.pem

AMI="ami-0c02fb55956c7d316"   # Amazon Linux 2 us‑east‑1
aws ec2 run-instances \
  --image-id $AMI           \
  --instance-type t3.medium \
  --key-name $KEYNAME       \
  --security-group-ids sg-XXXXX \
  --subnet-id subnet-XXXXX  \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s-lab}]'
```

Grab the **PublicIpAddress**:

```bash
IP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=k8s-lab \
     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
ssh -i ${KEYNAME}.pem ec2-user@${IP}
```

### 0.5  Prepare the Node (inside EC2)

```bash
# Update & install Docker
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Minikube (driver=none option works on EC2)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=none
```

> **Or Spin an EKS Cluster quickly with eksctl**

```bash
brew install eksctl   # macOS, or use curl installer on Linux
eksctl create cluster --name masterclass --region us-east-1 --nodes 3 --node-type t3.medium
```

🎉 **Cluster ready!**  Proceed to **Day 1**.
===============================================================================================================================================

#### Day 1  – Cluster Up & Basics

```bash
# Bring up cluster
bash day01-cluster-setup/minikube-start.sh
# Verify
kubectl cluster-info
kubectl get nodes -o wide
```

Discuss control‑plane components; demo `watch kubectl get pods ‑A`.

#### Day 2  – Pods

```bash
kubectl apply -f day02-pods/pod-nginx.yaml
kubectl exec -it nginx-demo -- curl -s localhost
```

Add readiness probe live; explain restarts.

#### Day 3  – ReplicaSets

```bash
kubectl apply -f day03-replicasets/rs-nginx.yaml
kubectl scale rs web-rs --replicas 5
```

#### Day 4  – Deployments

```bash
kubectl apply -f day04-deployments/deploy-nginx.yaml
bash day04-deployments/rollout-script.sh
kubectl rollout history deployment/web-deploy
```

#### Day 5  – Services & Ingress

```bash
kubectl apply -f day05-services/svc-nodeport.yaml
bash day12-helm-ingress/helm-install-nginx.sh   # installs controller (reuse later)
kubectl apply -f day05-services/ingress-basic.yaml
minikube tunnel   # if on local machine
```

#### Day 6  – ConfigMaps & Secrets

```bash
kubectl apply -f day06-configmaps-secrets/configmap-app.yaml
kubectl apply -f day06-configmaps-secrets/secret-tls.yaml
kubectl get secret tls-cert -o yaml
```

#### Day 7  – Stateful MySQL

```bash
kubectl apply -f day07-stateful-mysql/pvc-mysql.yaml
kubectl apply -f day07-stateful-mysql/sts-mysql.yaml
kubectl exec -it mysql-0 -- mysql -uroot -ppassword -e 'SHOW DATABASES;'
```

#### Day 8  – Advanced Scheduling

```bash
kubectl label nodes <node> disktype=ssd
kubectl apply -f day08-scheduling/affinity-ssd.yaml
kubectl describe pod affinity-demo | grep Node:
```

#### Day 9  – Namespaces & RBAC

```bash
kubectl apply -f day09-rbac-namespaces/rbac-viewer.yaml
kubectl auth can-i get pods --as system:serviceaccount:dev:default -n dev
```

#### Day 10  – Jobs & CronJobs

```bash
kubectl apply -f day10-jobs-cronjobs/job-pi.yaml
kubectl apply -f day10-jobs-cronjobs/cron-backup.yaml
kubectl get jobs,cronjobs
```

#### Day 11  – Horizontal Pod Autoscaler

```bash
# install metrics‑server (one‑liner)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f day11-autoscaling/hpa-web.yaml
kubectl top pod
```

Open a second terminal, generate load with BusyBox `wget` loop.

#### Day 12  – Helm & CRDs

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm search repo ingress | head
kubectl apply -f day12-helm-ingress/crd-greeting.yaml
kubectl get crd | grep greeting
```

#### Day 13  – Observability

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prom prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  -f day13-observability/prometheus-values.yaml
kubectl -n monitoring port-forward svc/kube-prom-grafana 3000:80
```

Login to Grafana (`admin/prom-operator`).

#### Day 14  – Security Best Practices

```bash
kubectl apply -f day14-security/namespace-baseline.yaml
kubectl run demo --image=nginx -n secure --restart=Never  # should succeed
kubectl exec -it demo -n secure -- id
```

Explain Pod Security Standards.

#### Day 15  – GitOps with ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f day15-gitops-argocd/argocd-app.yaml
```

Open ArgoCD UI; watch auto‑sync.

#### Day 16  – Cluster Admin / Maintenance

```bash
kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <worker>
# etcd backup (control-plane shell)
bash day16-admin-tasks/etcd-backup.sh
```

#### Day 17  – Troubleshooting Workshop

Follow scenarios in `day17-troubleshooting/cheat-sheet.md`.

#### Day 18  – Capstone Project

* Students clone `day18-capstone-project/` overlay, update image tags, and submit PRs.
* Instructor reviews with `kubectl get all -n capstone`.

</details>

---

## Repo Structure

```text
k8s-masterclass/
├── day00-aws-bootstrapping/      # AWS onboarding scripts & docs
├── day01-cluster-setup/         # Minikube & Kind manifests
├── day02-pods/                  # Pod examples
├── …                            # One folder per day
└── day18-capstone-project/      # Final project skeleton
```

Scripts (`*.sh`) are executable; manifests (`*.yaml`) are declarative and can be applied with `kubectl apply -f`.

---

## Contributing

PRs are welcome! Follow Conventional Commits (`feat:`, `fix:`) and open an issue first for major changes.

---

## License

MIT © Raghavendra (2025)
