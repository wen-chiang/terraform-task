locals {
  naming_prefix = lower(replace("${var.company_code}-${var.environment}", "_", "-"))
}
