# Northbridge EKS Platform

A layered, reproducible Amazon EKS platform built with Terraform, designed to be rebuilt from scratch, tested, and destroyed at the end of every work session.

- **Region:** `us-east-1`
- **Current environment:** `dev` (staging planned for phase 7, built from the same code)

## Status

| Phase | Name | Status |
|---|---|---|
| 0 | Preparation (S3 state bucket, backend, repository layout) | Done |
| 1 | Networking (VPC, 3 AZs, NAT, routing) | Done |
| 2 | EKS cluster, managed nodes, Pod Identity roles, EFS | Done |
| 3 | Kubernetes add-ons | In progress: code written, mostly untested |
| 4 | GitOps (Argo CD) | Planned |
| 5 | Multi-tenancy (namespaces, RBAC, quotas) | Planned |
| 6 | CI automation (GitHub Actions) | Planned |
| 7 | Staging and testing | Planned |
| 8 | Deliverables and documentation | Planned |

### Phase 3 progress

"Written" means the Terraform code is committed and passes `terraform validate`. "Tested" means it was installed on a real cluster and checked.

| Add-on | Version | Status |
|---|---|---|
| EBS CSI driver (EKS add-on) + `gp3` StorageClass | `v1.67.2-eksbuild.1` | Tested: a 1 Gi volume was bound and written to |
| EFS CSI driver (EKS add-on) + `efs` StorageClass | `v3.5.3-eksbuild.1` | Written. Shared-volume test across two nodes still to be recorded |
| `gp3` as default StorageClass | - | Written, not applied yet |
| Metrics Server | chart `3.14.0` | Written |
| AWS Load Balancer Controller | chart `3.6.2` | Written |
| Cluster Autoscaler | chart `9.59.0` | Written (see known limitations) |
| External Secrets Operator | chart `2.14.0` | Written. `ClusterSecretStore` and a test `ExternalSecret` still to be added as YAML |
| kube-prometheus-stack (Prometheus, Grafana) | chart `92.17.1` | Written |
| Fluent Bit (logs to CloudWatch) | chart `0.58.3` | Written |
| ExternalDNS | - | IAM role ready (layer 2). Chart not written yet |
| cert-manager | - | Not started |

## Architecture

The platform is split into independent Terraform layers. Each layer has its own state file, so a mistake in one layer cannot corrupt another. A layer reads what it needs from the layer below through `terraform_remote_state` (read-only).

```
layers/03-addons   Helm charts, EKS add-ons, StorageClasses
        |  reads cluster name, endpoint, CA, VPC ID
layers/02-eks      EKS cluster, managed node group, EFS, log group, Pod Identity roles
        |  reads VPC ID, private subnet IDs
layers/01-network  VPC, public and private subnets across 3 AZs, NAT gateways
        |
bootstrap/         S3 bucket that stores the state of all the layers
```

### What each layer builds

**Bootstrap** - S3 bucket for Terraform state with versioning and server-side encryption. State locking uses the native S3 lock file (`use_lockfile = true`, Terraform 1.10+), so no DynamoDB table is needed.

**Layer 1 - Network** - A VPC across 3 Availability Zones with one public and one private subnet per zone, NAT gateways, and route tables. Subnets are tagged with the cluster name so that EKS and the load balancer controller can discover them.

**Layer 2 - EKS**
- EKS 1.36 created with `terraform-aws-modules/eks/aws` 21.29.0 (pinned exactly).
- One managed node group (3 x `t3.medium`, Amazon Linux 2023, min 3 / max 6) spread over the 3 private subnets, so one node per AZ.
- Core add-ons: `vpc-cni`, `coredns`, `kube-proxy`, `eks-pod-identity-agent`.
- Public API endpoint restricted to the CIDRs listed in `api_allowed_cidrs`; private endpoint enabled.
- Secrets encrypted with a KMS key; control plane logs sent to CloudWatch.
- Encrypted EFS file system, a security group that allows NFS (port 2049) only from the nodes, and one mount target per AZ.
- A CloudWatch log group for container logs, with a 7-day retention.
- EKS Pod Identity roles, each with a least-privilege policy and an association to a fixed service account (see below).

