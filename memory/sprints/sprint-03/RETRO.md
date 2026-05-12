# Sprint 3 — Retrospective
**Date :** 12 mai 2026
**Facilitateur :** agent coder
**Format :** Keep / Improve / Add

---

## Ce qui a bien fonctionne (Keep)

### Smoke test CI comme filet de securite release
Le job `smoke-test` ajoute dans `release.yml` (J2) est un vrai gain de robustesse. Desormais, chaque release deployee est automatiquement verifiee : montage DMG, presence Memo.app, signature ad-hoc. Ce pattern (verifier l'artefact apres publication, pas seulement pendant la build) est a conserver dans tous les futurs projets de distribution.

### MCP GitHub pour la verification sans navigateur
L'utilisation systematique des outils MCP GitHub (releases, branches, assets) a permis de confirmer l'etat reel du remote sans navigateur. La verification du CTA docs/index.html, du DMG v1.0 (sha256, taille, downloads), et des branches orphelines a ete faite directement via API. Pattern efficace pour un environnement sans GUI.

### Livraison groupee J3+J4 en une seule session
Les items J3 (release body) et J4 (README screenshots) etaient orthogonaux et de faible complexite. Les traiter dans une seule session a evite une PR supplémentaire et un cycle review/merge. A appliquer quand plusieurs petits items peuvent etre groupes sans risque de conflit.

### Reviewer LGTM 100% au premier passage
Sur les 3 sprints, le taux de LGTM au premier passage est de 100%. Cela valide la methodologie : lire les sources avant de modifier, tester (ou documenter l'impossibilite de tester) avant de commiter, et documenter les bloquants avec des instructions humaines precises.

---

## Ce qui doit s'ameliorer (Improve)

### Bloquants sandbox documentés trop tardivement
Les bloquants proxy 403 (push --delete, push tag) ont ete identifies en cours de session et non anticipés. L'agent aurait pu verifier en debut de session si `git push` est fonctionnel avant de planifier des operations remote.
**Action :** En debut de session, tester la connectivite git push avec un dry-run (`git push --dry-run`) si l'objectif inclut des operations remote.

### DAILY_GOAL non mis a jour entre les sprints
Le DAILY_GOAL.md est reste date du 04/05 alors que le sprint a progresse jusqu'au 12/05. Le manager aurait du mettre a jour DAILY_GOAL entre chaque jour de sprint, ou l'agent aurait du detecter la discordance de date et se referer a SPRINT_CURRENT.md pour identifier les items restants.
**Action :** Quand la date dans DAILY_GOAL.md est anterieure a la date courante, consulter SPRINT_CURRENT.md pour identifier le prochain item non fait.

### PLAN.md sprint non synchronise avec SPRINT_CURRENT.md
Le fichier `memory/sprints/sprint-03/PLAN.md` est reste dans l'etat initial (tous les items "A faire") pendant que SPRINT_CURRENT.md etait mis a jour. Les deux fichiers devraient rester synchronises.
**Action :** Apres chaque mise a jour de SPRINT_CURRENT.md, mettre a jour PLAN.md en parallele.

---

## Ce qui manque et devrait etre ajoute (Add)

### Test de connectivite git en debut de session
Un check rapide (`git ls-remote --exit-code origin HEAD`) en debut de session permettrait de savoir si les operations remote sont disponibles avant de planifier des taches qui en dependent.

### Workflow de cleanup branches via GitHub API
Puisque `git push --delete` est bloque par le proxy sandbox, utiliser les outils MCP GitHub (si un outil de suppression de branche est disponible) serait une alternative. Si aucun outil MCP ne le supporte, documenter ce gap dans LESSONS_LEARNED.md pour le template launchpad.

### Notification proactive en fin de session pour les actions humaines
Quand une session se termine avec des bloquants humain, une notification explicite (via PushNotification si disponible) avec les commandes exactes rendrait la coordination plus fluide. Le SESSION_LOG est bon pour la trace, mais pas pour l'alerte en temps reel.

---

## Decisions pour la suite (si Sprint 4)

Si le projet continue, les items suivants ont de la valeur :
1. **Whisper local (WhisperKit)** : reduire la dependance au cloud, ameliorer la latence
2. **Historique des transcriptions** : panneau de relecture des 20 dernières transcriptions
3. **Localisation francaise** : reportee hors v1.0, faisable en 1 sprint
4. **Changelog automatise** : script qui extrait la section courante de CHANGELOG.md et la prepend au prochain release body
5. **Screenshots reels** : remplacer les placeholders docs/index.html si captures macOS disponibles

---

## Score de sante sprint

| Dimension | Note | Commentaire |
|-----------|------|-------------|
| Velocite (items livres) | 4/5 | 3/5 DoD items sans blocage, 2 bloquants humain |
| Qualite (LGTM rate) | 5/5 | 100% premier passage reviewer |
| Process (blockers documentes) | 5/5 | Bloquants identifies, commands exactes fournies, aucune ambiguite |
| Communication (resumes clairs) | 5/5 | CODER_SUMMARY, SESSION_LOG, et actions humaines documentees |
| Sprint Goal atteint | 4/5 | Goal partiellement atteint — items techniques livres, bloquants environnementaux documentés |

**Score global : 23/25**
