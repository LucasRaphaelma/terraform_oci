#resource "oci_identity_compartment" "cliente_teste" {
#  name          = "cliente-teste"
#  description   = "Compartimento do cliente-teste"
#  compartment_id = var.tenancy_ocid
#}

resource "oci_core_virtual_network" "vcn_pfsense" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  display_name   = "VCN-pfSense"
  cidr_block     = "10.0.0.0/24"
  dns_label      = "vcnpfsense"
}

resource "oci_core_virtual_network" "vcn_cliente" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  display_name   = "VCN-cliente-teste"
  cidr_block     = "10.122.163.0/24"
  dns_label      = "vcncliente"
}

# Subnet pública do pfSense
resource "oci_core_subnet" "subnet_pfsense" {
  compartment_id      = oci_identity_compartment.cliente_teste.id
  vcn_id              = oci_core_virtual_network.vcn_pfsense.id
  cidr_block          = "10.0.0.0/30"
  display_name        = "SB-pfSense"
  dns_label           = "sbpfsense"
  prohibit_public_ip_on_vnic = false
  route_table_id      = oci_core_route_table.route_table_pfsense.id
  security_list_ids   = [oci_core_security_list.sl_pfsense.id]
  dhcp_options_id     = oci_core_virtual_network.vcn_pfsense.default_dhcp_options_id
}

# Internet Gateway
resource "oci_core_internet_gateway" "igw_pfsense" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  vcn_id         = oci_core_virtual_network.vcn_pfsense.id
  display_name   = "igw-cliente-teste"
}

# Route Table com saída para Internet
resource "oci_core_route_table" "route_table_pfsense" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  vcn_id         = oci_core_virtual_network.vcn_pfsense.id
  display_name   = "rt-pfsense"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw_pfsense.id
  }
}

# Security List liberando todo tráfego
resource "oci_core_security_list" "sl_pfsense" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  vcn_id         = oci_core_virtual_network.vcn_pfsense.id
  display_name   = "sl-pfsense"

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

# Subnet privada do cliente
resource "oci_core_subnet" "subnet_cliente" {
  compartment_id      = oci_identity_compartment.cliente_teste.id
  vcn_id              = oci_core_virtual_network.vcn_cliente.id
  cidr_block          = "10.122.163.0/24"
  display_name        = "SB-cliente-teste"
  dns_label           = "sbcliente"
  prohibit_public_ip_on_vnic = true
  route_table_id      = oci_core_route_table.rt_cliente.id
  security_list_ids   = [oci_core_security_list.sl_cliente.id]
  dhcp_options_id     = oci_core_virtual_network.vcn_cliente.default_dhcp_options_id
}

# Security List do cliente (libera tudo)
resource "oci_core_security_list" "sl_cliente" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  vcn_id         = oci_core_virtual_network.vcn_cliente.id
  display_name   = "sl-cliente"

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

# Route Table que aponta para o pfSense como gateway
resource "oci_core_route_table" "rt_cliente" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  vcn_id         = oci_core_virtual_network.vcn_cliente.id
  display_name   = "rt-cliente"

  # ⚠️ Comentado temporariamente para evitar ciclo de dependência
  # Quando a VNIC LAN do pfSense já estiver criada, sera adicionado essa rota.
  #
  # route_rules {
  #   destination       = "0.0.0.0/0"
  #   destination_type  = "CIDR_BLOCK"
  #   network_entity_id = "<OCID do IP privado 10.122.163.254>"  # VNIC do pfSense (LAN)
  # }
}

# IP público reservado
resource "oci_core_public_ip" "ip_fw" {
  compartment_id = oci_identity_compartment.cliente_teste.id
  display_name   = "ip-fw"
  lifetime       = "RESERVED"
}

# Instância pfSense com VNIC primária (WAN)
resource "oci_core_instance" "pfsense" {
  availability_domain = var.availability_domain
  compartment_id      = oci_identity_compartment.cliente_teste.id
  display_name        = "pfsense-cliente-teste"
  shape               = var.shape
  shape_config {
  ocpus         = 1
  memory_in_gbs = 8
}

  source_details {
    source_type = "image"
    source_id   = var.pfsense_image_id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.subnet_pfsense.id
    assign_public_ip       = false
    display_name           = "wan"
    hostname_label         = "wan"
    skip_source_dest_check = false
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

# VNIC secundária (LAN) para a VCN do cliente
resource "oci_core_vnic_attachment" "lan_vnic" {
  instance_id    = oci_core_instance.pfsense.id
  display_name   = "lan-cliente"

  create_vnic_details {
    subnet_id              = oci_core_subnet.subnet_cliente.id
    assign_public_ip       = false
    skip_source_dest_check = true
    display_name           = "lan"
    hostname_label         = "lan"
    private_ip             = "10.122.163.254"
  }
}

# IP privado estático para a VNIC LAN (10.122.163.254)
