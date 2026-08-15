```@meta
CurrentModule = GiacSlate
```

# API reference

Everything GiacSlate exports, plus the internals a lesson author needs.

The public surface is deliberately small. The notebooks only ever call the ten exported
names below; everything else — the front-end registration, the MathJSON walk, the score
card rendering — wires itself up on `using GiacSlate` and is not meant to be called
directly.

## Index

```@index
Pages = ["api.md", "math-input.md", "grading.md"]
```

## Exported

Each exported name is documented on the page where it is explained in context:

| name | what it is | page |
|---|---|---|
| [`@giac_str`](@ref) | the `giac"…"` literal | [Math input](math-input.md) |
| [`gmath`](@ref), [`gdisplay`](@ref) | typeset a Giac expression in Markdown prose | [Math input](math-input.md) |
| [`Mathfield`](@ref) | the MathLive `@bind` control | [Math input](math-input.md) |
| [`mathfield_to_giac`](@ref) | MathJSON → `GiacExpr` | [Math input](math-input.md) |
| [`giac_src_to_tex`](@ref) | GIAC source → LaTeX (the display side of the bridge) | [Math input](math-input.md) |
| [`mathjson_to_giac_src`](@ref) | MathJSON → GIAC source (the write-back side) | [Math input](math-input.md) |
| [`check`](@ref) | grade one exercise | [Autograding](grading.md) |
| [`grade`](@ref) | grade a whole section | [Autograding](grading.md) |
| [`course_report`](@ref) | roll every section into one overview | [Autograding](grading.md) |

## For lesson authors

These are not exported — reach them as `GiacSlate.expect` and so on — but they are the
building blocks of a lesson file, and they are stable enough to document. See
[Autograding](grading.md) for how they fit together.

```@docs
GiacSlate.expect
GiacSlate.expect_symbolic
GiacSlate.property
GiacSlate.register!
GiacSlate.pass
```

A lesson also uses two plain structs, whose fields are their whole interface:

```julia
Section(id::Symbol, title::String, blurb::String, exercises::Vector{Exercise})
Exercise(key::Symbol, title::String, hint::String, run::Function)
```

`blurb` is shown once the section is fully solved; `key` is the keyword a reader passes
to [`check`](@ref) or [`grade`](@ref); `run` maps an answer to a `Vector{Check}` — in
practice a call to `expect_symbolic`, `expect`, or `property`.

## Not part of the API

Worth naming explicitly, because they are visible in the source and it would be
reasonable to assume otherwise:

- `GiacSlate.__slate_frontend` — the package-global hook Slate calls to install the
  editor extension and the two bridge handlers. Slate calls it; you do not.
- `GiacSlate.MathfieldButton` — the `∫` cell-toolbar action, registered by that hook.
- `_canon_src`, `_giac_src`, `_clean_symbol`, `_giac_fn` — the canonicalisation and
  MathJSON-walk internals. Their behaviour is described in
  [Math input](math-input.md), but their signatures are not stable.
- `Check`, `ExResult`, `GradeReport`, `CourseReport` — the grader's result types.
  They exist to be rendered as a score card, not to be inspected.
