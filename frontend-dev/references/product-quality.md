# Frontend Product Quality, UX and Performance

## Product quality and UX
Technical correctness isn't enough; the feature must be usable and consistent. What the agent should do:
- **Design system first**: use existing components and tokens (spacing, colour, typography, radius). Don't create a one-off component when a system component fits; if a gap exists, flag it rather than inventing a new pattern silently.
- **Complete user journeys**: walk the whole flow, not just the screen — entry points, first-time (empty) experience, success confirmation, error recovery, back/refresh behaviour, deep links, and what happens next.
- **Microcopy**: clear, specific, action-oriented labels and messages. Error text says what happened and how to fix it ("Card expired — use a different card"), not "Something went wrong". Follow the product's tone; keep strings in the i18n system.
- **Feedback and affordance**: every action gets visible feedback (pending state, success toast, inline confirmation); destructive actions require confirmation or offer undo.
- **Forms**: minimal fields, correct input types and `autocomplete`, inline validation on blur, preserve input on error, sensible defaults.
- **Analytics instrumentation**: when the project tracks events, add them per the existing tracking plan/naming convention (e.g. `object_action`: `checkout_started`, `checkout_completed`), with properties that answer real product questions, and **never** PII, tokens or free-text input. Test that key events fire once (not on every render).
- **Conversion-critical paths** (signup, onboarding, checkout): minimize steps and distractions, keep primary action obvious, avoid layout shift around buttons.
- **Flag UX risks for a human** instead of guessing: confusing flows, unclear copy, missing designs for states, accessibility trade-offs. The agent can't measure usability or conversion without real users — it should say so and suggest how to validate (usability test, A/B test behind a flag, analytics funnel).

## Performance
- Targets (Core Web Vitals, p75): **LCP < 2.5 s, INP < 200 ms, CLS < 0.1**.
- Code-split by route; lazy-load heavy, below-the-fold components.
- Optimize images (modern formats, responsive `srcset`, explicit width/height, lazy loading); preload the LCP image and key fonts.
- Avoid unnecessary re-renders (stable props, memoization only where profiling shows benefit); virtualize long lists.
- Watch bundle size (bundle analyzer, size-limit in CI); question every new dependency.
- Measure with Lighthouse / Lighthouse CI and real-user monitoring, not intuition.
