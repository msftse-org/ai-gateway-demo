---
name: documentation-keeper
description: 'Create and maintain AGENT.md and README.md project documentation. Use when: documentation, AGENT.md, README.md, update docs, changelog, project tracker, internal decisions, public documentation, getting started guide, project structure, architecture decisions, keep docs up to date'
argument-hint: 'Describe what changed in the project, or ask to create initial documentation'
---

# Documentation Keeper

Maintains two complementary documentation files at the workspace root: `AGENT.md` (internal project tracker) and `README.md` (public-facing documentation). Creates them from scratch for new projects and keeps them in sync with ongoing changes.

## When to Use

- Setting up a new project that needs documentation
- After adding, modifying, or removing infrastructure, modules, scripts, configuration, or features
- After making architectural decisions or trade-offs worth recording
- When explicitly asked to update, create, or sync documentation
- When another skill (e.g., `terraform-builder`) instructs you to update documentation after completing its work

## File Purposes

| File | Audience | Purpose |
|------|----------|---------|
| `AGENT.md` | Developers, AI agents | Internal tracker: architecture, decisions, conventions, changelog |
| `README.md` | Users, contributors | Public docs: what this project does, how to set it up, how to use it |

**No duplication.** Internal decisions and rationale belong in `AGENT.md`. User-facing setup and usage belong in `README.md`. Cross-reference between them where appropriate.

## AGENT.md Specification

`AGENT.md` is the internal project tracker. It records what exists, why decisions were made, and what changed over time. Structure it with these sections (include only sections that are relevant to the project):

### Required Sections

1. **Title and summary** — one-line project description
2. **Project structure** — file/folder tree reflecting the actual workspace. Keep this accurate at all times
3. **Changelog** — dated entries recording what was added, changed, or removed. Append-only — never delete or rewrite past entries

### Optional Sections (include when relevant)

- **Stages / Phases** — if the project has a phased delivery plan
- **Architecture** — resource tables, component diagrams, system boundaries
- **Key decisions** — rationale for non-obvious choices (e.g., tool selection, workarounds, constraints)
- **Getting started / Prerequisites** — developer setup steps
- **Configuration / Variables** — tables of configurable values with defaults and descriptions
- **Conventions** — naming patterns, coding standards, tagging rules specific to the project

### Changelog Format

```markdown
### YYYY-MM-DD — Short Title
- Bullet point describing what changed
- Another change
- Include file paths where helpful
```

Always use the current date. Group related changes under a single dated heading.

## README.md Specification

`README.md` is the public-facing documentation. It tells users what the project does and how to use it. Structure it with these sections (include only sections that are relevant to the project):

### Required Sections

1. **Title and description** — what this project is and what it does
2. **Quick start** — prerequisites table and deployment/installation commands
3. **Project structure** — file/folder tree matching `AGENT.md` (keep in sync)

### Optional Sections (include when relevant)

- **What gets deployed / What's included** — tables describing created resources, components, or artifacts
- **Configuration** — how to customise the deployment or behavior (variables, settings, env files)
- **Scripts / CLI usage** — command reference for any scripts or tools
- **Technical notes** — non-obvious implementation details users should know
- **Roadmap** — planned stages or features with status
- **References** — links to external docs, specs, or related projects

### Style Guidelines

- Use tables for structured data (prerequisites, resources, variables)
- Include copy-pasteable code blocks for all commands
- Link to external documentation rather than duplicating it
- Add badges or images at the top if the project has them

## Creation Procedure

Use this when `AGENT.md` and/or `README.md` do not yet exist.

1. **Scan the workspace** — list directories, read key files (entry points, configs, scripts, manifests, IaC files) to understand the project's purpose, structure, and tooling
2. **Identify project metadata** — name, language/framework, dependencies, build/deploy tools, cloud providers, scripts
3. **Generate `AGENT.md`** — populate the required and applicable optional sections from the specification above. Record initial decisions and architecture. Add a changelog entry for the initial creation
4. **Generate `README.md`** — populate the required and applicable optional sections. Write clear setup instructions based on what you discovered in the workspace
5. **Verify consistency** — ensure the project structure trees match in both files, and no information is duplicated across them

## Update Procedure

Use this when `AGENT.md` and `README.md` already exist and the project has changed.

1. **Read both files** — always read the current `AGENT.md` and `README.md` before making any edits
2. **Scan the workspace** — list directories and read any new or modified files to understand what changed
3. **Identify deltas** — determine what is new, changed, or removed: files, modules, scripts, variables, outputs, resources, decisions, dependencies
4. **Update `AGENT.md`** — edit affected sections (architecture tables, decision list, project structure tree, variables table, etc.). Append a new dated changelog entry summarising the changes. Never remove or rewrite existing changelog entries
5. **Update `README.md`** — edit affected sections (what gets deployed, configuration, scripts, project structure tree, etc.). Add or update commands, tables, and descriptions as needed
6. **Verify consistency** — ensure project structure trees match in both files. Confirm no internal decisions leaked into `README.md` and no user-facing setup prose was added to `AGENT.md`

## Constraints

- **Never remove changelog entries** — the changelog in `AGENT.md` is append-only
- **Never fabricate information** — scan the workspace to discover facts. If you cannot determine something, say so rather than guessing
- **Always read before writing** — read both `AGENT.md` and `README.md` before any update to avoid overwriting recent changes
- **Keep structure trees accurate** — the project structure tree in both files must reflect the actual workspace. Run a directory listing to verify
- **Respect file boundaries** — internal decisions stay in `AGENT.md`, user-facing documentation stays in `README.md`
- **Preserve existing style** — when updating, match the formatting, heading levels, and conventions already used in each file
- **Date entries correctly** — always use the actual current date for changelog entries
