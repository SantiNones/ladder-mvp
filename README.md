# Ladder

MVP that computes, deterministically, what a person is missing to reach the
next level of a published competency framework, and uses an LLM only to write
a narrative about a gap the model did not compute.

## Framework attribution

The competency criteria in the seed come from the publicly published
**Dropbox Engineering Career Framework** (Software Engineer IC2 / IC3):

https://dropbox.github.io/dbx-career-framework/

Every criterion row stores `source: "dropbox-public"`. This is a local demo
with explicit attribution — not Dropbox's product, and not presented as ours.

## Run locally

Two servers in development:

```bash
cd api && bin/rails s          # :3000
cd client && npm run dev       # :5173 (proxies /api → Rails)
```

```bash
cd api && bin/rails db:seed             # idempotent demo data
cd api && bin/rails narrative:generate  # populates Ana's narrative + trace panel
cd api && bin/rails test
```

**Run both seed commands together, in that order, every time.**
`db:seed` resets `narrative` / `prompt_payload` to `nil` on every run — it's
the demo data, not the AI output. Without the second command, My ladder will
render with no narrative and no trace panel, which looks broken but isn't.

See `SPEC.md` and `decisions.md` for what gets built and why.
