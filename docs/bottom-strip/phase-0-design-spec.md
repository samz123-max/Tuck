# Bottom Strip — Phase 0 Product and Experience Specification

Status: Approved
Branch: `design/bottom-strip`
Target: Tuck for macOS 14 and later, with a premium macOS 27 presentation on supported systems

## 1. Product intent

Bottom Strip is an optional presentation style for Tuck that places clipboard history in a wide, shallow surface anchored to the bottom of the active display. It is intended to make visual scanning faster while preserving Tuck's existing clipboard engine, search, pinning, preview, paste-stack, multi-selection, and keyboard workflows.

The feature should feel like a natural Tuck interface for modern macOS. Paste and Clipbara are behavioral references for a bottom-edge clipboard surface, not visual specifications to copy.

## 2. Goals

- Let people choose between Tuck's existing floating window and the new Bottom Strip.
- Make recent clipboard items faster to recognize through content-aware horizontal cards.
- Preserve fast keyboard-first use and the originating application's workflow.
- Open on the display where the user is working and behave reliably across Spaces and multi-display arrangements.
- Use macOS 27 materials, geometry, motion, and accessibility behavior in a restrained, native way.
- Retain a coherent and attractive fallback appearance on macOS 14 through macOS 26.
- Keep the existing floating-window experience stable while the strip is developed.

## 3. Non-goals

- Replacing the existing floating-window interface.
- Reproducing Paste or Clipbara pixel-for-pixel.
- Changing clipboard capture, persistence, exclusion, or automatic-paste semantics.
- Raising Tuck's minimum deployment target solely for the strip.
- Adding cloud sync, accounts, collaboration, or network-backed content.
- Adding a large set of visual customization controls before the default design is proven.

## 4. Terminology

- **Interface style:** The user's choice between `Floating Window` and `Bottom Strip`.
- **Strip:** The complete bottom-anchored panel.
- **Chrome:** Search, filters, section controls, and other controls surrounding clipboard content.
- **Card:** A visual representation of one clipboard-history item.
- **Active display:** The display containing the pointer when Tuck is invoked, with a deterministic fallback when the pointer is not on a display.
- **Originating application:** The foreground application in use immediately before Tuck opens.

## 5. Core experience

### 5.1 Invocation

- The existing global shortcut, menu-bar item, and application reopen paths continue to invoke Tuck.
- Invocation opens the interface style selected in Appearance settings.
- Repeating the shortcut while the strip is visible closes it unless Tuck is in its existing shortcut-cycling mode.
- The strip does not become a normal Dock application or replace the originating application as the user's working context.
- Search accepts typing immediately after presentation.

### 5.2 Placement

- The strip opens on the active display.
- Its lower edge aligns to the active display's `visibleFrame`, so a visible Dock is respected.
- It spans nearly the full usable width of the active display, with a restrained 12-point inset at each horizontal edge so its rounded silhouette remains visible.
- It never spans multiple displays.
- Its on-screen frame remains stationary during reveal and dismissal. The content animates within a clipped panel so displays stacked below the active display cannot capture the window.
- The strip participates in the active Space and can appear alongside full-screen applications using Tuck's existing auxiliary-panel behavior.

### 5.3 Provisional geometry

These values are design starting points and may be tuned during the panel prototype:

- Horizontal screen inset: 12 points on each side.
- Width: the active display's `visibleFrame` width minus those insets.
- Standard height: approximately 336 points.
- Compact-height fallback: reduce only as required to remain inside a constrained display's visible frame.
- Outer strip radius: system-derived where possible; otherwise 18–22 points.
- Chrome-to-card spacing: 10–14 points.
- Card width: adaptive, approximately 215–230 points.
- Card height: adaptive, approximately 220–240 points, with a subtly portrait proportion.
- Inter-card spacing: 8–10 points.

The layout must adapt rather than clip when the display is narrower than the provisional minimum.

### 5.4 Information architecture

The default strip contains two vertical regions:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Search clipboard…]  [All] [Text] [Links] [Images]      [Preview] [•••]   │
│                                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ →  │
│  │ selected │  │  image   │  │   text   │  │   link   │  │  color   │    │
│  │   card   │  │   card   │  │   card   │  │   card   │  │   card   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

- Chrome remains visually quiet so clipboard content is dominant.
- Category filters use the existing Tuck categories and state.
- Pins appear before recent unpinned items when pins are configured at the start, or after them when configured at the end.
- A subtle section boundary distinguishes pins from history without creating a second competing toolbar.
- Paste-stack state is represented as a compact, clearly labelled collection at the appropriate edge of the card sequence.
- Counts and secondary metadata are shown only when they help orientation.

## 6. Card system

### 6.1 Shared card anatomy

Each card provides:

- A compact content-type label.
- Relative copy time.
- Source-application icon when enabled and available.
- A content-specific preview.
- Pin state and selection affordances.
- Shortcut or multi-selection number when applicable.
- A context menu for secondary actions.

