## Overview

This project defines several custom Cursor agents under `.cursor/agents` to support writing, reviewing, and managing research outputs. This document summarizes what each agent does, how to invoke it, and what files it reads from and writes to.

## Agent catalog

### AI Fingerprint Auditor (`ai-detector`)

- **Purpose**: Audit LaTeX/Markdown manuscripts for LLM-style fingerprints and "chat leakage" to ensure the text reads as fully human-authored for top-tier journal submission.
- **Trigger scope**: `*.tex`, `*.md`.
- **Typical invocation**: Run on a manuscript file to check for AI-style phrasing before submission or sharing.
- **Main behavior**:
  - Scans the target file for chatty openings/closings, overused transitions, fluff adjectives, and robotic rhythm.
  - Computes a human-voice score.
  - Writes or updates a dated audit report.
- **Outputs**:
  - `reports/ai_audit_report_MMDDYYYY.md` – markdown table of flagged locations, issue types, detected text, suggested fixes, and an overall human-voice score.

### Finance Paper Reviewer (`finance-paper-reviewer`)

- **Purpose**: Act as an anonymous referee for the **Journal of Finance (JF)**, providing a structured pre-submission referee-style report on a manuscript.
- **Trigger scope**: `*.tex`, `*.md`, `*.docx`.
- **Invocation pattern**:
  - Call the agent on the **main manuscript file** (typically the main `.tex` file).
  - The argument must be the path to that main file; the agent does **not** auto-detect it.
- **Main behavior**:
  - Treats the target journal as fixed: `Journal of Finance (JF)`.
  - Parses the main LaTeX file plus inputs/includes to understand the full paper.
  - Assumes figures are stored under `docs/figures/` (PDF/PNG/EPS/JPG/JPEG/SVG).
  - Runs six internal review dimensions (style, consistency, identification, math, tables/figures, contribution/JF fit).
  - Consolidates these into a single pre-submission referee report.
- **Outputs**:
  - `PRE_SUBMISSION_REVIEW_[YYYY-MM-DD].md` – a structured report with:
    - Overall assessment and recommendation at JF standards.
    - Section-by-section outputs from the six internal review agents.
    - A prioritized list of critical, major, and minor action items.

### Literature Reviewer (`literature-reviewer`)

- **Purpose**: Orchestrate an end-to-end literature review workflow: web search and PDF collection, local BibTeX construction, a thematic markdown review, and a follow-up critique by a second agent.
- **Trigger scope**: `*.md`, `*.tex` (invoked with a topic string as arguments).
- **Invocation pattern**:
  - Call the agent with a **topic string** as the single argument (e.g., `"bank branch closures and credit supply"`).
  - The agent creates and uses a project-local folder `related-papers/` at the repo root.
- **Main behavior**:
  - **Phase 1 – PDF discovery and download**:
    - Uses web search / browser tools to find relevant academic papers and working papers.
    - Downloads accessible PDFs into `related-papers/`.
    - Maintains `related-papers/sources.md` with:
      - `## Downloaded PDFs` (local filename, URL, basic metadata).
      - `## Failed or Non-PDF Sources` (title/description, URL, and reason download failed).
  - **Phase 2 – Local-only BibTeX**:
    - Scans only local PDFs under `related-papers/` (no external metadata calls).
    - Heuristically infers title, authors, year, outlet, etc. from the PDF text.
    - Builds `related-papers/references.bib` with one entry per PDF.
  - **Phase 3 – Literature review markdown**:
    - For each PDF, reads enough text to summarize question, data, method, and findings.
    - For long PDFs, uses subagents to summarize ~5-page chunks, then synthesizes into a single per-paper summary.
    - Organizes papers into 2–5 thematic clusters (by topic/method/mechanism).
    - Writes `related-papers/literature-review.md` with:
      - Overview section.
      - Thematic discussion with per-paper bullet summaries keyed by BibTeX entries.
      - Gaps and directions for future work.
      - A references section built only from `references.bib`.
  - **Phase 4 – Critique agent**:
    - Launches a second, senior-researcher agent to review and critique the literature review.
    - Saves its feedback and suggestions for revision.
- **Outputs**:
  - `related-papers/` (folder at repo root) containing:
    - `sources.md` – downloaded and failed source log.
    - `references.bib` – BibTeX entries built from local PDFs.
    - `literature-review.md` – thematic literature review.
    - `literature-review-critique.md` – structured critique with overall assessment, major/minor comments, and suggested revisions.

## Usage notes

- **Agent discovery**: All agent definitions live under `.cursor/agents/`. Update this `AGENTS.md` whenever you add, rename, or significantly change an agent.
- **Determinism and safety**:
  - File paths are always relative to the project root.
  - Agents that download or create files keep all outputs in project-managed folders (`reports/`, `related-papers/`, `docs/figures/`).
- **Extensibility**:
  - New agents should follow the same pattern: clear purpose, explicit input expectations, and documented output locations so they can be easily composed into larger workflows.

