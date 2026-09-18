---
name: codebase-rulebook
description: Scan the repo end-to-end and write CODEBASE_RULEBOOK.md — the conventions every future code change is checked against. Use when the user runs /superflow:codebase-rulebook, asks to generate or refresh the rulebook, or when non-trivial code work is starting and no CODEBASE_RULEBOOK.md exists at the repo root.
---

# Codebase Rulebook

Scan the codebase end-to-end, extract its written and unwritten rules, and write `CODEBASE_RULEBOOK.md` at the repo root. Every future code change consults this file before writing code. This is the portability keystone of superflow — it's what lets the generic personas conform to *this* repo instead of any particular stack.

Note: this is the **codebase-specific** rulebook (project conventions). Keep it distinct from any user-level or org-wide rules you might track elsewhere.

Use this command **once** per codebase to bootstrap the rulebook, then re-run with `--refresh` whenever the codebase changes substantially (new framework, new test setup, new convention).

This command is inspect-only except for writing `CODEBASE_RULEBOOK.md`.

---

## How to invoke

```
/superflow:codebase-rulebook             # first run — scans everything and writes CODEBASE_RULEBOOK.md
/superflow:codebase-rulebook --refresh   # re-scan, preserve any human-edited sections, update the rest
/superflow:codebase-rulebook --dry-run   # show what would be written without writing
/superflow:codebase-rulebook --section <name>   # rescan only one section (e.g. "tests", "api")
```

---

## Lead behavior

The lead delegates the scan to `superflow:sherlock` (read-only) and writes the file itself. Nobody else writes rules.

Steps:

1. Confirm the repo type (run a quick `git status` and check the file tree).
2. If `CODEBASE_RULEBOOK.md` already exists and `--refresh` was not passed, ask:
   > A rulebook already exists. Refresh it? (yes / no / dry-run)
3. Delegate the scan to `sherlock` with the brief below.
4. Fill the template from sherlock's report, following the writing rules below, and write `CODEBASE_RULEBOOK.md`. Preserve `<!-- human-edited -->` sections on refresh.
5. Present a one-paragraph summary of what was found (`N sections written, M open questions`).
6. Tell the user the rulebook is now in effect — future code changes will consult it.

---

## sherlock assignment

```text
Owner: `sherlock`
Objective: Scan this codebase end-to-end and report every written and unwritten convention, with evidence, so the lead can fill the CODEBASE_RULEBOOK.md template.
Scope:
  - Configs: package.json, lockfiles, tsconfig*.json, eslint*, biome*, prettier*, ruff*, .flake8, pyproject.toml, mypy.ini, pyrightconfig.json, .editorconfig, go.mod, Cargo.toml, Gemfile
  - Pre-commit / git hooks: .husky/, lefthook.yml, .pre-commit-config.yaml, .git/hooks/
  - CI: .github/workflows/, .circleci/, .gitlab-ci.yml, ci.yml
  - Test configs: jest.config*, vitest.config*, playwright.config*, pytest.ini, tox.ini
  - Build configs: next.config*, vite.config*, webpack.config*, rollup.config*, esbuild.config*, Dockerfile
  - Repo docs: README.md, CONTRIBUTING.md, ARCHITECTURE.md, CLAUDE.md, any docs/ directory
  - PR/issue templates: .github/PULL_REQUEST_TEMPLATE*, .github/ISSUE_TEMPLATE/
  - Sample 10–20 representative source files (recent ones from `git log` if possible) to detect unwritten conventions.
Constraints:
  - Read-only. Do not run installs, builds, tests, or destructive commands.
  - Do not invent rules the codebase doesn't have.
  - If a section has no rule, write "Not enforced — no convention found".
  - Configs are the written law; repeated patterns in recent code are the unwritten law. If they disagree, report both.
Expected output:
  - For each template section below: the convention found, the evidence (config key, or the files the pattern was observed in), and the best reference example paths.
  - Sections with no convention: say so explicitly.
  - What could not be determined (goes to Open questions).
Validation: Read-only commands only (Glob, Grep, Read).
```

---

## CODEBASE_RULEBOOK.md structure (the template)

**This template is the single source of truth for the rulebook's structure.** Fill
it in verbatim, omitting sections that don't apply. Add or rename a section here and
nowhere else.

### Writing rules

- **Concrete and checkable.** "Max 300 lines per file" not "files should be small." A rule that needs human interpretation is not a rule.
- **Label every rule's weight.** `[ENFORCED]` — a violation fails CI, a lint rule, a type check, or a hook; cite the enforcer. `[OBSERVED]` — the house style, seen consistently in recent code but nothing mechanical checks it. Consumers treat ENFORCED as non-negotiable and OBSERVED as follow-unless-you-say-why; a rule with no label is a rule nobody can weigh.
- **Cite evidence.** Quote the config key or name the files the pattern was observed in.
- **Prescriptive verbs, bullet form, no essays.** "Use Zod for request validation."
- **Never invent.** No enforcement anywhere and not visible in recent code → not a rule. Undeterminable → `Not enforced — no convention found`, or an Open question.
- **Reference, don't restate.** Point at in-house packages and their docs rather than copying their internals; skip volatile facts (counts, inventories) that drift.
- **No editorializing.** Record what the codebase does; don't argue with it.


