<!--
Use "Related: #NNN" rather than "Fixes #NNN": a PR often addresses part of an
issue, and auto-closing has hidden unfinished work before (#36). Close issues by
hand once the work is genuinely complete.
-->

Related: #

## What changed

<!-- What the diff does, and why this approach. -->

## How it was verified

<!-- Tests run, demo exercised, CI jobs, manual checks. -->

- [ ] `testthat::test_local()` passes locally (run `R CMD INSTALL .` first — shinytest2 tests load the *installed* package)
- [ ] `roxygen2::roxygenise()` re-run if anything in `R/` changed
- [ ] `NEWS.md` entry added (imperative verb, ≤120 chars, no trailing full stop)
