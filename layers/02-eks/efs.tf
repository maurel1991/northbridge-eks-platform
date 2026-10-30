# Shared, encrypted network file system. Unlike EBS volumes (tied to one AZ),
# EFS can be mounted by pods running in any of the 3 AZs.
resource "aws_efs_file_system" "this" {
  creation_token = "${var.cluster_name}-efs"
  encrypted      = true

  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

# Firewall for the EFS mount targets (created in the next step).
resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs"
  description = "Allow NFS from the EKS nodes to EFS"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

# Only the EKS nodes may reach EFS, and only on the NFS port (2049).
resource "aws_vpc_security_group_ingress_rule" "efs_from_nodes" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = module.eks.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  description                  = "NFS from EKS nodes"
}

# One mount target ("serving hatch") per private subnet, so one per AZ.
# Nodes in each AZ reach the same EFS file system through the target in their AZ.
resource "aws_efs_mount_target" "this" {
  for_each = toset(data.terraform_remote_state.network.outputs.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}