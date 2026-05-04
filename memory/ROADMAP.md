# Memo — Roadmap de Publication

**Deadline : 30 avril 2026**
**Objectif :** GitHub Release (DMG ad-hoc signé) + GitHub Pages (landing page portfolio)

---

## Jalons

### Semaine 1 — 16-18 avril 2026 : Infrastructure CI + Distribution

- [x] **CI GitHub Actions** — workflow `swift test` sur push/PR (badge dans README) -- PR #7, 2026-04-17
- [x] **Script DMG** — `scripts/package-dmg.sh` + `make dmg` -- Sprint 1 J1, 2026-04-17
- [x] **GitHub Actions release** — `.github/workflows/release.yml` sur tag `v*` -- Sprint 1 J2, 2026-04-20

### Semaine 2 — 21-23 avril 2026 : Landing Page

- [x] **GitHub Pages** — `docs/index.html` + `.github/workflows/pages.yml` -- Sprint 1 J3-J4, 2026-04-20/21
  - Hero, features grid, how-it-works, download CTA
  - Dark theme, responsive
  - Lien vers le release GitHub

### Semaine 3 — 24-28 avril 2026 : Polish + Publication

- [x] **GitHub Release v1.0** — tag `v1.0`, changelog, DMG attache -- Sprint 2, 2026-04-29 (release id 315149842, Memo-v1.0.dmg 1.85 MB)
- [x] **README polish** — badges CI/release/macOS/license, install instructions -- Sprint 1 J4, 2026-04-21
- [ ] ~~**Localisation francaise**~~ — reporte hors v1.0 (deadline trop proche)

---

## Fait (core app complet)

- [x] Raccourci global personnalisable (Carbon)
- [x] Enregistrement audio (AVFoundation, AAC 16 kHz)
- [x] Transcription Whisper API (`gpt-4o-mini-transcribe`)
- [x] Panneau flottant (compact pill + full edit)
- [x] Collage via CGEvent (⌘V simulation)
- [x] Clé API dans le Keychain
- [x] Mode push-to-talk et toggle
- [x] Auto-paste (sans panneau de relecture)
- [x] 18 langues supportées (auto-détection)
- [x] Sandbox + entitlements corrects
- [x] PrivacyInfo.xcprivacy
- [x] 46 tests unitaires
- [x] Makefile (dev/test/app/install/clean)
- [x] Ad-hoc signing avec préservation TCC

### Semaine 4 — 4-11 mai 2026 : Post-Release Polish (Sprint 3)

- [ ] **GitHub Pages verification** — confirmer URL live + CTA fonctionnel
- [ ] **CI smoke test DMG** — job macos-14 qui monte/verifie le DMG dans release.yml
- [ ] **Release body enrichi** — inclure CHANGELOG.md dans la GitHub Release via body_path
- [ ] **Cleanup branches** — supprimer les branches orphelines du remote
- [ ] **README screenshots** — remplacer placeholders ou retirer la section

---

## Hors scope (v1.0)

- Prefixes de prompt
- Whisper local (whisper.cpp / WhisperKit)
- Historique des transcriptions
- Themes visuels
- Mac App Store (signature Developer ID requise)
- Localisation francaise (reporte hors v1.0)
