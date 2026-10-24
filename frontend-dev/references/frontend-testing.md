# Frontend Testing Patterns

## Contents
1. Component test with user-event and MSW
2. Testing loading / empty / error states
3. Hook / composable tests
4. Accessibility assertions
5. Playwright e2e with page objects
6. Visual regression
7. Flakiness checklist

## 1. Component test (React + Testing Library + MSW)
```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { server } from "@/tests/msw/server";

it("adds a todo and shows it in the list", async () => {
  server.use(http.post("/api/todos", async ({ request }) =>
    HttpResponse.json({ id: "1", ...(await request.json()) }, { status: 201 })));
  const user = userEvent.setup();
  render(<TodoPage />, { wrapper: AppProviders });

  await user.type(screen.getByLabelText(/new todo/i), "Write tests");
  await user.click(screen.getByRole("button", { name: /add/i }));

  expect(await screen.findByRole("listitem", { name: /write tests/i })).toBeInTheDocument();
});
```
Vue: `@testing-library/vue` (same API). Angular: `@testing-library/angular` or TestBed with harnesses. Svelte: `@testing-library/svelte`.

MSW setup (`tests/setup.ts`): `beforeAll(() => server.listen({ onUnhandledRequest: "error" }))`, `afterEach(() => server.resetHandlers())`, `afterAll(() => server.close())`. Failing on unhandled requests catches accidental real network calls.

## 2. Loading / empty / error states
```tsx
it("shows an error message with retry when the API fails", async () => {
  server.use(http.get("/api/todos", () => new HttpResponse(null, { status: 500 })));
  render(<TodoPage />, { wrapper: AppProviders });
  expect(await screen.findByRole("alert")).toHaveTextContent(/couldn't load/i);
  expect(screen.getByRole("button", { name: /retry/i })).toBeEnabled();
});

it("shows empty state when there are no todos", async () => {
  server.use(http.get("/api/todos", () => HttpResponse.json([])));
  render(<TodoPage />, { wrapper: AppProviders });
  expect(await screen.findByText(/nothing to do yet/i)).toBeVisible();
});
```

## 3. Hook / composable tests
```ts
const { result } = renderHook(() => useCart(), { wrapper: AppProviders });
act(() => result.current.add({ id: "p1", price: 10 }, 2));
expect(result.current.total).toBe(20);
```
Prefer extracting logic into pure functions and testing them without rendering at all.

## 4. Accessibility assertions
```tsx
import { axe } from "vitest-axe"; // or jest-axe
it("has no detectable a11y violations", async () => {
  const { container } = render(<SignupForm />);
  expect(await axe(container)).toHaveNoViolations();
});
```
Also test keyboard: `await user.tab(); expect(screen.getByRole("button", {name: /submit/i})).toHaveFocus();`

Playwright: `const results = await new AxeBuilder({ page }).analyze(); expect(results.violations).toEqual([]);`

## 5. Playwright e2e with page objects
```ts
// tests/e2e/pages/checkout.page.ts
export class CheckoutPage {
  constructor(private page: Page) {}
  async goto() { await this.page.goto("/checkout"); }
  async payWith(card: string) {
    await this.page.getByLabel("Card number").fill(card);
    await this.page.getByRole("button", { name: "Pay now" }).click();
  }
  confirmation() { return this.page.getByRole("heading", { name: /order confirmed/i }); }
}

// tests/e2e/checkout.spec.ts
test("user can complete checkout", async ({ page, request }) => {
  await request.post("/test-api/seed", { data: { cart: ["sku-1"] } }); // seed via API
  const checkout = new CheckoutPage(page);
  await checkout.goto();
  await checkout.payWith("4242424242424242");
  await expect(checkout.confirmation()).toBeVisible();
});
```
Config tips: `use: { baseURL, trace: "on-first-retry", screenshot: "only-on-failure" }`; a `setup` project that logs in once and saves `storageState`; projects for Chromium, WebKit/Firefox and a mobile device; `webServer` to start the app in CI.

## 6. Visual regression
- Snapshot stable, deterministic states (fixed data, fonts loaded, animations disabled).
- `await expect(page).toHaveScreenshot({ maxDiffPixelRatio: 0.01 })` or Storybook + Chromatic.
- Review diffs; never blindly update baselines.

## 7. Flakiness checklist
- No `waitForTimeout` / `sleep`; use web-first assertions and `findBy*`
- Network mocked or seeded deterministically; time frozen (`vi.useFakeTimers`, `page.clock`)
- Tests don't share accounts or data; each seeds its own
- Animations disabled in test env; fonts preloaded
- Retries in CI are a diagnostic aid, not a fix — investigate traces of retried tests
