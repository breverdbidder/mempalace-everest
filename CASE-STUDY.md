# Memory System Adoption — Case Study

## Summary

On 2026-04-22, Everest Capital USA adopted a three-layer memory stack for Claude Code across its agent chain (BidDeed, ZoneWise, brevard-doors, property360, kenstrekt, protection-partners, everest-portfolio, everest-capital). This document validates the value added by each repository and explains why the composition produces more than the sum of its parts.

All metrics marked [V] are VERIFIED from the adoption transaction (GitHub API 201/202 responses, tree API verification, pg_net + http extension commits). Metrics marked [P] are PROJECTED and pending real-world measurement. Metrics marked [U] are UNTESTED claims from upstream maintainers.

---

## Repo 1 — MemPalace/mempalace → breverdbidder/mempalace-everest

### What it is
Local-first AI memory system with a 4-layer wake-up stack, 20+ MCP tools, and hooks for Stop + PreCompact events in Claude Code. Verbatim storage (no summarization). Knowledge graph in SQLite with temporal validity windows.

### Everest-specific value

```yaml
context_economics:
  before:
    pattern: CLAUDE.md ballooning to thousands of lines loaded every session
    cost_per_session: ~20000 tokens just to orient Claude [P]
    session_overhead_daily: ~200000 tokens across 10 sessions [P]
  after:
    pattern: L0 identity (100 tok) + L1 essential story (500-800 tok) + L2 on-demand + L3 deep search
    cost_per_session_wake_up: 600-900 tokens [U from upstream]
    context_freed: 95pct+ for actual work [U from upstream]

compaction_survival:
  before: mid-session context loss when compaction triggered → rework same decisions
  after: PreCompact hook auto-injects identity + essential story into compacted context
  impact: directly solves mem:compaction_survival gap Mark flagged in the source video

tenant_context_separation:
  before: 8 tenants cross-contaminate single Claude context window
  after: one wing per tenant (EverestCapital, BidDeed, ZoneWise, BrevardDoors, Property360, Kenstrekt, ProtectionPartners, EverestPortfolio)
  config_location: config/everest-wings.yaml [V committed sha 51da0a85]

specific_use_cases:
  625_ocean_street:
    problem: Jun 25 2026 FDEP CCCL permit deadline, 100+ decisions across Clayton Bennett, Shinskie, Mariam, CRL Cielo, Zone 1 scope, design corrections
    memory_query_pattern: "what did Shinskie verify about Zone 1 windscreen measurements R1?"
    before: grep through chat history, risk stale data
    after: verbatim lookup with temporal validity window auto-flags stale context [U from upstream]
  biddeed_ml:
    problem: Anchor Bidder Counter-Proxy (82.6pct acc, 0.8832 AUC) has specific terminology — PlaintiffSubclass, CertHolderSubclass, deed_to_cert_holder — that no Claude session remembers without re-explanation
    after: terminology lives in BidDeed wing identity layer
  zonewise_data:
    problem: zw_parcels SSOT 342K rows 77 cols 23 idx 3 RPCs — column semantics forgotten between sessions
    after: ZoneWise wing drawer stores schema semantics once, queried on demand

hooks_value:
  verified_shipping:
    - .claude-plugin/hooks-windows/hooks.json [V sha 9433c5d1]
    - mempal-stop-hook.ps1 [V sha 69902282]
    - mempal-precompact-hook.ps1 [V sha eb373650]
  windows_native: wraps upstream bash hooks for Win10 PowerShell per mem:windows_only

cost:
  runtime: $0/month (local ChromaDB, no API calls) [V — design confirmed from upstream source inspection]
  delta_addition: sentence-transformers ~90MB one-time download [P]
  passes: mem:cost_discipline
```

### Risks and open questions

- Post-DELTA LongMemEval benchmark is [U]. Upstream claims 96.6pct raw / 100pct hybrid. We have not reproduced these numbers post-delta. The `91` score in repo_evaluations is a rubric estimate, not a benchmark run.
- Hook firing on Ariel's Win10 box is [U] until installed and run.
- ChromaDB has a 464 open-issue count on upstream — not a blocker, but worth monitoring.

---

## Repo 2 — heyitsnoah/claudesidian → breverdbidder/claudesidian-everest

### What it is
Pre-configured Obsidian vault structure for Claude Code with 20 agent skills covering reusable workflow patterns (thinking-partner, daily-review, systematic-debugging, weekly-synthesis, inbox-processor, pragmatic-review, research-assistant, pull-request, release, and 11 more).

### Everest-specific value

