# Progress and review record

This file records evidence; it does not replace reading the actual implementation.

## Current position

- Next lesson: **M02-L01**
- Current implementation revision: 85a0040f242a01d79c9b1a3890da29da2c2586fe
- Last reviewed implementation revision: 85a0040f242a01d79c9b1a3890da29da2c2586fe
- Toolchain/SDK record: reviewer verified native arm64 execution on macOS 27.0.1 (build 26A434), Apple Swift 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1), Apple Clang 21.0.0 (clang-2100.3.34.2), and the macOS 27.0 SDK on 2026-10-26. L04 was built with direct xcrun compiler commands in debug mode.
- Required fixes still open: none for M01-L05. Completion uses learner-confirmed execution; the unsubmitted trace/note exception is recorded below.
- Current source layout: `ImageEngine/Pixel.s`, `ImageEngine/Pixel.h`, and `ImageEngine/main.swift`, built through `ImageEngine.xcodeproj`. Earlier review entries retain their historical `src/` paths.
- Revision note: 85a0040f242a01d79c9b1a3890da29da2c2586fe is the exact main-branch source snapshot inspected for L05. Its only change from the previously reviewed implementation fc725ed9bef85083346290ecebe5877ca89544a2 is the L04 progress record; all implementation files are unchanged. This L05 progress update is committed afterward. The learner's local executable revision was not independently established.

## Status definitions

Use **Not started**, **In progress**, **Submitted**, **Changes requested**, **Verification pending**, or **Ready**. Ready means required implementation, evidence, and end-of-lesson understanding have been reviewed. A finished coding attempt with unanswered questions is not yet Ready.

Record the exact implementation commit being reviewed. Commit this progress update afterward, so the recorded hash is not self-referential. A later fix requires its own reviewed hash. Keep prior reviews in the history section rather than erasing them.

## Lesson ledger

| Lesson | Status | Reviewed implementation commit | Evidence / answers | Remaining work |
| --- | --- | --- | --- | --- |
| M01-L01 | Ready | 35456db2377fa2afe814cfae2310a9e5972cf8bb | Full source/diff reviewed; learner confirmed expected output, clean build, and environment; answers reviewed with corrections explained. | None. |
| M01-L02 | Ready | c1dd575eb643899fbfc867363d3eb9aea022f160 | Full source/diff reviewed; learner confirmed program execution and all checks; answers assessed with ABI and unsigned-wrap clarifications. Completion accepted at learner's explicit request; documentation/trace exceptions recorded below. | None required for progression. |
| M01-L03 | Ready | c97016d38061bc482a4e3931e4f5bf082700f2a1 | Corrected Swift diagnostic and header contracts inspected; native arm64 Xcode Debug build and all existing checks passed. Prior question assessment retained, with corrections already explained. | None. Next: M01-L04. |
| M01-L04 | Ready | fc725ed9bef85083346290ecebe5877ca89544a2 | Complete implementation and diff reviewed; exact committed runner built and executed on native arm64 macOS; 10 supplementary lesson checks passed. All four answers assessed; corrections to Q3 and Q4 explained. | None. Next: M01-L05. |
| M01-L05 | Ready | 85a0040f242a01d79c9b1a3890da29da2c2586fe | Current source and intervening diff inspected; learner confirmed following the guided LLDB session and everything working as expected. All four answers assessed, with LR naming and final W/X result corrections explained. Unsubmitted trace/note exception recorded below. | None required for progression. Next: M02-L01. |
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

## M01-L04 review — 2026-10-26

