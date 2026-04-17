# Objectif du jour — 2026-04-17 (Sprint 1, J1)

## Contexte sprint
Sprint 1 goal : Memo v1.0-rc1 telechareable depuis GitHub Release (DMG + GitHub Pages). 13 jours restants avant deadline (30 avril).

## Tache
Creer le script de packaging DMG et la target Makefile associee.

Le DMG doit :
1. Appeler `make app` pour builder `Memo.app` (via `scripts/package-app.sh` existant)
2. Creer un volume DMG temporaire avec `hdiutil`
3. Y copier `Memo.app` + un lien symbolique vers `/Applications`
4. Convertir en DMG compresse final : `Memo-v1.0.dmg`
5. Signer ad-hoc le DMG : `codesign --force --sign - Memo-v1.0.dmg`

Note : le script doit accepter un argument optionnel `VERSION` (defaut `1.0`) pour nommer le DMG `Memo-v$VERSION.dmg`. Le workflow release.yml (J2) extraira la version du tag git.

## Criteres de succes
- [ ] `scripts/package-dmg.sh` cree et executable
- [ ] `make dmg` ajoute dans `Makefile` (depend de `app`)
- [ ] `make dmg` produit `Memo-v1.0.dmg` dans le repertoire racine
- [ ] `make test` toujours vert (46 tests)
- [ ] Commit : `feat: add DMG packaging script and make dmg target`

## Fichiers concernes
- `scripts/package-dmg.sh` — a creer (hdiutil create/convert, codesign)
- `Makefile` — ajouter target `dmg` (depend de `app`)
- `scripts/package-app.sh` — reference existante (ne pas modifier)

## Priorite
**Haute** — J1 du Sprint 1. Bloquant pour la GitHub Release (J2). Chemin critique vers la deadline du 30 avril.

## Analyse strategique (weekly review 2026-04-17)

### Bilan semaine ecoulee
- CI GitHub Actions operationnel (PR #7) avec Keychain setup et TestSetup.swift
- Infrastructure agents en place (coder, reviewer, manager)
- Sprint 1 demarre, plan et backlog definis

### Etat du sprint
| Item | Statut |
|------|--------|
| Script DMG + `make dmg` | En cours (J1) |
| Workflow `release.yml` | A faire (J2) |
| Landing page `docs/index.html` | A faire (J3) |
| GitHub Pages + README | A faire (J4) |
| Smoke test DMG | A faire (J5) |
| Sprint Review + Retro | A faire (J7) |

### Risques identifies
1. **Branche non mergee** : 8 commits sur `claude/affectionate-cerf-UZCzX` pas encore dans `main` (CI, sprint kickoff). A merger via PR avant J2.
2. **Gatekeeper ad-hoc** : DMG ad-hoc sera bloque par Gatekeeper. Documenter `xattr -c Memo.app` dans README et landing page.
3. **13 jours restants** : Sprint 1 (distribution) doit finir le 24/04 pour laisser 6 jours de polish (localisation FR, README final, v1.0 tag).
