# Futuro: testes e2e / automações sem supervisão com `act()` + Jev

**Status:** ideia registrada em 2026-09-28. Não implementada. Depende de PRs ainda abertos no Stagehand.

## Contexto

A skill atual põe o agente (Claude) no comando: ele lê `browse snapshot` e manda `browse click @ref`. O Stagehand não chama nenhuma IA nesse fluxo.

Existe um segundo modo, que a skill ainda não cobre: **scripts que rodam sozinhos** (CI, cron) e usam as primitivas de IA do Stagehand:

```ts
await stagehand.act("clique em Finalizar compra");
const pedido = await stagehand.extract("número do pedido", z.object({ id: z.string() }));
```

Aqui o Stagehand chama um modelo para achar o elemento. O **Jev** (TypeSafe) é um modelo pequeno que só escolhe entre alternativas, em cerca de 100–300 ms. Ele substitui a maior parte dessas chamadas.

## Por que interessa para e2e

| Problema do e2e tradicional (Playwright/Cypress) | Com `act()` + Jev |
|---|---|
| Seletor quebra quando muda classe, id ou layout | A instrução em linguagem natural é autocorretiva |
| Escrever e manter seletores custa tempo | O teste lê como o critério de aceite |
| `act()` com LLM grande era caro e lento para CI | Jev: 4–11× mais rápido, 69–97% menos chamadas de LLM (números do PR) |

Números publicados pelos autores (evals do Stagehand; não reproduzidos aqui):

- act: 4.3× mais rápido, 97% menos chamadas de LLM, pass rate de 97.5% para 98.3%
- heldout: 4.1× mais rápido, 78% menos chamadas, de 87.5% para 97.5%
- observe: 11.1× mais rápido, 69% menos chamadas, de 75.0% para 83.3%
- extract: 8.7× mais rápido, 75% menos chamadas, 92% (sem mudança)

## Pré-requisitos antes de adotar

1. **Merge da pilha completa** em browserbase/stagehand: #2951 (snapshot editable ids) → #2952 (biblioteca Jev) → #2953 (act) → #2954 (observe + cache) → #2955 (extract). Na data acima, #2952 estava aberto e ainda sem ligação com o `act`.
2. **Chave da TypeSafe** (https://docs.typesafe.ai) e preço confirmado. O "custo ~0" é afirmação dos autores.
3. **Privacidade:** as descrições de elementos da página vão para a API da TypeSafe. Use em ambientes de teste/staging. Em sites logados com dados reais, só depois de avaliar. O PR substitui os valores de `%variáveis%` (por exemplo, senhas) por marcadores antes de enviar, mas o resto do conteúdo vai.

## Esboço de implementação

1. Projeto de testes com `@browserbasehq/stagehand` (Node ≥ 22.18) e o runner de sua escolha (vitest/playwright-test).
2. Browser: `localBrowser.launch({ headless: true })` na CI. Para fluxos logados, `localBrowser.connect({ cdpUrl })` no perfil dedicado desta skill (`scripts/chrome-profile.sh start --headless`).
3. **Determinismo primeiro:** ligar o cache de ações do Stagehand (`/v4/best-practices/caching`), para que as execuções repetidas repitam a ação resolvida sem chamar modelo. O Jev entra só quando o cache erra.
4. Asserções com `extract()` + schema zod, e não por texto livre.
5. Na falha, salvar screenshot + URL + a instrução `act` que falhou.
6. Métrica de adoção: comparar a flakiness e o tempo com os testes atuais num fluxo piloto antes de migrar mais.

Quando isso existir, cabe uma seção nova na skill: "Modo automação sem supervisão".

## Referências

- PR: https://github.com/browserbase/stagehand/pull/2952
- Docs act/extract/observe: https://docs.stagehand.dev/v4/basics/act
- Caching: https://docs.stagehand.dev/v4/best-practices/caching
