# Lessons Learned — Memo

Journal append-only. Ne jamais supprimer ou réécrire une entrée.
Format : `## [Pattern|Antipattern]: <nom> — <date> — (coder|reviewer|manager|human)`

Les entrées marquées `[promote]` sont candidates pour le template `ai-project-launchpad`.

---

## Antipattern: .claude/ dans .gitignore — 2026-04-16 — human [promote]
**Context:** Setup initial du workflow agents.
**Observation:** Le `.gitignore` ignorait `.claude/`, rendant les fichiers agents invisibles pour git. Les agents n'auraient jamais été versionnés ni partagés entre sessions.
**Decision/Rule:** Toujours versionner `.claude/agents/` dans git. Seul `.claude/settings.local.json` (secrets locaux) doit être ignoré.
**Outcome:** ✅ Corrigé au setup. Règle à appliquer dès `init` dans tout nouveau projet.

## Antipattern: Modèles d'agents incorrects — 2026-04-16 — human [promote]
**Context:** Brief original utilisait `claude-opus-4` et `claude-sonnet-4-5`.
**Observation:** Ces IDs de modèles sont obsolètes/inexistants. Les agents ne démarrent pas avec des IDs invalides.
**Decision/Rule:** Toujours vérifier les IDs de modèles dans la doc Anthropic. IDs corrects au 2026-04 : `claude-opus-4-6`, `claude-sonnet-4-6`.
**Outcome:** ✅ Corrigé. À documenter dans le template launchpad avec note de mise à jour.

## Antipattern: Keychain verrouillé en CI — 2026-04-17 — human [promote]
**Context:** GitHub Actions macOS runner, `swift test`.
**Observation:** Le login Keychain est verrouillé par défaut sur GitHub Actions. `SecItemAdd` retourne `errSecInteractionNotAllowed`, faisant échouer silencieusement les tests qui écrivent/lisent des secrets.
**Decision/Rule:** Toujours créer et déverrouiller un keychain de test dans le workflow CI avant `swift test`. Commande : `security create-keychain -p "" ci-test.keychain && security unlock-keychain`.
**Outcome:** ✅ Corrigé dans `.github/workflows/ci.yml`.

## Antipattern: NSApplication non initialisé dans swift test — 2026-04-17 — human [promote]
**Context:** Tests AppKit (NSPanel, NSWindow) dans un target `swift test` SPM.
**Observation:** `swift test` ne démarre pas de `NSApplication`. Les tests qui créent des panels ou appellent `NSApp.activate()` crashent ou retournent des tailles nulles.
**Decision/Rule:** Ajouter un `XCTestObservation` qui initialise `NSApplication.shared` avant tout test. Fichier : `Tests/*/TestSetup.swift`.
**Outcome:** ✅ Corrigé via `TestSetup.swift`.

## Antipattern: Skip condition trop large dans DeploymentTests — 2026-04-17 — human
**Context:** `test_appBundle_hasBinary` en CI.
**Observation:** `Memo.app/Contents/Info.plist` est tracké dans git, donc `Memo.app/` existe en CI. Le skip était basé sur `bundlePath` (le dossier) au lieu de `binaryPath` (le binaire absent). Le test échouait au lieu de skiper.
**Decision/Rule:** Les skip conditions dans les DeploymentTests doivent vérifier l'existence de l'artefact testé spécifiquement, pas du dossier parent.
**Outcome:** ✅ Corrigé dans `DeploymentTests.swift`.

## Antipattern: Branches orphelines sans auto-merge — 2026-04-16 — human [promote]
**Context:** Routines agents qui créent des PRs sans les merger.
**Observation:** Sans auto-merge dans le reviewer, les branches s'accumulent (6 branches après 2 jours). L'humain doit intervenir pour merger → casse l'autonomie du système.
**Decision/Rule:** Le reviewer doit toujours : créer la PR → merger immédiatement (squash) → supprimer la branche. Cycle fermé sans intervention humaine.
**Outcome:** ✅ Corrigé dans `reviewer.md`.
