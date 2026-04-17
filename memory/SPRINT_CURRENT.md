# Sprint 1 — Ship v1.0 Release Candidate
**Dates :** 17 avril → 24 avril 2026
**Sprint Goal :** Memo v1.0-rc1 est téléchargeable publiquement sous forme de DMG depuis une GitHub Release, avec une landing page GitHub Pages live.

---

## Definition of Done

- [ ] `scripts/package-dmg.sh` + `make dmg` → DMG local fonctionnel
- [ ] Workflow `.github/workflows/release.yml` déclenché sur tag `v*` → Release + DMG auto
- [ ] Landing page `docs/index.html` servie via GitHub Pages
- [ ] README mis à jour (install instructions, screenshots, badges CI/release)
- [x] 46 tests verts, CI passe (PR #7, 2026-04-17)
- [ ] Sprint Review + Retro dans `memory/sprints/sprint-01/`

---

## Backlog

| Jour | Objectif | Statut |
|------|----------|--------|
| J1 — 17/04 | Script `package-dmg.sh` + target `make dmg` | 🔄 En cours |
| J2 — 18/04 | Workflow `release.yml` sur tag `v*` | ⬜ À faire |
| J3 — 20/04 | Landing page `docs/index.html` (hero, features, download CTA) | ⬜ À faire |
| J4 — 21/04 | GitHub Pages activation + README polish | ⬜ À faire |
| J5 — 22/04 | Screenshots + smoke test DMG sur macOS | ⬜ À faire |
| J7 — 24/04 | Sprint Review + Rétrospective | ⬜ À faire |

---

## Contexte technique

- App déjà signable ad-hoc via `codesign --force --sign -`
- `scripts/package-app.sh` existe déjà — le DMG s'appuie dessus
- Pas de Developer ID requis pour v1.0 (ad-hoc seulement)
- GitHub Pages depuis `/docs` sur `main` (pas de branche séparée)
- Release workflow : déclenché sur push de tag `v*`, artifact = `Memo-v*.dmg`
