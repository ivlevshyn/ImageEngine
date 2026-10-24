# Progress and review record

This file records evidence; it does not replace reading the actual implementation.

## Current position

- Next lesson: **M01-L04**
- Current implementation revision: 50280e44dd0b71b73cb598c869c2b5b513c6ae70
- Last reviewed implementation revision: c97016d38061bc482a4e3931e4f5bf082700f2a1
- Toolchain/SDK record: reviewer verified native arm64 execution with Xcode 27.1 (build 27A9275) and the macOS 27.0 SDK on 2026-10-25. The complete compiler version output was not separately captured during this follow-up.
- Required fixes still open: none for M01-L03.
- Current source layout: `ImageEngine/Pixel.s`, `ImageEngine/Pixel.h`, and `ImageEngine/main.swift`, built through `ImageEngine.xcodeproj`. Earlier review entries retain their historical `src/` paths.
- Revision note: 50280e44dd0b71b73cb598c869c2b5b513c6ae70 adds ignore rules and a shared scheme after the reviewed revision; its diff contains no changes to the three implementation files or `project.pbxproj`. Native build/run evidence below applies to c97016d38061bc482a4e3931e4f5bf082700f2a1.

## Status definitions

Use **Not started**, **In progress**, **Submitted**, **Changes requested**, **Verification pending**, or **Ready**. Ready means required implementation, evidence, and end-of-lesson understanding have been reviewed. A finished coding attempt with unanswered questions is not yet Ready.

Record the exact implementation commit being reviewed. Commit this progress update afterward, so the recorded hash is not self-referential. A later fix requires its own reviewed hash. Keep prior reviews in the history section rather than erasing them.

## Lesson ledger

| Lesson | Status | Reviewed implementation commit | Evidence / answers | Remaining work |
| --- | --- | --- | --- | --- |
| M01-L01 | Ready | 35456db2377fa2afe814cfae2310a9e5972cf8bb | Full source/diff reviewed; learner confirmed expected output, clean build, and environment; answers reviewed with corrections explained. | None. |
| M01-L02 | Ready | c1dd575eb643899fbfc867363d3eb9aea022f160 | Full source/diff reviewed; learner confirmed program execution and all checks; answers assessed with ABI and unsigned-wrap clarifications. Completion accepted at learner's explicit request; documentation/trace exceptions recorded below. | None required for progression. |
| M01-L03 | Ready | c97016d38061bc482a4e3931e4f5bf082700f2a1 | Corrected Swift diagnostic and header contracts inspected; native arm64 Xcode Debug build and all existing checks passed. Prior question assessment retained, with corrections already explained. | None. Next: M01-L04. |
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

## M01-L02 review — 2026-10-04

- Implementation commit: c1dd575eb643899fbfc867363d3eb9aea022f160
- Previous reviewed implementation commit: 35456db2377fa2afe814cfae2310a9e5972cf8bb.
- Files inspected: src/asm/pixel.s, src/bridge/Pixel.h, src/swift/main.swift; complete changes since the previous reviewed implementation and repository tree.
- Reviewer environment: remote GitHub source inspection; no native macOS build or execution by reviewer.
- Initial outcome: Verification pending; arithmetic and declarations correct, runtime evidence and separate contract documentation/register trace outstanding.
- Final outcome: Ready at the learner's explicit request to record the lesson as done after confirming program execution and all checks.
- Required fixes: no arithmetic or ABI defects found. Separate contract comments and a learner-written register trace were not supplied; accepted as documentation/trace exceptions for progression at the learner's completion request, not represented as fulfilled requirements.
- Evidence executed by reviewer: none; static review only.
- Evidence supplied by learner: confirmed running the program and that everything checks, covering lesson examples and checks in the review context.
- Static-only / unverified items: runtime results are learner-confirmed; exact build/run commands and output logs were not supplied or independently verified. Header contract comments remain absent in the reviewed revision. No separate learner-written register trace was submitted; static trace for input 40 is entry w0=40, after mov w1=255, after sub w0=215.
- Understanding questions: all four answers assessed. Clarified that the calling convention assigns both argument and result to w0; swapping subtraction operands gives channel minus 255, whose negative mathematical result wraps when returned as UInt32 (40 produces 4,294,967,081). UInt8 range and the caller's input-range responsibility were understood. No further answer submission required.
- Next action: begin M01-L03.

