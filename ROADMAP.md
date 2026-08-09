# Roadmap — GIAC surface not yet covered by the notebooks

An audit of what the four notebooks in `notebooks/` exercise, and what they leave
untouched in the GIAC/Xcas engine (~2200 functions). Every snippet below was run
against the engine and returns the result shown, so each item is a concrete cell
waiting to be written rather than a guess about what might work.

## Covered today

| Notebook | Surface |
| --- | --- |
| `giac_tour.jl` | expand/factor/simplify/partfrac, diff/integrate/limit/taylor, solve/csolve/desolve, inv/det/eigenvalues/charpoly, ifactor/chrem/nextprime/polynomial gcd, laplace/fourier, trigexpand/tlin, complex parts |
| `giac_intro.jl` | the same core, driven from Julia with `tex`/`mathblock`, plus Taylor + second-order step response with ECharts |
| `laplace_lesson.jl` | laplace/ilaplace, transfer function, poles, damping regimes, self-grading exercises |
| `custom_controls.jl` | `giac"…"` live fields, `gmath`/`gdisplay` interpolation, widget plumbing |

## Gaps

### 1. Z-transform — promised in prose, never demonstrated

`giac_tour.jl` §6 announces "Laplace (and its inverse), Fourier, **and the
z-transform**" and then shows only the first two. The most visible hole.

```
ztrans(n^2, n, z)         → (z^2+z)/(z^3-3*z^2+3*z-1)
invztrans(z/(z-1), z, n)  → 1
```

### 2. Heaviside and Dirac — the pedagogical hole in the Laplace lesson

The lesson covers initial conditions but has no step or impulse input and no
time-shift theorem, which is the practical core of the transform for physics and
control.

```
laplace(Heaviside(t-3)*(t-3)^2, t, s)  → 2*exp(-3*s)/s^3
laplace(Dirac(t-2), t, s)              → exp(-2*s)
```

Related and equally absent: `piecewise` / `when` for signals defined by parts.

```
piecewise(x<0, -x, x>=0, x)
```

### 3. Discrete recurrences

`rsolve` is to sequences what `desolve` is to ODEs — Binet's formula in one line.

```
rsolve(u(n+2)=u(n+1)+u(n), u(n), [u(0)=0, u(1)=1])
  → [(-sqrt(5)/5)*((1-sqrt(5))/2)^n + (sqrt(5)/5)*((1+sqrt(5))/2)^n]
```

### 4. Vector calculus

```
curl([x*y, y*z, z*x], [x,y,z])      → [-y, -z, -x]
divergence([x^2,y^2,z^2], [x,y,z])  → 2*x+2*y+2*z
grad(x^2*y, [x,y])                  → [2*x*y, x^2]
laplacian(x^2+y^2, [x,y])           → 4
hessian(x^2*y+y^3, [x,y])           → [[2*y, 2*x], [2*x, 6*y]]
```

Note: `jacobian([x*y, x+y], [x,y])` came back unevaluated in testing — worth
investigating before putting it in a notebook.

### 5. Units and physical constants

A full unit system, never mentioned anywhere. Cheap to demo and directly useful
in a physics lesson.

```
convert(100_km/_h, _m/_s)  → 27.7777777778_(m*s^-1)
mksa(1_eV)                 → 1.602176634e-19_(kg*m^2*s^-2)
3_N * 2_m                  → 6_(N*m)
```

### 6. Numerics and arbitrary precision

Everything in the notebooks is exact; nothing is ever approximated. The
exact ↔ numeric contrast is itself a good lesson.

```
fsolve(cos(x)=x, x)            → [0.739085133215]
romberg(exp(-x^2), x, 0, 1)    → 0.746824132812
odesolve(sin(t*y), t=0..2, y, 1)
evalf(pi, 50)                  → 50 exact digits
```

### 7. Statistics and regression

Zero coverage: `mean`, `stddev`, `median`, `quartiles`, `linear_regression`,
`polynomial_regression`, distributions.

```
linear_regression([[1,2],[2,4.1],[3,5.9]])  → [1.95, 0.1]
normald_cdf(0, 1, 1.96)                     → 0.975002104852
binomial(10, 3, 0.5)                        → 0.1171875
quartiles([1,2,3,4,5,6,7,8])
```

### 8. Matrix decompositions and subspaces

