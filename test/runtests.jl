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
    end
end