## M01-L03 review — 2026-10-18

- Implementation commit: 033a92f2ef8bc5edfbee645bc4b381940e3f3aaf
- Previous reviewed implementation commit: c1dd575eb643899fbfc867363d3eb9aea022f160.
- Files inspected: src/asm/pixel.s, src/bridge/Pixel.h, src/swift/main.swift, learning/progress.md; complete changes since the previous reviewed implementation. Lesson requirements, course guide, tutor guidance, and assembly/ABI reference were read in this conversation.
- Reviewer environment: native arm64 macOS; Apple Swift 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1), target arm64-apple-macosx27.0.0. Exact repository files were copied to a temporary review directory; project source was not modified.
- Outcome: Changes requested. Packing and extraction arithmetic are correct by inspection, but the exact pushed Swift source does not type-check.
- Evidence executed by reviewer: `xcrun clang -arch arm64 -g -c pixel.s -o pixel.o` passed. `xcrun swiftc -typecheck -module-cache-path <temporary-cache> -import-objc-header Pixel.h main.swift` failed at main.swift:26 with two diagnostics: `String(_:radix:uppercase:)` requires `[UInt32]` to conform to `BinaryInteger`. No executable was built or run.
- Evidence supplied by learner: "Confirmed, everything works as expected" after the final lesson checks. This is learner-reported runtime confirmation; exact logs were not supplied, and it cannot establish a successful build of this pushed revision because the reviewer reproduced a compile error.
- Understanding questions: all four answered and assessed. Q1 partially correct; clarified that the mask keeps eight low bits (two hexadecimal digits) after shifting. Q2 incomplete; explained nonoverlapping fields and that OR never carries. Q3 incorrect; explained that red 256 is 0x00000100 and contaminates green rather than overflowing UInt32. Q4 correct: most-to-least significant bytes are alpha, blue, green, red. Corrections were explained before the learner requested this progress update; no additional answer submission requested.
- Next action: fix the two required items below, rebuild/run the lesson checks and existing examples, commit and push, then review the corrected implementation hash before advancing to M01-L04.

| Completion requirement | Evidence | Status |
| --- | --- | --- |
| Packing and four extraction functions | All five functions in pixel.s use the correct shifts, OR, and masks; return through w0; no memory accesses, calls, or preserved-register changes. Assembly compiles. | Met |
| Matching C declarations | All five declarations use uint32_t and match the exported symbols, including the accepted .global spelling for green_channel. | Met |
| Explicit channel domain and layout | Teaching states inputs are 0...255 and integer layout is 0xAABBGGRR; corresponding caller-obligation comments are absent beside the header declarations. | Missing |
| Decimal and hexadecimal examples with labelled output | main.swift contains both forms and labels the packed value and four channels. | Met |
| Exact expected values and round trips, including zero and 255 | Five checkPixel cases cover 0x44332211, black opaque, white opaque, and a mixed endpoint case. Their execution is blocked by the Swift diagnostic. | Unverified |
| Earlier examples preserved | Existing alpha, inversion, doubling, and double-inversion code remains present; earlier assembly behavior is unchanged. Runtime regression results for this exact revision are unavailable. | Unverified |
| Bit-position explanation and final questions | Learner correctly described channel order; mask width, OR behavior, and invalid input were clarified in conversation. | Met with corrections explained |

### Required fixes

1. In `src/swift/main.swift:26`, `checkPixel` passes arrays `original` and `extracted` to an integer-only formatting initializer. Swift checks this code even if the failure branch would never execute. Replace that diagnostic with `fatalError("Extraction failed: expected \(original), got \(extracted)")`. Rebuild and rerun; the current revision cannot substantiate the reported successful run.
2. In `src/bridge/Pixel.h`, document beside `pack_rgba` that all four inputs must be in 0...255 and the result uses integer layout 0xAABBGGRR. Document that the extraction functions accept that packed layout and return a channel in 0...255. No runtime validation or silent masking of invalid pack arguments is required.

### Optional improvements

- Add a space between the expected and actual values in the packing failure message so the diagnostic is easier to read.

## M01-L03 follow-up review — 2026-10-25

