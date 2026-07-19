# Projeto Oracle — Hermes Agent 24/7 na OCI

## Visão Geral

Este repositório provisiona e configura o **Hermes Agent** para execução contínua
(24/7) em uma máquina virtual da **Oracle Cloud Infrastructure (OCI)**. O objetivo
é obter uma implantação enxuta, reprodutível e baseada em perfil "nuvem".

O fluxo de provisionamento divide-se em duas etapas:

1. **Terraform** cria a infraestrutura subjacente (rede e máquina virtual).
2. **Ansible** instala e configura o Hermes, o mecanismo de busca e o extrator
   de páginas na instância recém-criada.

## Componentes

- **Busca web**: `ddgs` (nativo, sem dependência de contêineres).
- **Extração de páginas**: `crawl4ai` em execução local (self-hosted), em modo
  HTTP, sem Chromium ou Docker.
- **Segredos do Hermes**: armazenados em Ansible Vault e materializados em `.env`
  com permissão `0600` — nunca expostos em texto aberto.
- **Gateway**: executado como systemd user service (sem privilégios de
  administrador para o próprio Hermes).
- **Idioma padrão**: `pt-BR`, definido no template de configuração da VM.

## Estrutura do Repositório

| Caminho            | Conteúdo                                                        |
|--------------------|-----------------------------------------------------------------|
| `terraform/`       | Infraestrutura na OCI (VCN, subnet, gateway, VM Ampere, cloud-init). Documentado em `terraform/README.md`. |
| `ansible/`         | Playbooks de instalação e configuração, templates, plugin crawl4ai e inventory. Documentado em `ansible/README.md`. |
| `README.md` (raiz) | Este arquivo — visão geral e objetivos do projeto.              |

## Reprodução do Ambiente

Consulte `terraform/README.md` e `ansible/README.md` para o detalhamento de cada
etapa. Em resumo:

1. Aplicar o Terraform na pasta `terraform/` e registrar o IP público gerado.
2. Atualizar o `inventory.ini` do Ansible com o novo IP (etapa obrigatória).
3. Executar o playbook de instalação do Hermes.
4. Executar o playbook de configuração do crawl4ai.
5. Validar busca web e extração de páginas a partir da VM.
