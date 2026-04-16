# Objectif du jour — 2026-04-17

## Contexte

Le core de Memo est complet (46 tests, sandbox configuré, ad-hoc signing). Pour publier avant le 30 avril, la première étape est de mettre en place un pipeline CI qui valide automatiquement chaque changement. Sans CI, les agents ne peuvent pas garantir la qualité du code sur les futures branches.

## Tâche

Créer un workflow GitHub Actions qui lance `swift test` automatiquement sur chaque push et pull request.

Le workflow doit :
1. Se déclencher sur `push` et `pull_request` (toutes branches)
2. Tourner sur `macos-14` (Apple Silicon runner GitHub)
3. Utiliser Swift intégré à l'image (pas besoin d'installation séparée)
4. Lancer `swift test`
5. Afficher clairement si les tests passent ou échouent

Ajouter également un **badge CI** dans `README.md` (sous le titre `# Memo`).

## Critères de succès

- [ ] Fichier `.github/workflows/ci.yml` créé et valide (YAML correct)
- [ ] `make test` passe localement (46 tests, 0 failed)
- [ ] Badge CI ajouté dans README.md
- [ ] Commit propre avec message `ci: add GitHub Actions swift test workflow`
- [ ] Branche `feature/20260417-github-actions-ci` poussée sur origin

## Fichiers concernés

- `.github/workflows/ci.yml` — à créer
- `README.md` — ajouter le badge CI sous `# Memo`

## Priorité

**Haute** — bloquant pour tout le reste : les agents ne peuvent pas valider les builds sans CI.
