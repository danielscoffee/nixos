---
name: high-end-frontend
description: High-end frontend library stack. Use when choosing or combining libraries for premium web UI (motion choreography, smooth scroll, page transitions, 3D/WebGL, vector animation, typography), or when a library choice should be settled by prototyping competing directions.
---

# High-end frontend stack

Build the smallest stack that delivers the page's **signature moment**, give every layer exactly one **owner**, and settle taste questions with prototypes instead of argument.

## 1. Recon

Read `package.json`, the styling setup, and any existing motion code first. An installed library keeps its job unless it blocks the brief; flag a better fit and leave the dependency alone unless the user asks to switch.

## 2. Product primitives

For dialogs, menus, selects, command menus, toasts, OTP inputs, animated numbers, charts, drag and drop, virtualization, state, and class composition, read `~/.claude/skills/pick-ui-library/SKILL.md` and use its picks. Inside its categories that list is the source of truth.

## 3. The high-end layer

| Job | Default | Switch when |
|---|---|---|
| Component motion: springs, layout, enter/exit, gestures | Motion (`motion/react`) | Plain CSS transitions cover hovers and fades |
| Choreographed sequences, scroll storytelling, split text, FLIP | GSAP with ScrollTrigger, SplitText, Flip (every plugin is free) | Motion fits better when the motion follows component state |
| Drop-in micro-transitions: dropdowns, toasts, tabs, badges | transitions.dev snippets (plain CSS, `t-*` classes) | The project already has motion tokens of its own |
| Page and route transitions | View Transitions API; React `<ViewTransition>` via the `react-view-transitions` skill | GSAP for choreography past a crossfade or shared-element morph |
| Inertial smooth scroll | Lenis | Native scroll for app UI, dashboards, and long reading |
| 3D scenes and product viewers | Three.js through React Three Fiber + drei | OGL for one shader effect; a Spline embed for a designer-authored scene |
| Post-processing (bloom, grain, depth of field) | pmndrs `postprocessing` / `@react-three/postprocessing` | A single GLSL plane for one effect |
| Interactive vector animation with state and input | Rive | dotLottie for playback of After Effects exports |
| Type | Self-hosted variable fonts (`next/font` or Fontsource), `text-wrap: balance` on headings and `pretty` on body, a fluid `clamp()` scale | |
| Owned component source | shadcn/ui on top of the primitives from step 2 | |
| Icons | Lucide | Phosphor when the design needs several weights |
| Carousels | Embla | |

## 4. Pairing rules

- **One owner per property.** Motion, GSAP, and CSS transitions never animate the same property on the same element.
- **One clock for Lenis and ScrollTrigger:** `lenis.on('scroll', ScrollTrigger.update)`, `gsap.ticker.add((t) => lenis.raf(t * 1000))`, `gsap.ticker.lagSmoothing(0)`.
- In React, run GSAP inside `useGSAP` from `@gsap/react` so it cleans up, and register plugins once at module scope.
- Load 3D lazily (dynamic import plus `Suspense`), cap `dpr={[1, 2]}`, and use `frameloop="demand"` for scenes that sit still.
- Every layer honors `prefers-reduced-motion`; Lenis turns off under it.
- Animate `transform` and `opacity`. One signature moment per page outshines motion on every element.

## 5. Settle taste with variants

When the choice comes down to feel (Motion springs or a GSAP timeline, Rive or Lottie, Lenis on or off, a 3D hero or a typographic one), build 2 or 3 variants, one per library direction. Put them behind the picker in `~/.claude/skills/prototype/PICKER.md`, copied verbatim, and follow that skill's hard rules: an isolated prototype surface, every variant fully working, and production code untouched until the user picks. The user can also run `/prototype` directly.

## 6. Library packs

These packs are invoke-only, so they never load on their own. Once a layer has its owner, read the matching files before writing that layer's code:

- **GSAP:** `~/.claude/skills/gsap-core/SKILL.md`, then `gsap-react`, `gsap-scrolltrigger`, `gsap-timeline`, `gsap-plugins`, or `gsap-frameworks` (Vue, Svelte) in the same folder.
- **React Three Fiber:** `~/.claude/skills/_jutsu/threejs-r3f/SKILL.md`.
- **Vanilla three.js:** `~/.claude/skills/threejs-*/SKILL.md`. They were written around r160, so read `uv2` as `uv1` with `texture.channel`, finish the post-processing chain with `OutputPass`, use physical light intensities, and import `ContactShadows` from drei only.
- **Drop-in transitions:** `~/.claude/skills/transitions-dev/SKILL.md` and its numbered reference files.
- **Motion personality and choreography:** `~/.claude/skills/motion-design/SKILL.md`.
- **Reference UI to measured tokens:** `~/.claude/skills/design-dna/SKILL.md`. Its color-measurement scripts need `sharp`, which cannot install into the read-only skill folder; skip that step and say so.

The user runs genjutsu's pipelines directly: `/cast` for one effect or section, `/paint` for a full visual identity, `/bunshin` for a whole site (a multi-agent build that costs millions of tokens).

## 7. Hand-offs

- Aesthetic direction: `impeccable`; the user can run `/taste-skill` for a second direction
- Motion craft and motion review: `animate`, `emil-design-eng`, `apple-design`, `review-animations`
- Palettes, font pairings, and per-stack UI rules: `~/.claude/skills/ui-ux-pro-max/SKILL.md` and its search script
- React performance: `react-best-practices`

## Output

List each chosen library with its job in one line, what you left out and why, and the install commands. Done means every layer the brief needs has exactly one owner, and each added dependency traces to a moment in the brief.
