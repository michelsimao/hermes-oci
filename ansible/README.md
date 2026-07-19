# Ansible — Instalação e Configuração do Hermes na VM OCI

## Visão Geral

Este módulo provisiona o Hermes e seus componentes de suporte na máquina virtual
criada pelo Terraform. Dois playbooks compõem o fluxo:

- **Playbook A** (`playbook_install_hermes.yml`): instala o Hermes e o gateway.
- **Playbook B** (`playbook_setup_crawl4ai.yml`): configura busca e extração de
  páginas.

## Arquivos

| Arquivo / Pasta                        | Responsabilidade                                                                 |
|----------------------------------------|----------------------------------------------------------------------------------|
| `inventory.ini`                        | Grupo `[hermes_vm]` com o IP público da VM e variáveis de conexão SSH. Deve ser atualizado a cada `terraform apply`. |
| `playbook_install_hermes.yml`          | Instala o Hermes (usuário `ubuntu`, sem privilégios de administrador para o Hermes). Aguarda o cloud-init, instala `uv`, gera `config.yaml` e `.env`, e inicia o gateway como user service. |
| `playbook_setup_crawl4ai.yml`          | Instala `ddgs` e `crawl4ai`, implanta o servidor e o plugin, e ajusta o `config.yaml` para usar os backends correspondentes. |
| `templates/config.yaml.j2`             | Gera `~/.hermes/config.yaml` (modelo `tencent/hy3:free`, `web.backend: ddgs`, `web.extract_backend: crawl4ai`, `display.language: pt-BR`, plugin crawl4ai habilitado). |
| `templates/hermes.env.j2`              | Gera `~/.hermes/.env` com `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL` e `GROQ_API_KEY`, oriundos do Ansible Vault. |
| `group_vars/all/vault.yml`             | Segredos criptografados (Ansible Vault). O `.env` é derivado deste arquivo — nunca comitar o vault descriptografado nem o `.env` em texto. |
| `files/crawl4ai_server.py`             | Servidor FastAPI que encapsula o `AsyncWebCrawler` em modo HTTP (sem Chromium). Endpoints: `POST /crawl`, `GET /health`. |
| `files/crawl4ai.service`               | Unidade systemd do serviço crawl4ai (`uv run --with crawl4ai ...`). |
| `plugins/web/crawl4ai/`                | Backend de extração self-hosted: `plugin.yaml` (kind: backend), `provider.py` (POST em `127.0.0.1:8000/crawl`) e `__init__.py`. |

## Playbook A — Instalação do Hermes

1. `wait_for_connection` (SSH) e coleta de facts.
2. Aguarda o cloud-init (`cloud-init status`), com `failed_when` que detecta
   execuções anteriores com erro (rc=2) mesmo quando o status reporta "done".
3. Instala `uv` e o Hermes (instalador desacoplado via `setsid`).
4. Gera `config.yaml` a partir de `templates/config.yaml.j2`.
5. Gera `.env` a partir de `templates/hermes.env.j2` (segredos do Vault), modo `0600`.
6. Executa `hermes gateway install` e `hermes gateway start` como user service.

## Playbook B — Configuração do Crawl4AI

1. Instala `ddgs` e `httpx` no venv do Hermes.
2. Instala `crawl4ai`, `fastapi` e `uvicorn` via `uv tool`.
3. Copia `files/crawl4ai_server.py` e `files/crawl4ai.service`.
4. Sobe o serviço crawl4ai e aguarda o healthcheck (`/health`).
5. Copia o plugin `plugins/web/crawl4ai/`.
6. Habilita o plugin (`hermes plugins enable crawl4ai`).
7. Ajusta `config.yaml`: `backend: ddgs` e `extract_backend: crawl4ai`.
8. Reinicia o gateway via handler único do systemd.

## Execução

```bash
# a partir do diretório raiz do projeto
ansible-playbook -i ansible/inventory.ini ansible/playbook_install_hermes.yml
ansible-playbook -i ansible/inventory.ini ansible/playbook_setup_crawl4ai.yml
```

## Segredos

Os segredos residem em `group_vars/all/vault.yml`, criptografados pelo Ansible
Vault. O `.env` é gerado a partir desse arquivo. Não comite o vault
descriptografado nem o `.env` resultante.
