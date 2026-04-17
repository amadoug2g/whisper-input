# Sprint 1 — Plan (snapshot J0)
**Créé le :** 2026-04-17
**Sprint :** 17 → 24 avril 2026

## Goal
Memo v1.0-rc1 est téléchargeable publiquement sous forme de DMG depuis une GitHub Release, avec une landing page GitHub Pages live.

## Backlog priorisé
1. Script DMG (`scripts/package-dmg.sh` + `make dmg`)
2. Workflow GitHub Actions `release.yml` sur tag `v*`
3. Landing page `docs/index.html`
4. GitHub Pages activation
5. README final (screenshots, badges, install instructions)
6. Smoke test DMG sur macOS
7. Sprint Review + Rétrospective

## Definition of Done
- [ ] `make dmg` produit un `.dmg` fonctionnel
- [ ] Tag `v1.0-rc1` → Release GitHub avec DMG en pièce jointe
- [ ] `https://amadoug2g.github.io/whisper-input` live avec landing page
- [ ] CI vert (46 tests, 0 failures)
- [ ] README production-grade
- [ ] `memory/sprints/sprint-01/SPRINT_REVIEW.md` + `RETRO.md` créés

## Risques identifiés
- DMG signing sans Developer ID : ad-hoc fonctionne pour distribution directe, mais Gatekeeper bloquera. Solution : documenter `xattr -c` pour l'utilisateur.
- `NSHostingView.fittingSize` peut retourner zéro sans display → tailles panel incorrectes en CI (mitigé par TestSetup.swift).

## Contexte état du projet au J0
- Core app : ✅ complet (46 tests, sandbox, Keychain, hotkey, Whisper API)
- CI GitHub Actions : ✅ opérationnel (fix Keychain + TestSetup)
- Infrastructure agents : ✅ en place (coder, reviewer, manager, routines)
- `main` propre : ✅ (PR #6 mergée, 4 branches stales à supprimer manuellement)
