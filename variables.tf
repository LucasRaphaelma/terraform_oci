variable "clientes_compartment_ocid" {
  description = "OCID do compartimento Clientes"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID do tenancy"
  type        = string
}

variable "availability_domain" {
  description = "Domínio de disponibilidade"
  type        = string
}

variable "shape" {
  description = "Shape da instância"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "pfsense_image_id" {
  description = "OCID da imagem customizada do pfSense"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Caminho do arquivo da chave pública SSH"
  type        = string
}

variable "user_ocid" {
  description = "OCID do usuário"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint da chave"
  type        = string
}

variable "private_key_path" {
  description = "Caminho do arquivo da chave privada"
  type        = string
}

variable "region" {
  description = "Região da OCI (ex: sa-saopaulo-1)"
  type        = string
}
