# Prompts — dev-weown-anythingllm

This directory is the committed source of truth for this instance's two
AnythingLLM workspace system prompts, per
[docs/design/DESIGN-client-intake-and-agent-workflows.md](../../../docs/design/DESIGN-client-intake-and-agent-workflows.md)
Phase 1.

| File | Workspace | Grounds |
|---|---|---|
| `public.md` | `WS_PUBLIC_SLUG` | the website embed widget — anonymous visitors |
| `private.md` | `WS_PRIVATE_SLUG` | the authenticated dashboard's private chat |

**Neither file exists yet.** This instance's live prompts have not been
bootstrapped into version control — the current content is only in the
AnythingLLM runtime database. Bootstrapping requires the instance's admin API
key, which per this repo's [AGENTS.md](../../../AGENTS.md) secrets-hygiene
standard must never pass through an agent's context. **A human runs this
step**, not an agent:

```bash
# From anythingllm-docker/scripts/, with an SSH tunnel or direct reachability
# to this instance's AnythingLLM API already arranged:

# 1. Confirm the system-prompt field name on THIS AnythingLLM version first.
#    This is a read-only GET — it cannot modify anything.
./allm-prompt-sync.sh discover <allm-url> <public-workspace-slug>

# 2. Bootstrap each file from the live instance.
./allm-prompt-sync.sh pull <allm-url> <public-workspace-slug> \
    ../sites/dev-weown-anythingllm/prompts/public.md
./allm-prompt-sync.sh pull <allm-url> <private-workspace-slug> \
    ../sites/dev-weown-anythingllm/prompts/private.md

# 3. Review the pulled content, then commit both files. From this point on,
#    they are the source of truth — edit the file, review in a PR, then:
./allm-prompt-sync.sh push <allm-url> <public-workspace-slug> \
    ../sites/dev-weown-anythingllm/prompts/public.md
```

`diff` mode checks the live instance against the committed file without
changing anything, and exits non-zero on drift — the mechanism for detecting
when the two have come apart:

```bash
./allm-prompt-sync.sh diff <allm-url> <public-workspace-slug> \
    ../sites/dev-weown-anythingllm/prompts/public.md
```

## Not for fleet-registry tenants

Tenants in `WeOwnDev/weown-fleet`'s `tenants.yaml` (e.g. `beta-weown-chat`) already
have managed, versioned prompts — `prompts/ws-{public,private}.tmpl` rendered and
applied by `apply-product-config.sh`. On those, `diff` is fine for drift detection;
`push` would fight the fleet script. Use this convention only for the sites in this
repo that the registry does not manage.

## Why this instance first

`dev-weown-anythingllm` is the lowest-risk target to prove the mechanism
against — per
[docs/design/DESIGN-client-intake-and-agent-workflows.md](../../../docs/design/DESIGN-client-intake-and-agent-workflows.md)
§6, it's also where the agent-mode probe runs. Once `pull` → commit →
`push` → `diff` is proven here, the same convention extends to
`ai.weown.agency`, `beta-weown-chat` and `s004.ccc.bot` — each gets its own
`prompts/{public,private}.md` — in a follow-up change, not this one.

## Do not hand-author these files before the bootstrap

A committed file that was never pulled from the live instance is a fiction —
`push`ing it would silently overwrite whatever is actually running, and
`diff` would report "drift" against content that was never real to begin
with. Pull first, always.