**Layer 3 - Add-ons**
- The EBS and EFS CSI drivers are AWS-managed EKS add-ons; other components are Helm charts with pinned versions, configured through `yamlencode` values.
- A `monitoring` namespace holds the Prometheus stack. Grafana's admin password is generated with the `random` provider and stored in a Kubernetes secret (see security notes).
- Prometheus keeps 7 days of metrics on a 10 Gi encrypted `gp3` volume. Alertmanager is disabled for now, and scraping of the managed control plane is disabled because it is not reachable on EKS.
- Fluent Bit runs on every node and ships container logs to the CloudWatch log group created in layer 2.

### Pod Identity roles

Pods have no AWS permissions by default. Each add-on that needs AWS gets its own IAM role through EKS Pod Identity, with no static credentials stored in the cluster.

| Add-on | Namespace / service account | Scope of the permissions |
|---|---|---|
| EBS CSI driver | `kube-system` / `ebs-csi-controller-sa` | AWS-managed `AmazonEBSCSIDriverPolicy` |
| EFS CSI driver | `kube-system` / `efs-csi-controller-sa` | AWS-managed `AmazonEFSCSIDriverPolicy` |
| AWS Load Balancer Controller | `kube-system` / `aws-load-balancer-controller` | Official upstream policy (v3.6.2) |
| ExternalDNS | `external-dns` / `external-dns` | Change records in one Route 53 zone only, plus read-only listing |
| External Secrets Operator | `external-secrets` / `external-secrets` | Read-only access to secrets under `<project>/<environment>/` |
| Cluster Autoscaler | `kube-system` / `cluster-autoscaler` | Scale only the Auto Scaling groups tagged as owned by the cluster |
| Fluent Bit | `logging` / `fluent-bit` | Write log streams in one CloudWatch log group only |

The namespace and service account names must match the Helm values used when each component is installed.

## Repository layout

```
.
├── bootstrap/state-backend/   S3 state bucket (local state, created once)
├── envs/
│   └── dev/
│       ├── backend.hcl        Shared backend settings (no state key)
│       ├── network.tfvars     Layer 1 variables
│       ├── eks.tfvars         Layer 2 variables
│       └── addons.tfvars      Layer 3 variables
├── layers/
│   ├── 01-network/
│   ├── 02-eks/
│   │   └── policies/          Upstream IAM policy JSON files
│   └── 03-addons/
├── modules/                   Reusable modules
├── gitops/                    Argo CD content (phase 4)
└── docs/                      Documentation
```

## Conventions

- **One layer = one folder = one state key.** Keys follow `<env>/<layer>/terraform.tfstate`.
- **Partial backend.** Every layer declares an empty `backend "s3" {}`. Common settings live in `envs/<env>/backend.hcl`; only the key is passed at `init`.
- **Version pinning.** Terraform, providers, modules, EKS add-ons and Helm charts are pinned. `.terraform.lock.hcl` files are committed.
- **Tagging.** `Project`, `Environment`, `Owner` and `CostCenter` are applied to every taggable AWS resource through the provider `default_tags`.
- **No secrets in Git.** State files, credentials and local variable files are excluded by `.gitignore`.
- **Reproducibility.** Everything needed to rebuild an environment is in Git, including per-environment variable files.
- **Chart version vs app version.** Pin the `CHART VERSION` column of `helm search repo`, not the `APP VERSION` column.

### Pinned versions

| Component | Version |
|---|---|
| Terraform | `>= 1.10.0, < 2.0.0` (developed with 1.15.5) |
| AWS provider | `~> 6.0` |
| Helm provider | `~> 3.3` |
| Kubernetes provider | `~> 3.4` |
| Random provider | `~> 3.0` |
| EKS module | `21.29.0` |
| Kubernetes (EKS) | `1.36` |
| EBS CSI driver add-on | `v1.67.2-eksbuild.1` |
| EFS CSI driver add-on | `v3.5.3-eksbuild.1` |
| Metrics Server chart | `3.14.0` |
| AWS Load Balancer Controller chart | `3.6.2` (same version as the IAM policy) |
| Cluster Autoscaler chart | `9.59.0` |
| External Secrets chart | `2.14.0` |
| kube-prometheus-stack chart | `92.17.1` |
| Fluent Bit chart | `0.58.3` |