Only `inv`/`det`/`eigenvalues`/`charpoly` are shown. Missing: `lu`, `qr`, `svd`,
`cholesky`, `jordan`, `rank`, `ker`, `image`, matrix exponential — and
`linsolve`, which is imported in the `giac_tour.jl` setup cell and never called.

```
exp([[0,1],[-1,0]])          # matrix exponential = rotation
jordan([[2,1,0],[0,2,1],[0,0,2]])   → (P, J) pair
ker([[1,2],[2,4]])           → [[2,-1]]
svd([[1,2],[3,4]])
```

### 9. Polynomial toolbox

```
resultant(x^2-1, x^2-4, x)       → 9
discriminant(x^2+b*x+c, x)       → b^2-4*c
gcdex(x^2-1, x^2+2*x+1, x)       → [-1, 1, 2*x+2]     # polynomial Bézout
gbasis([x^2+y^2-1, x-y], [x,y])  → [2*y^2-1, x-y]     # Gröbner basis
sturmab(x^3-2*x+1, x, -3, 3)     → 3                  # real roots in a range
lagrange([1,2,3], [1,4,9], x)                          # interpolation
cyclotomic(12), tchebyshev1(4), legendre(3)
```

### 10. Inequalities and optimisation

```
solve(x^2 > 4, x)                 → [x < -2, x > 2]
extrema(x^4-4*x^2, x)             → [[sqrt(2), -sqrt(2)], [0]]
fMin(x^4-4*x^2, x=0..3)           → sqrt(2)
simplex_reduce([[1,2],[3,1]], [8,9], [3,2])   → linear programming
```

### 11. The Xcas language itself

The notebooks use GIAC only as an expression evaluator. It is a programming
language: function definitions, loops, conditionals, local variables — all valid
inside a `giac"…"` field.

```
f(u) := u^2 + 1;  f(3)   → 10
```

### 12. Special functions

```
Gamma(1/2)     → sqrt(pi)
erf(1.0)       → 0.84270079295
BesselJ(0,1.0) → 0.765197686558
Zeta(2)        → pi^2/6
Si(1.0), Ci(1.0), Beta(2,3)
```

### 13. Mentioned in prose but never shown

- §5 of the tour says "totients" without ever calling it: `euler(360)` → `96`.
- The "dragons" section describes `assume` with no worked example:
  `assume(a>0)` then `integrate(exp(-a*x), x, 0, inf)`.

### 14. Number theory beyond factorisation

```
dfc(pi, 6)              → [3,7,15,1,292,1,…]   # continued fraction
powmod(7, 222, 11)      → 5
ichinrem([2,3],[3,5])   → [8,15]
GF(2, 8)                                        # finite fields
```

### 15. Whole subsystems untouched

- **Synthetic geometry**: `point`, `line`, `circle`, `inter`, `distance` —
  `distance(point(0,0), point(3,4))` → `5`, and `inter(line(y=x), circle(point(0,0),1))`
  returns both intersection points exactly.
- **Graph theory**: the `graphtheory` package.

### 16. Trig/log rewriting

`texpand`, `tcollect`, `trig2exp`, `halftan`, `lncollect`, `normal` — several are
imported in `giac_tour.jl`'s setup and never used. The full list of
imported-but-unused names there: `normal`, `collect`, `limit`, `series`,
`linsolve`, `ilaplace`, `isprime`, `texpand`, `tcollect`, `eigenvectors`, `rref`.
Either use them or trim the import.

## Porting the Giac.jl examples

