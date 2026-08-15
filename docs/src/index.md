```@raw html
---
layout: home

hero:
  name: GiacSlate.jl
  text: Computer algebra, live in the notebook
  tagline: Giac — the engine behind Xcas — driven from Julia, with editable MathLive math fields, typeset results, and exercises that grade themselves.
  actions:
    - theme: brand
      text: Get started
      link: /getting-started/
    - theme: alt
      text: The notebooks
      link: /notebooks/
    - theme: alt
      text: View on GitHub
      link: https://github.com/JuliaGiac/GiacSlate.jl
  image:
    src: /logo.svg
    alt: GiacSlate.jl
    dark: /logo-dark.svg

features:
  - icon: ∫
    title: Exact algebra
    details: Factor, integrate, solve, transform — with no floating-point roundoff anywhere. All ~1800 GIAC commands, reachable from Julia.
    link: /notebooks/
  - icon: ⌨️
    title: Live math fields
    details: A giac"…" literal renders as an editable MathLive field. The reader types fractions and exponents; the cell recomputes.
    link: /math-input/
  - icon: ✅
    title: Self-grading exercises
    details: A symbolic grader that accepts any algebraically equivalent form, with score cards, hints, and a progress report.
    link: /grading/
  - icon: 🧩
    title: A native Slate extension
    details: Built on SlateExtensionsBase — no boot cell, no assets to declare. `using GiacSlate` is the whole setup; the front-end loads on demand.
  - icon: 📐
    title: Typeset in prose
    details: gmath and gdisplay drop a Giac expression into the middle of a Markdown paragraph, and it re-typesets when the variable changes.
    link: /math-input/
  - icon: 🔁
    title: Reproducible in CI
    details: Every notebook is executed and published as a Documenter page by DocumenterSlate — with verifiable archives, provenance, and a deploy job that executes nothing.
---
```

## What it is

**GiacSlate.jl** connects [Giac.jl](https://github.com/JuliaGiac/Giac.jl) — the Julia
wrapper around [Giac](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac_fr.html),
the computer algebra engine behind Xcas — to reactive
[Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl) notebooks.

It supplies three things neither Giac.jl nor Slate provides on its own:

1. a **typed `@bind` control** ([`Mathfield`](@ref)) whose value is an expression
   entered on a math keyboard, not a string;
2. a **MathJSON ↔ GIAC source ↔ LaTeX bridge**, which is what makes a `giac"…"` render
   as typeset mathematics and become editable on click;
3. a **symbolic autograder**, which compares a student's answer to a reference solution
   by algebraic equivalence rather than by string equality.

The four notebooks in [`notebooks/`](https://github.com/JuliaGiac/GiacSlate.jl/tree/main/notebooks)
are not mockups: the pages under **The notebooks** are the real output of those `.jl`
files, executed headlessly by
[DocumenterSlate.jl](https://github.com/s-celles/DocumenterSlate.jl).

## Installation

GiacSlate isn't registered yet. From the Pkg REPL (press `]`):

```julia-repl
pkg> add https://github.com/JuliaGiac/GiacSlate.jl
```

Then, to open a notebook:

```sh
git clone https://github.com/JuliaGiac/GiacSlate.jl.git
cd GiacSlate.jl
slate notebooks/giac_intro.jl
```

[Getting started](getting-started.md) covers the `slate` CLI and the notebook
environment in more detail.

## A taste

```julia
using Giac, GiacSlate
using Giac.Commands: factor, integrate, laplace

@giac_var x
@giac_var t
@giac_var s

factor(x^4 - 1)              # (x-1)*(x+1)*(x^2+1)
integrate(x * exp(x), x)     # (x-1)*exp(x)
laplace(exp(-2t), t, s)      # 1/(s+2)
```

…and, inside a notebook cell, the same thing editable with the mouse:

```julia
factor(giac"x^6 - 1")        # the literal is a live MathLive field
```

## Where to go next

```@contents
Pages = ["getting-started.md", "math-input.md", "grading.md", "api.md"]
Depth = 2
```
