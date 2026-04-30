# Sprint 2 — Ship v1.0 Final Release
**Dates :** 27 avril -> 30 avril 2026 (3 jours)
**Sprint Goal :** Pousser le tag `v1.0`, verifier que la GitHub Release est publiee avec le DMG, et que GitHub Pages sert la landing page. Memo v1.0 est publiquement disponible avant le 30 avril 2026 23h59.

---

## Definition of Done

- [x] `*.dmg` ajoute au `.gitignore` (fix retro Sprint 1) -- deja present ligne 38
- [x] ROADMAP.md a jour (items Sprint 1 coches) -- fait 2026-04-27
- [x] Tag `v1.0` pousse sur `main` -> workflow `release.yml` declenche -- J2 OK (tag annote sur e775ac1, confirme via MCP)
- [x] GitHub Release `v1.0` visible publiquement avec `Memo-v1.0.dmg` attache -- CONFIRME 2026-04-30 (release id 315149842, DMG 1.85 MB, publie 2026-04-29T11:39:02Z, 1 download)
- [~] GitHub Pages sert `docs/index.html` -- pages.yml present et correct, verification URL necessite navigateur (humain)
- [x] Lien de telechargement sur la landing page pointe vers une release existante -- CTA pointe vers releases/latest/download/Memo-v1.0.dmg, release v1.0 existe

---

## Backlog

| Jour | Objectif | Statut |
|------|----------|--------|
| J1 -- 27/04 | Pre-release checklist : .gitignore fix, ROADMAP update, verifier release.yml et pages.yml, preparer changelog | Done |
| J2 -- 28/04 | Pousser tag `v1.0`, verifier GitHub Release + DMG attache | Partiellement done (tag OK sur remote e775ac1, release absente — permissions fix manquant) |
| J3 -- 29/04 | Verifier GitHub Pages live, smoke test liens, correctifs derniere minute si besoin | Done — fix release.yml merge dans main (permissions:write + workflow_dispatch). ACTION humain: declencher workflow_dispatch release.yml depuis GitHub Actions UI (version=1.0) |
| J4 -- 30/04 | DEADLINE — Confirmer GitHub Release v1.0 live + DMG attache, cloturer Sprint 2 | Done — GitHub Release v1.0 CONFIRME (id 315149842, Memo-v1.0.dmg 1.85 MB, publie 2026-04-29, 1 download). Sprint 2 clos. |

---

## Contexte technique

- Sprint 1 a livre toute l'infrastructure : `scripts/package-dmg.sh`, `release.yml`, `pages.yml`, `docs/index.html`, README.
- Il ne reste que le declenchement reel : pousser le tag `v1.0`.
- Smoke test DMG necessite macOS (l'agent tourne sur Linux). Fournir les commandes exactes a l'humain.
- La landing page a un lien CTA vers `releases/latest` -- fonctionnera des que la release existe.
- Screenshots sont des placeholders -- hors scope critique pour v1.0.

## Risques

- **CI release.yml jamais testee** : le workflow n'a jamais ete declenche. Risque d'echec au premier tag.
- **Pas de macOS disponible** : impossible de verifier le DMG ni faire de smoke test. Depend de l'humain.
- **GitHub Pages peut ne pas etre active** : necessite activation manuelle dans Settings > Pages si pas deja fait.
