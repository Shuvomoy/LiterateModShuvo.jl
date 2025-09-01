# `LiterateModShuvo.jl`


This is a `mod` for `Literate.jl`, which acts the same as the package except: 


- Treats content enclosed in Julia multiline comments (#= and =#) as raw Markdown text, outputting it directly into the Markdown file without any wrapping. (Currently Literate.jl already supports it.)

- All the julia region name in the Julia code becomes a section title, e.g., a line such as `#region RegionName` in the input Julia file becomes a section title in the markdown, e.g., `## RegionName` in the markdown. All the associated `#endregion` are removed from the markdown file (because they are not meaningful anymore given that the beginning of the region has been converted into a Section title). 

- Treats all other content (i.e., Julia code that is (i) not enclosed in these multiline comments, (ii) not  `#region RegionName` or (iii) not `#endregion`) as code blocks, wrapping each contiguous block of code in four backticks with the language specifier `````julia` followed by the code and closing four ybackticks. 

# Installation

You can install this package by typing the following in Julia repl: 

```
add https://github.com/Shuvomoy/LiterateShuvosMod.jl.git
```

# Usage: conversion to markdown

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

# Usage: notebook conversion

Same as `Literate.jl`:

```
LiterateModShuvo.notebook("name_of_the_file.jl")
```





