export const meta = {
  name: 'council-vote',
  description: 'Multi-voice council for expensive-to-reverse decisions — independent schema-forced votes, no vote ever silently dropped',
  whenToUse: 'Launched by the `superflow:council` skill AFTER the human confirmed the decision text, the voice roster, and any external spend. Do not launch directly — the skill owns cost confirmation.',
  phases: [
    { title: 'Ground', detail: 'sherlock gathers code excerpts (skipped when not code-tied)' },
    { title: 'Voices', detail: 'personas + confirmed external CLIs vote independently, in parallel' },
    { title: 'Synthesize', detail: 'architect tallies, quotes disagreements verbatim, recommends' },
  ],
}

// args = {
//   decision:  string (required) — the restated decision under review
//   code_tied: boolean (default true) — spawn sherlock for code excerpts first
//   providers: array of 'codex' | 'gemini' | 'claude' — external voices the user
//              EXPLICITLY confirmed in the /council wrapper. Empty/omitted = persona-only.
//              The wrapper owns cost confirmation; this script never adds a provider.
//   hints:     optional array of file paths sherlock should start from
// }
//
// Contract with the `superflow:council` skill (the wrapper):
// - Human confirmation of decision + external spend happens BEFORE launch, in the wrapper.
// - Sanitization is enforced HERE, per external voice, abort-on-hit → abstain (never a
//   silent drop, never "best-effort parse then discard").
// - The wrapper renders `synthesis` verbatim and may show the `votes` table.

// The harness may deliver `args` as a JSON-encoded STRING rather than an object (observed
// 2026-08-11: two consecutive launches died instantly on "args.decision is required" with a
// perfectly well-formed args object at the call site). Normalize once, here, instead of
// making every reader defensive — a council run that dies on arg plumbing burns the whole
// setup cost (roster confirmation, spend approval) for nothing.
const _args = (typeof args === 'string') ? JSON.parse(args) : args
const decision = (_args && _args.decision || '').trim()
if (!decision) throw new Error('council: args.decision is required')
const codeTied = !_args || _args.code_tied !== false
const asList = (x) => Array.isArray(x) ? x : x ? [x] : []
const ALLOWED_PROVIDERS = ['codex', 'gemini', 'claude']
const providers = asList(_args && _args.providers)
for (const p of providers) {
  if (!ALLOWED_PROVIDERS.includes(p)) throw new Error(`council: unknown provider "${p}" — allowed: ${ALLOWED_PROVIDERS.join(', ')}. Only human-confirmed providers may be passed.`)
}
const hints = asList(_args && _args.hints)

const VOTE = {
  type: 'object',
  required: ['verdict', 'risks', 'strongest_alternative', 'reasoning'],
  properties: {
    verdict: { type: 'string', enum: ['proceed', 'proceed-with-changes', 'rethink', 'abstain'] },
    risks: { type: 'array', items: { type: 'string' }, maxItems: 3, description: 'Top risks, most severe first' },
    strongest_alternative: { type: 'string', description: 'The best alternative to the proposal, one sentence' },
    reasoning: { type: 'string', description: 'The voice\'s core argument. For an abstain: WHY. CLI failure/unparseable → include a raw excerpt of what the CLI returned. Sanitization abort → the pattern CLASS only (e.g. "PEM block in excerpts"), NEVER any excerpt of the constructed prompt.' },
    sent_summary: { type: 'string', description: 'External voices only — one line for post-run audit: what was sent to the vendor (files + total excerpt lines), or "nothing sent" on abort. Persona voices omit this.' },
  },
}

const GROUND = {
  type: 'object',
  required: ['summary', 'excerpts'],
  properties: {
    summary: { type: 'string', description: 'What the code says that bears on this decision, 150-400 words' },
    excerpts: { type: 'string', description: 'The most relevant verbatim code excerpts, each headed by path:line, 200 lines TOTAL max' },
    files: { type: 'array', items: { type: 'string' } },
  },
}

phase('Ground')
let ground = null
if (codeTied) {
  ground = await agent(`Decision under council review: ${decision}

Gather the code context the council voices need to judge this decision well. ${hints.length ? 'Start from these paths: ' + hints.join(', ') + '.' : ''}
Read-only — inspect, never modify. Use graphify for structure lookups if available (fall back to glob/grep silently; never block on it). Skip nested worktree copies of this repo and vendored/generated trees.
Keep excerpts SHARP: only lines that change the decision, 200 lines total max, each block headed by its path:line.
NEVER excerpt secret material — no .env* contents, keys/tokens/passwords, PEM blocks, or connection strings carrying credentials; if such a line is load-bearing, replace the value with [redacted].`,
    { agentType: 'superflow:sherlock', label: 'ground:sherlock', phase: 'Ground', schema: GROUND })
} else {
  log('Not code-tied — skipping sherlock grounding')
}

const excerpts = ground ? `\n\nInvestigator summary: ${ground.summary}\n\nRelevant code excerpts (gathered by a read-only investigator):\n${ground.excerpts}` : ''

// The exact voice prompt format ported from the prose council skill.
const votePrompt = (lens) => `Decision under review: ${decision}
${excerpts}

You are ONE independent voice in a multi-voice council. Your lens: ${lens}
Steel-man the proposal first, then judge it. Do not average yourself toward a middle verdict — if you think rethink, say rethink. Risks: at most 3, most severe first.`

const SANITIZE = `SANITIZATION (non-negotiable, runs BEFORE anything is sent to the external CLI):
- never include .env* file contents
- redact strings matching secret patterns: sk-*, AKIA*, ghp_*, xox[bpars]-*, xoxe-*, xapp-*, PEM private-key blocks (-----BEGIN ... PRIVATE KEY-----), connection strings carrying credentials (scheme://user:password@host), or any high-entropy string near the words key|token|secret|password
- redact URLs carrying tokens/signatures
- never include content from /etc/, ~/.ssh/, ~/.aws/, /private/
If ANY pattern hits inside the prompt you constructed: DO NOT SEND. Return verdict "abstain" with reasoning "sanitization abort: <pattern class> found" — do not include the secret itself.`

