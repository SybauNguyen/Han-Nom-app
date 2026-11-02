# Stroke-order data notice

The writing practice uses the character stroke-order/median data format published for Hanzi Writer Data 2.0.1, derived from the Make Me a Hanzi project.

- Upstream data: Hanzi Writer Data / Make Me a Hanzi
- License: Arphic Public License (see upstream license text)
- Runtime source used by the app: `https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/<character>.json`
- The app uses the `medians` data for per-stroke guidance and grading.

Hanzi Writer itself is an MIT-licensed open-source JavaScript library; the character data has a separate license/provenance and is not covered by the library's MIT license.

The app treats stroke grading as handwriting practice rather than calligraphy certification. Thresholds are intentionally tolerant and should be calibrated with real user testing before a public release.