```yaml
skills_donor_economics:
  skills_adopted: 20
  time_saved_vs_authoring: estimated 15-20 hours at solo-founder rate [P]
  licensing: MIT permissive, no NOTICE required, no royalty obligations

highest_value_skills_for_everest:
  thinking-partner:
    problem: Ariel constantly has to redirect Claude from premature solutioning back to exploration mode
    value: skill enforces "ask before answering" pattern automatically
    ties_to: mem:session_rules 90min cap — more productive exploration per session
  daily-review:
    problem: mem:session_rules says max 90min per chat, max 3 chats per task
    value: daily-review skill produces structured close-out that feeds MemPalace L1 Essential Story
  weekly-synthesis:
    problem: 37 open tasks, pattern recognition across them is hard without summary
    value: synthesizes week into cross-tenant insights stored in halls/decisions
  systematic-debugging:
    problem: Hetzner runner failed in 15 sec today with opaque zip-logs — classic debugging blind spot
    value: forces investigation skeleton before pattern-matching to first hypothesis
  inbox-processor:
    problem: 00_Inbox scratch notes pile up unconverted
    value: converts raw inbox into structured MemPalace drawers with entity tags
  pragmatic-review:
    problem: 625 Ocean permit CD set review with Shinskie corrections
    value: review skeleton catches what Ariel misses on tired passes
  research-assistant:
    problem: REPOEVAL depth pressure under 90min cap
    value: structured deep-dive pattern produces the extrep_evaluations quality dossiers

para_decision:
  upstream_structure: PARA (00_Inbox, 01_Projects, 02_Areas, 03_Resources, 04_Archive, 05_Attachments)
  everest_existing: 000-700 structure in everest-vault
  resolution: fork inherits PARA folders from upstream but install script symlinks only skills into everest-vault/.agents/skills/
  conflict: none — PARA coexists but is not used
```

### Risks

- Skills are markdown + prompt patterns, not code. Quality depends on how Claude Code interprets them. Most are well-tested by the upstream community (2.2K stars).
- Low validation score (12/20) reflects absence of quantitative benchmarks — this is a pattern donor, not a measured system.

---

## Repo 3 — mem0ai/mem0 → DELTA into mempalace-everest

### What it is
Universal memory layer for AI agents with hybrid data store (vector + KV + graph). 53K stars, Apache-2.0 licensed, benchmarked at +26pct accuracy over OpenAI Memory on LOCOMO, under 7K tokens per retrieval call [U from upstream].

### Why DELTA and not ADOPT

```yaml
mem0_adopt_breach:
  default_config: requires LLM calls per add and search (gpt-4.1-nano default)
  cost_impact: at Everest session volume (10 sessions/day), ~$15-40/month in API calls [P]
  verdict: breaches mem:cost_discipline ($10 session max, target $100/mo beyond Max subscription)

mem0_delta_advantage:
  lifted_files: 3
    - mempalace/reranker/base.py [V sha b4f7b04c]
    - mempalace/reranker/sentence_transformer_reranker.py [V sha ba06d2c4]
    - mempalace/entity/extraction.py [V sha aa93e328]
  composition_layer:
    - mempalace/reranker_bridge.py [V sha c4ae6992] — new, Everest-authored
  loc_ratio: 571 LOC lifted vs ~50K LOC in full mem0 = 1.1pct surface for 80pct of retrieval-quality value [P rubric]
  cost: $0/month (sentence-transformers runs local)
  apache_compliance: NOTICE file shipped [V sha adc09b77]
```

### What the DELTA actually buys

```yaml
retrieval_quality:
  mempalace_alone:
    signal: ChromaDB cosine similarity on embeddings
    limitation: recall degrades on queries with proper-noun density
  with_delta:
    signals: cosine + sentence-transformer rerank + entity overlap boost
    specific_win: query "what did Shinskie say about Zone 1" boosted by entity match on "Shinskie" and "Zone 1" beyond pure vector similarity
    benchmark: UNTESTED post-delta; upstream mem0 reports +26pct on LOCOMO for full stack [U]

use_case_zonewise_rag:
  future: chat.zonewise.ai Dify RAG layer planned per userMemories
  pattern: same rerank+entity_boost port applies to zw_parcels queries
  reuse: the DELTA surface is not locked to MemPalace; it is a reusable retrieval enhancement for the whole Everest stack
```

---

## Compound value — why the three together beat any one alone

