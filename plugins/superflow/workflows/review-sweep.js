export const meta = {
  name: 'review-sweep',
  description: 'Epic-gate review: parallel bughunter lenses over a partitioned diff, findings adversarially verified into CONFIRMED/PLAUSIBLE tiers',
  whenToUse: 'Epic release gates and diffs >~5 files ONLY (a run costs 300k-1M tokens). Small PRs get a plain bughunter pass. After fixing findings, re-run scoped: args.scope = the touched files. The fix loop lives in the main session — run, fix in chat, re-run scoped.',
  phases: [
    { title: 'Partition', detail: 'diff + blast radius → 2-6 coherent slices (graphify, grep fallback)' },
    { title: 'Sweep', detail: 'one bughunter per slice, rulebook-aware' },
    { title: 'Verify', detail: 'one skeptic per finding — refute or confirm, never repro-or-drop' },
  ],
}

// args = {
//   base:  string (default: the remote's default branch via origin/HEAD, else main) — reviews base...HEAD
//   scope: optional array of paths — overrides the diff; use for the post-fix re-run
//   note:  optional string — context for reviewers ("this is the cage cutover epic", etc.)
// }
//
// Findings come back in two tiers, both reported:
//   CONFIRMED — survived a dedicated refuter with evidence. Act on these.
//   PLAUSIBLE — the skeptic could neither refute nor confirm (integration-seam bugs land
//               here — the class that costs the most in production — so they are NEVER
//               dropped for want of a repro).

// `args` arrives verbatim; a caller that JSON-encodes it hands us a string. Normalize once so
// a scoped re-run passed as a string does not silently review the full diff.
const _args = (typeof args === 'string') ? JSON.parse(args) : (args || {})
const base = _args.base || null
const baseCmd = base ? `git diff --name-only ${base}...HEAD`
  : 'git diff --name-only "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main)...HEAD"'
const baseLabel = base || 'origin/HEAD (default branch)'
const rawScope = _args.scope
const scope = Array.isArray(rawScope) ? rawScope : rawScope ? [rawScope] : null
const note = _args.note || ''

const PARTITIONS = {
  type: 'object',
  required: ['partitions'],
  properties: {
    partitions: {
      type: 'array',
      maxItems: 6,
      items: {
        type: 'object',
        required: ['name', 'files', 'rationale'],
        properties: {
          name: { type: 'string' },
          files: { type: 'array', items: { type: 'string' }, description: 'Changed files plus their blast-radius neighbors' },
          rationale: { type: 'string', description: 'Why these files form one coherent review slice' },
        },
      },
    },
    left_out: { type: 'array', items: { type: 'string' }, description: 'Changed files NOT covered by any partition (must be empty or explained)' },
    empty_diff: { type: 'boolean', description: 'True when there is nothing to review' },
  },
}

const FINDINGS = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'line', 'summary', 'severity', 'evidence'],
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          summary: { type: 'string', description: 'One sentence: the defect, not the fix' },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          evidence: { type: 'string', description: 'The code path / inputs that make this a bug' },
          fix_sketch: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  required: ['tier', 'evidence'],
  properties: {
    tier: { type: 'string', enum: ['CONFIRMED', 'PLAUSIBLE', 'REFUTED'] },
    evidence: { type: 'string', description: 'For REFUTED: the concrete reason it cannot happen. For CONFIRMED: the trace that shows it does. PLAUSIBLE: what is missing to decide.' },
  },
}

phase('Partition')
const plan = await agent(`Partition this repo's pending changes into coherent review slices.

${scope ? `SCOPED RE-RUN — review exactly these paths (a fix round just touched them): ${scope.join(', ')}. Skip the git diff.`
        : `Run \`${baseCmd}\` (and \`git status --porcelain\` for uncommitted work) to list changed files.`}
For each changed file, find its blast radius: try \`graphify affected <file>\` first; if the CLI or graph is missing, fall back to grep for importers/references — never block on graphify. Skip generated/vendored artifacts (node_modules/, dist/, build/, graphify-out/) and any nested worktree copies of this repo.
Group changed files + blast-radius neighbors into 2-6 slices a single reviewer can hold coherently (by subsystem/seam, not by count). EVERY changed file must land in a slice or be listed in left_out with a reason. If there are no changes at all, return empty_diff: true.
Read-only — inspect, never modify.${note ? ` Context: ${note}` : ''}`,
  { label: 'partition', phase: 'Partition', schema: PARTITIONS })

