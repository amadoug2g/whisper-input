# Sprint 2 — Retrospective
**Date :** 1 mai 2026
**Facilitateur :** agent coder
**Format :** Keep / Improve / Add

---

## Ce qui a bien fonctionne (Keep)

### Diagnostic root cause rapide (J3)
Quand la GitHub Release etait absente apres le push du tag, l'agent a identifie en une session la cause exacte (permissions:contents:write absent dans release.yml sur main au moment du tag). Cela a permis de produire un fix cible sans tâtonnement.

### Confirmation via MCP GitHub
L'utilisation de l'API GitHub (via MCP) pour confirmer l'etat des releases, tags, et assets a ete decisive. Pas de speculation — confirmation directe : release id, taille DMG, sha256, nombre de telechargements.

### workflow_dispatch comme filet de securite
L'ajout du `workflow_dispatch` au fix release.yml a permis le rattrapage manuel sans avoir a creer un nouveau tag ou une nouvelle release. Pattern utile pour tous les workflows de publication.

### Cloture Sprint propre
Sprint 1 avait termine avec SPRINT_REVIEW.md et RETRO.md dans `memory/sprints/`. Sprint 2 suit le meme pattern. La memoire du projet reste coherente et traçable.

---

## Ce qui doit s'ameliorer (Improve)

### Tester release.yml avant le tag final
Le probleme de permissions sur release.yml etait detectable avant de pousser `v1.0`. Un tag pre-release (`v1.0-rc1`) ou un `workflow_dispatch` de test aurait revele le probleme sans bloquer J2.
**Action :** Pour toute future release, tester le workflow release.yml avec un tag de test ou un dispatch manuel avant de pousser le tag definitif.

### Push du tag bloque par sandbox
Le push du tag v1.0 en J2 a ete bloque par la sandbox (HTTP 403). L'agent a documente l'action requise (humain : `git push origin v1.0`) mais le delai entre J2 et J3 montre que la coordination humain/agent sur des actions bloquees peut prendre du temps.
**Action :** Quand une action necessite l'humain, envoyer une notification explicite (PushNotification ou message en fin de session) avec les commandes exactes et l'impact du delai.

### Permissions GitHub Actions sous-documentees
Le `permissions` block dans les workflows GitHub Actions est critique mais souvent omis. release.yml a ete livre sans `contents: write` lors du Sprint 1 J2.
**Action :** Ajouter une checklist dans le PLAN de sprint pour verifier les permissions minimales de chaque workflow avant livraison.

---

## Ce qui manque et devrait etre ajoute (Add)

### Test de smoke automatise du DMG en CI
Le smoke test du DMG reste manuel (necessite macOS + GUI). Un job CI `macos-14` qui monte le DMG avec `hdiutil attach`, verifie que Memo.app est present, et detache le volume serait utile pour les prochaines releases.

### Changelog dans la GitHub Release body
La release v1.0 a ete creee avec le body par defaut. Inclure le contenu de CHANGELOG.md (section v1.0) dans le body de la release via `softprops/action-gh-release` (parametre `body_path`) rendrait la page de release plus informative.

### Screenshots dans docs/index.html et README
Les placeholders de screenshots Sprint 1 sont toujours presents. Ce serait le premier item visuel a ameliorer si un Sprint 3 etait planifie.

---

## Decisions pour la suite (si Sprint 3)

1. **Smoke test automatise** : job CI macos-14 qui monte et verifie le DMG
2. **Release body** : inclure CHANGELOG.md dans la GitHub Release
3. **Screenshots reels** : remplacer les placeholders dans docs/ et README
4. **Changelog automatise** : script qui extrait la section courante de CHANGELOG.md pour la release body
5. **GitHub Pages verification** : confirmer https://amadoug2g.github.io/whisper-input/ dans un navigateur

---

## Score de sante sprint

| Dimension | Note | Commentaire |
|-----------|------|-------------|
| Velocite (items livres) | 5/5 | 6/6 DoD items completes |
| Qualite (LGTM rate) | 5/5 | 100% premier passage reviewer |
| Process (blockers resolus) | 4/5 | J2 bloque (release absente) corrige J3 — 1 jour de delai |
| Communication (resumes clairs) | 5/5 | CODER_SUMMARY, SESSION_LOG, et actions humaines documentees |
| Sprint Goal atteint | 5/5 | Memo v1.0 public avant la deadline du 30 avril 2026 |

**Score global : 24/25**
