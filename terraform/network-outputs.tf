output "connect_from_inet" {
  description = "connect_from_inet"
  value = {
    natbastion = module.network.natbastion_eip
  }
}
