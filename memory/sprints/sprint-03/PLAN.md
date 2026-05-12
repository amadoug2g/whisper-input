# Sprint 3 — Post-Release Polish
**Dates :** 4 mai -> 11 mai 2026 (1 semaine)
**Sprint Goal :** Consolider la release v1.0 : verifier GitHub Pages, ameliorer la CI (smoke test DMG), enrichir la release body avec le changelog, et nettoyer les branches orphelines.

---

## Definition of Done

- [ ] GitHub Pages confirme fonctionnel (URL live testee, CTA download verifie) -- Bloque humain (proxy 403)
- [x] CI : smoke test DMG automatise dans release.yml (hdiutil attach/detach, verification Memo.app) -- Done J2, PR #21
- [x] GitHub Release v1.0 body enrichi avec le contenu de CHANGELOG.md -- Done J3, body_path: CHANGELOG.md
- [ ] Branches orphelines supprimees (cleanup remote) -- Bloque humain (proxy 403)
- [x] README : screenshots placeholders remplaces ou section retiree -- Done J4, section retiree

---

## Backlog

| Jour | Objectif | Statut |
|------|----------|--------|
| J1 -- 04/05 | GitHub Pages verification + fix si necessaire, cleanup branches orphelines | Bloque humain |
| J2 -- 05/05 | CI : smoke test DMG automatise (job macos-14 dans release.yml) | Done |
| J3 -- 06/05 | Release body : inclure CHANGELOG.md dans release.yml (body_path) | Done |
| J4 -- 07/05 | README : screenshots reels ou retrait section placeholder | Done |
| J5 -- 08/05 | Sprint review + retro | Done |

---

## Contexte technique

- v1.0 est publiee et fonctionnelle (GitHub Release id 315149842, Memo-v1.0.dmg 1.85 MB).
- GitHub Pages : pages.yml existe, docs/index.html existe, mais verification navigateur jamais faite.
- Branches orphelines sur remote : claude/affectionate-cerf-gMClj, claude/tender-einstein-QyVHC, claude/affectionate-cerf-DWEYt, claude/affectionate-cerf-PScAP.
- Sprint 2 retro recommande : smoke test DMG en CI, changelog dans release body, screenshots reels.
- Pas d'urgence deadline -- focus qualite et polish.

## Risques

- **Pas de macOS disponible** : l'agent tourne sur Linux, impossible de faire le smoke test DMG manuellement. Le test doit etre automatise en CI (macos-14).
- **GitHub Pages peut necessiter activation manuelle** : si Settings > Pages n'est pas configure, l'URL ne sera pas accessible.
- **Screenshots** : necessite une capture d'ecran depuis macOS. Peut rester en placeholder si l'humain ne fournit pas de captures.