if (!plan || plan.empty_diff || !(plan.partitions || []).length) {
  log('Nothing to review — empty diff')
  return { confirmed: [], plausible: [], refuted_count: 0, unverified_count: 0, dead_slices: [], left_out: [], partitions: [], note: 'empty diff — nothing reviewed' }
}
if ((plan.left_out || []).length) log(`NOT covered by any slice: ${plan.left_out.join(', ')}`)
log(`Partitions: ${plan.partitions.map((p) => `${p.name} (${p.files.length} files)`).join(' · ')}`)

phase('Sweep')
const swept = await parallel(plan.partitions.map((p) => () =>
  agent(`Adversarial review of ONE slice of this repo's pending changes (diff base: ${baseLabel}).

Your slice — ${p.name}: ${p.rationale}
Files (changed + blast radius): ${p.files.join(', ')}
${note ? `Epic context: ${note}\n` : ''}
Hunt for real defects: logic errors, broken edge cases, regressions in the blast radius, integration-seam mismatches (caller/callee drift, schema drift, lifecycle races), and deviations from CODEBASE_RULEBOOK.md (read the relevant sections first — flag deviations, never invent rules that are not in it).
Read-only — inspect, never modify. graphify is best-effort; grep works too. Report only defects you can point at code for — no style nits, no speculation without a code path. An empty findings list is a valid, good answer.`,
    { agentType: 'superflow:bughunter', label: `sweep:${p.name}`, phase: 'Sweep', schema: FINDINGS })))

const deadSlices = plan.partitions.filter((_, i) => !swept[i]).map((p) => p.name)
if (deadSlices.length) log(`${deadSlices.length} slice(s) returned nothing (agent died) — NOT reviewed: ${deadSlices.join(', ')}`)
const all = swept.filter(Boolean).flatMap((r) => r.findings || [])
const seen = new Set()
const unique = all.filter((f) => {
  const key = `${f.file}:${f.line || 0}:${(f.summary || '').toLowerCase()}`
  if (seen.has(key)) return false
  seen.add(key)
  return true
})
log(`Findings: ${all.length} raw → ${unique.length} after dedupe`)
if (!unique.length) return { confirmed: [], plausible: [], refuted_count: 0, unverified_count: 0, dead_slices: deadSlices, left_out: plan.left_out || [], partitions: plan.partitions.map((p) => p.name), note: deadSlices.length ? 'no findings, but some slices were not reviewed' : 'no findings' }

phase('Verify')
const verified = await parallel(unique.map((f) => () =>
  agent(`Adversarially verify ONE review finding. Try hard to REFUTE it by reading the actual code — do not trust the reporter.

Finding: ${f.summary}
Location: ${f.file}:${f.line}
Claimed evidence: ${f.evidence}

Read ${f.file} and every caller/callee the claim depends on. Verdicts:
- REFUTED: you can show concretely why the failure cannot happen (guard exists, path unreachable, types prevent it). Cite the line.
- CONFIRMED: you traced the failing path end-to-end. Cite the trace.
- PLAUSIBLE: you can neither refute nor fully trace it (cross-process/integration seams often land here). Say exactly what is undecidable from the code alone.
Never refute for lack of a reproduction alone — absence of repro is not absence of bug. Read-only.`,
    { label: `verify:${f.file.split('/').pop()}:${f.line}`, phase: 'Verify', schema: VERDICT })
    .then((v) => v && { ...f, tier: v.tier, verify_evidence: v.evidence })))

const kept = verified.filter(Boolean)
const unverified = unique.filter((_, i) => !verified[i])
if (unverified.length) log(`${unverified.length} finding(s) lost their verifier — returned as unverified, not dropped`)
const rank = { high: 0, medium: 1, low: 2 }
const bySeverity = (a, b) => (rank[a.severity] ?? 3) - (rank[b.severity] ?? 3)
const confirmed = kept.filter((f) => f.tier === 'CONFIRMED').sort(bySeverity)
const plausible = kept.filter((f) => f.tier === 'PLAUSIBLE').sort(bySeverity)
const refuted = kept.filter((f) => f.tier === 'REFUTED')
log(`Verified: ${confirmed.length} CONFIRMED · ${plausible.length} PLAUSIBLE · ${refuted.length} refuted · ${unverified.length} unverified`)

return {
  confirmed,
  plausible,
  unverified,
  refuted_count: refuted.length,
  unverified_count: unverified.length,
  dead_slices: deadSlices,
  left_out: plan.left_out || [],
  partitions: plan.partitions.map((p) => p.name),
  note: deadSlices.length ? `slices not reviewed: ${deadSlices.join(', ')}` : '',
}