Selection must be obvious without relying on color alone. Hover, selected, pressed, pinned, and multi-selected states must remain visually distinct.

### 6.2 Content types

- **Text:** Prioritize readable content with sensible line limits. Preserve code-like spacing when detected without turning every text card into a code editor.
- **Image:** Use an aspect-fit thumbnail with a quiet backing surface. Show dimensions or file size only when useful.
- **Link:** Show a recognizable domain, title when available, shortened URL, and browser/source icon without performing network metadata fetches.
- **File:** Show file icon or thumbnail, filename, and concise type information.
- **Color:** Show a large swatch plus normalized color value with sufficient contrast around pale and dark colors.
- **Mixed/rich content:** Choose the most informative locally available representation while retaining all pasteboard representations for paste.

### 6.3 Loading and stability

- Cards use lazy construction.
- Image decoding and thumbnail creation must not block panel presentation.
- Placeholder geometry matches final geometry to avoid cards jumping as previews arrive.
- Newly copied items enter predictably without unexpectedly moving keyboard selection.

## 7. Search, navigation, and selection

### 7.1 Keyboard

- Left and Right move between cards.
- Home and End move to the first and last visible result where available.
- Space opens or closes the preview for the selected card.
- Return performs Tuck's configured select/paste action.
- Escape follows Tuck's existing hierarchy: clear search or transient state first, then close.
- Existing pin, delete, preview, paste-stack, and numbered-item shortcuts remain available.
- Shift/Command multi-selection behavior remains consistent with the floating window.
- Tab navigation reaches interactive chrome in a logical order without trapping focus.

### 7.2 Pointer and scrolling

- Clicking a card performs the same primary action as selecting a row in the floating window.
- Hover never changes keyboard selection by itself.
- Trackpad horizontal scrolling is native and preserves momentum.
- A conventional vertical mouse wheel moves the card sequence horizontally when the pointer is over it.
- Scrolling does not accidentally activate or paste a card.
- Context menus and drag operations remain available where supported today.

### 7.3 Selection visibility

- Opening the strip selects the first eligible result using existing Tuck rules.
- Keyboard movement scrolls the selected card fully into view.
- Automatic scrolling uses the smallest useful movement; it does not continually recenter the row.
- Selection survives filter and history updates when the selected item remains visible.

## 8. Preview behavior

The baseline design uses an attached preview surface above the strip rather than widening the strip sideways.

- Manual preview toggling is always available.
- Bottom Strip never opens previews automatically. Space is the deliberate preview action for the selected card.
- The existing automatic-preview preference applies only to Floating Window.
- The preview is aligned within the strip's horizontal footprint and constrained to the active display.
- It does not cover the selected card's essential selection state.
- Changing selection updates the open preview without closing and reopening the entire strip.
- Closing the preview returns keyboard interaction to the selected card.
- Reduce Motion replaces spatial preview transitions with a short cross-fade or immediate update.

An in-strip replacement preview may be prototyped as an alternative. It should only replace this baseline if it proves less disruptive and faster for repeated keyboard navigation.

## 9. Visual direction for macOS 27

### 9.1 Principles

- **Native before decorative:** Prefer system typography, symbols, materials, focus behavior, and accessibility adaptation.
- **Content over chrome:** Clipboard cards carry the visual hierarchy; controls support them quietly.
- **Glass with purpose:** Use Liquid Glass for the strip shell and interactive chrome, not as an effect layered indiscriminately over card content.
- **Concentric geometry:** Nested cards and controls visually follow the strip's outer curvature.
- **Depth through restraint:** Use fine borders, material separation, and small elevation changes instead of heavy shadows.
- **Motion explains structure:** The strip reveals from the bottom; selection and preview motion clarify relationships rather than decorate routine actions.

### 9.2 Platform adaptation

- On macOS 27, adopt refined Liquid Glass, interactive response for suitable controls, tighter system window geometry, container-concentric corners, and the Show Borders environment where APIs permit.
- On macOS 26, use the existing Liquid Glass path where appropriate.
- On macOS 14–25, use native visual-effect materials and explicit, visually equivalent borders and radii.
- Reduce Transparency uses an opaque or near-opaque system background.
- Increase Contrast and Show Borders strengthen boundaries without changing layout.
- Light and dark appearances are first-class designs, not automatic inversions of one reference appearance.

## 10. Settings

Appearance settings will add an `Interface style` choice:

- `Floating Window` — the existing Tuck experience and default during development.
- `Bottom Strip` — the new interface.

The first release should avoid exposing low-value tuning. The strip may initially expose only:

- Interface style.
- Display behavior if user testing demonstrates that active-display placement is insufficient.
- Automatic preview remains a Floating Window preference and is not shown as a Bottom Strip option.

Floating-window size and position remain independent from strip geometry. Switching styles must not overwrite the other style's saved state.

## 11. State and behavior compatibility

