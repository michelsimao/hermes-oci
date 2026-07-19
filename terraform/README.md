# Infraestrutura Terraform — VM Hermes na OCI

## Visão Geral

Este módulo cria a rede e a máquina virtual (Ampere ARM, elegível ao Always Free)
que hospeda o Hermes. Utiliza o provider OCI na versão `5.30.0` e a região padrão
`sa-saopaulo-1`.

O ponto de entrada é o `terraform apply`, que recria a VM e expõe o IP público
como output. Após cada aplicação, o `inventory.ini` do Ansible deve ser atualizado
com o novo endereço.

## Arquivos

| Arquivo             | Responsabilidade                                                                 |
|---------------------|----------------------------------------------------------------------------------|
| `provider.tf`       | Configuração do provider OCI (região, tenancy, usuário, fingerprint, chave de API). |
| `network.tf`        | VCN, Internet Gateway, Route Table, Security List e subnet pública.              |
| `compute.tf`        | Recurso `oci_core_instance.hermes` — VM Ampere A1 (2 OCPU / 12 GB), Ubuntu 24.04 Minimal aarch64. |
| `variables.tf`      | Declaração de todas as variáveis do módulo.                                       |
| `outputs.tf`        | Expõe `hermes_public_ip` e `ssh_command`.                                         |
| `cloud-init.yaml`   | Provisionamento inicial da VM (pacotes base e firewall).                         |
| `terraform.tfvars`  | Valores das variáveis (modelo de exemplo, sem credenciais reais).                |

## Detalhes da VM

- **Shape:** `VM.Standard.A1.Flex` (Ampere ARM) — elegível ao Always Free.
- **OCPU / Memória:** 2 / 12 GB (dentro do free tier).
- **Imagem:** Ubuntu 24.04 Minimal `aarch64`.
- **Boot volume:** 150 GB (aproveita o free tier de até 200 GB).
- **IP público:** atribuído (`assign_public_ip = true`).

## Rede e Segurança

- VCN `10.0.0.0/16`, subnet pública `10.0.1.0/24`.
- **Ingress:** somente SSH (22) via `var.ssh_ingress_cidr` (padrão `0.0.0.0/0`).
  Recomenda-se restringir ao IP de origem em ambientes de produção.
- **Egress:** liberado (`0.0.0.0/0`, protocolo all).
- ICMP tipo 3 / código 4 liberado (path MTU, conforme recomendação da OCI).
- Firewall de host (`ufw`) ativado pelo cloud-init (defesa em profundidade).

## Ajuste de cloud-init

A OCI bloqueia tráfego HTTP de saída (porta 80) nesta subnet; apenas HTTPS (443)
é permitido. O `ubuntu.sources` padrão apontava para o mirror regional em HTTP,
causando falha no `apt-get update` e erro no `cloud-init status`.

Correção aplicada em `cloud-init.yaml`:

- `apt_preserve_sources_list: true` (impede reescrita do sources list).
- `write_files` sobrescreve `/etc/apt/sources.list.d/ubuntu.sources` usando
  `https://ports.ubuntu.com` (resposta 200 em HTTPS).
- `runcmd` blindado: utiliza `ufw` somente se o binário estiver presente.

## Aplicação

```bash
cd terraform
terraform init
terraform apply        # registre hermes_public_ip no output
```

> O `terraform apply` recria a VM e altera o IP público. Atualize o `inventory.ini`
> do Ansible com o novo IP antes de executar os playbooks.

## Destruição

```bash
cd terraform
terraform destroy
```