- Implementation commit: fc725ed9bef85083346290ecebe5877ca89544a2.
- Previous reviewed implementation commit: c97016d38061bc482a4e3931e4f5bf082700f2a1.
- Files inspected: `ImageEngine/Pixel.s`, `ImageEngine/Pixel.h`, `ImageEngine/main.swift`, `ImageEngine.xcodeproj/project.pbxproj`, `learning/progress.md`, course guide, selected lesson, tutor guidance, and assembly/ABI reference. The complete diff since the previous reviewed revision was inspected. Local HEAD matched the latest pushed main-branch commit and the working tree was clean.
- Reviewer environment: native arm64 macOS 27.0.1 (build 26A434); Apple Swift 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1), target arm64-apple-macosx27.0.0; Apple Clang 21.0.0 (clang-2100.3.34.2); macOS 27.0 SDK. Compiler commands used Xcode's installed tools through `xcrun`.
- Outcome: **Ready**. All three functions, interface types, lesson results, and earlier examples are correct. No required fixes remain.
- Evidence executed by reviewer: extracted the exact committed source files into a temporary directory, assembled and linked them with `xcrun clang` and `xcrun swiftc -g -Onone`, and ran the unchanged committed Swift runner. Compilation and execution exited successfully, and all 23 output lines matched the expected results. A separate reviewer-created Swift runner linked against the same assembly object and passed all 10 lesson checks listed below. Repository source was not changed during review.
- Evidence supplied by learner: reported completing the lesson and submitted all four understanding answers in the teaching conversation. Runtime evidence for this review was independently executed by the reviewer.
- Static-only / unverified items: the Xcode target itself, release-mode behavior, and performance were not tested in this review. They are not required for L04. The supplementary runner is review evidence, not committed project test coverage.
- Understanding questions: Q1 correct: writing W0 does not preserve X0's old upper half. Q2 correct: the self-move establishes zero upper bits. Q3 incorrect initially: a W-register shift is limited to 32 bits, not 64; explained truncation with UInt32.max times four yielding 4,294,967,292 in W0 instead of 17,179,869,180 in X0. Q4 incomplete initially: a valid UInt32 width does not establish valid allocated storage; explained valid starting address, sufficient storage, bounded accesses, and overflow-free size arithmetic. Corrections were explained before the learner submitted the implementation for review; no repeat answer submission was required.
- Required fixes: none.
- Optional improvement: retain explicit checks for every lesson case in `main.swift`. The committed runner prints the maximum-input addition results and all four row-byte results, but only the largest row size has a new explicit failure check; the addition cases for 0 and 254 were verified by the supplementary runner.
- Next action: begin **M01-L05 — Follow the machine in LLDB**.

| Completion requirement | Evidence | Status |
| --- | --- | --- |
| Three complete assembly functions and ABI behavior | Correct W/X operations, explicit widening, exported symbols, and returns. Functions use only X0/W0, make no calls, and perform no memory access. | Met |
| Explicit argument and result widths | Header declares uint32_t inputs and uint64_t results; the Swift runner receives UInt64 results. Compilation, linking, and execution succeed. | Met |
| Add before/after widening | Supplementary checks confirm both functions return 1 for 0 and 255 for 254; UInt32.max produces 0 and 4,294,967,296 respectively. | Met |
| Wide row-byte arithmetic and result table | Header documents 64-bit byte-count calculation; assembly widens before the X-register shift. Runner prints all four required widths with correct results, independently checked below. | Met |
| No giant allocation; arithmetic versus memory validity | Functions calculate integers only. Header states no allocation/access; valid storage and bounded access requirements were explained in the answer assessment. | Met with corrections explained |
| Earlier examples preserved | Unchanged runner passed packing/extraction and double-inversion checks; output confirmed alpha 255/0, inversion 255/254/215/127/0, and doubling 200 to 400. | Met |
| Final understanding questions | All four assessed in conversation; Q1-Q2 correct, Q3-Q4 corrections explained, no further submission requested. | Met with corrections explained |

The 10 independently checked results were:

| Function | Inputs | Expected and observed results |
| --- | --- | --- |
| `add_one_u32_then_widen` | 0, 254, UInt32.max | 1, 255, 0 |
| `widen_then_add_one` | 0, 254, UInt32.max | 1, 255, 4,294,967,296 |
| `rgba_row_bytes` | 0, 1, 3, UInt32.max | 0, 4, 12, 17,179,869,180 |

Exact source snapshots, supplementary runner, and command/output log were kept at `/private/tmp/imageengine-review-fc725ed-p720oppa/` during review (`review.log`). The committed implementation was built and run with:

```bash
xcrun clang -arch arm64 -g -c /private/tmp/imageengine-review-fc725ed-p720oppa/Pixel.s -o /private/tmp/imageengine-review-fc725ed-p720oppa/pixel.o
xcrun swiftc -g -Onone -module-cache-path /private/tmp/imageengine-review-fc725ed-p720oppa/ModuleCache -import-objc-header /private/tmp/imageengine-review-fc725ed-p720oppa/Pixel.h /private/tmp/imageengine-review-fc725ed-p720oppa/main.swift /private/tmp/imageengine-review-fc725ed-p720oppa/pixel.o -o /private/tmp/imageengine-review-fc725ed-p720oppa/ImageEngine
/private/tmp/imageengine-review-fc725ed-p720oppa/ImageEngine
```

