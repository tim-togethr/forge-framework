# Visual Companion Guide

Supplementary instructions for the brainstorming skill. When a brainstorming question would benefit from visual presentation, use this workflow to show proposals in the browser.

## When to Use

Decide per-question, not per-session. The test: would the user understand this better by seeing it than reading it?

**Use the browser for:**
- UI mockups and layout proposals
- Architecture diagrams and system flows
- Side-by-side visual comparisons
- Design polish decisions (spacing, typography, color)
- Spatial relationships (page layout, component arrangement)

**Use the terminal for:**
- Requirements and scope questions
- Conceptual A/B/C choices with no visual component
- Tradeoff lists and prioritization
- Technical decisions (database schema, API design, auth strategy)
- Clarifying questions

A question about a UI topic is not automatically a visual question. "Should we add a dashboard?" is a scope question (terminal). "How should the dashboard lay out these 4 widgets?" is a spatial question (browser).

## Workflow

1. Read `templates/frame.html` from this skill's directory.
2. Generate HTML content using the template's CSS classes (see below).
3. Replace the `<!-- CONTENT -->` marker inside `#claude-content` with the generated content.
4. Write the complete file to `.forge/visual/<semantic-name>.html` (create the directory if needed).
5. Run `open .forge/visual/<semantic-name>.html` via the Bash tool.
6. Tell the user what's on screen with a brief summary — what they're looking at and what to focus on.
7. Ask them to respond in the terminal.
8. For iterations: write a new file (e.g., `approaches-v2.html`), run `open` again. Never reuse filenames.

## CSS Classes Available

### Options (A/B/C choices)

Use `.options` for a vertical list of approach options. Each `.option` is a distinct choice.

```html
<div class="section">
  <h2>Proposed Approaches</h2>
  <p class="subtitle">Three options for the notification system</p>
  <div class="options">
    <div class="option recommended">
      <h3>A: Event-Driven Queue</h3>
      <p>Push notifications through a message queue with fan-out delivery.</p>
      <div class="pros-cons">
        <ul class="pros"><li><span>Scalable to millions of events</span></li></ul>
        <ul class="cons"><li><span>Requires new infrastructure</span></li></ul>
      </div>
    </div>
    <div class="option">
      <h3>B: Polling Service</h3>
      <p>Clients poll a lightweight API endpoint on interval.</p>
    </div>
  </div>
</div>
```

### Cards (visual designs)

Use `.cards` for a grid of visual options — layout proposals, component variants, etc.

```html
<div class="cards">
  <div class="card recommended">
    <h3>Sidebar Navigation</h3>
    <p class="subtitle">Fixed left panel with collapsible sections</p>
    <div class="placeholder">240px sidebar mockup</div>
  </div>
  <div class="card">
    <h3>Top Navigation</h3>
    <p class="subtitle">Horizontal bar with dropdown menus</p>
    <div class="placeholder">Full-width nav mockup</div>
  </div>
</div>
```

### Mockup Container

Use `.mockup` to frame a UI wireframe with a labeled header.

```html
<div class="mockup">
  <div class="mockup-header">Dashboard — Desktop View</div>
  <div class="mockup-body">
    <div class="mock-nav">Logo &nbsp; Home &nbsp; Settings &nbsp; Profile</div>
    <div style="display: flex;">
      <div class="mock-sidebar">Menu Item 1<br>Menu Item 2<br>Menu Item 3</div>
      <div class="mock-content">
        <h3>Welcome back</h3>
        <p class="subtitle">Your recent activity</p>
        <div class="placeholder">Chart area</div>
      </div>
    </div>
  </div>
</div>
```

### Split View (side-by-side)

Use `.split` to compare two things side by side.

```html
<div class="split">
  <div class="mockup">
    <div class="mockup-header">Option A: Tabs</div>
    <div class="mockup-body">
      <div class="placeholder">Tab layout mockup</div>
    </div>
  </div>
  <div class="mockup">
    <div class="mockup-header">Option B: Accordion</div>
    <div class="mockup-body">
      <div class="placeholder">Accordion layout mockup</div>
    </div>
  </div>
</div>
```

### Pros and Cons

Use `.pros-cons` inside an option or card for structured tradeoffs.

```html
<div class="pros-cons">
  <ul class="pros">
    <li><span>Fast to implement</span></li>
    <li><span>Familiar pattern</span></li>
  </ul>
  <ul class="cons">
    <li><span>Doesn't scale past 10k users</span></li>
    <li><span>Requires polling</span></li>
  </ul>
</div>
```

### Mock Wireframe Elements

Building blocks for quick UI wireframes:

- `.mock-nav` — a horizontal navigation bar
- `.mock-sidebar` — a vertical sidebar panel
- `.mock-content` — a main content area
- `.mock-button` — a styled button element
- `.mock-input` — a styled text input

```html
<div class="mock-content">
  <h3>Create New Project</h3>
  <div class="mock-input">Project name</div>
  <br>
  <div class="mock-input">Description</div>
  <br>
  <span class="mock-button">Create</span>
</div>
```

### Typography and Sections

- `h2` — page or section title
- `h3` — subsection or card title
- `.subtitle` — secondary description text below a heading
- `.section` — a block with bottom margin for grouping content
- `.label` — small uppercase label text
- `.placeholder` — a gray box representing an area that would contain real content

### The `.recommended` Class

Add `.recommended` to any `.option` or `.card` to give it a subtle accent-colored highlight. Use this to visually mark the recommended approach.

```html
<div class="option recommended">
  <h3>Recommended: Event-Driven Architecture</h3>
  <p>This approach best fits the scale and latency requirements.</p>
</div>
```

## Design Tips

- **Scale fidelity to the question.** A high-level architecture choice needs boxes and arrows, not pixel-perfect mockups. A layout decision needs spatial arrangement, not lorem ipsum.
- **Explain the question on each page.** Use `h2` and `.subtitle` at the top so the page stands alone — the user may glance at it minutes later.
- **2-4 options max per screen.** More than that overwhelms. If you have 5 options, consolidate or split into two rounds.
- **Use real content when it matters.** If the decision depends on how long the text is or what the data looks like, use realistic examples, not placeholders.
- **Keep mockups simple.** Use `.placeholder` blocks for areas that aren't relevant to the decision. Don't build a full page when only the header matters.
- **Use semantic filenames.** Name files after what they show: `approaches.html`, `layout.html`, `architecture.html`, `nav-options.html`.

## Cleanup Note

Generated files live in `.forge/visual/`. They are gitignored. The user can delete them anytime.
