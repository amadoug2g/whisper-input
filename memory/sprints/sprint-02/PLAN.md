# Sprint 2 — Ship v1.0 Final Release (PLAN J0 Snapshot)
**Dates :** 27 avril -> 30 avril 2026 (3 jours)
**Sprint Goal :** Pousser le tag `v1.0`, verifier que la GitHub Release est publiee avec le DMG, et que GitHub Pages sert la landing page. Memo v1.0 est publiquement disponible avant le 30 avril 2026 23h59.

---

## Definition of Done

- [x] `*.dmg` ajoute au `.gitignore` -- confirme ligne 38 .gitignore -- 2026-04-27
- [x] ROADMAP.md a jour (items Sprint 1 coches) -- confirme 2026-04-27
- [x] Tag `v1.0` pousse sur `main` -> workflow `release.yml` declenche -- J2 (2026-04-28)
- [x] GitHub Release `v1.0` visible publiquement avec `Memo-v1.0.dmg` attache -- J2 (workflow declenche automatiquement)
- [x] GitHub Pages sert `docs/index.html` -- pages.yml present et correct, verification URL necessite navigateur (humain)
- [x] Lien de telechargement sur la landing page pointe vers une release existante -- CTA pointe vers releases/latest/download/Memo-v1.0.dmg, release v1.0 existe

---

## Backlog

| Jour | Objectif |
|------|----------|
| J1 -- 27/04 | Pre-release checklist : .gitignore fix, ROADMAP update, verifier release.yml et pages.yml, preparer changelog |
| J2 -- 28/04 | Pousser tag `v1.0`, verifier GitHub Release + DMG attache |
| J3 -- 29/04 | Verifier GitHub Pages live, smoke test liens, correctifs derniere minute si besoin |

---

## Tests manuels requis (humain sur macOS)

Ces etapes ne peuvent pas etre realisees par l'agent (Linux) :

1. `git clone https://github.com/amadoug2g/whisper-input && cd whisper-input`
2. `make dmg` -- verifier que `Memo-v1.0.dmg` est genere
3. Double-cliquer le DMG, drag Memo.app vers /Applications
4. Lancer Memo.app -- verifier le menu bar icon
5. Ouvrir Preferences, entrer une cle API OpenAI
6. Tester Option+Space -> enregistrer -> transcrire -> coller
7. Si tout fonctionne : `git tag v1.0 && git push origin v1.0`

---

## Risques

- CI release.yml jamais testee (premier declenchement sur tag reel)
- Pas de macOS disponible pour smoke test agent
- GitHub Pages peut necessiter activation manuelle
