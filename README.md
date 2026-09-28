# stagehand-browser skill

Skill global para Claude Code (e Codex / Gemini CLI / Copilot CLI via `~/.agents/skills`) usar um navegador real com o **Stagehand v4**, através do CLI `browse` da Browserbase.

- Um comando de shell por passo, com snapshots compactos de acessibilidade. Sem o custo de schema de ferramentas MCP e sem screenshots a cada passo.
- **Perfil Chrome dedicado e persistente**: você loga uma vez e o agente continua logado nas próximas sessões.

## Instalar (em cada computador)

Requisitos: Node ≥ 22.12 (recomendado ≥ 22.18), Google Chrome e git.

```bash
git clone <URL-DESTE-REPO> ~/.stagehand-browser-skill
bash ~/.stagehand-browser-skill/install.sh
```

Atualizar: `cd ~/.stagehand-browser-skill && git pull && bash install.sh`

O instalador:
1. instala/atualiza `npm install -g browse`;
2. cria symlinks em `~/.claude/skills/stagehand-browser` e `~/.agents/skills/stagehand-browser`.

## Primeiro uso (login)

```bash
bash ~/.claude/skills/stagehand-browser/scripts/chrome-profile.sh start
```

Abre um Chrome separado (perfil em `~/.local/share/stagehand-browser/profile`). Faça login nos sites que o agente vai usar. Depois disso, é só pedir ao Claude: "abre o site X e ...".

| Comando | Efeito |
|---|---|
| `chrome-profile.sh start [--headless]` | sobe o Chrome dedicado na porta 9333 |
| `chrome-profile.sh stop` | fecha |
| `chrome-profile.sh status` | está rodando? |

Variáveis: `STAGEHAND_PROFILE_DIR`, `STAGEHAND_CDP_PORT`, `CHROME_PATH`.

## Por que não o meu Chrome do dia a dia?

Testado, não funciona. A extensão de runtime do Stagehand v4 exige flags de inicialização do Chrome (`--enable-unsafe-extension-debugging`, `--remote-allow-origins=chrome-extension://…`), e o Chrome 136+ recusa porta de debug no perfil padrão. Por isso a skill usa um perfil dedicado, que também isola o agente dos seus dados pessoais.

## Segurança

- O perfil guarda cookies e tokens. Trate `~/.local/share/stagehand-browser/` como credencial (permissão 700).
- A porta CDP escuta só em `127.0.0.1`, e a origem liberada é somente a extensão do Stagehand (nunca `*`).
- Logue no perfil dedicado só nos sites que o agente realmente precisa.
- Telemetria anônima do `browse`: desligue com `export DO_NOT_TRACK=1`.

## Ideias futuras

- [Testes e2e / automações sem supervisão com `act()` + Jev](docs/future-jev-e2e.md)
