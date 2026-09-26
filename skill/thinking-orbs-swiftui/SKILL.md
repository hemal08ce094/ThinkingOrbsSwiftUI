---
name: thinking-orbs-swiftui
description: Add Thinking Orbs, the SwiftUI port of the thinking-orbs npm library (github.com/hemal08ce094/ThinkingOrbsSwiftUI), to an iOS, macOS, visionOS, tvOS or watchOS SwiftUI project. It adds the package and replaces spinners, typing dots and "thinking…" indicators in AI chat, agent, search, voice and sync UIs with dotted 3D thought-orbs (working, searching, solving, listening, connecting, weaving, composing, breathing, shaping). Use when the user asks for thinking orbs, orb loaders, an AI thinking or loading indicator, a nicer spinner for an assistant or agent, or to apply or add Thinking Orbs to an app.
---

# Add Thinking Orbs to a SwiftUI project

Thinking Orbs are monochrome, dotted 3D loading indicators drawn with `Canvas` and `TimelineView`. The package is `https://github.com/hemal08ce094/ThinkingOrbsSwiftUI`, product `ThinkingOrbs`, from `0.1.0`. It needs iOS 15, macOS 12, tvOS 15, watchOS 8 or visionOS 1, and has no dependencies. See `references/xcode-package.md` to wire it up.

## 1. Preflight

- Find the app target's deployment targets. If they're below the minimums above, stop and ask.
- Decide the **scope** from the request. "Add an orb to the chat" means the chat only. Don't replace every `ProgressView` in the app unless the user asks for that.
- Find the loading indicators in scope, for example `grep -rn "ProgressView\|TypingIndicator\|isLoading\|isThinking\|isStreaming" --include=*.swift`, and read each call site before editing.

## 2. Add the package

Follow `references/xcode-package.md`. Resolve and build once before converting anything.

## 3. API

```swift
import ThinkingOrbs

ThinkingOrb(_ state: OrbState = .working,
            size: OrbSize = .large,     // .large 64pt | .small 20pt (integer literals 64/20 also work)
            theme: OrbTheme = .auto,    // .auto follows colorScheme | .dark light-ink | .light dark-ink
            speed: Double = 1,          // multiplier on the preset's baked speed
            paused: Bool = false,       // freeze on the current frame
            label: String? = nil)       // VoiceOver label; default is per state ("Searching…")

OrbCanvas(state:size:dark:t:)           // one frozen frame, for widgets, snapshots and ImageRenderer
OrbEngine.frame(_:size:t:)              // raw z-sorted geometry (OrbFrame: dots + lines)
```

The view has a fixed size (64×64 or 20×20) and a transparent background.

## 4. Pick the state from what the app is actually doing

| App activity | State |
|---|---|
| generic "working", tool running, background task | `.working` |
| web or doc search, retrieval, lookup, indexing | `.searching` |
| reasoning, "thinking…", math, planning, code analysis | `.solving` |
| microphone open, dictation, voice mode, transcribing | `.listening` |
| connecting, syncing, auth handshake, fetching from an integration | `.connecting` |
| merging sources, combining results, multi-step agent | `.weaving` |
| streaming or drafting a reply, writing, generating text | `.composing` |
| idle but waiting, or a calm "thinking" presence | `.breathing` |
| generating an image, layout or design | `.shaping` |

If one indicator covers several phases (for example search, then reason, then write), drive `state` from the phase enum the app already has. Don't invent phases the app doesn't track.

## 5. Where each size goes

| Stock pattern | Replace with |
|---|---|
| `ProgressView()` beside "Thinking…" or "Searching…" text, or in a status pill | `HStack(spacing: 8) { ThinkingOrb(.solving, size: .small); Text("Thinking…") }` |
| three-dot typing bubble in a chat | `ThinkingOrb(.composing, size: .small)` inside the existing bubble |
| assistant avatar while it responds | `ThinkingOrb(state, size: .large)`, optionally on a `Circle()` fill |
| full-screen or empty-state loader for an AI feature | `ThinkingOrb(state, size: .large)` centred, with a caption below |
| mic button or voice sheet while listening | `.listening` (`.large` in the sheet, `.small` inside a button) |
| toolbar or navigation-bar activity | `.small` |

**Leave these native:** pull-to-refresh, determinate progress (`ProgressView(value:)`), plain non-AI loading (images, pagination), system sheets, and anything that shows a percentage. The orbs are for "an agent is thinking", not for every network wait.

Keep the existing `if isLoading` conditions and accessibility labels. If the old view had an `accessibilityLabel`, pass it as `label:`.

## 6. Gotchas

- **Theme:** `.auto` follows the environment's `colorScheme`. If the orb sits on a surface whose brightness doesn't match the scheme (a dark card in light mode, say), pin `theme: .dark` or `.light`, or put `.environment(\.colorScheme, .dark)` on that surface.
- **Other sizes:** there are only two tuned designs. For something like 32pt, use `.small` with `.scaleEffect(1.6)` or `.large` with `.scaleEffect(0.5)`. Don't redraw the dots yourself.
- **Colour:** the dots are grayscale by design. To tint them, apply `.colorMultiply(.accentColor)` to a `theme: .dark` orb. Don't fork the painter.
- **Transitions:** switching `state` swaps the geometry instantly. For a smooth change, wrap the swap in `.transition(.opacity)` with `.id(state)` and `withAnimation(.easeInOut(duration: 0.2))`.
- **Lists:** each orb runs its own `TimelineView`. That's fine for a handful. In a long list, show orbs only on the rows that are actually in progress.
- **Reduce Motion** is already handled with a static frame. Don't add pulsing or scaling on top.
- **Widgets or Live Activities:** use `OrbCanvas(state:size:dark:t:)` with a fixed `t`, because TimelineView doesn't animate there.

## 7. Verify

1. Build every platform the target supports and fix every error.
2. Trigger the loading state in the simulator. Use launch arguments or a debug toggle if the app has one, otherwise temporarily force the condition, then revert. Screenshot with `xcrun simctl io <udid> screenshot`, and take one in dark mode too.
3. Report which indicators were replaced and with which states, what was left native and why, and any deployment-target change.
