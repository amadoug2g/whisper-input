# Sprint 1 — Rétrospective
**Date :** 24 avril 2026
**Facilitateur :** agent coder
**Format :** Keep / Improve / Add

---

## Ce qui a bien fonctionné (Keep)

### Multi-agent workflow
Le pipeline coder → reviewer → manager a fonctionné sans friction sur les 4 jours livrés. Chaque PR a obtenu LGTM au premier passage avec des suggestions non-bloquantes constructives. Aucune boucle de correction longue.

### Critères de succès explicites par jour
Chaque `DAILY_GOAL.md` listait des critères de succès checklistés (fichier créé, commande qui fonctionne, commit message). Cela a éliminé l'ambiguïté sur "done" et facilité l'évaluation reviewer.

### Séparation script/Makefile
Le pattern `Makefile target → bash script` (ex: `make dmg` → `scripts/package-dmg.sh`) est propre : le Makefile gère les dépendances (dmg depend de app), le script fait le travail. Réutilisable en CI avec `make dmg VERSION=$TAG`.

### `set -euo pipefail` dans tous les scripts bash
Les scripts bash du sprint ont tous `set -euo pipefail`. Aucun bug silencieux découvert post-livraison.

### Priorisation J0 du blocker
La branche non-mergée (`claude/affectionate-cerf-UZCzX`) a été identifiée comme bloquant critique dès le DAILY_GOAL de J1 et résolue avant de commencer le travail. Cela a évité un rebase douloureux plus tard.

---

## Ce qui doit s'améliorer (Improve)

### J5 — Smoke test impossible en environnement Linux
Le smoke test DMG (J5) n'a pas pu être réalisé parce que l'agent coder tourne sur Linux et `hdiutil` est macOS-only. Ce point était prévisible dès J0 mais n'a pas été signalé comme risque dans le plan.
**Action :** Pour les tâches nécessitant macOS (smoke test, screenshots, codesign vérification), documenter explicitement dans le DAILY_GOAL que c'est "à faire manuellement par l'humain" et fournir les commandes exactes.

### Dépendance au README pour les screenshots
J4 a livré un README avec un placeholder `<!-- screenshot -->` pour les screenshots. Sans J5, la landing page et le README restent incomplets visuellement. Les deux tâches auraient dû être couplées ou J5 priorisé avant J4.
**Action :** Ne pas livrer de placeholder dans le README si le contenu réel n'est pas planifié pour le même sprint.

### Pas de tag `v1.0` poussé
Le sprint était censé aboutir à une GitHub Release publique. Le tag `v1.0` n'a pas été créé (l'humain doit le faire après validation manuelle). Cela reste le vrai "done" du sprint goal, et il est conditionnel à un smoke test non réalisé.
**Action :** Le sprint goal doit distinguer "infrastructure prête" (livré) de "release publique réelle" (conditionnel à smoke test humain). Reformuler le sprint goal pour la prochaine fois.

### Coordination J2+J3 fusionnés
J2 (release.yml) et J3 (landing page) ont été livrés dans un seul commit/PR. C'est efficace mais rend la PR plus difficile à reviewer (deux features distinctes). Le reviewer a noté une suggestion non-bloquante (lien CTA en dur).
**Action :** Garder des PRs atomiques par objectif journalier même si le scope est petit. Facilite le revert et le blame.

---

## Ce qui manque et devrait être ajouté (Add)

### Smoke test checklist dans le PLAN
Ajouter une section "Tests manuels requis" dans `sprints/sprint-XX/PLAN.md` listant les étapes que seul un humain sur macOS peut valider (ouvrir le DMG, drag-to-Applications, lancer l'app, tester le hotkey).

### `.gitignore` entrée pour `*.dmg`
Le reviewer a signalé en J1 que `*.dmg` n'est pas dans `.gitignore`. C'est un oubli mineur mais `Memo-v1.0.dmg` (50 MB+) ne doit jamais être commité accidentellement.
**Action :** Ajouter `*.dmg` et `tmp-memo-build.dmg` dans `.gitignore` au Sprint 2 J1.

### Notification humain en fin de sprint
Quand le sprint est "infrastructure done mais smoke test manquant", l'agent devrait produire un résumé actionnable pour l'humain : liste des commandes exactes à lancer sur macOS pour valider et créer le tag.

---

## Décisions prises pour le Sprint 2

1. **Smoke test DMG** : priorité J1 Sprint 2 — fournir un script/checklist pour l'humain sur macOS, ou configurer un workflow CI self-hosted macOS.
2. **Screenshots réels** : dépend du smoke test. Priorité J1-J2 Sprint 2.
3. **Tag `v1.0`** : pousser après smoke test validé. Ce sera la vraie "release publique".
4. **`.gitignore` fix** : petit correctif à inclure dans le premier commit Sprint 2.
5. **Scope Sprint 2** : à définir par le manager. Candidats — localisation FR, préfixes de prompt, historique des transcriptions.

---

## Score de santé sprint

| Dimension | Note | Commentaire |
|-----------|------|-------------|
| Vélocité (items livrés) | 4/5 | 6/7 items, J5 manqué pour raison structurelle |
| Qualité (LGTM rate) | 5/5 | 100% premier passage |
| Process (blockers résolus) | 5/5 | Blocker PR #8 résolu le J0 |
| Communication (résumés clairs) | 5/5 | CODER_SUMMARY et SESSION_LOG complets |
| Sprint Goal atteint | 4/5 | Infrastructure complète, release publique conditionnelle |

**Score global : 23/25**
