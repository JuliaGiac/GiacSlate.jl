```@meta
CurrentModule = GiacSlate
```

# The notebooks

Four Kaimon Slate notebooks in
[`notebooks/`](https://github.com/JuliaGiac/GiacSlate.jl/tree/main/notebooks). The pages
in this section are their real output, executed headlessly by
[DocumenterSlate.jl](https://github.com/s-celles/DocumenterSlate.jl) — not a
transcription. Every page carries a verified source download, a reproducible archive,
and a KaimonSlate command that lets you inspect the notebook without evaluating a
single cell.

Open one with `slate notebooks/giac_intro.jl`. Only `giac_intro.jl` is a prerequisite
for the others; after that they are independent.

| | notebook | what you get |
|:--|:--|:--|
| 1 | [Symbolic Computation with Giac.jl](notebooks/giac_intro.md) | the way in — algebra, calculus, Laplace, and two interactive explorers |
| 2 | [A Tour of GIAC](notebooks/giac_tour.md) | the map of the engine in nine sections, ending in a list of sharp edges |
| 3 | [The Laplace Transform](notebooks/laplace_lesson.md) | a physics lesson with ten self-grading exercises |
| 4 | [Custom Controls Playground](notebooks/custom_controls.md) | the widget extension points, taken apart |

## 1 · Symbolic Computation with Giac.jl

Exact algebra first: factoring, expanding, simplifying and partial fractions, all
returning closed forms that Slate typesets directly. Then equation solving with genuinely
exact roots — rational, irrational and complex. Then calculus: derivatives, closed-form
integrals, and limits including improper ones.

Two interactive pieces carry the notebook:

- **A Taylor explorer.** Pick a function and a truncation order; Giac computes the Taylor
  polynomial about ``x = 0`` *symbolically*, and it is plotted against the exact curve.
  Push the order up and watch the polynomial hug the function — then notice that
  ``\arctan x`` still diverges past its radius of convergence ``|x| = 1``, however many
  terms you add.
- **A second-order system, end to end.** Giac inverts ``H(s)/s`` symbolically to get the
  exact step response — no numerical ODE solver anywhere. Drag the damping ratio and
  natural frequency: the closed form, the pole locations in the complex ``s``-plane, and
  the time response all move together, and the poles split into a complex-conjugate pair
  as ``\zeta`` drops below 1.

Between them, forward and inverse Laplace transforms, including a round trip that has to
land back on the signal it started from.

## 2 · A Tour of GIAC

The working map of the engine, in nine sections: algebra, calculus, solving equations and
ODEs, linear algebra, number theory and exact arithmetic, integral transforms,
trigonometry, complex numbers — and then **§9, "Here be dragons"**.

That last section is the reason to read this notebook rather than a command list. It is
an honest inventory of the sharp edges, found by building the rest of the notebook:

- `desolve` fails **silently** — conditions passed as a list return `[]` rather than
  raising. Join them with `and`, and keep the whole call inside one `giac"…"` field.
- singular integrals are taken at face value: `integrate(1/x, x, -1, 1)` returns `0`,
  the formal principal value, with no warning that the integrand blows up.
- `mod` is a residue *class*, not a remainder. `173 mod 12` stays in ℤ/12; for the plain
  integer, use `irem`.
- bare symbols are assumed real, until you say `assume(y, complex)`.
- series carry their remainder term.

Every boxed expression on the page is a live math field in the running notebook: click,
edit the mathematics, press <kbd>Enter</kbd>, and the cell recomputes. Since each one is
ordinary Xcas source, all ~1800 GIAC commands are one keystroke away.

## 3 · The Laplace Transform

A lesson, not a demonstration. It builds the transform up through three physical systems
— exponential decay, a first-order RC circuit, and the damped harmonic oscillator —
around the one idea that makes it worth learning: differentiation in time becomes
multiplication by ``s``, so a differential equation turns into algebra.

Ten exercises across three sections grade themselves as you type:

| section | exercises |
|:--|:--|
| Meeting the transform | ``\mathcal{L}\{e^{-at}\}``, ``\mathcal{L}\{\sin \omega t\}``, and one inverse |
| First-order systems | transform the decay law, invert it, then a numeric half-life |
| Second-order systems | the oscillator's transfer function, ``\omega_n``, ``\zeta``, and classifying the regime |

Symbolic answers are typed into a live math field and compared by algebraic equivalence,
so any equivalent form counts. Numeric answers are written as Julia functions and checked
against a reference on fixed cases. See [Autograding](grading.md) for how that works, and
how to write a lesson of your own.

## 4 · Custom Controls Playground

The scratchpad where the extension points get taken apart: `slateRegisterWidget`,
`slateRegisterEditorExtension`, and the giac↔LaTeX bridge handlers behind them. It shows
a Giac variable dropped straight into **prose** with `gmath` and `gdisplay` and
re-typesetting as the variable changes, then `giac"…"` running live in a real code cell —
no sandbox — with <kbd>⌘</kbd>/<kbd>Ctrl</kbd>+<kbd>M</kbd> inserting a fresh field.

Read it for the mechanism, not for the mathematics. [Math input](math-input.md) is the
prose version of the same material.

## How these pages are built

```sh
julia --project=docs docs/render.jl   # executes the notebooks, fills docs/slate_cache
julia --project=docs docs/make.jl     # builds the site, executes no cell
```

The split is deliberate: the job that runs notebook code holds no secrets, and the job
that holds `DOCUMENTER_KEY` runs with `execution = :never`, where a cache miss raises
rather than falling back to executing. See [Getting started](getting-started.md#Building-this-documentation).

Every cell of every notebook is executed, and `fail_on_error` is left at its strict
default: a cell that throws fails the build rather than shipping as a caveat.

!!! note "Where a chart should be, you will see a `Dict`"
    An ECharts figure is a live browser chart with no server-side renderer, and
    DocumenterSlate extracts only `image/png` and `image/svg+xml` as page assets — so
    such a cell is written out as its `text/plain` form, option dictionary and data
    series included. Three cells are affected. In the running notebook they are ordinary
    interactive plots. See [`UPSTREAM.md`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/UPSTREAM.md),
    defect 3.
