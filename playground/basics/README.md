# Basics: equality

Every example in this directory expresses the same claim:

$$
1 + 1 = 2
$$

Read it as **“One plus one is equal to two.”** Here `=` means equality,
not assignment. `1 + 1` is an expression; `1 + 1 = 2` is a statement.
The proofs explicitly use natural numbers (`Nat`): `0, 1, 2, …`.

## The same claim in different formats

| File | Role | How to try it |
| --- | --- | --- |
| [basics.tex](basics.tex) | LaTeX document, with inline and display math | Run `pdflatex basics.tex` with a LaTeX installation. |
| [basics.html](basics.html) | Presentation MathML inside an HTML page | Open in a modern browser; no JavaScript or internet required. |
| [basics.presentation.mathml](basics.presentation.mathml) | Standalone presentation MathML | Inspect the XML; the HTML page shows how to embed it. |
| [basics.content.mathml](basics.content.mathml) | Content MathML expression tree | Inspect the XML: `equals(add(1, 1), 2)`. |
| [basics.mathjax.html](basics.mathjax.html) | TeX notation rendered by MathJax | Open in a browser with JavaScript and internet access. |
| [basics.lean](basics.lean) | Claim and checked proof in Lean 4 | Run `lean basics.lean`. |
| [basics.bend](basics.bend) | Claim and checked proof in Bend 2 | Run `bend basics.bend`. |

Run these commands from `playground/basics`.
MathJax is a renderer, not a separate notation language or file format.
Its example uses the same math delimiters as the LaTeX document, but does
not need LaTeX's document wrapper.

## Read the syntax

- **LaTeX / MathJax TeX input:** `\( … \)` means inline math;
  `\[ … \]` means display math on its own line.
- **Presentation MathML:** `mrow` groups a row, `mn` is a number, and `mo`
  is an operator. This describes appearance, not a typed mathematical claim.
- **Content MathML:** `apply` applies an operator to its arguments,
  `eq` is equality, `plus` is addition, and `cn` is a number.
  Content MathML encodes meaning; it is not generally rendered natively by
  browsers as presentation MathML is.
- **Lean:** the claim follows `:` and the proof follows `:= by`.
  `(1 : Nat)` fixes the number type. `rfl` closes this claim because both
  sides reduce to the same value.
- **Bend:** `1n` and `2n` are natural-number literals. `Nat.add` adds them.
  `{… == … : Nat}` is an equality proposition, and `{==}` closes it when
  both sides reduce to the same term.

These are three different jobs: **displaying notation**, **encoding meaning**,
and **checking a proof**. None of the display formats proves the equation.

## Tiny next experiment

Change only the right-hand `2` to `3` in an example.
The LaTeX, MathML, and MathJax examples can still display or encode that false
claim. The Lean and Bend proofs should fail to check.

Then restore `2` and try reversing the two sides. Does that change the claim?