```md
# CODEBASE RULEBOOK

_Generated by superflow on YYYY-MM-DD. Run `/superflow:codebase-rulebook --refresh` to update._
_Sections marked <!-- human-edited --> are preserved on refresh._

_How to read this file: `[ENFORCED]` rules fail CI or a hook — non-negotiable. `[OBSERVED]` rules are the house style — follow unless you state why not. Silent on a case → follow the nearest existing pattern in the touched file; do not invent a rule._

## Project type & stack
- Language(s): ...
- Framework(s) + versions: ...
- Runtime version: ... (from .nvmrc, .python-version, go.mod, etc.)
- Package manager: ...
- Monorepo: yes/no (if yes, list workspace roots)
- Common commands:
  - install: ...
  - dev: ...
  - build: ...
  - test: ...
  - lint: ...
  - typecheck: ...

## File size & structure
- [ENFORCED|OBSERVED] Max lines per file: <number> (source: <config key or "observed convention">)
- Max lines per function: <number or "not enforced">
- Directory layout:
  - `src/components/` — ...
  - `src/pages/` or `app/` — ...
  - (etc.)
- File naming: <kebab-case | PascalCase | camelCase> for <category>
- Barrel exports: yes/no
- Default exports allowed: yes/no

## Linting & formatting
- Linter: <name + version>
- Formatter: <name + version>
- Notable enabled/disabled rules:
  - `<rule>`: <on|off|warn>
- Run on commit: yes/no (mechanism: husky/lefthook/pre-commit)
- Auto-fix on save: yes/no

## Type checking
- Strict mode: yes/no
- Key flags: `<flag>: <value>` ...
- Type generation (e.g., Prisma, openapi codegen): ...

## Tests
- Framework: ...
- Test file location: `<path or pattern>`
- Test naming: `<pattern>`
- Coverage threshold: <number>% (source: <config key or CI step>)
- What gets tested:
  - Units: ...
  - Integration: ...
  - E2E: ...
- Mocks/fixtures: ...
- New file → required tests: <yes — explain | no | only for X>
- Reference examples: `<path 1>`, `<path 2>`

## Components / UI
- Pattern: ...
- Styling: ...
- State management: ...
- Forms: ...
- Routing: ...
- Reference component: `<path>`

## API / endpoints
- Style: REST | RPC | GraphQL | tRPC
- Route layout: ...
- Request validation: ...
- Response format: ...
- Error format: ...
- Auth: ...
- Status code conventions: ...
- Reference endpoint: `<path>`

## Database / data layer
- ORM / query layer: ...
- Migration tool + dir: ...
- Naming: tables (snake_case | plural | ...), columns, indexes
- Soft-delete: yes/no
- Reference query / migration: `<path>`

## Assets / images
- Location: ...
- Formats: ...
- Optimization pipeline: ...
- Naming: ...

## Commits, PRs, branches
- Commit message format: ...
- Branch naming: ...
- PR template: yes/no (path: ...)

## CI / gates
- Provider: ...
- Required checks before merge: ...
- Coverage gate: ...
- Other gates: ...

## Custom conventions
- [ENFORCED|OBSERVED] ... (every rule in every section carries one of the two labels)

## Open questions
- [items the scan couldn't determine — user should answer here]
```

---

## How the rulebook is used afterward

Once `CODEBASE_RULEBOOK.md` exists at the repo root, every code change must consult it. This is reinforced by superflow (its session-start hook injects the reminder; the `superflow` skill carries the detail):

- Before any non-trivial code change, codezilla reads `CODEBASE_RULEBOOK.md` (or the relevant section).
- New files conform to the conventions documented there.
- Tests are written per the "Tests" section.
- API/component/asset conventions are followed.
- If a change would violate the rulebook, codezilla flags it and asks the user — either the rule needs an exception, or the rulebook needs an update.

`bughunter` also consults the rulebook to identify deviations during reviews.

---

## Rules

- The scan is read-only; the only file written is `CODEBASE_RULEBOOK.md`.
- Do not invent rules. If you can't determine a convention, say so in `Open questions`.
- Re-running with `--refresh` preserves human-edited sections (marked `<!-- human-edited -->`).
- `--refresh` keeps the `[ENFORCED]`/`[OBSERVED]` labels; a refresh that drops them is a defect.
- `--dry-run` prints what would be written without modifying the file.
- The rulebook is the source of truth for *what the codebase does today*. To change a convention, update both the code and the rulebook.
