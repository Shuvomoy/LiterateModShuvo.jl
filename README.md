# `LiterateModShuvo.jl`


This is a `mod` for `Literate.jl`, which acts the same as the package except: 


- Treats content enclosed in Julia multiline comments (#= and =#) as raw Markdown text, outputting it directly into the Markdown file without any wrapping. (Currently Literate.jl already supports it.)

- Multiline equations are allowed that can be labeled and referenced. They need to be in the style (situated in the multiline comment blocks)
  ```
  $$
  \begin{aligned}
    Ax &= b \\
    x &\ge 0
  \end{aligned}
  $$ {#eq-Ax-eq-b}
  ```

  and can be referred to as `Equation @eq-Ax-eq-b` in the `.jl` file.

- All the julia region name in the Julia code becomes a section title, e.g., a line such as `#region RegionName` in the input Julia file becomes a section title in the markdown, e.g., `## RegionName` in the markdown. All the associated `#endregion` are removed from the markdown file (because they are not meaningful anymore given that the beginning of the region has been converted into a Section title). 

- Treats all other content (i.e., Julia code that is (i) not enclosed in these multiline comments, (ii) not  `#region RegionName` or (iii) not `#endregion`) as code blocks, wrapping each contiguous block of code in four backticks with the language specifier `````julia` followed by the code and closing four ybackticks. 

## Installation

You can install this package by typing the following in Julia repl: 

```
]add https://github.com/Shuvomoy/LiterateModShuvo.jl
```

## Usage: conversion to markdown

To convert a julia file into markdown, just follow `Literate` syntax:

```
LiterateModShuvo.markdown("name_of_file.jl") # this will be the so called `DefaultFlavor`
```

Other flavors are possible, e.g., 

```
LiterateModShuvo.markdown("name_of_file.jl", flavor = LiterateModShuvo.DocumenterFlavor())
```

```
LiterateModShuvo.markdown("name_of_file.jl", flavor = LiterateModShuvo.LaTeXFlavor())
```

and so on.

and the list of flavors are:

* DefaultFlavor
* DocumenterFlavor
* CommonMarkFlavor
* FranklinFlavor
* QuartoFlavor
* LaTeXFlavor() (will create a compilable LaTeX document besides the markdown files)

## Usage: conversion to LaTeX

```
LiterateModShuvo.markdown("name_of_file.jl", flavor = LiterateModShuvo.LaTeXFlavor())
```

will create both a markdown file and also a LaTeX file, that you can compile in `xetex`. Equation labeling and referencing is allowed in the original Julia file, but they need to adhere to the `Quarto` equation style, for example:

```
#=

$$
\begin{aligned}
  Ax &= b \\
  x &\ge 0
\end{aligned}
$$ {#eq-Ax-eq-b}

Here, Equation @eq-Ax-eq-b represents a system of linear equations with non-negativity constraints.

=#


```

Note that equation labels should always be in format `{#eq-EquationLabel}` (will become `\label{EquationLabel}` in the LaTeX file) and they need to be referred to in format `@eq-EquationLabel` (will become `\eqref{EquationLabel}` in the LaTeX file).

If you include an explicit LaTeX display environment inside the `$$ ... $$` block and also provide a label, it must be a numbered (non-`*`) environment like `equation`/`align` (i.e. do not use `\[...\]` or `equation*`/`align*`).

Also, `##` heading in markdown will become LaTeX section, `###` will become LaTeX subsection, `####` will become LaTeX subsubsection, and `#####` will become LaTeX paragraph.

## Usage: LaTeX <-> Julia conversion

Convert a LaTeX `.tex` file into a "disciplined" Julia `.jl` file:

```
LiterateModShuvo.LaTeX2Jul("paper.tex")                  # writes paper.jl in pwd
LiterateModShuvo.LaTeX2Jul("paper.tex", "outdir")        # optional output dir
```

Rules:

- `tcblisting` blocks become Julia code.
- Everything else becomes `#= ... =#` blocks.
- Display math `\[ ... \]` and common display environments are rewritten to `$$ ... $$`.

Convert back to LaTeX:

```
LiterateModShuvo.Jul2LaTeX("notes.jl")                   # writes notes.tex alongside input
LiterateModShuvo.Jul2LaTeX("notes.jl", convert_bracket_math_only_if_no_begin = false)
```

Rules:

- Julia code outside `#= ... =#` becomes `tcblisting` (minted).
- Text inside `#= ... =#` is treated as LaTeX.
- `$$ ... $$` without `\begin{...}` becomes `\[ ... \]`; display environments wrapped in `$$` are unwrapped.

# Usage: notebook conversion

Same as `Literate.jl`:

```
LiterateModShuvo.notebook("name_of_the_file.jl")
```





