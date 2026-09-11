# Tuck identity — Phase 1 design lock

## Decision

- Product name: **Tuck**
- Descriptor: **Clipboard history**
- Tagline: **A happy little home for everything you copy.**
- Personality: warm, quiet, useful, lightly playful
- Existing app icon: retained. Its teal pouch and paper slips already express the new name.

This phase changes no application code or shipping asset catalogue. The files in this directory are design sources and review proofs for later implementation.

## Menu-bar family

All four marks use the same rounded pouch geometry and a single-colour silhouette. They are designed as macOS template images so the system can supply the correct foreground colour for light, dark, tinted, and high-contrast menu bars.

| Option | Role | Character |
| --- | --- | --- |
| **Pocket** | Default | The clearest bridge between the app icon and its menu-bar presence. |
| **Peek** | Alternative | Two offset slips give the mark more motion and energy. |
| **Buddy** | Alternative | Tiny cut-out eyes and smile add personality without becoming a mascot. |
| **Spark** | Alternative | A small four-point spark adds a polished, delightful note. |

The source artwork uses a 32 × 32 coordinate grid. It must be exported with transparency at exactly 16 × 16 pixels for 1× and 32 × 32 pixels for 2×. No colour, shadow, gradient, or baked light/dark treatment should be added.

## Implementation contract for Phase 3

- Default new selection: **Pocket**.
- Existing `maccy`, `clipboard`, `scissors`, and `paperclip` preferences migrate to Pocket.
- Picker labels and accessibility names are Pocket, Peek, Buddy, and Spark.
- Preserve these vector masters as the source of truth; asset-catalog PNGs are generated derivatives.
- Inspect every exported mark in both menu-bar appearances at native size before integration is accepted.

## Approval gate

Phase 1 is complete when the name, tagline, four glyphs, default selection, and retained application icon are accepted. Phase 2 can then update visible product identity independently of the icon integration.
