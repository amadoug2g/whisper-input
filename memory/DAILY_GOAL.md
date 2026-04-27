# Objectif du jour -- 2026-04-27 (Sprint 2, J1)

## Contexte sprint
Sprint 2 goal : Pousser le tag v1.0 et verifier que la GitHub Release + GitHub Pages sont live avant le 30 avril 2026. 3 jours restants.

## Tache
Pre-release checklist : preparer le repo pour le tag v1.0.

Actions concretes :
1. Ajouter `*.dmg` au `.gitignore` (fix identifie en retro Sprint 1)
2. Verifier que `.github/workflows/release.yml` est correct et fonctionnel (lire le fichier, valider la syntaxe)
3. Verifier que `.github/workflows/pages.yml` est correct
4. Verifier que `docs/index.html` a un lien de telechargement fonctionnel (pointe vers `releases/latest`)
5. Preparer un CHANGELOG minimal pour la release v1.0 (section "What's New" pour le body de la GitHub Release)
6. S'assurer que `main` est propre et a jour avec le remote

Ne PAS pousser le tag aujourd'hui -- J2 demain. Aujourd'hui = verification et preparation uniquement.

## Criteres de succes
- [ ] `*.dmg` present dans `.gitignore`
- [ ] `release.yml` verifie (syntaxe, trigger `v*`, DMG build, softprops/action-gh-release)
- [ ] `pages.yml` verifie (trigger, permissions, deploiement docs/)
- [ ] `docs/index.html` lien CTA verifie
- [ ] Commit pre-release pousse sur `main`

## Fichiers concernes
- `.gitignore` -- ajouter `*.dmg`
- `.github/workflows/release.yml` -- lecture et verification
- `.github/workflows/pages.yml` -- lecture et verification
- `docs/index.html` -- verification lien CTA
- `memory/ROADMAP.md` -- mise a jour items coches (fait par manager)
- `memory/SPRINT_CURRENT.md` -- nouveau sprint (fait par manager)

## Priorite
**Haute** -- Deadline dans 3 jours. Regle #3 : uniquement distribution. Tout doit etre pret pour pousser le tag v1.0 demain (J2).
