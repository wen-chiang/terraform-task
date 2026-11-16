locals {
  network_defaults = {
    high_availability = var.high_availability
    availability_zones = var.availability_zones
    enable_nat_gateway = var.enable_nat_gateway
  }
}