## Prerequisites

- Terraform 1.10 or later, AWS CLI v2, `kubectl`, Helm.
- AWS credentials with permission to create the resources above (`aws sts get-caller-identity` must succeed).
- On Windows with Git Bash, prefix `kubectl exec` commands that contain a path with `MSYS_NO_PATHCONV=1`, otherwise paths such as `/data/file` are rewritten to Windows paths.

## Runbook

### First-time setup

1. Create the state bucket from `bootstrap/state-backend` (local state).
2. Check the settings in `envs/<env>/backend.hcl` and the `.tfvars` files.
3. Set `api_allowed_cidrs` in `envs/<env>/eks.tfvars` to your current public IP in `/32` form (`curl -s https://checkip.amazonaws.com`).

### Build (always in this order)

```bash
# Layer 1 - network
cd layers/01-network
terraform init -backend-config=../../envs/dev/backend.hcl -backend-config="key=dev/01-network/terraform.tfstate"
terraform apply -var-file=../../envs/dev/network.tfvars

# Layer 2 - EKS
cd ../02-eks
terraform init -backend-config=../../envs/dev/backend.hcl -backend-config="key=dev/02-eks/terraform.tfstate"
terraform apply -var-file=../../envs/dev/eks.tfvars

# Connect kubectl
aws eks update-kubeconfig --region us-east-1 --name northbridge-dev
kubectl get nodes -L topology.kubernetes.io/zone

# Layer 3 - add-ons
cd ../03-addons
terraform init -backend-config=../../envs/dev/backend.hcl -backend-config="key=dev/03-addons/terraform.tfstate"
terraform apply -var-file=../../envs/dev/addons.tfvars
```

Expected result of layer 2: three nodes in `Ready` state, one in each of `us-east-1a`, `us-east-1b` and `us-east-1c`.

### Access Grafana

Grafana is not exposed (service type `ClusterIP`). Use a port-forward and read the generated admin password from the secret:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
kubectl get secret grafana-admin -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
```

Then open `http://localhost:3000` and sign in as `admin`.

### Tear down (reverse order)

1. Delete anything created by hand in the cluster (test pods, PVCs, load balancers), then check `kubectl get pv` is empty.
2. `terraform destroy` in `layers/03-addons`, then `layers/02-eks`, then `layers/01-network`, each with its `-var-file`.
3. Check that nothing billable remains:

```bash
aws eks list-clusters --region us-east-1
aws ec2 describe-nat-gateways --region us-east-1 --filter Name=state,Values=available --query "NatGateways[].NatGatewayId"
aws efs describe-file-systems --region us-east-1 --query "FileSystems[].FileSystemId"
aws ec2 describe-volumes --region us-east-1 --query "Volumes[].VolumeId"
aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[].LoadBalancerName"
```

All five commands should return an empty list. The state bucket stays in place. CloudWatch log data is kept for 7 days by design.

### Cost reference (us-east-1, approximate)

| Item | Per hour |
|---|---|
| EKS control plane | $0.10 |
| 3 x `t3.medium` nodes | $0.125 |
| 3 NAT gateways | $0.135 |
| **Total while running** | **about $0.36** |

Destroy the environment at the end of each session.

### Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `terraform init` asks for the bucket name | The `-backend-config` options are missing. Use the full `init` command shown in the build section. |
| `Backend configuration changed` on `init` | Either the command was run in the wrong layer folder, or the stored settings are incomplete. Check the folder, and compare the stored `key` with `grep -E '"bucket"\|"key"' .terraform/terraform.tfstate`. Only use `-reconfigure` when the folder and key are right; never use `-migrate-state` to get past this message. |
| `Error acquiring the state lock` after an interrupted run | An orphaned lock. Confirm no `terraform.exe` is running, then `terraform force-unlock <ID>`. |
| Connection lost during `apply` (`no such host`) | Terraform writes `errored.tfstate`. Restore the connection, release the lock if needed, run `terraform state push errored.tfstate`, then `terraform plan`. Do not run `apply` again before pushing the state. |
| Plan wants to replace the cluster after an interrupted creation | The resource is marked tainted. If the cluster is `ACTIVE`, run `terraform untaint 'module.eks.aws_eks_cluster.this[0]'`. |
| `kubectl` times out | The public IP changed. Update `api_allowed_cidrs` and apply layer 2. |
| Terraform asks for variable values | A `-var-file` is missing. Close the shell rather than answering the prompts, and use `-input=false` to avoid prompts. |
| `Unsupported argument` or `Unsupported block type` on a provider | The Helm provider v3 uses attributes (`kubernetes = { ... }`), while the Kubernetes provider v3 still uses blocks (`exec { ... }`). |

## Architecture decisions (draft ADRs)

1. **Layered state with remote-state outputs.** One state file per layer limits the blast radius and lets each layer be tested before the next one is built.
2. **Native S3 state locking.** Terraform 1.10+ supports `use_lockfile`, which removes the DynamoDB table.
3. **EKS Pod Identity instead of IRSA.** Roles are attached to service accounts through an association managed on the AWS side. This removes the need for an OIDC provider per add-on and is simpler to reason about.
4. **EBS and EFS CSI drivers as EKS managed add-ons.** AWS maintains compatibility with the cluster version, which reduces upgrade risk. Helm is used for components that have no managed add-on.
5. **One shared EFS file system with dynamic access points.** Pods in any AZ can mount it; each volume request gets an isolated sub-directory.
6. **Helm values through `yamlencode`.** Settings are passed as generated YAML instead of many `set` arguments, which is easier to read and independent of the Helm provider v3 syntax changes.
7. **Custom resources outside Terraform.** Objects such as `ClusterSecretStore` and `ExternalSecret` depend on CRDs installed by the chart itself, which Terraform cannot know at plan time. They are kept as plain YAML, applied with `kubectl` for tests and later managed by Argo CD.
8. **CloudWatch Logs for container logs.** No log storage to run in the cluster, and logs outlive the cluster. The log group is created by Terraform with a 7-day retention to keep costs bounded.
9. **Grafana password generated by Terraform (for dev).** Simple, and kept out of Git. The trade-off is that the value lives in the encrypted Terraform state. A later improvement is to store it in Secrets Manager and sync it with External Secrets.

## Security notes

- The state bucket is encrypted and versioned; state is never committed to Git.
- The Kubernetes API is reachable only from the allowed CIDRs.
- Each add-on role is scoped as narrowly as its function allows (one DNS zone, one secrets prefix, one log group, owned Auto Scaling groups only).
- Kubernetes secrets are encrypted with a KMS key.
- The Grafana admin password is generated, marked sensitive, and stored in the Terraform state and in a Kubernetes secret. It never appears in Git.

## Known limitations

- **Cluster Autoscaler version skew.** The latest chart installs Cluster Autoscaler 1.35.0 while the cluster runs Kubernetes 1.36. A one-minor-version gap is usually fine but not officially supported. Scaling is tested in phase 7, and Karpenter is a stretch goal.
- **Fluent Bit and Pod Identity.** Support for Pod Identity credentials in the Fluent Bit CloudWatch output is still to be confirmed on a running cluster. IRSA is the fallback for this one component.
- **Most phase 3 components are untested.** They are validated but have not yet been installed together on a real cluster.
- **DNS and HTTPS.** ExternalDNS and cert-manager are not written yet, so no application is reachable by name.

## Roadmap

Remaining phase 3 items (ExternalDNS, cert-manager, tests of every add-on), GitOps with Argo CD, multi-tenancy (RBAC, quotas, Pod Security Standards), a GitHub Actions pipeline (`fmt`, `validate`, TFLint, Checkov, plan as a pull request comment), a staging environment built from the same code, and the final documentation (architecture diagram, ADRs, demo). Stretch goals: Karpenter, Kyverno or Gatekeeper, Velero, Kubecost and a disaster recovery exercise.