#!/usr/bin/env python3
"""
Cross-skill routing eval: does each query select the right skills, given all six descriptions?

Approximation: real agents decide inside their own harness. This presents the same skill metadata
(name + description) a harness shows, asks the model which skills it would load, and scores each
labelled (query, skill) pair. Use it as a cheap first signal; confirm with skill-creator's run_loop.

Usage:
  export ANTHROPIC_API_KEY=...
  python evals/run_trigger_evals.py --model <model-id> [--repeats 3] [--dry-run]
No third-party packages needed (uses urllib).
"""
import argparse, glob, json, os, re, sys, time, urllib.error, urllib.request
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)
SKILLS = ["dev-core", "backend-dev", "frontend-dev", "fullstack-integration", "ship-and-operate", "debug-production"]

def metadata():
    out = []
    for s in SKILLS:
        txt = open(os.path.join(ROOT, s, "SKILL.md"), encoding="utf-8").read()
        desc = re.search(r"^description: (.*)$", txt, re.M).group(1)
        out.append(f"- {s}: {desc}")
    return "\n".join(out)

SYSTEM = """You are a coding agent. These skills are available; each is a folder of instructions you can load.
Load a skill only if the task would benefit from its instructions. Answer with ONLY a JSON array of the
skill names you would load for the user's message, e.g. ["dev-core","backend-dev"], or [] for none.

Available skills:
{meta}"""

RETRYABLE = {429, 500, 502, 503, 504, 529}

def post(body, attempts=6):
    """POST to the Messages API, retrying rate limits, overloads and network errors with backoff."""
    for i in range(attempts):
        req = urllib.request.Request("https://api.anthropic.com/v1/messages", data=body, headers={
            "content-type": "application/json", "x-api-key": os.environ["ANTHROPIC_API_KEY"],
            "anthropic-version": "2023-06-01"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code not in RETRYABLE or i == attempts - 1: raise
            wait = float(e.headers.get("retry-after") or 2 ** i)
        except (urllib.error.URLError, TimeoutError):
            if i == attempts - 1: raise
            wait = 2 ** i
        time.sleep(min(wait, 60))

def ask(model, system, query):
    body = json.dumps({"model": model, "max_tokens": 100, "system": system,
                       "messages": [{"role": "user", "content": query}]}).encode()
    text = "".join(b.get("text", "") for b in post(body)["content"])
    m = re.search(r"\[.*?\]", text, re.S)
    try: return set(json.loads(m.group(0))) if m else set()
    except json.JSONDecodeError: return set()

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--model", required=False)
    ap.add_argument("--repeats", type=int, default=3); ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    cases = []
    for f in sorted(glob.glob(os.path.join(HERE, "triggers", "*.json"))):
        skill = os.path.basename(f)[:-5]
        for c in json.load(open(f, encoding="utf-8")): cases.append((skill, c["query"], c["should_trigger"]))
    system = SYSTEM.format(meta=metadata())
    if a.dry_run:
        print(system); print(f"\n{len(cases)} labelled cases x {a.repeats} repeats"); return 0
    if not a.model or "ANTHROPIC_API_KEY" not in os.environ:
        print("Need --model and ANTHROPIC_API_KEY (or use --dry-run).", file=sys.stderr); return 2

    print(f"{len(cases)} cases x {a.repeats} repeats = {len(cases) * a.repeats} API calls")
    out_path = os.path.join(HERE, "trigger_results.json")
    stats = defaultdict(lambda: {"tp": 0, "fp": 0, "tn": 0, "fn": 0}); failures = []
    for n, (skill, q, expected) in enumerate(cases, 1):
        try:
            hits = sum(skill in ask(a.model, system, q) for _ in range(a.repeats))
        except Exception as e:  # keep what's been scored so far
            print(f"\nstopped at case {n}/{len(cases)}: {e}", file=sys.stderr)
            json.dump({"stats": stats, "failures": failures, "completed": n - 1}, open(out_path, "w"), indent=2)
            return 2
        triggered = hits * 2 > a.repeats            # majority vote
        key = ("tp" if triggered else "fn") if expected else ("fp" if triggered else "tn")
        stats[skill][key] += 1
        if key in ("fp", "fn"): failures.append((skill, key, f"{hits}/{a.repeats}", q))
        json.dump({"stats": stats, "failures": failures, "completed": n}, open(out_path, "w"), indent=2)
        print(".", end="", flush=True)
    print("\n\nskill                    recall  precision  accuracy")
    total_ok = total = 0
    for s in SKILLS:
        t = stats[s]; n = sum(t.values()); ok = t["tp"] + t["tn"]; total_ok += ok; total += n
        rec = t["tp"] / max(1, t["tp"] + t["fn"]); prec = t["tp"] / max(1, t["tp"] + t["fp"])
        print(f"{s:24} {rec:6.0%}  {prec:9.0%}  {ok}/{n}")
    print(f"\noverall accuracy: {total_ok}/{total}")
    if failures:
        print("\nmisses (fn = should load but didn't, fp = loaded but shouldn't):")
        for s, k, h, q in failures: print(f"  [{s} {k} {h}] {q}")
    return 0 if not failures else 1

if __name__ == "__main__": sys.exit(main())
