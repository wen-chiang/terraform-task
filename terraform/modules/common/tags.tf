locals {
  utc_date      = formatdate("YYYY-MM-DD", timestamp())
  created_value = var.created_date != null ? var.created_date : local.utc_date
  updated_value = var.update_date != null ? var.update_date : local.utc_date

  base_tags = {
    Company     = var.company_name
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = var.managed_by
    Project     = var.project
    CreatedDate = local.created_value
    UpdateDate  = local.updated_value
  }

  tags = merge(local.base_tags, var.additional_tags)
}
