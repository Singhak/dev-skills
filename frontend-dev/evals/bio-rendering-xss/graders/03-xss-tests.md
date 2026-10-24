---
type: llm
focus: trace
weight: 1
---

Tests render payloads such as <img src=x onerror=alert(1)>, <script> and a javascript: link and assert that no script/event handler or javascript: href ends up in the DOM.
