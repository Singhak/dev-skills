---
type: llm
focus: trace
weight: 1
---

The limits are enforced atomically, for example by a unique constraint on (coupon, user), a conditional UPDATE ... WHERE remaining > 0, or a transaction with row locking, not by reading a count and then inserting in separate steps.
