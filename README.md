# Projeto Oracle — Hermes Agent 24/7 na OCI

---

## Objetivo

Subir o **Hermes Agent 24/7** numa VM **Oracle Cloud (OCI)**, perfil "nuvem",
enxuto e reprodutível. Fluxo: **Terraform** cria a infraestrutura (rede + VM) →
**Ansible** instala e configura o Hermes, o buscador e o extrator de páginas.


## Decisões já tomadas

- **Busca web** = `ddgs` (nativo, sem Docker). 
- **Extract de páginas** = `crawl4ai` self-hosted em modo HTTP (sem Chromium/Docker).
- Segredos do Hermes vêm de **Ansible Vault** → `.env` com mode `0600`, não texto solto.
- Gateway roda como **systemd user service** (sem sudo no próprio Hermes).
- Idioma padrão da conversa = **`pt-BR`** (configurado no template da VM).

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `terraform/` | Infra na OCI (VCN, subnet, gateway, VM Ampere, cloud-init) |
| `ansible/` | Playbooks de instalação/config, templates, plugin crawl4ai, inventory |
| `README.md` (raiz) | Este arquivo — visão geral e objetivos |
| `runbook-oracle.md` | Plano de deploy passo a passo (Fase 1 / Fase 2) |
| `migration.md` | Matriz de migração (o que levar do laptop vs deixar) |

## Estado atual (2026-07-15)

- [x] Fase 1 concluída: Terraform aplicado, playbooks rodados, **web search + page
      extraction testados e funcionando** na VM.
- [ ] Fase 2 pendente: OCI Vault / Secret Manager pros segredos.
- [ ] Cópia das memórias do Hermes local pra oracle (próximo passo após descanso).

## Como reproduzir do zero

1. `terraform init && terraform apply` na pasta `terraform/` → anota o IP público (output).
2. Ajusta o `inventory.ini` do Ansible com o **novo IP** (passo obrigatório!).
3. `ansible-playbook -i ansible/inventory.ini ansible/playbook_install_hermes.yml`
4. `ansible-playbook -i ansible/inventory.ini ansible/playbook_setup_crawl4ai.yml`
5. Testa da VM: web search e extração de página.

## Pendências conhecidas

- Runbook ainda cita SearXNG/Docker e `hermes setup` interativo — código foi pra
  `ddgs` + template. Revisar quando der.
- STT na VM: `config.yaml.j2` mantém `stt.enabled: true` mas a VM é headless
  (sem mic). Avaliar desligar na nuvem.
