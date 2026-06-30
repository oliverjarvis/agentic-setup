---
name: no-em-dash
description: Use when writing any prose, code comments, commit messages, or PR text. Enforces never using em-dashes or en-dashes; substitute commas, colons, parentheses, or separate sentences.
---

# No Em-Dash

## The rule

Never use the em-dash character (U+2014) or the en-dash character (U+2013) in any
output. This includes prose, code comments, commit messages, PR descriptions, and
generated documentation.

This plugin also injects this rule at the start of every session via a SessionStart
hook, so it stays active even when this skill is not explicitly invoked.

## What to use instead

| Instead of an em-dash for... | Use |
|------------------------------|-----|
| A break or aside in a sentence | A comma, or a pair of parentheses |
| Introducing an explanation or list | A colon |
| Joining two related clauses | A period and a second sentence, or a semicolon |
| A numeric range (en-dash) | The word "to", e.g. "5 to 10" |

## Examples

(In the "avoid" rows, `[EM]` marks where an em-dash would have gone. The character
is never written literally here, so this file stays compliant with its own rule.)

Avoid:

> The build failed `[EM]` a missing dependency.

Prefer:

> The build failed: a missing dependency.

Avoid:

> Run the tests `[EM]` they catch most regressions `[EM]` before pushing.

Prefer:

> Run the tests (they catch most regressions) before pushing.

## Self-check

Before sending output, scan it for the characters U+2014 and U+2013. If either is
present, rewrite the sentence using one of the substitutions above. A regular hyphen
(`-`) is fine where a hyphen genuinely belongs (for example, in `no-em-dash`).
