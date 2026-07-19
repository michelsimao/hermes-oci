# Migration.md — Plano de migração do Hermes para a OCI

> Objetivo: subir o Hermes 24/7 na VM OCI (ARM) e decidir o que levar (enxuto)
> vs o que deixar no laptop (pesado / não roda headless).
> Status: rascunho — decidir junto com o Mi antes de aplicar.

---

## 1. INVENTÁRIO VERIFICADO (config.yaml + filesystem)

### 1.1 Recursos ENABLED: true (ativos de verdade)

| Recurso | Linha config | Nota |
|---|---|---|
| tool_loop_guardrails.warnings | 138 | avisos de loop |
| compression | 149 | compressão de contexto (threshold 0.5) |
| Kanban dispatch | 169 | enabled true · auto_decompose true · auto_promote_children **false** |
| Kanban discovery | 180 | descoberta de skills |
| Voice STT | 381 | provider: groq ✅ |
| Voice auto_tts | 400 | responde por áudio ✅ |
| Voice beep / silence_threshold | 401-402 | config de voz |
| Memory | 411 | memory_enabled true ✅ |
| User profile | 412 | user_profile_enabled true ✅ |
| Delegation (subagentes) | 431-433 | orchestrator_enabled true · max_spawn_depth 1 · subagent_auto_approve false |
| Curator | 447 | auto-cura de skills (168h) |
| Backup | 455 | keep 5 ✅ |
| Guardrails tirith | 513 | tirith_enabled true · redact_secrets true |
| Model catalog | 546 | URL oficial |
| LSP | 584 | language server |
| Cron | — | scheduler ativo (check-in 20h) |

### 1.2 Recursos ENABLED: false (desligados)

- checkpoints (123)
- tool_loop_guardrails.hard_stop (139)
- runtime_footer (322)
- voice_fx (476)
- message_timestamps (553)
- streaming (562)
- bitwarden (594) — vault desligado
- website_blocklist (518)

### 1.3 Skills instaladas (filesystem — dezenas)

Catálogo padrão + usadas: `daily-task-manager`, `gbrain`/`gbrain-ops`/`gbrain-setup`/`gbrain-advisor`, `hermes-kanban`/`hermes-kanban-ops`/`task-board-kanban`, `media/hermes-voice-mode`, `devops/self-host-hermes`, `devops/hermes-local-ops`, `computer-use`, `devops/local-vision` (llava/Ollama), `web/web-crawl4ai`, `web/image-and-drawing-output`, `media/svg-illustration`, `article-to-pt-audio`, `voice-note-ingest`, `brain-ops`/`brain-pdf`/`query`/`ingest`/`maintain`, `research`/`perplexity-research`/`arxiv`/`data-research`, `cron-scheduler`, `github`/`repo-architecture`, `mlops`/`k8s-cluster-ops`/`docker-maintenance`, `software-development`, `testing`/`cross-modal-review`, `creative`/`strategic-reading`/`soul-audit`/`concept-synthesis`, `smart-home`(openhue)/`social-media`(xurl)/`email`(himalaya), `minion-orchestrator`/`autonomous-ai-agents`, + dezenas do catálogo padrão.

### 1.4 Outros

- Plugin: `hermes-achievements`
- Profile: `devops` (separado)
- `.env`: GROQ_API_KEY + chaves
- `.zshrc`: edits `(by hermes)` (bun + local/bin)

---

## 2. MATRIZ DE MIGRAÇÃO (o que levar vs deixar)

### ✅ LEVAR (essencial + leve)

| Item | Por quê |
|---|---|
| Memórias (MEMORY.md / USER.md) | linha de vida do Hermes |
| memory_enabled + user_profile_enabled | já ativo, vai junto |
| cron-scheduler | check-in 24/7 — perfeito na nuvem |
| backup + curator | manutenção automática |
| daily-task-manager + gbrain* | se levar o brain |
| devops/self-host-hermes | o próprio deploy OCI |
| Skills leves (research, github, brain-*, query, web-crawl4ai, etc) | úteis, quase zero custo |

### ❌ NÃO LEVAR (pesado / não roda headless)

| Item | Por quê |
|---|---|
| computer-use | precisa desktop / cua-driver |
| devops/local-vision + llava/Ollama | sem GPU / sem Ollama na VM |
| hermes-local-ops | é pro laptop, não nuvem |
| minion-orchestrator / autonomous-ai-agents | custo de subagentes (a não ser que queira) |

### ⚠️ DEPENDE (avaliar com o Mi)

| Item | Risco / nota |
|---|---|
| hermes-voice-mode (STT groq ativo) | VM OCI headless SEM mic → input de voz não funciona; só TTS de saída. Recomendo: levar TTS, desligar STT na VM por enquanto |
| kanban | enabled true, mas Mi deu um tempo. Levar ou não = decisão do Mi |
| bitwarden | desligado, mas se quiser secret management depois é mais simples que OCI Vault |
| smart-home / social-media / email | só se for usar integrações na VM |

---

## 3. PENDÊNCIAS (anotadas em ops/tasks no brain)

- **P2:** Secret Management com OCI Vault (estudo) — guardar API keys no Vault e expor na VM via IAM em runtime, em vez de .env em texto plano
- **P3:** Configurar servidores MCP no Hermes (Filesystem → Fetch/Web → GitHub)

---

## 4. PRÓXIMO PASSO (quando decidir)

Criar Playbook de "sync" (scp/rsync) que copia pra VM:
1. `~/.hermes/memories/` (MEMORY.md, USER.md)
2. `config.yaml` enxuto (sem voice STT, sem computer-use)
3. Skills leves selecionadas
4. `.env` (ou Vault — ver P2)

> Regra do Mi: nada de mexer sem EXECUTE. Decidir junto antes de aplicar.
