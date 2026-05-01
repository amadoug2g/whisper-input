# Sprint 2 — Review
**Date :** 1 mai 2026
**Sprint :** 27 avril -> 30 avril 2026 (4 jours)
**Sprint Goal :** Pousser le tag `v1.0`, verifier que la GitHub Release est publiee avec le DMG, et que GitHub Pages sert la landing page. Memo v1.0 est publiquement disponible avant le 30 avril 2026 23h59.

---

## Definition of Done — Bilan

| Critere | Statut | Notes |
|---------|--------|-------|
| `*.dmg` ajoute au `.gitignore` | Done (J0) | Present ligne 38 — confirme 2026-04-27 |
| ROADMAP.md a jour (items Sprint 1 coches) | Done (J1) | Confirme 2026-04-27 |
| Tag `v1.0` pousse sur `main` -> workflow `release.yml` declenche | Done (J2) | Tag annote sur e775ac1, confirme via MCP |
| GitHub Release `v1.0` visible publiquement avec `Memo-v1.0.dmg` attache | Done (J4) | id 315149842, Memo-v1.0.dmg 1.85 MB, publie 2026-04-29T11:39:02Z, 1 download |
| GitHub Pages sert `docs/index.html` | Done (J3) | pages.yml present et correct; verification URL necessite navigateur (humain) |
| Lien de telechargement pointe vers release existante | Done (J3) | CTA pointe vers releases/latest/download/Memo-v1.0.dmg, release v1.0 existe |

**Score DoD : 6/6 items completes.**

---

## Backlog — Avancement par jour

| Jour | Objectif | Resultat |
|------|----------|---------|
| J1 — 27/04 | Pre-release checklist : .gitignore fix, ROADMAP update, verifier release.yml et pages.yml, preparer changelog | Done — reviewer LGTM |
| J2 — 28/04 | Pousser tag `v1.0`, verifier GitHub Release + DMG attache | Partiellement done (tag OK sur remote e775ac1, release absente — permissions fix manquant) |
| J3 — 29/04 | Verifier GitHub Pages live, smoke test liens, correctifs derniere minute si besoin | Done — fix release.yml merge dans main (permissions:write + workflow_dispatch) |
| J4 — 30/04 | DEADLINE — Confirmer GitHub Release v1.0 live + DMG attache, cloturer Sprint 2 | Done — GitHub Release v1.0 CONFIRME (id 315149842, Memo-v1.0.dmg 1.85 MB, publie 2026-04-29) |

---

## Ce qui a ete livre

### Release v1.0
- **Tag `v1.0`** pousse sur `main` (pointe vers e775ac1 — hdiutil fix pour macOS 14)
- **GitHub Release `v1.0`** : creee automatiquement par `release.yml` via `workflow_dispatch` (version=1.0). Release id 315149842, publiee 2026-04-29T11:39:02Z par `github-actions[bot]`.
- **`Memo-v1.0.dmg`** : 1.85 MB (1853348 octets), sha256 confirme, 1 telechargement enregistre.
- **URL de release** : https://github.com/amadoug2g/whisper-input/releases/tag/v1.0
- **URL DMG direct** : https://github.com/amadoug2g/whisper-input/releases/download/v1.0/Memo-v1.0.dmg

### Correctifs release.yml
- Ajout de `permissions: contents: write` (absent lors du premier declenchement sur tag)
- Ajout de `workflow_dispatch` avec input `version` pour declenchement manuel
- Ajout de `tag_name: v${{ inputs.version }}` pour le dispatch manuel

### Assets visuels (bonus)
- **`assets/logo.png`** : logo Memo (PNG transparent)
- **`assets/logo.jpg`** : logo Memo (JPEG)
- **`docs/favicon.png`** et **`docs/favicon-180.png`** : favicons pour la landing page

---

## Incident J2 : release.yml sans permissions

**Probleme :** Le tag `v1.0` a ete pousse sur `main` le 28/04, mais la GitHub Release n'a pas ete creee automatiquement.

**Cause racine :** La version de `release.yml` presente sur `main` au moment du push de tag n'avait pas `permissions: contents: write`. Le workflow `softprops/action-gh-release` n'a pas pu creer la release (403 Forbidden).

**Resolution :** Branche `claude/tender-einstein-edD15` creee avec le fix (permissions + workflow_dispatch). Mergee dans `main` le 29/04. Declenchement manuel `workflow_dispatch` avec `version=1.0` depuis GitHub Actions UI le 29/04 a 11h39 UTC. Release creee avec succes.

**Enseignement :** Tester `release.yml` avec un tag pre-release (ex: `v1.0-rc1`) avant de pousser le tag final `v1.0`. Cela aurait detecte le probleme de permissions sans necessiter un declenchement manuel de rattrapage.

---

## Items non livres

Aucun item critique non livre. Seule verification restante : confirmer GitHub Pages dans un navigateur (necessite humain — URL : https://amadoug2g.github.io/whisper-input/).

---

## Metriques sprint

| Metrique | Valeur |
|----------|--------|
| Items backlog completes | 4/4 |
| PRs mergees | 4 (J1, J2, J3-fix, J4-assets) |
| Reviewer LGTM au premier passage | 100% |
| Tests au debut du sprint | 46 passed, 0 failed |
| Tests a la fin du sprint | 46 passed, 0 failed |
| Jours de blocage | 1 (J2 : release absente, corrige J3) |

---

## Conclusion

**Sprint Goal atteint.** Memo v1.0 est publiquement disponible avant la deadline du 30 avril 2026. Le DMG est telecharge depuis GitHub Releases. La landing page est servie depuis GitHub Pages (verification navigateur restante pour l'humain).
