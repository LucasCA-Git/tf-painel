# Testes unitários do módulo compute com provider mockado.

mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/tf-painel-test-alb/0123456789abcdef"
      dns_name = "tf-painel-test-alb-123.us-east-1.elb.amazonaws.com"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/tf-painel-test-tg/0123456789abcdef"
    }
  }
}

variables {
  name               = "tf-painel-test"
  environment        = "test"
  vpc_id             = "vpc-0123456789abcdef0"
  public_subnet_ids  = ["subnet-pub-a", "subnet-pub-b"]
  private_subnet_ids = ["subnet-priv-a", "subnet-priv-b"]
}

run "defaults_public_subnet_no_ingress" {
  command = plan

  assert {
    condition     = aws_instance.this.subnet_id == "subnet-pub-a"
    error_message = "Without NAT the instance must use the first public subnet."
  }

  assert {
    condition     = aws_instance.this.associate_public_ip_address == true
    error_message = "Without NAT the instance needs a public IP for egress."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.instance_from_alb) == 0
    error_message = "Instance must have no ingress rule when the ALB is disabled."
  }

  assert {
    condition     = length(aws_lb.this) == 0
    error_message = "ALB must be disabled by default."
  }
}

run "hardening_is_enforced" {
  command = plan

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted == true
    error_message = "Root volume must be encrypted."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ssm_core.policy_arn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    error_message = "Instance role must allow SSM Session Manager (the only admin access path)."
  }
}

run "private_placement_with_nat" {
  command = plan

  variables {
    use_private_subnets = true
  }

  assert {
    condition     = aws_instance.this.subnet_id == "subnet-priv-a"
    error_message = "With NAT the instance must use the first private subnet."
  }

  assert {
    condition     = aws_instance.this.associate_public_ip_address == false
    error_message = "Private instance must not have a public IP."
  }
}

run "alb_toggle" {
  command = apply

  variables {
    enable_alb = true
  }

  assert {
    condition     = length(aws_lb.this) == 1 && aws_lb.this[0].drop_invalid_header_fields
    error_message = "ALB must exist and drop invalid headers."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.instance_from_alb) == 1
    error_message = "Instance must accept HTTP from the ALB security group."
  }

  assert {
    condition     = output.url == "http://tf-painel-test-alb-123.us-east-1.elb.amazonaws.com"
    error_message = "url output must point to the ALB DNS name."
  }
}

run "graviton_uses_arm64_ami" {
  command = plan

  variables {
    instance_type = "t4g.micro"
  }

  assert {
    condition     = data.aws_ssm_parameter.al2023.name == "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
    error_message = "t4g instances must use the arm64 AMI."
  }
}

run "rejects_expensive_instance" {
  command = plan

  variables {
    instance_type = "m5.large"
  }

  expect_failures = [var.instance_type]
}

run "permissions_boundary_is_attached" {
  command = plan

  variables {
    permissions_boundary_arn = "arn:aws:iam::123456789012:policy/tf-painel-workload-boundary"
  }

  assert {
    condition     = aws_iam_role.instance.permissions_boundary == "arn:aws:iam::123456789012:policy/tf-painel-workload-boundary"
    error_message = "Instance role must carry the permissions boundary required by the apply role."
  }
}
