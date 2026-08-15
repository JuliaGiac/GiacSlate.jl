```@meta
CurrentModule = GiacSlate
```

# Autograding

The lesson autograder: how a student's answer is checked, and how to write a lesson of
your own.

The design goal is narrow but strict. A student types an answer into a math field; the
grader must accept **any algebraically equivalent form** — `1/(s+a)` and `(s+a)^(-1)`
and `1/(a+s)` are the same answer — and it must never leak the reference solution by
accident. Answer keys and reference solutions live in the package, never in the
notebook: the reader only ever sees their own code and a self-updating score card.

## The three entry points

```julia
using GiacSlate    # brings grade, check, course_report
```

[`check`](@ref) is the one a student uses most. Drop it in a cell below the answer;
because the cell reads the binding, Slate re-runs it on every edit:

```julia
#%% code
L_exp = giac"1/(s+a)"

#%% code
check(:lap_exp, L_exp)
```

[`grade`](@ref) scores a whole section at once, with omitted exercises shown as "not
attempted":

```julia
grade(:transforms; lap_exp = L_exp, lap_sin = L_sin, inv_lap = f_cos)
```

[`course_report`](@ref) rolls every registered section into one overview — overall
completion plus a bar per section:

```julia
course_report(;
    lap_exp = L_exp, lap_sin = L_sin, inv_lap = f_cos,
    decay_transform = N_s, decay_solution = N_t, half_life = half_life,
    transfer_fn = H, nat_freq = omega_n, damping_ratio = zeta, classify = classify,
)
```

All three render as an HTML score card, so a notebook cell shows a progress bar and a
per-check ✓/✗ list rather than a returned value to read.

If a key is registered in more than one section, `check(:key, answer)` refuses rather
than guessing; disambiguate with `check(:section, :key, answer)`.

## How an answer is compared

Two comparison strategies, chosen per exercise.

### Symbolic answers

`GiacSlate.expect_symbolic` passes if and only if Giac reduces `student - reference` to
zero. It tries `simplify`, then `normal`, and accepts `0` from either. That is exact
algebra, not a tolerance — and it is what makes every equivalent rewriting count.

Three behaviours worth knowing:

- an answer of `missing` (a blank math field) reports **"not answered yet"**, not a
  wrong answer;
- an expression Giac cannot read reports **"couldn't read your expression"**, with the
  error, and never counts as a wrong answer to the mathematics;
- on a genuinely wrong answer, the correct closed form is **not** revealed by default —
  that being the point of the exercise. Pass `reveal = true` to show it.

The student's expression is canonicalised before comparison (`ω` → `omega`, `x₀` →
`x_0`), so an answer typed on the math keyboard compares equal to a reference written
in ASCII. See [Math input](math-input.md).

### Numeric answers

`GiacSlate.expect` grades a student **function** by calling it on fixed argument tuples
and comparing against a reference implementation with a tolerance:

```julia
expect(raw"half-life $t_{1/2}=\ln 2/a$", ans,
       a -> log(2) / a, [(0.5,), (2.0,), (0.1,)]; atol = 1e-8)
```

One `Check` is emitted per case. The student's function is called through a guard, so a
throw or an unfilled `missing` stub reports as a failed check rather than taking the
grader down — an "not implemented yet" case is distinguished from a wrong result.

`GiacSlate.property` is the third combinator: a single boolean assertion as a `Check`,
for when neither of the two above fits.

## Writing a lesson

A lesson is a set of `Section`s registered at load time. Each `Section` carries an id, a
title, a blurb shown when it is fully solved, and a vector of `Exercise`s; each
`Exercise` carries the keyword a reader will pass to `check`/`grade`, a title, a hint,
and the function that turns an answer into a `Vector{Check}`.

```julia
_ref(str) = Giac.giac_eval(str)

register!(Section(:transforms, "Section 1 · Meeting the transform",
    "You can move a signal into the s-domain and back.",
    [
        Exercise(:lap_exp, "1.1 · Transform of a decaying exponential",
            raw"The pole sits at $s=-a$.",
            ans -> expect_symbolic(raw"$\mathcal{L}\{e^{-at}\}$", ans, _ref("1/(s+a)"))),
    ]))
```

Two conventions make this work smoothly:

- reference solutions are built as `giac_eval` **source strings**. Their identifiers
  match the reader's `@giac_var`s **by name**, so no bindings need to be shared between
  the lesson file and the notebook.
- hints and labels are `raw"…"` strings containing LaTeX, rendered in the score card.

`src/laplace_lesson.jl` is the worked example: three sections, ten exercises, mixing
symbolic and numeric grading. Its output is the
[Laplace transform notebook](notebooks/laplace_lesson.md).

## Reference

```@docs
check
grade
course_report
```
