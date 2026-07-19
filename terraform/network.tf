# ==========================================================================
# network.tf — Toda a infraestrutura de rede da VCN Hermes na OCI
# VCN + Subnet pública + Internet Gateway + Route Table + Security List
# ==========================================================================

# --------------------------------------------------------------------------
# VCN (Virtual Cloud Network)
# --------------------------------------------------------------------------
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "vcn-hermes"
  dns_label      = var.vcn_dns_label
  freeform_tags  = var.freeform_tags
}

# --------------------------------------------------------------------------
# Internet Gateway — saída para a internet
# --------------------------------------------------------------------------
resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "igw-hermes"
  enabled        = true
  freeform_tags  = var.freeform_tags
}

# --------------------------------------------------------------------------
# Route Table — rota default (0.0.0.0/0) via Internet Gateway
# --------------------------------------------------------------------------
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "rt-publica-hermes"
  freeform_tags  = var.freeform_tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# --------------------------------------------------------------------------
# Security List — libera SSH (22) e portas do Hermes; saída livre
# --------------------------------------------------------------------------
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sl-publica-hermes"
  freeform_tags  = var.freeform_tags

  # Egress: libera toda saída
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Ingress: SSH (22) de qualquer origem
  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.ssh_ingress_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: ICMP (ping / path MTU) — recomendado pela OCI
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

# --------------------------------------------------------------------------
# Subnet pública — associada à route table e security list acima
# --------------------------------------------------------------------------
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "subnet-publica"
  cidr_block                 = "10.0.1.0/24"
  dns_label                  = "pub"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
  freeform_tags              = var.freeform_tags
}