phase('Voices')
const externalVoice = (provider) => agent(`You relay one council vote through the external CLI "${provider}". Follow exactly:

1. Read the provider config: try \`cat .claude/superflow.json\` (repo-local) first, then \`cat ~/.claude/superflow.json\` — first file that exists wins. Find providers.${provider} (command + model). If the CLI is missing (\`command -v\` fails), return verdict "abstain", reasoning "CLI not installed".
2. Construct this prompt VERBATIM (fill the placeholders):
---
Decision under review: ${decision}
${excerpts ? '[code excerpts identical to the block below]' + excerpts : '(no code excerpts)'}

You are one voice in a multi-model council. Respond in this exact format:

## Verdict
proceed / proceed-with-changes / rethink

## Top 3 risks
1.
2.
3.

## Strongest alternative
...

## One-line reasoning
...

Do not preamble. Do not explain that you are an AI. Just respond.
---
3. ${SANITIZE}
4. Write the sanitized prompt to a private temp file: \`FILE=$(mktemp)\` then \`chmod 600 "$FILE"\`. Run the CLI from an EMPTY temp directory (\`cd "$(mktemp -d)"\`) so an agentic CLI cannot wander this repo on its own — the vendor must see ONLY the sanitized prompt; where the CLI supports it, disable its file tools / use its read-only sandbox flag. Prefer stdin over argv (e.g. \`codex exec - < "$FILE"\`; fall back to \`"$(cat "$FILE")"\` only if stdin is unsupported), append the configured --model/-m flag, and if the CLI rejects the model name retry ONCE without the flag. Up to 3 minutes; then \`rm -f "$FILE"\` — also on failure.
5. Parse the CLI's stdout into your structured return, mapping verdict wording onto the enum exactly ("proceed with changes" → "proceed-with-changes"). If the output ignores the format, EXTRACT the verdict/risks as best you can; if extraction is impossible, return verdict "abstain" and put the first ~40 lines of raw output in reasoning. A vote is NEVER silently dropped — an abstain with the raw text always reaches synthesis.
6. Always fill sent_summary: the file paths + total excerpt line count actually sent, or "nothing sent" on any abort.`,
  { label: `voice:external-${provider}`, phase: 'Voices', schema: VOTE })
    .then((v) => v && { voice: `external:${provider}`, ...v })

const voices = await parallel([
  () => agent(votePrompt('Technical Evaluator — architecture, correctness, long-term tradeoffs, scaling. Inspect-and-critique only; read the repo if you need ground truth, never modify it.'),
    { agentType: 'superflow:architect', label: 'voice:architect', phase: 'Voices', schema: VOTE })
    .then((v) => v && { voice: 'architect (Technical Evaluator)', ...v }),
  () => agent(votePrompt('Failure modes — how this decision breaks in production: edge cases, regressions, operational risk, the bug classes it invites. Inspect only; never modify.'),
    { agentType: 'superflow:bughunter', label: 'voice:bughunter', phase: 'Voices', schema: VOTE })
    .then((v) => v && { voice: 'bughunter (failure modes)', ...v }),
  () => agent(votePrompt('Implementation Guide — shippability: concrete implementation steps, scope check (too small / right-sized / overbuilt), complexity hotspots, honest time-to-ship. Inspect only.'),
    { agentType: 'superflow:codezilla', label: 'voice:implementation-guide', phase: 'Voices', schema: VOTE })
    .then((v) => v && { voice: 'Implementation Guide', ...v }),
  () => agent(votePrompt('Product — user value, scope, and what this decision costs the people who use the thing. Is the problem worth solving at all, and is this the smallest thing that solves it? Inspect only.'),
    { agentType: 'superflow:bossbaby', label: 'voice:bossbaby', phase: 'Voices', schema: VOTE })
    .then((v) => v && { voice: 'bossbaby (product value)', ...v }),
  ...providers.map((p) => () => externalVoice(p)),
])

const votes = voices.filter(Boolean)
const lost = voices.length - votes.length
if (lost > 0) log(`${lost} voice(s) died before returning — reported below, not hidden`)
log(`Votes in: ${votes.map((v) => `${v.voice}=${v.verdict}`).join(' · ')}`)

phase('Synthesize')
const synthesis = await agent(`You chair the council. Decision under review: ${decision}
${excerpts}

The independent votes, verbatim (JSON):
${JSON.stringify(votes, null, 1)}
${lost > 0 ? `\nNOTE: ${lost} voice(s) failed to return at all — state this in "Voices heard".` : ''}

Produce the council synthesis in EXACTLY this markdown shape:

## Council

### Decision under review
### Voices heard            (every voice above, including abstains and failures, with lens labels)
### Strongest case for proceeding
### Strongest case against
### Tally                   (proceed / proceed-with-changes / rethink counts; abstains listed, never counted as votes)
### Where the voices agree
### Where the voices disagree   (the interesting part — QUOTE each side verbatim from their reasoning; never average a disagreement away)
### Top 3 risks across all voices
### Strongest alternative on the table
### Recommendation          (Verdict / Why / If proceeding, change first / If rethinking, try instead / What would change the verdict)

Rules: the final verdict is YOUR call, not a vote count — if you diverge from the majority, explain why. An abstain's raw output may still contain signal; read it before discarding.`,
  { agentType: 'superflow:architect', label: 'synthesize', phase: 'Synthesize', effort: 'high' })

return { synthesis, votes }
