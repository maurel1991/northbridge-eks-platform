# EBS CSI driver, installed as an AWS-managed EKS add-on.
# No pod_identity_association here: the association for the
# "ebs-csi-controller-sa" service account already exists (layer 2).
resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = local.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = var.ebs_csi_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# StorageClass "gp3": encrypted gp3 EBS volumes, created in the AZ of the pod.
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [aws_eks_addon.ebs_csi]
}
# EFS CSI driver, installed as an AWS-managed EKS add-on.
# The Pod Identity association for "efs-csi-controller-sa" already exists (layer 2).
resource "aws_eks_addon" "efs_csi" {
  cluster_name  = local.cluster_name
  addon_name    = "aws-efs-csi-driver"
  addon_version = var.efs_csi_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# StorageClass "efs": each volume request gets its own sub-directory
# (through an EFS access point) inside the shared file system created in layer 2.
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = data.terraform_remote_state.eks.outputs.efs_file_system_id
    directoryPerms   = "700"
    basePath         = "/dynamic"
  }

  depends_on = [aws_eks_addon.efs_csi]
}