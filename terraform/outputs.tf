output "connect_from_inet" {
  description = "connect_from_inet"
  value = {
    bastion = module.compute_nat.eip_nat
  }
}
