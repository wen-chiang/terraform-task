locals {
  operations_profile = {
    backup_retention_days      = var.backup_retention_days
    log_retention_days         = var.log_retention_days
    enable_monitoring          = var.enable_monitoring
    enable_detailed_monitoring = var.enable_detailed_monitoring
  }
}
