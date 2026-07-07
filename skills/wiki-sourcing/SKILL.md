---
name: wiki-sourcing
description: >
  The sourcing and verification doctrine for the wiki — the rules that decide when a claim needs a
  fetched source, when to hedge, and when to refuse to write something as fact. Every skill that
  WRITES to the wiki (wiki-ingest, wiki-research, wiki-update, data-ingest, ingest-url,
  wiki-synthesize, the history-ingest skills) must apply this before committing a claim. Read this
  when writing any note that states a fact, or when the user asks how the wiki decides what to trust.
---

# Wiki Sourcing — What the Wiki Is Allowed to State as Fact

A wiki is only as trustworthy as its weakest claim. The failure mode is not "missing information" —
it's a **confident false fact** copied from a second-hand summary and never checked. This doctrine
exists to make that failure impossible by default. It is the single rule that separates an
LLM-maintained wiki from a pile of unverified notes.

Apply it to **every claim you write or revise**, regardless of which skill you're running.

---

## 1. The gate is the claim type, NOT the note type

Do not decide sourcing by the note's `category`. Decide it per **statement**:

| Claim type | Example | Rule |
|---|---|---|
| **Falsifiable external fact** | a number, date, price, version, benchmark, statistic, or a named attribution ("X said/built Y") | **Must** carry a *fetched* source: a URL you actually retrieved this session, plus an `(as of YYYY-MM, source)` marker. If you cannot fetch a confirming source right now → write it as `[unverified]` or hedge ("reportedly", "~"). **Never** as a bare confident fact. |
| **Judgement / prediction / advice** | "X will win", "the better approach is Y" | Label it as a judgement with date + basis: `(assessment, as of YYYY-MM, based on …)`. Don't launder an opinion into a settled law. |
| **Definition / principle / framework** | "a harness is the scaffolding around a model", "REST is stateless" | No source needed — it's conceptual structure, not a falsifiable event. |

Hard rule: this triggers on the **claim, not the page**. A concept or insight note that smuggles in a
hard number ("fails 88% of the time", "3× faster") must source or hedge that number exactly like a
reference note would.

## 2. A summary is not a source

The most common way a false fact enters a wiki: it's copied from a digest, a search-result snippet,
another LLM's answer, or someone's tweet — all **second-hand**.

- A digest / snippet / model answer is a *lead*, not a source. Trace it to the **primary** (or a
  secondary you actually fetch) before asserting.
- If you can only find the claim restated in aggregators, that is a signal to **hedge**, not to assert.
- The one class of fact worth this friction is exactly the falsifiable kind in §1. Spend it there.

## 3. Three states — and degradation is not refutation

Every falsifiable claim is in exactly one state. Keep them distinct:

- **Verified** — you fetched a source this session that confirms both the substance and the date.
  → Assert it, with `(as of YYYY-MM, source)`.
- **Unverifiable** — you could not fetch a confirming source right now (paywall, 403, timeout, only a
  snippet). → Write `[unverified]` / hedge, and **keep the claim in the note.** It may well be true;
  you just can't stand behind it yet.
- **Refuted** — a source actually loaded and *contradicts* it. → Don't write it, or correct it.

**A fetch failure is a tooling degradation, not evidence the claim is false.** Never delete or deny a
claim just because the fetcher failed — that silently destroys real knowledge. Narrow every "no" to
the *refuted* case; everything unfetchable is `[unverified]`, never a deletion.

## 4. Don't cave to pressure — only sources move a claim

An LLM that both writes and checks its own claims shares its own blind spots and tends to fold when
pushed. Guard against it:

- **Attack the premise, not just the wording.** Ask "is this even the right claim / unit /
  comparison?", not only "is the number formatted right?".
- **Pushback is not evidence.** "That sounds wrong" or the user insisting does **not** flip a
  **Verified** claim to **Refuted** — only a *fetched contradicting source* does. Persistence ≠ proof.
- **Don't rubber-stamp your own output.** Before asserting a falsifiable claim, try once to *break* it
  (look for a source that contradicts it). Can't break it AND a source confirms it → Verified. Can't
  confirm it → `[unverified]`, never a confident assert.

## 5. How this shows up on the page

- Verified fact: `... rose to 128k tokens (as of 2025-03, https://…).`
- Unverifiable: `... reportedly ~128k tokens [unverified].`
- Judgement: `Long-context beats RAG for this case (assessment, as of 2025-03, based on the two notes below).`
- Inference you drew yourself (not from any source): keep using the existing provenance markers —
  `^[inferred]` / `^[ambiguous]` and the `provenance:` frontmatter block (see `wiki-ingest`).
  This doctrine governs *external* facts; those markers govern *your own* interpolation. Use both.

## 6. Minimum bar before you commit a write

For each new/changed claim, in order:

1. Classify it (§1). Definition/principle → write it. Judgement → label it. Falsifiable → continue.
2. Do you have a fetched confirming source this session? Yes → assert with `(as of …, src)`.
3. No → is it merely restated in a digest/snippet? Then it's second-hand (§2) → `[unverified]`/hedge.
4. Did a source actively contradict it? → refute/correct (§3). Otherwise keep it, hedged.
5. Never let user pressure alone downgrade a Verified claim (§4).

If you followed these five steps, the wiki stays trustworthy no matter which skill did the writing.

---

## Note for skill authors

This is a **doctrine skill** — it has no standalone action. The write-path skills reference it in their
Quality Checklists. When you add a new skill that creates or edits notes, add one line to its checklist:
`[ ] Applied the wiki-sourcing gate to every falsifiable claim`.

> Prior art (not invented here): draft-then-verify-against-primary-source is the standard pattern for
> agent-maintained knowledge bases — e.g. Google Cloud's Open Knowledge Framework enriches each drafted
> concept with fetched citations before the knowledge is trusted. This skill is that pattern, stated as
> a rule.
