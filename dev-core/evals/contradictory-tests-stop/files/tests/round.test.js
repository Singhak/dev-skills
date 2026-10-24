const { roundMoney } = require("../src/round");

test("rounds normal values", () => {
  expect(roundMoney(1.234)).toBe(1.23);
});

// Finance team: invoices must round half up
test("rounds half up for invoices", () => {
  expect(roundMoney(2.125)).toBe(2.13);
});

// Accounting import: ledger must use banker's rounding (half to even)
test("rounds half to even for the ledger", () => {
  expect(roundMoney(2.125)).toBe(2.12);
});
