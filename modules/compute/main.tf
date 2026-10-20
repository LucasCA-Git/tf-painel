locals {
  # Arquitetura da AMI derivada da família da instância (t4g = Graviton/arm64).
  ami_arch = startswith(var.instance_type, "t4g") ? "arm64" : "x86_64"

  # Sem NAT a instância vai para a subnet pública com IP público só para saída (ADR-0003).
  subnet_id        = var.use_private_subnets ? var.private_subnet_ids[0] : var.public_subnet_ids[0]
  assign_public_ip = !var.use_private_subnets
}

# AMI mais recente do Amazon Linux 2023, publicada pela AWS no SSM Parameter Store.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${local.ami_arch}"
}

# -----------------------------------------------------------------------------
# IAM: acesso administrativo somente via SSM Session Manager.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name                 = "${var.name}-ec2"
  assume_role_policy   = data.aws_iam_policy_document.ec2_trust.json
  permissions_boundary = var.permissions_boundary_arn

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-ec2"
  role = aws_iam_role.instance.name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Security group da instância: nenhuma entrada, exceto do ALB.
# -----------------------------------------------------------------------------
resource "aws_security_group" "instance" {
  name_prefix = "${var.name}-instance-"
  description = "tf-painel instance - ingress only from the ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-instance" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "instance_all" {
  #checkov:skip=CKV_AWS_382:Egress is required for SSM agent, OS updates and packages (no VPC endpoints by design, see ADR-0003)
  security_group_id = aws_security_group.instance.id
  description       = "Outbound for SSM, OS updates and packages"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "instance_from_alb" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.instance.id
  description                  = "HTTP from the ALB only"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb[0].id
}

# -----------------------------------------------------------------------------
# Instância EC2
# -----------------------------------------------------------------------------
resource "aws_instance" "this" {
  #checkov:skip=CKV_AWS_88:Public IP is only used for egress when NAT is disabled; the SG has no public ingress (ADR-0003)
  #checkov:skip=CKV_AWS_126:Detailed monitoring is a paid feature, out of scope for this lab
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  iam_instance_profile        = aws_iam_instance_profile.instance.name
  associate_public_ip_address = local.assign_public_ip
  ebs_optimized               = true
  monitoring                  = false

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    environment = var.environment
    app_version = var.app_version
  })
  user_data_replace_on_change = true

  # IMDSv2 obrigatório: mitiga SSRF roubando credenciais da instância.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # Uma AMI nova não deve recriar a instância nem gerar falso drift;
    # atualização de AMI é feita de forma intencional com -replace.
    ignore_changes = [ami]
  }
}
