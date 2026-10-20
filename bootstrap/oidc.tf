# -----------------------------------------------------------------------------
# GitHub Actions OIDC: duas roles com confiança diferente (ver ADR-0001).
# -----------------------------------------------------------------------------
locals {
  oidc_host = "token.actions.githubusercontent.com"
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : (
    "arn:${local.partition}:iam::${local.account_id}:oidc-provider/${local.oidc_host}"
  )
  # Roles/profiles que os ambientes podem criar: tf-painel-dev-*, tf-painel-prod-*.
  # As roles do próprio pipeline (tf-painel-gha-*) ficam FORA desse escopo.
  workload_role_arns = [
    for env in var.environments : "arn:${local.partition}:iam::${local.account_id}:role/${var.project}-${env}-*"
  ]
  workload_profile_arns = [
    for env in var.environments : "arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.project}-${env}-*"
  ]
  workload_log_group_arns = [
    for env in var.environments : "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/${var.project}-${env}/*"
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  # A AWS valida o certificado do GitHub pela própria CA confiável;
  # o thumbprint é mantido apenas por compatibilidade.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --- Role de PLAN: só leitura + state ----------------------------------------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # PRs e a branch main podem planejar; nenhum outro ref.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values = [
        "repo:${local.repo}:pull_request",
        "repo:${local.repo}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "${var.project}-gha-plan"
  description          = "GitHub Actions - terraform plan (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

# State para o PLAN: lê o state e só escreve/apaga o lockfile (.tflock).
# Assim um PR não consegue corromper ou apagar o state de prod.
data "aws_iam_policy_document" "state_read_lock" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "ReadState"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/envs/*"]
  }

  statement {
    sid       = "ManageLockfile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/envs/*.tflock"]
  }
}

# State para o APPLY: leitura e escrita do state.
data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "ReadWriteStateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/envs/*"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state-read"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.state_read_lock.json
}

# --- Role de APPLY: escrita, apenas via GitHub Environments -------------------
data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # O claim `sub` vira `environment:<nome>` quando o job declara environment.
    # Assim só jobs atrelados a dev/prod (prod com aprovação) assumem esta role.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = [for env in var.environments : "repo:${local.repo}:environment:${env}"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = "${var.project}-gha-apply"
  description          = "GitHub Actions - terraform apply/destroy (environments only)"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

# Leitura ampla para o refresh do Terraform.
resource "aws_iam_role_policy_attachment" "apply_readonly" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "apply_state" {
  name   = "terraform-state"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.state_access.json
}

data "aws_iam_policy_document" "apply_write" {
  # Rede, compute e load balancer: limitados à região do projeto.
  statement {
    sid = "NetworkComputeLoadBalancing"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # IAM: criar/alterar roles SÓ dos ambientes e SÓ com o permissions boundary.
  # Sem o boundary, a role de apply poderia criar uma role admin e assumi-la.
  statement {
    sid = "WorkloadRolesWithBoundary"
    actions = [
      "iam:CreateRole",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = local.workload_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.workload_boundary.arn]
    }
  }

  statement {
    sid = "WorkloadRolesLifecycle"
    actions = [
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = local.workload_role_arns
  }

  statement {
    sid = "WorkloadInstanceProfiles"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
    ]
    resources = local.workload_profile_arns
  }

  # PassRole apenas para EC2 e VPC Flow Logs.
  statement {
    sid       = "PassWorkloadRoles"
    actions   = ["iam:PassRole"]
    resources = local.workload_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "vpc-flow-logs.amazonaws.com"]
    }
  }

  # Cinto e suspensório: nunca mexer nas roles do pipeline nem no boundary.
  statement {
    sid     = "DenyPipelineSelfModification"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/${var.project}-gha-*",
      aws_iam_policy.workload_boundary.arn,
    ]
  }

  statement {
    sid       = "DenyBoundaryRemoval"
    effect    = "Deny"
    actions   = ["iam:DeleteRolePermissionsBoundary", "iam:PutRolePermissionsBoundary"]
    resources = ["*"]
  }

  # Service-linked role do ELB (criada uma única vez por conta).
  statement {
    sid       = "ElbServiceLinkedRole"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  # Log groups dos flow logs, sob o prefixo do projeto.
  statement {
    sid = "ProjectLogGroups"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
    ]
    resources = local.workload_log_group_arns
  }
}

# -----------------------------------------------------------------------------
# Permissions boundary: teto de permissões de QUALQUER role criada pelos
# ambientes (instância EC2 e flow logs). Mesmo que alguém anexe uma política
# admin, a permissão efetiva nunca passa disto.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "workload_boundary" {
  # Equivalente ao AmazonSSMManagedInstanceCore (Session Manager).
  statement {
    sid = "SsmManagedInstance"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
    ]
    resources = ["*"]
  }

  # VPC Flow Logs escrevendo nos log groups dos ambientes.
  statement {
    sid = "FlowLogsDelivery"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [for arn in local.workload_log_group_arns : "${arn}:*"]
  }
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "${var.project}-workload-boundary"
  description = "Permissions boundary for every role created by the tf-painel environments"
  policy      = data.aws_iam_policy_document.workload_boundary.json
}

resource "aws_iam_role_policy" "apply_write" {
  name   = "terraform-apply"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_write.json
}