- Implementation commit: c97016d38061bc482a4e3931e4f5bf082700f2a1.
- Previous reviewed implementation commit: 033a92f2ef8bc5edfbee645bc4b381940e3f3aaf, as recorded in the 2026-10-18 review.
- Files inspected: `ImageEngine/Pixel.s`, `ImageEngine/Pixel.h`, `ImageEngine/main.swift`, `ImageEngine.xcodeproj/project.pbxproj`, repository tree, course guide, M01 lesson text, tutor guidance, assembly/ABI reference, and this progress record.
- Reviewer environment: native arm64 macOS; Xcode 27.1 (build 27A9275), macOS 27.0 SDK. Exact implementation and project files were copied to a temporary review directory; repository source was not changed.
- Outcome: **Ready**. Both required fixes from the prior review are present, the Xcode Debug build succeeds, and the executable passes the lesson checks and earlier examples.
- Required fixes: none. `checkPixel` now formats arrays directly in its failure message. The header documents packing inputs in 0...255, integer layout 0xAABBGGRR, and extraction results in 0...255.
- Evidence executed by reviewer: the Xcode target was built with the command below and the resulting executable was run; both exited successfully. The initial sandboxed build could not write Xcode caches; the same command succeeded after normal cache access was authorized.
- Evidence supplied by learner: prior question answers and their assessment are preserved in the 2026-10-18 entry. The learner also reported completing ignore rules and a shared scheme; the later commit's diff confirms those additions.
- Static-only / unverified items: the historical implementation hash returned HTTP 404 in the current repository, so a fresh diff against that old revision was unavailable. The follow-up used the complete current files and the preserved prior review findings. Release-mode execution and performance were not tested or required for this lesson.
- Understanding questions: all four were previously assessed; the mask-width, OR, and invalid-input corrections were already explained. The prior review explicitly requested no additional answer submission. No new questions are outstanding.
- Next action: begin **M01-L04 — Register width and integer interpretation** using the current Xcode layout.

| Completion requirement | Evidence | Status |
| --- | --- | --- |
| Packing and four extraction functions | Complete assembly inspected; shifts, OR, masks, return register, and scratch-register use match the contract. Assembly compiled and linked through Xcode. | Met |
| Matching C declarations | Five declarations match the exported symbols and use uint32_t. Swift calls link and execute. | Met |
| Explicit channel domain and layout | Pixel.h documents 0...255 packing inputs, 0xAABBGGRR layout, and 0...255 extraction results. | Met |
| Decimal and hexadecimal examples with labelled output | Both examples print 0x44332211; channels print 17, 34, 51, and 68. | Met |
| Exact expected values and round trips, including zero and 255 | All five checkPixel cases completed, including opaque black, opaque white, and mixed endpoint values; runner printed RGBA packing/unpacking tests passed. | Met |
| Earlier examples preserved | Runtime output confirmed alpha 255/0, inversion results 255/254/215/127/0, doubling 200 to 400, and passing double-inversion checks. | Met |
| Bit-position explanation and final questions | Prior answer assessment and explained corrections retained from the 2026-10-18 review. | Met with corrections explained |

The temporary review directory was `/private/tmp/imageengine-review-c97016d`. Exact successful build and run commands:

```bash
xcodebuild -project /private/tmp/imageengine-review-c97016d/ImageEngine.xcodeproj -target ImageEngine -configuration Debug ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO SYMROOT=/private/tmp/imageengine-review-c97016d/build OBJROOT=/private/tmp/imageengine-review-c97016d/obj CLANG_MODULE_CACHE_PATH=/private/tmp/imageengine-review-c97016d/ModuleCache build
/private/tmp/imageengine-review-c97016d/build/Debug/ImageEngine
```

The later workflow commit `50280e44dd0b71b73cb598c869c2b5b513c6ae70` changes only `.gitignore` and adds `ImageEngine.xcodeproj/xcshareddata/xcschemes/ImageEngine.xcscheme`. It was inspected separately; the shared scheme was not used for the earlier target-based build. This progress update is committed afterward so its own commit hash is not used as the reviewed implementation hash.

## How to resume

Read the next lesson plus its prerequisites and inspect the actual repository revision. If code and this ledger disagree, resolve the discrepancy from evidence. Do not infer completion from a commit message alone. Relevant lesson answers may be kept under `learning/answers/` by the learner or supplied in the review conversation.
