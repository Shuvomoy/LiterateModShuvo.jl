import LiterateModShuvo
using Test

@testset "LaTeXFlavor" begin
    mktempdir() do outputdir
        files = LiterateModShuvo.markdown(
            joinpath(@__DIR__, "test.jl"),
            outputdir;
            flavor = LiterateModShuvo.LaTeXFlavor(),
        )

        @test isfile(files.tex)
        tex = read(files.tex, String)
        @test occursin("\\begin{itemize}", tex)
        @test occursin("\\item item 1", tex)
        @test occursin("\\item item 2", tex)
        @test occursin("\\item item 3", tex)
        @test occursin("\\end{itemize}", tex)

        # Unlabeled $$ ... $$ blocks should become \[ ... \] unless already wrapped.
        @test occursin("\\[\n\\begin{aligned}", tex)
        @test !occursin("\\begin{equation*}", tex)

        # Labeled blocks without an explicit LaTeX environment are wrapped in equation + label.
        @test occursin("\\begin{equation}\\label{einstein}", tex)
    end
end

@testset "LaTeXFlavor display math wrappers" begin
    mktempdir() do dir
        # Labeled block with a numbered environment: keep environment, just insert \label after \begin{...}.
        jlfile = joinpath(dir, "align_label.jl")
        write(
            jlfile,
            raw"""#=
$$
\begin{align}
a &= b
\end{align}
$$ {#eq-ab}

Equation @eq-ab.
=#
""",
        )
        files = LiterateModShuvo.markdown(jlfile, dir; flavor = LiterateModShuvo.LaTeXFlavor())
        tex = read(files.tex, String)
        @test occursin("\\begin{align}\n\\label{ab}", tex)
        @test !occursin("\\begin{equation}\\label{ab}", tex)

        # Labeled blocks must not use unnumbered wrappers like \[...\] or starred environments.
        jlfile2 = joinpath(dir, "bracket_label.jl")
        write(
            jlfile2,
            raw"""#=
$$
\[
a=b
\]
$$ {#eq-ab}
=#
""",
        )
        @test_throws ErrorException LiterateModShuvo.markdown(
            jlfile2,
            dir;
            flavor = LiterateModShuvo.LaTeXFlavor(),
        )

        jlfile3 = joinpath(dir, "starred_label.jl")
        write(
            jlfile3,
            raw"""#=
$$
\begin{equation*}
a=b
\end{equation*}
$$ {#eq-ab}
=#
""",
        )
        @test_throws ErrorException LiterateModShuvo.markdown(
            jlfile3,
            dir;
            flavor = LiterateModShuvo.LaTeXFlavor(),
        )
    end
end
