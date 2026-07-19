# ==========================================================================
# compute.tf — VM Ampere (ARM) para rodar o Hermes na OCI
# Shape VM.Standard.A1.Flex · 2 OCPU · 12 GB · Ubuntu 24.04 Minimal (aarch64)
# ==========================================================================

# --------------------------------------------------------------------------
# Availability Domain — pega o primeiro AD do tenancy
# --------------------------------------------------------------------------
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# --------------------------------------------------------------------------
# Imagem Ubuntu 24.04 Minimal para ARM (aarch64)
# O plan confirma qual imagem foi resolvida antes do apply.
# --------------------------------------------------------------------------
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04 Minimal aarch64"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --------------------------------------------------------------------------
# Instância Compute Ampere (ARM) — Always Free elegível
# --------------------------------------------------------------------------
resource "oci_core_instance" "hermes" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "hermes-vm"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
    # Boot volume — aproveita o free tier (até 200GB Always Free)
    boot_volume_size_in_gbs = 150
  }


  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "hermes-vnic"
    hostname_label   = "hermes"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  freeform_tags = var.freeform_tags
}

