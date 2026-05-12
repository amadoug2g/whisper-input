# Sprint 3 — Review
**Date :** 12 mai 2026
**Sprint :** 4 mai -> 11 mai 2026 (1 semaine)
**Sprint Goal :** Consolider la release v1.0 : verifier GitHub Pages, ameliorer la CI (smoke test DMG), enrichir la release body avec le changelog, et nettoyer les branches orphelines.

---

## Definition of Done — Bilan

| Critere | Statut | Notes |
|---------|--------|-------|
| GitHub Pages confirme fonctionnel (URL live testee, CTA download verifie) | Bloque (humain) | pages.yml correct sur main, CTA verifie via MCP. Activation necessite Settings > Pages dans navigateur. |
| CI : smoke test DMG automatise dans release.yml (hdiutil attach/detach, verification Memo.app) | Done (J2) | Job smoke-test ajoute, needs:build-and-release, hdiutil attach -nobrowse, codesign --verify. PR #21 merge. |
| GitHub Release v1.0 body enrichi avec le contenu de CHANGELOG.md | Done (J3) | body_path: CHANGELOG.md dans release.yml — applicable a partir de la prochaine release. |
| Branches orphelines supprimees (cleanup remote) | Bloque (humain) | 4 branches identifiees ; push --delete bloque par proxy sandbox 403. |
| README : screenshots placeholders remplaces ou section retiree | Done (J4) | Section Screenshots placeholder retiree proprement. |

**Score DoD : 3/5 items completes. 2 bloquants humain (contraintes environnementales, pas d'echec d'implementation).**

---

## Backlog — Avancement par jour

| Jour | Objectif | Resultat |
|------|----------|---------|
| J1 — 04/05 | GitHub Pages verification + fix si necessaire, cleanup branches orphelines | Partiellement bloque — pages.yml et CTA confirmes corrects ; 4 branches orphelines identifiees ; push --delete bloque par proxy 403 |
| J2 — 05/05 | CI : smoke test DMG automatise (job macos-14 dans release.yml) | Done — reviewer LGTM, PR #21 merge |
| J3 — 06/05 (realise 11/05) | Release body : inclure CHANGELOG.md dans release.yml (body_path) | Done — reviewer LGTM |
| J4 — 07/05 (realise 11/05) | README : screenshots reels ou retrait section placeholder | Done — section placeholder retiree, reviewer LGTM |
| J5 — 08/05 (realise 12/05) | Sprint review + retro | Done — ce fichier + RETRO.md |

---

## Ce qui a ete livre

### CI Hardening
- **Job `smoke-test`** dans `.github/workflows/release.yml` : declenche apres `build-and-release`, tourne sur `macos-14`. Telecharge le DMG publie via `gh release download`, monte avec `hdiutil attach -nobrowse -noautoopen`, verifie la presence de `Memo.app`, verifie la signature avec `codesign --verify --verbose`, detache avec `hdiutil detach`. Garantit qu'un DMG publie est montrables et contient l'application correctement signee.

### Release Body Enrichi
- **`body_path: CHANGELOG.md`** dans le job `build-and-release` de `release.yml`. Les prochaines releases publiees via `workflow_dispatch` ou tag `v*` auront automatiquement le contenu de `CHANGELOG.md` comme description de release.

### README Polish
- **Section Screenshots retiree** du README. La section placeholder "a venir depuis Sprint 1 J5" n'apportait pas de valeur et creait de l'attente non satisfaite. README maintenant sans placeholder visible.

---

## Items non livres / Bloquants humain

### GitHub Pages verification
- **Statut :** pages.yml correct sur `main`, dernier deploy triggere lors du commit `313ac9e` (favicon, 2026-04-30). La verification live de l'URL https://amadoug2g.github.io/whisper-input/ necessite un navigateur (indisponible dans l'environnement agent).
- **Action humain :** Settings > Pages > Source = "GitHub Actions". Si inactif, activer et lancer `workflow_dispatch` sur `pages.yml`.

### Suppression des branches orphelines
- **Statut :** 4 branches identifiees sur remote (`claude/affectionate-cerf-gMClj`, `claude/tender-einstein-QyVHC`, `claude/affectionate-cerf-DWEYt`, `claude/affectionate-cerf-PScAP`). `git push --delete` bloque par proxy sandbox HTTP 403.
- **Action humain :** `git push origin --delete claude/affectionate-cerf-gMClj claude/tender-einstein-QyVHC claude/affectionate-cerf-DWEYt claude/affectionate-cerf-PScAP`

---

## Metriques sprint

| Metrique | Valeur |
|----------|--------|
| Items backlog completes | 5/5 (dont 2 avec bloquants humain) |
| Items DoD livres sans blocage | 3/5 |
| PRs mergees | 2 (J2 PR #21, J3+J4 PR) |
| Reviewer LGTM au premier passage | 100% |
| Tests au debut du sprint | 46 passed, 0 failed |
| Tests a la fin du sprint | 46 passed, 0 failed |
| Jours de blocage technique | 0 (tous les bloquants sont des contraintes environnementales) |

---

## Conclusion

**Sprint Goal partiellement atteint.** Les 3 items techniques implementables dans l'environnement Linux (CI smoke test, release body, README) sont livres et valides. Les 2 items restants (GitHub Pages verification, suppression branches) sont bloquants humain par contrainte sandbox — l'implementation est correcte mais necessite une action manuelle.

Le projet Memo v1.0 est stable et pret pour une prochaine iteration eventuelle.
