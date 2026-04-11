# Visual Companion for Brainstorming

**Date:** 2026-04-11
**Approach:** B — Static HTML + `open` (zero infrastructure)

## Problem

The `visual_companion` gate is enforced for engineers but has no backing skill or template. Brainstorming proposals are markdown-only. Complex choices (UI layouts, architecture diagrams, side-by-side comparisons) are better understood visually.

## Chosen Approach

Self-contained HTML files opened in the default browser. No server, no WebSocket, no Node.js dependency. Selection stays in the terminal. Inspired by Superpowers' visual companion but stripped to the essentials.

## Files

| File | Action | Purpose |
|---|---|---|
| `forge/packs/planning/skills/brainstorming/templates/frame.html` | Create | Forge-branded HTML/CSS template with light/dark theme and CSS class vocabulary |
| `forge/packs/planning/skills/brainstorming/visual-companion.md` | Create | Skill instructions: when to use, workflow, CSS reference, design tips |
| `forge/packs/planning/skills/brainstorming/SKILL.md` | Edit | Reference visual companion in Phase 3 |

## Workflow

1. During brainstorming Phase 3, Claude decides per-question: "would this be clearer visually?"
2. Claude reads `templates/frame.html` (tier 3 resource)
3. Generates content HTML using the template's CSS classes
4. Replaces `<!-- CONTENT -->` marker, writes complete file to `.forge/visual/<name>.html`
5. Runs `open <filepath>` to launch in default browser
6. User views proposal, returns to terminal to respond

## Design Decisions

- **No server**: Fits Forge's "no compiled code" philosophy. Upgrade path to server-lite (Approach C) is additive.
- **Same CSS vocabulary as Superpowers**: `.options`, `.option`, `.cards`, `.pros-cons`, `.split`, `.mockup` — content patterns are compatible if we add a server later.
- **No click-to-select**: Terminal selection works fine for "pick A, B, or C". Reduces ~500 lines of JS/WebSocket code.
- **Output to `.forge/visual/`**: Consistent with Forge directory structure. Added to `.gitignore`.

## Success Criteria

- [ ] Brainstorming skill knows when to use visual vs terminal
- [ ] HTML template renders correctly in light and dark mode
- [ ] `open` command launches the file in the default browser
- [ ] CSS classes produce clean, readable proposal views
- [ ] Pack validation passes
