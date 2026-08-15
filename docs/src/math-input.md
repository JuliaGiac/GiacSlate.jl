```@meta
CurrentModule = GiacSlate
```

# Math input

How an expression written on a math keyboard becomes a Julia value, and how a Julia
value becomes typeset mathematics again.

GiacSlate offers two distinct entry points, which are easy to confuse:

| | [`Mathfield`](@ref) | [`@giac_str`](@ref) (`giac"…"`) |
|---|---|---|
| what it is | a `@bind` control | a literal inside a code cell |
| bound value | MathJSON (a `String`) | a `GiacExpr`, directly |
| conversion | [`mathfield_to_giac`](@ref), explicit | none — the literal *is* the expression |
| typical use | an exercise answer to grade | an expression the reader edits in place |

## `giac"…"` — the live literal

A `giac"…"` literal is ordinary Xcas source, evaluated by `giac_eval`:

```julia
factor(giac"x^6 - 1")
desolve(giac"y'' + 4*y = 0 and y(0) = 1 and y'(0) = 0", giac"y(t)")
```

What makes it special is the editor extension `using GiacSlate` installs: inside a code
cell, such a literal **renders** as a typeset MathLive field. Click into it, edit the
mathematics, press <kbd>Enter</kbd> — the literal's source is rewritten and the cell
recomputes. The file stays perfectly ordinary Julia: outside Slate, `giac"x^2+1"`
evaluates exactly the same.

<kbd>⌘</kbd>/<kbd>Ctrl</kbd>+<kbd>M</kbd> inserts a fresh field; the `∫` button in the
cell toolbar does the same with the mouse.

An **empty** literal is `missing`, not an error:

```julia
giac""        # missing
```

That is deliberate: a blank math field should read as "not filled in yet" and flow
through the grader as such, rather than breaking the cell.

## `Mathfield` — the `@bind` control

When what you want is the reader's *answer* rather than an expression edited in place,
bind a control:

```julia
@bind answer Mathfield(label = "your answer")
```

`answer` receives MathJSON — a `String`. To turn it into an expression:

```julia
expr = mathfield_to_giac(answer)   # a GiacExpr, or `missing` if the field is empty
```

Because the bound value is a plain `String`, `SlateExtensionsBase`'s type-driven
coerce/reconcile defaults apply as-is: the answer survives a re-run of the bind cell.

The front-end component (`assets/mathfield.js`) is fetched only on the first binding of
a `Mathfield`, through `required_assets`.

## Typesetting in prose

[`gmath`](@ref) and [`gdisplay`](@ref) render a Giac expression as LaTeX ready to be
interpolated into a Markdown cell with `{{ … }}`:

```julia
# in a code cell
Hs = giac"1/(s^2 + 2*s + 5)"
```

````markdown
The system has transfer function {{ gmath(Hs) }}, a second-order response. Its
unit-step response is

{{ gdisplay(yt) }}
````

`gmath` produces inline math (`$…$`), `gdisplay` a display block (`$$…$$`). Because the
Markdown cell reads the variable, it re-typesets whenever that variable changes.

## The bridge, in both directions

The two conversion functions are exported, and exposed to the front-end as the
`giac_tex` and `giac_src` handlers:

```
GIAC source  ──[ giac_src_to_tex ]──▶  LaTeX          (display)
MathJSON     ──[ mathjson_to_giac_src ]──▶  GIAC source  (write-back)
```

- [`giac_src_to_tex`](@ref) evaluates, then renders to LaTeX. GIAC is lenient — it
  returns `undef` on malformed input instead of throwing — so `undef` is treated as an
  error here: an unreadable field must show as broken, not as the literal word `undef`.
- [`mathjson_to_giac_src`](@ref) returns **source text** and evaluates nothing. Empty
  input, a `null`, and the `["Error", …]` payload MathLive emits for an invalid field
  all give `""` — a half-typed formula must not break the cell being edited.
- [`mathfield_to_giac`](@ref) is the variant that does evaluate, returning a `GiacExpr`.

### What the MathJSON walk translates

MathJSON heads are converted into Xcas source: arithmetic (`Add`, `Subtract`,
`Multiply`, `Divide`, `Power`, `Root`, `Sqrt`), grouping (`Delimiter`, `Sequence`),
`List`, `Equal`, `Subscript`, the usual constants (`Pi`, `ExponentialE`,
`ImaginaryUnit`, `GoldenRatio`, the infinities), and a table of functions (trigonometric
and hyperbolic, `Exp`, `Ln`, `Log`, `Abs`, `Floor`, `Gamma`, `Factorial`, …).

Two explicit refusals, rather than bogus symbols:

- **string literals** are not valid math input;
- **decorated symbols** (`x̂`, `x̄`, `x⃗`, `ẋ`, …) have no clean GIAC counterpart, so the
  conversion raises instead of inventing a `hat(x)` that would neither compute nor
  compare against anything. Use a plain name (`xhat`, `xbar`).

Likewise, a symbol still non-ASCII after canonicalisation is refused.

!!! note "The fallback on unknown heads is not an allowlist"
    An unrecognised MathJSON head is translated into a GIAC function call of the same
    name, lowercased. That is a best-effort fallback, useful for reaching the engine's
    ~1800 commands — not a security boundary. There would be no point in one here
    anyway: a `giac"…"` literal is arbitrary Xcas source by construction. These
    notebooks are meant to be read and run by their owner, not to execute input from an
    untrusted third party.

### Greek letters and subscripts

A math keyboard emits Greek letters as Unicode glyphs, which GIAC treats as distinct
from its ASCII identifiers. A single normaliser is shared by every ingress — the
MathJSON bridge, the `giac"…"` macro, the display path, and the grader — folding:

| written | canonicalised |
|---|---|
| `ω`, `θ`, `Δ` | `omega`, `theta`, `Delta` |
| `x₀`, `ω₁` | `x_0`, `omega_1` |

This unifies **encodings of one symbol**; it never merges two distinct symbols.

## Reference

```@docs
@giac_str
gmath
gdisplay
Mathfield
mathfield_to_giac
giac_src_to_tex
mathjson_to_giac_src
```