```yaml
stack_composition:
  container: MemPalace provides wings/rooms/drawers + temporal knowledge graph
  intelligence: mem0 DELTA provides rerank + entity signals at $0 runtime
  orchestration: claudesidian skills tell Claude WHEN to read/write memory and HOW to structure it

multiplier_effect:
  example:
    trigger: session starts
    sequence:
      - PreCompact hook (MemPalace) injects L0+L1
      - thinking-partner skill (claudesidian) activates if query is exploratory
      - L3 search fires on topic mention, rerank_drawer_hits (mem0 DELTA) boosts top hits
      - daily-review skill (claudesidian) closes session into structured drawers
  outcome: each repo alone gives maybe 30pct of the lift; composed they give 80pct+ [P rubric]
```

---

## Business impact for Everest

```yaml
session_longevity:
  rule_context: mem:session_rules max 90min per chat, max 3 chats per task, not shipped in 90min triggers SUMMIT dispatch
  hypothesis: memory-aware sessions reduce re-context-load by 25-35pct [P]
  expected: more tasks shipped per session before SUMMIT dispatch threshold triggers
  measurement_plan: track tasks_shipped per 90min chat pre/post adoption over 2 weeks

open_tasks_pressure:
  current: 37 open tasks acknowledged this chat session
  mechanism: new chat = re-explain previous chat = lose time = drift
  after: L0+L1 auto-inject means new chat knows project state in 900 tokens

eg14_audit_trail:
  rule_context: mem:eg14_gate has 14 points with critical 1/6/8/11, eg14_runs table
  value: MemPalace knowledge graph stores EG14 decisions with temporal validity
  benefit: when honesty V3 audit checks a past claim, the knowledge graph has the source

tenant_quality:
  before: 8 tenants share one context window, cross-contamination on advice
  after: wing-scoped memory per tenant
  specific_win: advice about Mariam brokerage (Property360) no longer leaks BidDeed assumptions

agent_chain_alignment:
  rule_context: mem:agent_chain tenants + forks list
  new_addition: mempalace-everest + claudesidian-everest join crewai-everest, marketingskills, ai-marketing-skills as MIT permissive forks
  ecosystem_story: 5 forks now validate the Agentic AI ecosystem positioning (not SaaS) for investor framing
```

---

## What this adoption does NOT deliver (honest)

```yaml
not_delivered_this_adoption:
  - benchmark_run_post_delta: UNTESTED, 91 score is rubric not LongMemEval
  - windows_hook_firing: UNTESTED until Ariel installs on Win10
  - sentence_transformers_install: UNTESTED
  - performance_on_ariel_data: UNTESTED — all benchmarks are upstream generic
  - hetzner_runner_fix: SEPARATE — 87.99.129.125 failed step 6 today, unrelated to memory stack

follow_up_work:
  - run LongMemEval post-delta benchmark locally
  - install + run 1 week of sessions, measure re-context overhead reduction
  - diagnose Hetzner runner failure (affects mem:dispatch_arch)
  - decide claudesidian PARA strip (current: left intact, skills-donor only)
```

---

## Investor narrative framing

For the Agentic AI ecosystem positioning:

```yaml
ip_discipline_demonstrated:
  - three-tier adoption hierarchy (full ADOPT, partial ADOPT, surgical DELTA)
  - license compliance: MIT permissive preserved, Apache-2.0 NOTICE shipped
  - zero copyleft poison: all three repos pass mem:license_poison t4 PERMISSIVE
  - fork discipline: breverdbidder org now has 5 MIT permissive forks validating IP moat

operational_leverage:
  - memory system is the spine of Ariel-as-product-owner working 10 hrs/day across tenants
  - wing-per-tenant means adding a 9th venture (future) is additive, not disruptive
  - cost profile: $0/month runtime on a foundational capability layer

defensibility:
  - MemPalace knowledge graph temporal validity + honesty V3 markers = defensible claims audit trail
  - tenant wings + AAAK compression + reranker DELTA = non-trivial to replicate
```

---

## Writebacks

```yaml
supabase:
  repo_evaluations: 5 rows (87ebf2c0, fcad9928, 84b0eb88, d86e3f03, c16f945c)
  summit_chat_dispatch: 3e24ee8b-0b32-4fd1-957d-932f4844d65f state=closed marker=PUSHED
  honesty_violations: b82565be HIGH tag=VERIFIED (logged 2-turn-prior ghost-success framing)
  github_commits: 13 (all HTTP 201)

github:
  breverdbidder/mempalace-everest: 13 new files on develop branch
  breverdbidder/claudesidian-everest: EVEREST-FORK.md on main

citations:
  mem:rule1 mem:rule2 mem:rule3 mem:rule4
  mem:agent_chain.tenants mem:cred_hygiene mem:cost_discipline
  mem:honesty_protocol V3 mem:license_poison mem:windows_only
  mem:direct_gh_push mem:yaml_primacy V2 mem:compaction_survival
```
