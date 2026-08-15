```@meta
CurrentModule = GiacSlate
```

# Getting started

Installing GiacSlate, opening the first notebook, and knowing what loads itself versus
what you have to declare.

## Installation

GiacSlate is not in the General registry yet, so it installs straight from the
repository. From the Pkg REPL (press `]`):

```julia-repl
pkg> add https://github.com/JuliaGiac/GiacSlate.jl
```

Once the package is registered, `pkg> add GiacSlate` will be the one-liner.

The algebra engine itself arrives with [Giac.jl](https://github.com/JuliaGiac/Giac.jl),
which is a dependency: there is no system Giac to install alongside.

## Opening a notebook

The notebooks are Kaimon Slate files, so you need the `slate` CLI (from
[KaimonSlate.jl](https://github.com/kahliburke/KaimonSlate.jl)):

```sh
git clone https://github.com/JuliaGiac/GiacSlate.jl.git
cd GiacSlate.jl
slate notebooks/giac_intro.jl
```

Start with `giac_intro.jl` — it is the only one that is a prerequisite for the others.

## The notebook environment

`notebooks/Project.toml` declares the environment the four notebooks run in:

```toml
[deps]
Giac = "e4421f97-9838-4fd0-9fa5-94f11373bf78"
GiacSlate = "f4c9f34b-fa6a-4506-9309-e8c0bac809fa"
KaimonSlate = "f7b954f5-0334-4562-ac21-b005218ce1da"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"

[sources]
GiacSlate = {path = ".."}
```

That file is not a convenience: it is what DocumenterSlate activates in the isolated
process that executes each notebook in CI. Without it, resolution would fall back to
the `Slate.env` footer embedded in the `.jl` files, which lists only `Giac` — and every
`using GiacSlate` cell would fail.

## What loads itself

This is the part that surprises people coming from other Slate extensions: **there is
no boot cell**.

```julia
using Giac
using GiacSlate
```

Those two lines are the whole setup. On `using GiacSlate`, `SlateExtensionsBase`'s
package-global front-end hook installs:

- the **editor extension** that turns every `giac"…"` literal in a code cell into a live
  MathLive math field;
- the two **JS ↔ Julia bridge handlers** — `giac_tex` (GIAC source → LaTeX, the display
  side) and `giac_src` (MathJSON → GIAC source, the write-back side);
- the **`∫` button** in every code cell's toolbar, the clickable twin of
  <kbd>⌘</kbd>/<kbd>Ctrl</kbd>+<kbd>M</kbd>.

The [`Mathfield`](@ref) control's own component loads **lazily**, the first time a
`Mathfield` is bound, and not before.

## Declaring symbolic variables

Giac works on symbols, which have to be introduced on the Julia side:

```julia
@giac_var x
@giac_var t
@giac_var s
```

Watch out for one encoding trap: a math keyboard emits Greek letters as Unicode glyphs
(`ω`), and to GIAC `ω` and `omega` are **distinct** symbols — `omega - ω` does not
cancel. GiacSlate therefore folds every Greek glyph onto its Xcas name at each ingress
(the `giac"…"` literal, the MathJSON bridge, the grader), so a keyboard-entered `ω` and
a typed `omega` are the same variable everywhere. Unicode subscripts likewise: `x₀`
becomes `x_0`.

## The four notebooks

| | notebook | what's in it |
|---|---|---|
| 1 | [`giac_intro.jl`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/notebooks/giac_intro.jl) | exact algebra, calculus, linear algebra, Taylor series driven by a slider |
| 2 | [`giac_tour.jl`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/notebooks/giac_tour.jl) | the map of the Xcas engine, math field by math field, with its list of sharp edges |
| 3 | [`laplace_lesson.jl`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/notebooks/laplace_lesson.jl) | a physics lesson on the Laplace transform, with self-grading exercises |
| 4 | [`custom_controls.jl`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/notebooks/custom_controls.jl) | the playground for the widget extension points |

The pages under **The notebooks** on this site are the real output of those files,
executed headlessly.

!!! note "Two cells of `giac_intro.jl` show an error on this site"
    They read `fkey.value` from a labeled `Select`, which is what the widget contract
    says to do. It fails because KaimonSlate registers its built-in widget kinds at
    module top level rather than in `__init__`, so the registration is lost to
    precompilation and the kind registry is empty at run time — the bind then returns a
    bare `String` instead of a `Choice`. This affects a live Slate session too; the
    documentation build is simply what executes these cells in CI. See
    [`UPSTREAM.md`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/UPSTREAM.md),
    defect 1.

## Building this documentation

The site builds in two deliberately separate steps:

```sh
julia --project=docs docs/render.jl   # executes the notebooks, fills docs/slate_cache
julia --project=docs docs/make.jl     # builds the site, executes no cell
```

Or, with [`just`](https://github.com/casey/just):

```sh
just docs
```

The second script runs with `execution = :never`: a cache miss raises there instead of
falling back to executing. That is what lets the deploy job — the only one holding
`DOCUMENTER_KEY` — never run notebook code. See
[`.github/workflows/docs.yml`](https://github.com/JuliaGiac/GiacSlate.jl/blob/main/.github/workflows/docs.yml).
