# Objectif du jour — 2026-04-17 (Sprint 1, J1)

## Contexte sprint
Sprint 1 goal : Memo v1.0-rc1 téléchargeable depuis GitHub Release (DMG + GitHub Pages).
Voir `memory/SPRINT_CURRENT.md` pour le backlog complet.

## Tâche
Créer le script de packaging DMG et la target Makefile associée.

Le DMG doit :
1. Appeler `make app` pour builder `Memo.app` (via `scripts/package-app.sh` existant)
2. Créer un volume DMG temporaire avec `hdiutil`
3. Y copier `Memo.app` + un lien symbolique vers `/Applications`
4. Convertir en DMG compressé final : `Memo-v1.0.dmg`
5. Signer ad-hoc le DMG : `codesign --force --sign - Memo-v1.0.dmg`

## Critères de succès
- [ ] `scripts/package-dmg.sh` créé et exécutable
- [ ] `make dmg` ajouté dans `Makefile` (dépend de `app`)
- [ ] `make dmg` produit `Memo-v1.0.dmg` dans le répertoire racine
- [ ] `make test` toujours vert (46 tests)
- [ ] Commit : `feat: add DMG packaging script and make dmg target`

## Fichiers concernés
- `scripts/package-dmg.sh` — à créer
- `Makefile` — ajouter target `dmg`

## Priorité
**Haute** — J1 du Sprint 1. Bloquant pour la GitHub Release (J2).
