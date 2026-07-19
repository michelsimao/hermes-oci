# ==========================================================================
# output.tf — Saídas úteis do deploy (IP, comando SSH)
# ==========================================================================

output "hermes_public_ip" {
  description = "IP público da VM Hermes"
  value       = oci_core_instance.hermes.public_ip
}

output "ssh_command" {
  description = "Comando pronto para SSH na VM"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${oci_core_instance.hermes.public_ip}"
}
