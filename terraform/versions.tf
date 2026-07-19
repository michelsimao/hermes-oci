terraform {
  # Fixar a versão do Terraform evita que alguém com uma versão incompatível quebre o state file.
  required_version = ">= 1.5.0" 

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "5.30.0"
    }
  }
}
