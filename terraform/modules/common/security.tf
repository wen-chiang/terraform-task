locals {
  security_profile = {
    mode               = var.mode
    enforce_encryption = var.enforce_encryption
    enable_logging     = var.enable_logging
    enforce_tls        = var.enforce_tls
    encryption_key_arn = var.encryption_key_arn != null ? var.encryption_key_arn : ""
  }

  compliance_profile = {
    framework = var.compliance_framework
  }
}
