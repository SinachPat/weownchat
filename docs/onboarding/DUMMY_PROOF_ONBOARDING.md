# WeOwnChat — Dummy-proof onboarding (team brief)

Updated from team conversation (signup → legal → Stripe trial → DO instance → live; location/industry preload; billing.weown.dev).

---

## What’s confusing today

We have to make the onboarding super clear so it'll be dummy-proof. It currently feels confusing.

Personally viewing from a non-technical perspective too, I don't know how I can:

- Create an account (Register)
- I can only see an option to sign in.
- When does the purchase happen? do we allow full onboarding and access to dashboard with core features restricted until user makes payment?
- I assume the instances are automatically generated now when the user finishes their account creation.

**Also from testing:** registration works, but it should be **linked from the landing page**, and we should communicate better **what an instance is** and the value as part of the flow.

---

## Locked product direction (from team thread)

| Topic | Direction |
|-------|-----------|
| Access before pay | They **don’t get a live space until they pay / start trial** (not a free unpaid dashboard). |
| Trial | **7-day free trial**: collect card on Stripe now; **Stripe does not charge for 7 days**. Trial **generates their instance**. |
| Provision | After signup + legal + Stripe trial/pay → create **DO droplet in the AOP’s DigitalOcean account** → they’re live. |
| Account | Same account used on **billing.weown.dev** to create instance(s) (AnythingLLM servers) **and** to log into them. Billing exists because they are getting **their own server**, not just a shared login. |
| Docs / Q&A | Prefer **preload ~100 common Q&As** by **location + industry** (e.g. CPA in Lagos ≠ financial advisor in Denver). Unclear if there’s a separate “upload your docs” interim step on day one — checklist can still teach upload later. |
| Legal | Click-through **legal agreement** after signup (**not finalized yet**). |
| Stripe | Dummy/test checkout up now; production path = pay-with-card, delay first charge 7 days. |

### Open / architectural notes (keep in the discussion)

1. ALLM does **not** support OIDC/OAuth2 — long-standing concern; forking WeOwn Chat to add OIDC is real work.
2. Raw ALLM back-end would let users change models — deemed **too complicated**; our UI may largely sit in front (or “go away… kind of”) so users don’t hit that.
3. These product/architecture calls are exactly what we need to keep building.

---

## Ideal onboarding (dummy-proof)

**Create account** is always visible next to Sign in (and “New here? Create account” on the sign-in screen). New users shouldn’t have to hunt for Register. **Landing page CTA → registration.**

Happy path:

1. **Create account** (from landing or Sign in → Create account)
2. **Verify email** (if required)
3. **Legal agreement** click-through (copy TBD / not finalized)
4. **Stripe** — start **7-day free trial** (card on file; **no charge for 7 days**) *or* pay
5. Short wait: **“Setting up your practice assistant…”**  
   Behind the scenes: provision **DO droplet** (AOP DO account) + AnythingLLM / WeOwnChat instance for that account
6. Land in their space — **same account** logs them into the instance
7. Onboarding communicates clearly:
   - You now have **your own WeOwnChat space** (your practice assistant on your site)
   - Why billing exists: you’re getting a dedicated server, managed via **billing.weown.dev**
8. **Preload** ~100 Q&As for their **location + industry** (so they aren’t empty on day one)
9. Optional / later checklist (if we still want guided setup after live):
   - Add your documents (Public = website-facing; Private = client-safe)
   - Allow website domain
   - Appearance + booking button
   - Copy embed snippet
   - Test on their site

**Soft-lock variant (earlier idea) is superseded for go-live:** no full live instance until trial/pay. Exploration without a server is limited to marketing + signup + legal + Stripe — not an unpaid full dashboard.

---

## Copy / UX bar

Every screen answers: *where am I, what do I do next, how long will this take?*

Never say Docker / droplet / “instance” without translation. Prefer:

- “Your WeOwnChat space” / “your practice assistant”
- “We’re setting up your private server — usually a few minutes”
- “7 days free — you won’t be charged until [date]. Cancel anytime in billing.”

Landing: primary **Start free trial** / **Create account** → registration (already working; wire the link).

---

## Eng acceptance (short)

- [ ] Landing → Create account / Start free trial
- [ ] Sign in shows Create account
- [ ] Legal click-through before Stripe
- [ ] Stripe trial: card collected, first charge delayed 7 days
- [ ] Successful trial/pay → auto DO provision → redirect into space
- [ ] Same billing.weown.dev account logs into the instance
- [ ] Preload Q&A by location + industry
- [ ] Plain-language “what you just got” screen after provision
- [ ] Provision failure → human status, not blank dashboard

---

## Still open for the team

1. Final legal agreement text
2. Exact free-vs-locked matrix if anything is visible pre-pay (marketing only vs account shell)
3. Confirm preload taxonomy (industry × location source of truth)
4. Whether day-one checklist includes doc upload or only after preload
5. OIDC / ALLM-fork vs keep UI wrapper (models hidden)

---

*Paste-ready narrative version for Slack/email lives in the companion note; this file is the structured team brief.*
