We have to make the onboarding super clear so it'll be dummy-proof. It currently feels confusing.

Personally viewing from a non-technical perspective too, I don't know how I can:

- Create an account (Register)
- I can only see an option to sign in.
- When does the purchase happen? do we allow full onboarding and access to dashboard with core features restricted until user makes payment?

I assume the instances are automatically generated now when the user finishes their account creation.

So ideally, I'll want to see the onboarding go this way:

- **Create account** is always visible next to Sign in (and “New here? Create account” on the sign-in screen). New users shouldn’t have to hunt for Register. Registration should also be **linked from the landing page**.
- User signs up → clicks through a **legal agreement** (not finalized yet).
- Then **Stripe**: start a **7-day free trial** (card on file; Stripe **doesn’t charge for 7 days**) or pay. They don’t get a live space until this step — trial/pay is what generates the instance.
- Short “setting up your practice assistant…” wait, then we create their **DO droplet in the AOP’s DigitalOcean account** and they’re live. Same account on **billing.weown.dev** creates the instance(s) (AnythingLLM / WeOwnChat servers) **and** logs them in. Billing exists because they’re getting **their own server**, not just a shared app login — we should say that in plain language in the flow (“your WeOwnChat space / practice assistant”).
- Day one content: **preload ~100 common Q&As** by **location + industry** (CPA in Lagos ≠ financial advisor in Denver). Unclear if we also need an interim “upload your own documents” step on day one — checklist can cover uploads later if preload is enough to feel live.
- After they’re in, a simple checklist can still help:
  - Add your documents (Public = website-facing only; Private = client-safe)
  - Allow their website domain
  - Appearance + booking button
  - Copy embed snippet
  - Test on their site

I tested and registration is working — it just needs the landing link, clearer “what is my instance / why billing” messaging, and the 7-day trial → auto-provision path wired end to end. We can set Stripe so they “pay” (card on file) and aren’t charged for 7 days.

Notes for the build discussion (not user-facing):
- ALLM doesn’t support OIDC/OAuth2 (long-standing concern; forking to add it is real work).
- Raw ALLM back-end would let users change models — too complicated; our UI may largely wrap/hide that.
- These are the discussions we should be having — this is what we need to build a product.
