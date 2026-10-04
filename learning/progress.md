# Progress and review record

This file records evidence; it does not replace reading the actual implementation.

## Current position

- Next lesson: **M01-L02**
- Current implementation revision: 35456db2377fa2afe814cfae2310a9e5972cf8bb
- Last reviewed implementation revision: 35456db2377fa2afe814cfae2310a9e5972cf8bb
- Toolchain/SDK record: learner confirmed the native arm64 environment and toolchain checks on 2026-10-04; exact compiler/SDK version output was not supplied.
- Required fixes still open: none

## Status definitions

Use **Not started**, **In progress**, **Submitted**, **Changes requested**, **Verification pending**, or **Ready**. Ready means required implementation, evidence, and end-of-lesson understanding have been reviewed. A finished coding attempt with unanswered questions is not yet Ready.

Record the exact implementation commit being reviewed. Commit this progress update afterward, so the recorded hash is not self-referential. A later fix requires its own reviewed hash. Keep prior reviews in the history section rather than erasing them.

## Lesson ledger

| Lesson | Status | Reviewed implementation commit | Evidence / answers | Remaining work |
| --- | --- | --- | --- | --- |
| M01-L01 | Ready | 35456db2377fa2afe814cfae2310a9e5972cf8bb | Full source/diff reviewed; learner confirmed expected output, clean build, and environment; answers reviewed with corrections explained. | None. |
| M01-L02 | Not started | — | — | — |
| M01-L03 | Not started | — | — | — |
| M01-L04 | Not started | — | — | — |
| M01-L05 | Not started | — | — | — |
| M02-L01 | Not started | — | — | — |
| M02-L02 | Not started | — | — | — |
| M02-L03 | Not started | — | — | — |
| M02-L04 | Not started | — | — | — |
| M02-L05 | Not started | — | — | — |
| M03-L01 | Not started | — | — | — |
| M03-L02 | Not started | — | — | — |
| M03-L03 | Not started | — | — | — |
| M03-L04 | Not started | — | — | — |
| M03-L05 | Not started | — | — | — |
| M04-L01 | Not started | — | — | — |
| M04-L02 | Not started | — | — | — |
| M04-L03 | Not started | — | — | — |
| M04-L04 | Not started | — | — | — |
| M04-L05 | Not started | — | — | — |
| M05-L01 | Not started | — | — | — |
| M05-L02 | Not started | — | — | — |
| M05-L03 | Not started | — | — | — |
| M05-L04 | Not started | — | — | — |
| M05-L05 | Not started | — | — | — |
| M06-L01 | Not started | — | — | — |
| M06-L02 | Not started | — | — | — |
| M06-L03 | Not started | — | — | — |
| M06-L04 | Not started | — | — | — |
| M06-L05 | Not started | — | — | — |
| M07-L01 | Not started | — | — | — |
| M07-L02 | Not started | — | — | — |
| M07-L03 | Not started | — | — | — |
| M07-L04 | Not started | — | — | — |
| M07-L05 | Not started | — | — | — |
| M08-L01 | Not started | — | — | — |
| M08-L02 | Not started | — | — | — |
| M08-L03 | Not started | — | — | — |
| M08-L04 | Not started | — | — | — |
| M08-L05 | Not started | — | — | — |
| M09-L01 | Not started | — | — | — |
| M09-L02 | Not started | — | — | — |
| M09-L03 | Not started | — | — | — |
| M09-L04 | Not started | — | — | — |
| M09-L05 | Not started | — | — | — |
| M10-L01 | Not started | — | — | — |
| M10-L02 | Not started | — | — | — |
| M10-L03 | Not started | — | — | — |
| M10-L04 | Not started | — | — | — |
| M10-L05 | Not started | — | — | — |

## Review history

Append one entry after each whole-lesson review:

```text
Date:
Lesson:
Implementation commit:
Previous reviewed implementation commit:
Reviewer environment:
Outcome:
Required fixes:
Evidence executed by reviewer:
Evidence supplied by learner:
Static-only / unverified items:
Understanding questions:
Next action:
```

## M01-L01 review — 2026-10-04

- Implementation commit: 35456db2377fa2afe814cfae2310a9e5972cf8bb
- Previous reviewed implementation commit: none. Changes inspected against initial commit aca7a24ce4666639ce6e88e4cb63a54530741fc2.
- Files inspected: src/asm/pixel.s, src/bridge/Pixel.h, src/swift/main.swift, .gitignore; full commit diff and repository tree.
- Reviewer environment: remote GitHub source inspection; no native macOS build or execution by reviewer.
- Initial outcome: Verification pending; source requirements met, no required code fixes, local execution/environment evidence outstanding.
- Final outcome: Ready after learner confirmation in the review conversation.
- Required fixes: none.
- Evidence executed by reviewer: none; static review only.
- Evidence supplied by learner: confirmed build and output were as expected (opaque alpha 255, transparent alpha 0), all lesson checks including clean rebuild, and the expected native arm64 environment.
- Static-only / unverified items: runtime confirmation is learner-reported; exact command logs and compiler/SDK versions were not supplied and were not independently verified.
- Understanding questions: answers 1–3 correct; linker and directive/declaration distinctions in answers 4–5 corrected in conversation. Learner explicitly requested no restatement; no further answer submission required.
- Next action: begin M01-L02.

## How to resume

Read the next lesson plus its prerequisites and inspect the actual repository revision. If code and this ledger disagree, resolve the discrepancy from evidence. Do not infer completion from a commit message alone. Relevant lesson answers may be kept under `learning/answers/` by the learner or supplied in the review conversation.
