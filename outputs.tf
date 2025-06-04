output "ip_reservado_wan" {
  description = "IP público reservado para a interface WAN do pfSense"
  value       = oci_core_public_ip.ip_fw.ip_address
}

output "ip_privado_lan" {
  description = "IP privado da interface LAN do pfSense (em VCN do cliente)"
  value       = "10.122.163.254"
}

output "vcn_cliente_id" {
  description = "OCID da VCN do cliente"
  value       = oci_core_virtual_network.vcn_cliente.id
}

output "vcn_pfsense_id" {
  description = "OCID da VCN do pfSense"
  value       = oci_core_virtual_network.vcn_pfsense.id
}

output "subnet_cliente_id" {
  description = "OCID da Subnet do cliente"
  value       = oci_core_subnet.subnet_cliente.id
}
