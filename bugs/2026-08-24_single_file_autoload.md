# mvdstudy / mvcrr unrecognized after autoload (single-file packaging)

**Date:** 2026-08-24
**Affects:** v1.3.3, v1.3.4 (every published version)
**Severity:** High — breaks documented usage for any `net install` user
**Status:** Fixed in v1.4.0 (one `.ado` per command + `lmvgstudy.mlib`; see CHANGELOG.md and the v1.4.0 commit/tag)

## Symptom

```
. mvcrr ...
command mvcrr is unrecognized
r(199);
```

in a fresh session, or — intermittently — mid-script:

```
. mvgstudy (p_one = p l|p) , bootstrap
  (runs fine)
. mvdstudy , obj(p) current error(relative) bootstrap
command mvdstudy is unrecognized
r(199);
```

First observed 2026-08-24 in
`dissertation/chapter_2/sdi_scoring/application/code/05_validate_teacher_scores.do`
after switching from `include ".../mvgstudy.ado"` to the PLUS-installed copy.
The `mvgstudy` call with `bootstrap` (B = 1000) succeeded; the following
`mvdstudy` call failed.

## Cause

`mvgstudy.ado` defines all commands in one file:

| line | program |
|---|---|
| 19 | `mvgstudy` |
| 152 | `mvdstudy` |
| 348 | `mvcrr` |
| 637 | `parse_equation` (helper) |
| ~650–3574 | Mata block defining class `mvgstudy` |

Stata autoloads an ado-file **only by the name of the command being called**,
i.e. `mvdstudy` triggers a search for `mvdstudy.ado`, which does not exist.
Two failure modes follow:

1. **Cold start.** `mvdstudy` or `mvcrr` called before any `mvgstudy` call in
   the session is unrecognized. `mvcrr` in single-replication mode is
   documented as standalone, so this is a natural first command for a user to
   type.
2. **Auto-drop.** Even after `mvgstudy` has loaded the file, Stata silently
   drops autoloaded programs when its program cache fills (a long bootstrap
   loads many internal ado programs and does this reliably). `mvgstudy` can be
   reloaded by name; `mvdstudy` and `mvcrr` cannot, so they fail
   unpredictably. This looks flaky rather than deterministic.

`include` (and `run`/`do`) never hit either mode because programs defined that
way are user programs, not autoloaded programs, and are exempt from auto-drop.
That is why the bug was invisible during development.

The three separate `.sthlp` files and the `.pkg` description present these as
three commands, so users will reasonably expect each to work on its own.

## Workaround (users)

Load the file explicitly once per session:

```stata
capture findfile mvgstudy.ado
if _rc {
    display as error "mvgstudy.ado not found on the adopath"
    exit 111
}
run "`r(fn)'"
```

This is what `05_validate_teacher_scores.do` and `06_select_configs_crr.do`
in the dissertation chapter_2 pipeline now do. It is not a documented usage
and should not be required.

## Fix (planned)

Standard Stata packaging: one command per file.

1. Split into `mvgstudy.ado`, `mvdstudy.ado`, `mvcrr.ado`. Rename the helper
   to `_mvg_parse_equation.ado` (leading underscore = internal; avoids
   namespace collisions on user machines).
2. Move the Mata class out of the ado into a compiled library
   `lmvgstudy.mlib` (`mata mlib create lmvgstudy` / `mata mlib add`). Library
   functions are resolved by name from any ado, are not subject to auto-drop,
   and avoid recompiling ~2,900 lines of Mata on every reload. Keep the Mata
   source as `mvgstudy.mata` in the repo for development.
3. `mvdstudy` and `mvcrr` (full mode) legitimately require a prior `mvgstudy`
   run to have left a class instance in Mata memory. Each should check for it
   and exit with a clear "run mvgstudy first" error rather than a Mata
   instance error.
4. Update `mvgstudy.pkg` (`f` lines for the new `.ado` files and the `.mlib`)
   and `stata.toc`; bump to v1.4.0 and note in `CHANGELOG.md` that users must
   `net install ... replace` and that the change is behavior-neutral (point
   estimates and CIs identical to v1.3.4).
5. Verify by rerunning the chapter_2 script above against the new install and
   diffing its log against the v1.3.4 log (expected: identical apart from
   timestamps).

## Development location

Working copy for the fix: `Box-Box/mvgstudy_rewrite/stata_release_v2/`
(currently byte-identical to the repo `mvgstudy.ado`). Sync to this repo once
the refactor passes the check in step 5, then tag and push.