[`s-celles/Giac.jl/examples`](https://github.com/s-celles/Giac.jl/tree/main/examples)
holds six Pluto notebooks that should be ported to Slate. They cover a
different axis from the gaps above: not GIAC commands we've missed, but the
**Julia-side API** — conversion, `build_function`, the Symbolics.jl bridge —
which the current notebooks use incidentally and never explain.

| Example | Content | Port notes |
| --- | --- | --- |
| `01_basics.jl` | Symbolic variables, Julia↔GIAC conversion (`to_julia`, `to_giac`, from a Julia function), arbitrary-precision arithmetic, polynomial ops, calculus, `solve`/`fsolve`, string-based evaluation | Mostly direct. The conversion section is the valuable part — nothing in `notebooks/` documents the type boundary. |
| `02_latex.jl` | LaTeX rendering, derivative/integral display, Laplace **and z-transform**, matrices, how the rendering works | Partly superseded by `tex`/`gmath`/`gdisplay` and Slate's `{{ … }}`; rewrite around those rather than transliterate. Contains the z-transform demo missing from §1 above. |
| `03_examples.jl` | The broad command reference: algebra, `numerator`/`denominator`, the `~` equation operator, `substitute`, calculus, limits/series, Riemann sums and products, solve family, **vector calculus**, the full trig-rewrite set, linear algebra, Laplace + z-transform, and **held commands** (unevaluated Leibniz-notation display) | Largest overlap with `giac_tour.jl`. Merge rather than duplicate: fold the genuinely new pieces (`substitute`, `~`, held commands, vector calculus, z-transform) into the tour. Held commands are worth their own subsection — nothing in `notebooks/` shows an unevaluated $\frac{d}{dx}$ next to its result. |
| `04_plotting.jl` | `GiacExpr` → Julia function, 1D plot, 3D surface, `build_function`, gradient vector field | **Needs design work, not translation.** It is built on Plots.jl; Slate uses ECharts. A 1D line ports cleanly, but the surface plot and the `quiver!` vector field have no direct ECharts equivalent — decide on a substitute (heatmap + contour for the surface, line segments or a scatter with rotated symbols for the field) before starting. |
| `05_programming.jl` | GIAC's own language: `proc`, `if/then/else`, `for`, `while`, `local`, calling a GIAC procedure from Julia, wrapping it in a Julia function | Direct port, and it fills gap §11 exactly. Good candidate to become the "Xcas language" notebook rather than a tour section. |
| `06_symbolics_bridge.jl` | Giac.jl × Symbolics.jl: `to_giac(::Num)`, `to_symbolics(::GiacExpr)`, round-trip, `build_function` with `:giac` vs `:symbolics` backends **plus a benchmark**, then a gap showcase where Symbolics.jl cannot do what GIAC can (trig simplification, factorization, partfrac, Laplace, integer factorization, resultants, Diophantine equations, transcendental solving, square-free decomposition) | The strongest standalone port and entirely absent here. Adds a dependency on Symbolics.jl — keep it in its own notebook so the others stay light. The benchmark cells need care: they must not run on every reactive re-evaluation. |

Shared mechanical work for all six: Pluto `md"""` → Slate `@md"""`, PlutoUI
`@bind` widgets → Slate's `@bind`/`Slider`/`Select`, Pluto's `begin … end` cell
blocks → Slate cells with `id=`, and Plots.jl → `echart`. Wherever an example
prints a raw expression, prefer a live `giac"…"` field so the reader can edit it —
that is the whole point of the Slate port.

## Priorities

Ordered for this repository's audience (physics / control engineering, with a
self-grading path):

1. **Extend `laplace_lesson.jl` with Heaviside/Dirac and the time-shift theorem.**
   This is a gap in the teaching, not merely an unused feature.
2. **New notebook: discrete signals.** `ztrans`/`invztrans` plus `rsolve`, mirroring
   the Laplace lesson structure. Natural follow-on for sampled-data systems.
3. **New notebook: exact vs numeric.** `fsolve`, `romberg`, `odesolve`,
   `evalf(pi,50)`, alongside the `integrate(1/x, x, -1, 1)` trap already documented
   in the tour's "dragons" section.
4. **New notebook: units and constants.** Short, high value for physics.
5. **Three new sections in `giac_tour.jl`**: vector calculus, matrix
   decompositions, inequalities/optimisation — and the two or three lines needed
   to make good on what the text already promises (z-transform, totient). Fold in
   `substitute`, the `~` equation operator, and held commands from
   `03_examples.jl` at the same time.
6. **Port `05_programming.jl`** as a standalone "the Xcas language" notebook —
   direct translation, closes gap §11.
7. **Port `01_basics.jl`**, keeping the conversion and arbitrary-precision
   sections and dropping what the tour already covers. Documents the Julia↔GIAC
   type boundary, which nothing here does today.
8. **Port `06_symbolics_bridge.jl`** as its own notebook, with the Symbolics.jl
   dependency isolated there.
9. **`04_plotting.jl`** last: it needs an ECharts design for the surface plot and
   the gradient field before it can be ported at all.

`02_latex.jl` has no separate item — its material belongs inside the notebooks
above (rendering via `tex`/`gmath`, z-transform in the discrete-signals notebook).
