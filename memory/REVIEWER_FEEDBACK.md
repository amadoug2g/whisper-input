LGTM

Le workflow CI et le badge README sont corrects.

- `.github/workflows/ci.yml` : YAML valide, déclenchement push+PR toutes branches, runner macos-14, étape `swift test` présente
- `README.md` : badge CI ajouté sous `# Memo`, lien vers le bon workflow
- Message de commit conforme aux conventions (`ci:`)
- `make test` non exécutable localement (pas de Swift sur Linux) — attendu, le runner macos-14 est le mécanisme de validation

Aucun problème bloquant identifié.
