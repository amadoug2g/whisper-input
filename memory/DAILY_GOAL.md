# Objectif du jour -- 2026-05-04 (Sprint 3, J1)

## Contexte sprint
Consolider la release v1.0 : verifier GitHub Pages, ameliorer la CI, enrichir la release, nettoyer les branches orphelines.

## Tache
Verifier que GitHub Pages sert correctement la landing page de Memo, et nettoyer les branches orphelines sur le remote.

GitHub Pages est le dernier deliverable non verifie de la v1.0. La page devrait etre accessible a https://amadoug2g.github.io/whisper-input/. Le workflow `pages.yml` est configure pour deployer `docs/` sur push to main (filtre path `docs/**`). Si Pages n'est pas actif, documenter les etapes d'activation pour l'humain.

Branches orphelines a supprimer :
- claude/affectionate-cerf-gMClj
- claude/tender-einstein-QyVHC
- claude/affectionate-cerf-DWEYt
- claude/affectionate-cerf-PScAP

## Criteres de succes
- [ ] GitHub Pages status verifie via API GitHub (deployment existe ou non)
- [ ] Si Pages inactif : instructions d'activation documentees pour l'humain
- [ ] Si Pages actif : lien CTA vers DMG verifie (pointe vers release existante)
- [ ] Branches orphelines supprimees du remote
- [ ] SESSION_LOG.md mis a jour avec l'entree du jour

## Fichiers concernes
- `docs/index.html` -- landing page source
- `.github/workflows/pages.yml` -- workflow de deploiement Pages
- `memory/SESSION_LOG.md` -- log de session
- `memory/SPRINT_CURRENT.md` -- mise a jour statut J1

## Priorite
Haute -- GitHub Pages est le dernier deliverable v1.0 non confirme. Les branches orphelines sont du nettoyage rapide a faire en meme temps.
