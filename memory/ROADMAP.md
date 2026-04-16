# Memo — Roadmap de Publication

**Deadline : 30 avril 2026**
**Objectif :** GitHub Release (DMG ad-hoc signé) + GitHub Pages (landing page portfolio)

---

## Jalons

### Semaine 1 — 16-18 avril 2026 : Infrastructure CI + Distribution

- [ ] **CI GitHub Actions** — workflow `swift test` sur push/PR (badge dans README)
- [ ] **Script DMG** — créer un DMG distribuable à partir de Memo.app
- [ ] **GitHub Actions release** — build + package automatique sur tag `v*`

### Semaine 2 — 21-23 avril 2026 : Landing Page

- [ ] **GitHub Pages** — one-pager portfolio HTML/CSS statique
  - Screenshot/GIF de l'app
  - Description courte (FR + EN)
  - Lien vers le release GitHub
  - Bouton de téléchargement

### Semaine 3 — 24-28 avril 2026 : Polish + Publication

- [ ] **GitHub Release v1.0** — tag, changelog, DMG attaché
- [ ] **Localisation française** — compléter les strings FR dans l'UI
- [ ] **README polish** — badge CI, lien landing page, instructions d'installation

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

---

## Hors scope (v1.0)

- Prefixes de prompt
- Whisper local (whisper.cpp / WhisperKit)
- Historique des transcriptions
- Thèmes visuels
- Mac App Store (signature Developer ID requise)
