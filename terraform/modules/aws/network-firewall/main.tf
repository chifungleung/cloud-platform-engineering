locals {
  # Extract per-AZ firewall VPC endpoint IDs from firewall_status after creation.
  endpoint_id_by_az = {
    for s in tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states) :
    s.availability_zone => s.attachment[0].endpoint_id
  }

  # Flat list of {cidr, port, sid} for generating stateful PASS rules.
  # Each home_network gets one rule for HTTPS (443) and one for HTTP (80).
  http_https_rules = flatten([
    for i, cidr in var.home_networks : [
      { cidr = cidr, port = "443", sid = (i * 2) + 1 },
      { cidr = cidr, port = "80", sid = (i * 2) + 2 },
    ]
  ])

  # Cartesian product of AZ x home_network for public subnet return routes.
  public_return_routes = {
    for pair in setproduct(keys(var.public_route_table_id_by_az), var.home_networks) :
    "${pair[0]}/${pair[1]}" => { az = pair[0], cidr = pair[1] }
  }
}

resource "aws_networkfirewall_rule_group" "allow_http_https" {
  name     = "${var.name}-allow-http-https"
  type     = "STATEFUL"
  capacity = 10

  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }

    rules_source {
      dynamic "stateful_rule" {
        for_each = local.http_https_rules
        content {
          action = "PASS"
          header {
            direction        = "FORWARD"
            protocol         = "TCP"
            source           = stateful_rule.value.cidr
            source_port      = "ANY"
            destination      = "ANY"
            destination_port = stateful_rule.value.port
          }
          rule_options {
            keyword  = "sid"
            settings = [tostring(stateful_rule.value.sid)]
          }
        }
      }
    }
  }

  tags = merge({ Name = "${var.name}-allow-http-https" }, var.tags)
}

resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${var.name}-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_default_actions = ["aws:${var.stateful_default_action == "DROP_STRICT" ? "drop_strict" : "drop_established"}"]

    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.allow_http_https.arn
    }
  }

  tags = merge({ Name = "${var.name}-policy" }, var.tags)
}

resource "aws_networkfirewall_firewall" "this" {
  name                = var.name
  vpc_id              = var.vpc_id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn

  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_id_by_az
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = merge({ Name = var.name }, var.tags)
}

# Route: TGW attachment subnets → firewall endpoint (same AZ)
resource "aws_route" "tgw_to_firewall" {
  for_each = var.tgw_attachment_route_table_id_by_az

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.endpoint_id_by_az[each.key]
}

# Route: Firewall subnets → NAT Gateway (same AZ)
resource "aws_route" "firewall_to_nat" {
  for_each = var.firewall_route_table_id_by_az

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id_by_az[each.key]
}

# Route: Public subnets → firewall endpoint for return traffic to RFC1918 space (same AZ)
resource "aws_route" "public_return_via_firewall" {
  for_each = local.public_return_routes

  route_table_id         = var.public_route_table_id_by_az[each.value.az]
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = local.endpoint_id_by_az[each.value.az]
}
