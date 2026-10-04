# ARM64 image engine: learning by building

A 50-lesson course for a programmer with general programming experience, introductory Swift knowledge, and no assembly or manual-memory experience. Development target supplied by the learner: Apple Silicon M5 Max, macOS 27. The course begins with baseline AArch64 and NEON; it makes no assumptions about undocumented M5 timings or additional instruction extensions.

Everything in this package belongs in your repository's `learning/` directory. You create the implementation outside it while following the lessons. There are no finished project source files in this package. Code fences are teaching material to copy, run, understand, and modify when directed.

## Start here

1. Extract the ZIP at your repository root. It contains one top-level `learning/` directory.
2. Read [the course guide](course-guide.md), then begin **M01-L01**.
3. Give ChatGPT the repository URL and the teaching prompt below. An accessible checkout or uploaded repository ZIP also works.
4. Read one complete lesson message, implement the assignment, then perform the checks and answer the questions at its end.
5. Commit and push the lesson. Request a whole-lesson review using an exact commit hash.
6. Resolve required fixes, then record the reviewed implementation commit in [progress](progress.md).

One lesson is one teaching unit and one review unit. Internal sections do not require separate commits, replies, quizzes, or approval. Aim for 1–2 hours per lesson, but take longer when debugging or learning unfamiliar mathematics. Nothing is timed. Ask for help whenever you want.

## Teaching prompt

```text
Repository: <URL or attached checkout>
Revision: <branch or commit>
Lesson: M01-L01

Read learning/AGENTS.md, learning/course-guide.md, learning/progress.md,
the selected module, and relevant current source before teaching.
Apply learning/AGENTS.md as my requested teaching guidance for this session,
including when discussing source outside learning/.
Teach the entire selected lesson in ONE coherent message. Explain theory,
assembly code, and unfamiliar Swift syntax. Give concrete snippets and exact
file placement at the level of guidance specified by the lesson.
No intermediate quizzes, questions, checkpoint approvals, or requests to continue.
Put all verification and understanding questions at the end for after implementation.
Do not implement or commit the project for me. If you cannot access required
files, say exactly what is missing rather than guessing their contents.
```

## Whole-lesson review prompt

```text
Repository: <URL or attached checkout>
Completed lesson: <Mxx-Lyy>
Implementation commit: <full hash>
Previous reviewed implementation commit: <hash or none>
My end-of-lesson answers and local command output: <paste or paths>

Read learning/AGENTS.md and review the ENTIRE lesson against its requirements.
Inspect the complete relevant implementation at the stated commit, not just
the latest diff. Report requirement-by-requirement evidence, required fixes,
optional improvements, and anything you could not verify. Separate executed
tests from code inspection and my supplied output. Do not claim to have run
macOS ARM64 code unless you actually did. Ask understanding questions only now,
after the full lesson. Propose a learning/progress.md update; do not modify my
implementation unless I explicitly ask.
```

## Course map

| Module | Lessons | Working outcome |
| --- | --- | --- |
| [01 — First assembly](modules/01-first-assembly.md) | M01-L01–L05 | Swift calls small assembly pixel functions; you can trace them in LLDB. |
| [02 — Pixels in memory](modules/02-pixels-and-memory.md) | M02-L01–L05 | A real image is modified in bounded buffers and written to PPM. |
| [03 — Functions and transformations](modules/03-functions-and-transforms.md) | M03-L01–L05 | Contracts, nested calls, crop, and two flips. |
| [04 — Scalar color](modules/04-scalar-color.md) | M04-L01–L05 | Brightness, grayscale, contrast, blending, and compositing. |
| [05 — First NEON](modules/05-first-neon.md) | M05-L01–L05 | Safe vector loops with correct scalar tails. |
| [06 — Advanced NEON data handling](modules/06-neon-data.md) | M06-L01–L05 | Channel operations, exact vector arithmetic, and statistics. |
| [07 — Neighborhood filters](modules/07-filters.md) | M07-L01–L05 | Scalar and vector blur plus edge detection. |
| [08 — Floating point and resize](modules/08-float-and-resize.md) | M08-L01–L05 | Exposure, nearest/bilinear resize, and a linear-light path. |
| [09 — Performance](modules/09-performance.md) | M09-L01–L05 | Repeatable measurements and justified optimizations. |
| [10 — Integrated engine](modules/10-engine.md) | M10-L01–L05 | Pipelines, tiles, parallel work, PNG, and a documented release. |

## References

These are reminders and bridges to official documentation, not substitute instruction manuals.

- [Registers, instructions, and Apple ABI](reference/assembly-and-abi.md)
- [Memory and the Swift boundary](reference/memory-and-swift.md)
- [LLDB and common failures](reference/debugging.md)
- [NEON concepts and instruction families](reference/neon.md)
- [Pixel mathematics and numerical contracts](reference/image-math.md)
- [Testing, evidence, and benchmarking](reference/testing-and-performance.md)
- [Official online resources](reference/resources.md)

## Reproducibility and validation

Course version: **1.0**, prepared 2026-10-03. [Validation notes](validation.md) describe checks performed on this package and the limits of those checks. Record your actual Xcode/Command Line Tools, Swift compiler, and SDK versions when starting; the course does not pin an unverified future toolchain version.

GitHub access is not guaranteed in every ChatGPT environment. A public URL alone may not expose every file to the current tool. If retrieval fails, provide a checkout/archive and the exact commit. Never let a tutor infer unseen implementation from a commit message or the progress table.
