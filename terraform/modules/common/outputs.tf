output "tags" {
  description = "Common tags to apply to all resources."
  value       = local.tags

  precondition {
    condition = length(setsubtract(toset(var.required_tag_keys), toset(keys(local.tags)))) == 0
    error_message = "One or more required_tag_keys are missing from tags output."
  }
}

output "naming_prefix" {
  description = "Company naming prefix."
  value       = local.naming_prefix
}

output "resource_naming_pattern" {
  description = "Pattern hint that includes resource type for naming."
  value       = var.resource_naming_pattern
}

output "security_profile" {
  description = "Shared security defaults."
  value       = local.security_profile
}

output "operations_profile" {
  description = "Shared operational defaults."
  value       = local.operations_profile
}

output "network_defaults" {
  description = "Shared network defaults."
  value       = local.network_defaults
}

output "compliance_profile" {
  description = "Shared compliance defaults."
  value       = local.compliance_profile
}