The separate `LessonChecks.swift` was compiled with the same header, assembly object, and compiler options and run successfully. This progress update is committed after the reviewed implementation so its own hash is not used as review evidence.

## M01-L05 review — 2026-10-29

- Implementation/source snapshot inspected: 85a0040f242a01d79c9b1a3890da29da2c2586fe.
- Previous reviewed implementation commit: fc725ed9bef85083346290ecebe5877ca89544a2.
- Files inspected: `ImageEngine/Pixel.s`, `ImageEngine/Pixel.h`, `ImageEngine/main.swift`, `learning/progress.md`, tutor guidance, course guide, complete M01-L05 lesson, and debugging reference. The comparison against the previous reviewed revision contains only the L04 progress update; implementation source is unchanged.
- Reviewer environment: remote GitHub source inspection. No new build, program execution, or LLDB session was performed by the reviewer for L05. The toolchain record above is historical L04 evidence; no fresh compiler/SDK output was supplied for this session.
- Initial outcome: **Verification pending** after assessing the answers, while awaiting execution evidence.
- Final outcome: **Ready**, accepting the learner's subsequent confirmation that they debugged as instructed and everything worked as expected, followed by their explicit request to commit and push the updated progress record.
- Evidence supplied by learner: reported completing the guided debugger session successfully. In context, the session covered `invert_channel(40)`, stepping through its return, `widen_then_add_one(UInt32.max)`, inspecting results before `ret`, and finishing execution with existing examples.
- Evidence executed by reviewer: none for L05; source inspection and GitHub revision comparison only. Earlier independent L04 runtime evidence remains recorded in its own review and is not represented as a new debugger run.
- Static-only / unverified items: actual LLDB output, the concise saved trace, the learner note about disassembly/aliases, exact local build/run output, and local revision/working-tree state were not submitted or independently inspected. The learner report is accepted as runtime confirmation. The unsubmitted trace/note is an explicit documentation exception for progression at the learner's completion request, not a claim that those artifacts were reviewed or committed.
- Understanding questions: Q1 correct in substance; clarified that stepping over runs through a call, whereas instruction stepping enters it. Q2 correct: an older executable can prevent resolving the expected function. Q3 correct return-address concept; corrected the register name from `lc` to `lr` (`x30`). Q4 correctly described clearing the upper 32 bits and `w0=0xffffffff` after the self-move; the missing post-add state was explained: `x0=0x0000000100000000`, `w0=0x00000000`. All four were assessed; corrections were explained, with no repeat answer submission required.
- Required fixes: no code defects found in the lesson functions; no required fixes remain for progression.
- Optional improvement: retain concise real LLDB traces and an alias note with future debugging evidence.
- Next action: begin **M02-L01 — Read and write through a pointer**.

| Completion requirement | Evidence | Status |
| --- | --- | --- |
| Predictable inversion input and separate width example | Committed driver first calls inversion with 40 and calls `widen_then_add_one` with `UInt32.max`; matching assembly and declarations inspected. | Met |
| Usable debug build and source/executable correspondence | Learner confirmed following the guided build/debug session successfully; exact local source/executable correspondence was not independently established. | Met by learner confirmation; independent verification unavailable |
| Observe inversion register states and result before return | Guided trace covered entry 40, scratch 255, result 215, and the return; learner confirmed debugging as instructed. Actual output was not supplied. | Met by learner confirmation |
| Observe widening and full result before return | Guided trace covered explicit zero-extension followed by the 64-bit result 4,294,967,296; learner confirmed the session. Post-add W/X views were clarified in answer assessment. | Met by learner confirmation, with correction explained |
| Concise trace and disassembly/alias note | No saved trace or learner note submitted for inspection; teaching examples are expected states, not captured runtime output. | Unverified; documentation exception accepted for progression |
| Existing examples and any restored deliberate errors | Learner reported everything working as expected after the final instructions. Current committed arithmetic remains correct and unchanged; no deliberate-error experiment was reported. | Met by learner confirmation; no deliberate error reported |
| Final understanding questions | All four assessed; step-over behavior, LR naming, and post-add W/X state clarified. | Met with corrections explained |

This documentation-only progress commit follows the inspected source snapshot. It does not add implementation code or fabricate debugger transcripts.

## How to resume

Read the next lesson plus its prerequisites and inspect the actual repository revision. If code and this ledger disagree, resolve the discrepancy from evidence. Do not infer completion from a commit message alone. Relevant lesson answers may be kept under `learning/answers/` by the learner or supplied in the review conversation.
