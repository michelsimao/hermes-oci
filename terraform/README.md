# Infraestrutura Terraform — VM Hermes na OCI

> Cria a rede e a VM Ampere (ARM, Always Free) que hospeda o Hermes.
> Provider OCI `5.30.0`. Região padrão: `sa-saopaulo-1`.

---

## Recursos criados

| Arquivo | Recurso |
|---|---|
| `provider.tf` | Config do provider OCI (region, tenancy, user, fingerprint, chave API) |
| `network.tf` | VCN + Internet Gateway + Route Table + Security List + Subnet pública |
| `compute.tf` | `oci_core_instance.hermes` — VM Ampere A1 (2 OCPU / 12 GB), Ubuntu 24.04 Minimal aarch64 |
| `variables.tf` | Todas as variáveis (com defaults) |
| `outputs.tf` | `hermes_public_ip` e `ssh_command` |
| `cloud-init.yaml` | Provisionamento inicial da VM (pacotes base + firewall) |
| `terraform.tfvars` | Valores locais das variáveis (NÃO comitar segredos reais) |

## Detalhes da VM

- **Shape:** `VM.Standard.A1.Flex` (Ampere ARM) — Always Free elegível.
- **OCPU / Memória:** 2 / 12 GB (dentro do free tier).
- **Imagem:** Ubuntu 24.04 Minimal `aarch64`.
- **Boot volume:** 150 GB (aproveita free tier de até 200 GB).
- **IP público:** atribuído (variável `assign_public_ip = true`).

## Rede / Segurança

- VCN `10.0.0.0/16`, subnet pública `10.0.1.0/24`.
- **Ingress:** só SSH (22) — `var.ssh_ingress_cidr` (default `0.0.0.0/0`).
- **Egress:** livre (`0.0.0.0/0`, proto all).
- ICMP type 3/code 4 liberado (path MTU, recomendado pela OCI).
- Firewall de **host** (`ufw`) é ligado pelo cloud-init (defesa em profundidade).

## cloud-init — FIX importante (2026-07-15)

A OCI **bloqueia saída HTTP (porta 80)** nesta subnet; só **HTTPS (443)** passa.
O `ubuntu.sources` padrão apontava pro mirror regional em **HTTP** e o `apt-get
update` quebrava → nenhum pacote instalava → `cloud-init status: error`.

Correção aplicada no `cloud-init.yaml`:
- `apt_preserve_sources_list: true` (trava o sources list).
- `write_files` sobrescreve `/etc/apt/sources.list.d/ubuntu.sources` usando
  **`https://ports.ubuntu.com`** (respondeu 200 em HTTPS).
- `runcmd` blindado: só usa `ufw` se o binário existir.

## Como aplicar

```bash
cd terraform
terraform init
terraform apply        # anota hermes_public_ip no output
```

⚠️ O `terraform apply` **recria a VM** e muda o IP público. Sempre atualize o
`inventory.ini` do Ansible com o novo IP antes de rodar os playbooks.

## Como destruir

```bash
cd terraform
terraform destroy
```
