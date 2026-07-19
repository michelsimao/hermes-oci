variable "compartment_ocid" {
  description = "OCID do compartment onde os recursos serão criados"
  type        = string
}

variable "region" {
  description = "Região da OCI (ex.: sa-saopaulo-1)"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "vcn_cidr" {
  description = "Bloco CIDR da VCN (configurável)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_dns_label" {
  description = "Label DNS da VCN (3-15 chars alfanuméricos)"
  type        = string
  default     = "ocivcn"
}

variable "freeform_tags" {
  description = "Tags livres aplicadas aos recursos"
  type        = map(string)
  default = {
    Project   = "oracle-networking"
    ManagedBy = "terraform"
  }
}

variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the private key"
  type        = string
}

variable "api_private_key_path" {
  description = "The path to the private key file (API signing key)"
  type        = string
}

variable "ssh_private_key_path" {
  description = "The path to the private key file (for SSH)"
  type        = string
}



# --------------------------------------------------------------------------
# Rede
# --------------------------------------------------------------------------
variable "ssh_ingress_cidr" {
  description = "CIDR de origem permitido para SSH (22). 0.0.0.0/0 = qualquer IP"
  type        = string
  default     = "212.101.35.232/32"
}

# --------------------------------------------------------------------------
# Compute
# --------------------------------------------------------------------------
variable "instance_ocpus" {
  description = "Número de OCPUs da VM Ampere (Always Free: até 4)"
  type        = number
  default     = 2
}

variable "instance_memory_gbs" {
  description = "Memória da VM em GB (Always Free: até 24)"
  type        = number
  default     = 12
}

variable "ssh_public_key_path" {
  description = "Caminho absoluto da chave PÚBLICA SSH injetada na VM"
  type        = string
  default     = "/home/michel/.ssh/ssh-oci.pub"
}