- Search text, selected category, clipboard history, pins, and paste stack use shared models.
- Presentation-specific geometry and transient scroll position are separate.
- Closing either interface performs the same cleanup of search, selection, shortcut state, and preview state unless a current Tuck preference explicitly says otherwise.
- Switching interface style while Tuck is open takes effect on the next presentation; it does not reconstruct the visible panel underneath the user.
- The existing floating window remains the fallback if strip construction fails.

## 12. Accessibility requirements

- Every card exposes content type, useful content summary, source application, age, pin state, selection state, and shortcut where applicable.
- VoiceOver order matches the visible left-to-right order.
- All actions available by pointer have a keyboard or accessibility equivalent.
- Focus indicators remain visible against light, dark, glass, image, and color content.
- No state depends on color alone.
- Text remains legible at increased contrast and with transparency disabled.
- Motion responds to Reduce Motion.
- The interface tolerates larger accessibility text without losing primary actions, using truncation or adaptive layout deliberately.

## 13. Performance requirements

- A warmed panel presents without a visible blank frame or late full-layout jump.
- Opening remains responsive with the maximum configured history size.
- Only visible and near-visible cards request expensive thumbnails.
- Horizontal navigation remains smooth while thumbnails resolve.
- Closing cancels presentation-specific asynchronous work that is no longer useful.
- Repeated open/close cycles do not grow retained panel, card, image, or event-monitor state.

Precise latency and memory budgets will be recorded from the first working prototype, then used as regression baselines rather than guessed in advance.

## 14. Multi-display and system edge cases

The implementation and test plan must cover:

- One display with the Dock visible, hidden, left, right, and bottom.
- Multiple displays arranged left/right and above/below.
- Displays with different scale factors and resolutions.
- Invocation with the pointer on each display.
- Display connection or removal while the strip is closed and while it is visible.
- Full-screen applications and multiple Spaces.
- Stage Manager.
- Menu-bar auto-hide.
- A display too narrow for the preferred strip width.
- Screen-parameter changes between prewarming and presentation.
- Originating applications with ordinary, secure, and non-text input focus.

## 15. Acceptance criteria

Phase implementation is complete only when all of the following are true:

### Presentation

- Bottom Strip can be selected without removing or regressing Floating Window.
- It opens entirely inside the active display's visible frame and respects a visible Dock.
- It never appears on an adjacent display during animation.
- It opens and closes repeatedly without flashing, stale content, or a stranded invisible panel.
- Reduce Motion produces a suitable low-motion transition.

### Content and features

- Text, image, link, file, color, and mixed items have intentional card presentations.
- Search and category filtering produce the same logical results as Floating Window.
- Pins, paste stacks, deletion, plain-text paste, multi-selection, and preview remain functional.
- Empty history and no-results states are complete and visually intentional.

### Interaction

- The complete primary workflow is usable with keyboard only.
- Trackpad and mouse-wheel navigation are predictable.
- Selection is never obscured and is not changed merely by hovering.
- The correct item is pasted or copied, and the originating application workflow remains intact.
- Outside click, Escape, and repeated shortcut dismissal behave consistently.

### Visual quality

- Light, dark, Reduce Transparency, Increase Contrast, and Show Borders appearances have been reviewed.
- Glass never reduces card-content legibility.
- Geometry is visually concentric and consistent at supported strip sizes.
- Hover, pressed, selected, pinned, and multi-selected states are individually recognizable.
- The result is recognizably Tuck and does not reproduce another product's trade dress.

### Reliability

- Multi-display and Dock-position scenarios pass the defined test matrix.
- Existing Floating Window UI tests continue to pass.
- New frame-calculation and active-display rules have automated coverage.
- VoiceOver labels, order, actions, and focus restoration have been manually verified.
- Performance baselines show no navigation hitching or unbounded memory growth in repeated-use tests.

## 16. Phase gates

1. **Panel prototype gate:** Approve placement, geometry, animation, display selection, and dismissal before building final cards.
2. **Visual prototype gate:** Approve the card family, chrome, materials, selection language, and light/dark appearance before feature-parity work.
3. **Preview gate:** Compare attached-above-strip and in-strip manual preview behavior during repeated card navigation.
4. **Feature-complete gate:** Approve keyboard behavior, settings, accessibility, and feature parity before release hardening.

## 17. Phase 0 decisions and deferred questions

### Decisions

- Bottom Strip is optional and shares the existing invocation shortcut.
- Floating Window remains intact and independently remembers its geometry.
- The strip opens on the active display and respects `visibleFrame`.
- The window remains on-screen while its content animates.
- History uses horizontally scrolling, content-aware cards.
- macOS 27 styling is native, restrained, accessible, and progressively enhanced.
- Tuck behavior and identity take precedence over visual imitation.

### Questions intentionally deferred to prototypes

- Final strip height and card aspect ratio.
- Whether attached or in-strip preview is less disruptive.
- Whether pinned items need a persistent section label or only a subtle boundary.
- Whether user-facing card-size controls add enough value to justify settings complexity.
