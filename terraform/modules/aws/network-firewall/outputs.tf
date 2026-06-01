output "firewall_id" {
  value = aws_networkfirewall_firewall.this.id
}

output "firewall_arn" {
  value = aws_networkfirewall_firewall.this.arn
}

output "firewall_endpoint_id_by_az" {
  description = "Map of availability zone to VPC endpoint ID for the Network Firewall"
  value       = local.endpoint_id_by_az
}

output "firewall_policy_arn" {
  value = aws_networkfirewall_firewall_policy.this.arn
}

output "rule_group_arn" {
  value = aws_networkfirewall_rule_group.allow_http_https.arn
}
