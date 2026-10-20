# Testes unitários do módulo network com provider mockado:
# rodam offline, sem credenciais AWS, em segundos.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # ARNs gerados aleatoriamente pelo mock não passam na validação do provider.
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/tf-painel-test-flow-logs"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/tf-painel-test/vpc-flow-logs"
    }
  }
}

variables {
  name     = "tf-painel-test"
  vpc_cidr = "10.10.0.0/16"
}

run "defaults_are_cost_safe" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "NAT Gateway must be disabled by default."
  }

  assert {
    condition     = length(aws_flow_log.this) == 0
    error_message = "Flow logs must be disabled by default."
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public and 2 private subnets by default."
  }
}

run "subnet_cidrs_are_deterministic" {
  command = plan

  assert {
    condition     = aws_subnet.public["us-east-1a"].cidr_block == "10.10.0.0/24"
    error_message = "First public subnet should be 10.10.0.0/24."
  }

  assert {
    condition     = aws_subnet.private["us-east-1b"].cidr_block == "10.10.11.0/24"
    error_message = "Second private subnet should be 10.10.11.0/24."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs."
  }
}

run "nat_toggle_creates_single_nat_and_route" {
  command = plan

  variables {
    enable_nat_gateway = true
    az_count           = 3
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Exactly one NAT Gateway expected when enabled."
  }

  assert {
    condition     = length(aws_route.private_nat) == 1
    error_message = "Private route table must default-route to the NAT."
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "az_count = 3 should create 3 private subnets."
  }
}

run "flow_logs_toggle" {
  command = plan

  variables {
    enable_flow_logs = true
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "REJECT"
    error_message = "Flow logs should capture only REJECT traffic."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].name == "/tf-painel-test/vpc-flow-logs"
    error_message = "Log group must live under the /<name>/ prefix."
  }
}

run "rejects_single_az" {
  command = plan

  variables {
    az_count = 1
  }

  expect_failures = [var.az_count]
}
