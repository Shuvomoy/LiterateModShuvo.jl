"""
    LiterateModShuvo

Julia package for LiterateModShuvo Programming. This is a modded version of Literate.jl
"""
module LiterateModShuvo

import JSON, REPL, IOCapture

include("IJulia.jl")
import .IJulia

if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("public markdown, notebook, script"))
end

abstract type AbstractFlavor end
struct DefaultFlavor <: AbstractFlavor end
struct DocumenterFlavor <: AbstractFlavor end
struct CommonMarkFlavor <: AbstractFlavor end
struct FranklinFlavor <: AbstractFlavor end
struct QuartoFlavor <: AbstractFlavor end
struct LaTeXFlavor <: AbstractFlavor end

function markdown_to_latex(md_file::String, outputdir::String, config::Dict)
    # Read the markdown file
    md_content = read(md_file, String)
    
    # Extract title from first # heading if it exists
    title_match = match(r"^#\s+(.+)$"m, md_content)
    if title_match !== nothing
        # Process the title to handle inline code and special characters
        title = escape_latex_text_inline(title_match.captures[1])
    else
        title = "Untitled"
    end
    
    # Remove the title line from content if found
    if title_match !== nothing
        md_content = replace(md_content, title_match.match => "", count=1)
    end
    
    # Start building LaTeX content
    latex_content = IOBuffer()
    
    # Write preamble with additional packages for tables
    write(latex_content, """
    \\documentclass{article}
    \\usepackage{amsmath}
	\\usepackage{amssymb}
    \\usepackage[minted]{tcolorbox}
    \\usepackage{xcolor} % Required for bgcolor in minted
    \\definecolor{lightgray}{rgb}{0.9,0.9,0.9} % Define lightgray if not already defined
    \\usepackage{fontspec} %fontspec is required for code font
    \\setmonofont{JuliaMono}[Extension=.ttf, UprightFont=*-Regular, BoldFont=*-Bold, ItalicFont=*-RegularItalic, BoldItalicFont=*-BoldItalic, Contextuals=Alternate, Scale = 0.8]
    \\usepackage{tabularx} % For tables that fit page width
    \\usepackage{array} % For better column formatting
    \\usepackage{booktabs} % For professional looking tables
	\\usepackage{fullpage,graphicx,psfrag,amsfonts,verbatim, url}
    \\usepackage{parskip}
	
	\\usepackage{titlesec}
	\\usepackage{titling}
	\\usepackage{abstract}


	\\newcommand{\\headerfont}{\\sffamily\\bfseries\\boldmath}


	\\titleformat*{\\section}{\\Large\\headerfont}
	\\titleformat*{\\subsection}{\\large\\headerfont}
	\\titleformat*{\\subsubsection}{\\normalsize\\headerfont}
	\\titleformat*{\\paragraph}{\\normalsize\\headerfont}
	\\titleformat*{\\subparagraph}{\\normalsize\\headerfont}


	\\renewcommand\\abstractnamefont{\\headerfont}


	\\pretitle{\\begin{center}\\LARGE\\headerfont}
	\\posttitle{\\end{center}}
	\\preauthor{\\begin{center}\\large\\headerfont}
	\\postauthor{\\end{center}}
    
    \\title{My Title}
	
	\\author{Shuvomoy Das Gupta}
    
    \\begin{document}
    \\maketitle
    
    """)
    
    # Process the markdown content line by line
    lines = split(md_content, '\n')
    in_code_block = false
    in_display_math = false
    in_table = false
    in_list = false
    code_lang = ""
    code_buffer = IOBuffer()
    math_buffer = IOBuffer()
    table_lines = SubString{String}[]
    i = 1
    
    while i <= length(lines)
        line = lines[i]
        
        if !in_code_block && !in_display_math && !in_table && !in_list
            # Check for table start (line starting with |)
            if occursin(r"^\s*\|", line)
                in_table = true
                table_lines = [line]
                i += 1
                continue
            end

            # Check for unordered list start (e.g. "* item")
            list_match = match(r"^\s*[*+-]\s+(.+)$", line)
            if list_match !== nothing
                in_list = true
                write(latex_content, "\\begin{itemize}\n")
                item_text = replace(list_match.captures[1], r"\\\((.*?)\\\)" => s"$\1$")
                item_text = escape_latex_text_inline(item_text)
                item_text = replace(item_text, r"@eq-([a-zA-Z0-9_-]+)" => s"\\eqref{\1}")
                write(latex_content, "\\item $(item_text)\n")
                i += 1
                continue
            end
            
            # Check for display math start - handle $$ on its own line or at start of line
            if strip(line) == "\$\$" || occursin(r"^\s*\$\$", line)
                in_display_math = true
                math_buffer = IOBuffer()
                # Check if it's a single-line display math
                if occursin(r"^\s*\$\$.*\$\$", line)
                    # Single line display math - extract content between $$
                    math_content = replace(line, r"^\s*\$\$(.*?)\$\$.*$" => s"\1")
                    # Check for label after $$
                    label_match = match(r"\$\$\s*\{#([^}]+)\}", line)
                    if label_match !== nothing
                        label = label_match.captures[1]
                        # Validate that label starts with "eq-"
                        if !startswith(label, "eq-")
                            error("""
                            Invalid equation label format: {#$label}
                            # Validate that label starts with "eq-"
                            For compatibility, equation labels must always start with 'eq-'.
                            Please use the format: {#eq-SomeLabel}
                            And refer to it using: @eq-SomeLabel
                            
                            Found in line: $line
                            """)
                        end                    
                        # Remove "eq-" prefix if present for LaTeX label
                        label = replace(label, r"^eq-" => "")
                        write(latex_content, "\\begin{equation}\\label{$(label)}\n")
                        write(latex_content, strip(math_content), "\n")
                        write(latex_content, "\\end{equation}\n")
                    else
                        # No label - use equation* for unnumbered equation
                        write(latex_content, "\\begin{equation*}\n")
                        write(latex_content, strip(math_content), "\n")
                        write(latex_content, "\\end{equation*}\n")
                    end
                    in_display_math = false
                else
                    # Multi-line display math starts
                    remaining = replace(line, r"^\s*\$\$" => "")
                    if !isempty(strip(remaining))
                        write(math_buffer, strip(remaining), "\n")
                    end
                end
                i += 1
                continue
            end
            
            # Check for code block start with 3 or 4 backticks
            code_match = match(r"^```+(\w*)", line)
            if code_match !== nothing
                in_code_block = true
                code_lang = !isempty(code_match.captures[1]) ? code_match.captures[1] : "julia"
                code_buffer = IOBuffer()
                i += 1
                continue
            end
            
            # Convert markdown headers to LaTeX sections
            if (m = match(r"^#####\s+(.+)$", line)) !== nothing
                header_text = escape_latex_text_inline(strip(m.captures[1]))
                write(latex_content, "\\paragraph{$(header_text)}\n")
            elseif (m = match(r"^####\s+(.+)$", line)) !== nothing
                header_text = escape_latex_text_inline(strip(m.captures[1]))
                write(latex_content, "\\subsubsection{$(header_text)}\n")
            elseif (m = match(r"^###\s+(.+)$", line)) !== nothing
                header_text = escape_latex_text_inline(strip(m.captures[1]))
                write(latex_content, "\\subsection{$(header_text)}\n")
            elseif (m = match(r"^##\s+(.+)$", line)) !== nothing
                header_text = escape_latex_text_inline(strip(m.captures[1]))
                write(latex_content, "\\section{$(header_text)}\n")
            elseif !isempty(strip(line))
                # Regular text - escape LaTeX special characters if needed
                # Also convert @references to LaTeX \ref or \eqref
                escaped_line = escape_latex_text_inline(line)
                # Convert @eq-einstein style references to \eqref{einstein}
                escaped_line = replace(escaped_line, r"@eq-([a-zA-Z0-9_-]+)" => s"\\eqref{\1}")
                write(latex_content, escaped_line, "\n")
            else
                # Empty line
                write(latex_content, "\n")
            end
        elseif in_table
            # Continue accumulating table lines
            if occursin(r"^\s*\|", line)
                push!(table_lines, line)
            else
                # End of table - process it
                process_markdown_table(latex_content, table_lines)
                in_table = false
                table_lines = SubString{String}[]
                # Process the current line normally (it's not part of the table)
                i -= 1  # Reprocess this line
            end
        elseif in_list
            list_match = match(r"^\s*[*+-]\s+(.+)$", line)
            if list_match !== nothing
                item_text = replace(list_match.captures[1], r"\\\((.*?)\\\)" => s"$\1$")
                item_text = escape_latex_text_inline(item_text)
                item_text = replace(item_text, r"@eq-([a-zA-Z0-9_-]+)" => s"\\eqref{\1}")
                write(latex_content, "\\item $(item_text)\n")
            elseif isempty(strip(line))
                # Look ahead: keep list open if next non-empty line is also a list item
                j = i + 1
                while j <= length(lines) && isempty(strip(lines[j]))
                    j += 1
                end
                if j > length(lines) || match(r"^\s*[*+-]\s+(.+)$", lines[j]) === nothing
                    write(latex_content, "\\end{itemize}\n\n")
                    in_list = false
                end
            else
                write(latex_content, "\\end{itemize}\n\n")
                in_list = false
                i -= 1  # Reprocess this line outside list context
            end
        elseif in_display_math
            # Check for display math end - handle $$ anywhere in the line
            if occursin(r"\$\$", line)
                # Get content before $$
                before_end = replace(line, r"\$\$.*$" => "")
                if !isempty(strip(before_end))
                    write(math_buffer, strip(before_end), "\n")
                end
                # Check for label after $$
                label_match = match(r"\$\$\s*\{#([^}]+)\}", line)
                # Write the equation environment
                math_content = String(take!(math_buffer))
                if label_match !== nothing
                    label = label_match.captures[1]
                    # Validate that label starts with "eq-"
                    if !startswith(label, "eq-")
                        error("""
                        Invalid equation label format: {#$label}
                        
                        For compatibility, equation labels must always start with 'eq-'.
                        Please use the format: {#eq-SomeLabel}
                        And refer to it using: @eq-SomeLabel
                        
                        Found in line: $line
                        """)
                    end                    
                    # Convert eq-einstein to einstein for LaTeX label
                    label = replace(label, r"^eq-" => "")
                    write(latex_content, "\\begin{equation}\\label{$(label)}\n")
                    write(latex_content, strip(math_content), "\n")
                    write(latex_content, "\\end{equation}\n")
                else
                    # No label - use equation* for unnumbered equation
                    write(latex_content, "\\begin{equation*}\n")
                    write(latex_content, strip(math_content), "\n")
                    write(latex_content, "\\end{equation*}\n")
                end
                in_display_math = false
            else
                # Accumulate math content
                write(math_buffer, line, "\n")
            end
        elseif in_code_block
            # Check for code block end
            if occursin(r"^```+$", line)
                # Write the minted environment
                code_content = String(take!(code_buffer))
                if !isempty(strip(code_content))
                    write(latex_content, "\\begin{tcblisting}{listing only, minted language=julia, minted options={mathescape=true, breaklines}, colback=lightgray, colframe=black, boxrule=0pt, toprule=2pt, bottomrule=2pt, arc=0pt, outer arc=0pt, left=5pt, right=5pt, top=5pt, bottom=5pt}\n")
                    write(latex_content, code_content)
                    write(latex_content, "\\end{tcblisting}\n\n")
                end
                in_code_block = false
                code_lang = ""
            else
                # Accumulate code
                write(code_buffer, line, "\n")
            end
        end
        
        i += 1
    end
    
    # Handle any remaining table at end of file
    if in_table && !isempty(table_lines)
        process_markdown_table(latex_content, table_lines)
    end

    # Handle any remaining list at end of file
    if in_list
        write(latex_content, "\\end{itemize}\n\n")
    end
    
    # Write postamble
    write(latex_content, "\\end{document}\n")
    
    # Determine output filename
    base_name = basename(md_file)
    tex_filename = replace(base_name, r"\.md$" => ".tex")
    output_path = joinpath(outputdir, tex_filename)
    
    # Write to file
    open(output_path, "w") do io
        write(io, String(take!(latex_content)))
    end
    
    @info "Generated LaTeX file: `$(Base.contractuser(output_path))`"
    
    return output_path
end

"""
    process_markdown_table(io::IOBuffer, table_lines::Vector{<:AbstractString})

Process markdown table lines and write LaTeX tabularx output that fits page width.
"""
function process_markdown_table(io::IOBuffer, table_lines::Vector{<:AbstractString})
    if length(table_lines) < 2
        return  # Not a valid table
    end
    
    # Parse the header row
    header_line = table_lines[1]
    headers = split(header_line, "|")
    headers = [strip(h) for h in headers if !isempty(strip(h))]
    num_cols = length(headers)
    
    # Parse alignment row (if exists)
    alignments = Char[]
    data_start = 2
    if length(table_lines) >= 2 && occursin(r"^[\s\|:\-]+$", table_lines[2])
        align_line = table_lines[2]
        align_parts = split(align_line, "|")
        align_parts = [strip(a) for a in align_parts if !isempty(strip(a))]
        
        for part in align_parts
            if startswith(part, ":") && endswith(part, ":")
                push!(alignments, 'c')  # center
            elseif endswith(part, ":")
                push!(alignments, 'r')  # right
            else
                push!(alignments, 'l')  # left (default)
            end
        end
        data_start = 3
    else
        # No alignment row, default to left
        alignments = fill('l', num_cols)
    end
    
    # For wide tables (more than 3 columns), use tabularx to fit page width
    if num_cols > 3
        # Create column spec using X (flexible) columns for text and regular columns for numbers
        col_spec = ""
        for (i, header) in enumerate(headers)
            # Use 'X' for text columns (typically first/last), regular alignment for numeric
            if i == 1 || contains(lowercase(header), r"(description|name|type|field|implementation|role|mathematics)")
                col_spec *= "X"  # Flexible width column
            else
                col_spec *= string(alignments[i])  # Regular column with specified alignment
            end
        end
        
        # Start the tabularx environment
        write(io, "\\begin{tabularx}{\\textwidth}{$col_spec}\n")
        write(io, "\\toprule\n")
        
        # Write header row
        processed_headers = [process_table_cell(h) for h in headers]
        write(io, join(processed_headers, " & "), " \\\\\n")
        write(io, "\\midrule\n")
        
        # Process data rows
        for i in data_start:length(table_lines)
            row_line = table_lines[i]
            cells = split(row_line, "|")
            cells = [strip(c) for c in cells if !isempty(strip(c))]
            
            if !isempty(cells)
                processed_cells = [process_table_cell(c) for c in cells]
                write(io, join(processed_cells, " & "), " \\\\\n")
            end
        end
        
        write(io, "\\bottomrule\n")
        write(io, "\\end{tabularx}\n\n")
    else
        # For narrow tables, use regular tabular
        col_spec = join(alignments)
        write(io, "\\begin{tabular}{$col_spec}\n")
        write(io, "\\toprule\n")
        
        # Write header row
        processed_headers = [process_table_cell(h) for h in headers]
        write(io, join(processed_headers, " & "), " \\\\\n")
        write(io, "\\midrule\n")
        
        # Process data rows
        for i in data_start:length(table_lines)
            row_line = table_lines[i]
            cells = split(row_line, "|")
            cells = [strip(c) for c in cells if !isempty(strip(c))]
            
            if !isempty(cells)
                processed_cells = [process_table_cell(c) for c in cells]
                write(io, join(processed_cells, " & "), " \\\\\n")
            end
        end
        
        write(io, "\\bottomrule\n")
        write(io, "\\end{tabular}\n\n")
    end
end

"""
    process_table_cell(cell::String)

Process a table cell content, handling inline math and escaping.
"""
function process_table_cell(cell::AbstractString)
    # Convert \(...\) to $...$
    cell = replace(cell, r"\\\((.*?)\\\)" => s"$\1$")
    
    # Now process with our standard inline text escaping
    return escape_latex_text_inline(cell)
end

"""
    escape_latex_text_inline(str::AbstractString)

Escape special LaTeX characters in regular text, handling only inline math.
"""

function escape_latex_text_inline(str::AbstractString)
    # First, protect inline math expressions
    math_expressions = String[]
    protected_str = str
    
    # Find and protect inline math $...$
    math_pattern = r"\$[^\$]+\$"
    for m in eachmatch(math_pattern, str)
        push!(math_expressions, m.match)
        protected_str = replace(protected_str, m.match => "<<<MATH$(length(math_expressions))>>>", count=1)
    end
    
    # Find and protect inline code `...`
    code_expressions = String[]
    code_pattern = r"`([^`]+)`"
    for m in eachmatch(code_pattern, protected_str)
        code_content = m.captures[1]
        # Escape special LaTeX characters within the code content
        # Even inside \texttt{}, these characters need escaping
        escaped_code = code_content
        escaped_code = replace(escaped_code, "\\" => "\\textbackslash{}")
        escaped_code = replace(escaped_code, "{" => "\\{")
        escaped_code = replace(escaped_code, "}" => "\\}")
        escaped_code = replace(escaped_code, "_" => "\\_")  # Underscores need escaping!
        escaped_code = replace(escaped_code, "^" => "\\textasciicircum{}")
        escaped_code = replace(escaped_code, "~" => "\\textasciitilde{}")
        escaped_code = replace(escaped_code, "#" => "\\#")
        escaped_code = replace(escaped_code, "&" => "\\&")
        escaped_code = replace(escaped_code, "%" => "\\%")
        escaped_code = replace(escaped_code, "\$" => "\\\$")
        # Convert to \texttt{} format
        latex_code = "\\texttt{" * escaped_code * "}"
        push!(code_expressions, latex_code)
        protected_str = replace(protected_str, m.match => "<<<CODE$(length(code_expressions))>>>", count=1)
    end
    
    # Now escape special characters in the non-math, non-code text
    replacements = [
        "\\" => "\\textbackslash{}",
        "&" => "\\&",
        "%" => "\\%",
        "\$" => "\\\$",
        "#" => "\\#",
        "_" => "\\_",
        "{" => "\\{",
        "}" => "\\}",
        "~" => "\\textasciitilde{}",
        "^" => "\\textasciicircum{}"
    ]
    
    result = protected_str
    for (pattern, replacement) in replacements
        result = replace(result, pattern => replacement)
    end

    # Convert Markdown emphasis markers to LaTeX commands
    result = replace(result, r"\*\*(.+?)\*\*" => s"\\textbf{\1}")
    result = replace(result, r"\*(.+?)\*" => s"\\emph{\1}")
    
    # Restore math expressions
    for (i, math_expr) in enumerate(math_expressions)
        result = replace(result, "<<<MATH$(i)>>>" => math_expr)
    end
    
    # Restore code expressions (already converted to \texttt{})
    for (i, code_expr) in enumerate(code_expressions)
        result = replace(result, "<<<CODE$(i)>>>" => code_expr)
    end
    
    return result
end

# # Some simple rules:
#
# * All lines starting with `# ` are considered markdown, everything else is considered code
# * The file is parsed in "chunks" of code and markdown. A new chunk is created when the
#   lines switch context from markdown to code and vice versa.
# * Lines starting with `#-` can be used to start a new chunk.
# * Lines starting/ending with `#md` are filtered out unless creating a markdown file
# * Lines starting/ending with `#nb` are filtered out unless creating a notebook
# * Lines starting/ending with, `#jl` are filtered out unless creating a script file
# * Lines starting/ending with, `#src` are filtered out unconditionally
# * #md, #nb, and #jl can be negated as #!md, #!nb, and #!jl
# * Whitespace within a chunk is preserved
# * Empty chunks are removed, leading and trailing empty lines in a chunk are also removed

# Parser
abstract type Chunk end
struct MDChunk <: Chunk
    lines::Vector{Pair{String, String}} # indent and content
end
MDChunk() = MDChunk(String[])
mutable struct CodeChunk <: Chunk
    lines::Vector{String}
    continued::Bool
end
CodeChunk() = CodeChunk(String[], false)

# ismdline(line) = (occursin(r"^\h*#$", line) || occursin(r"^\h*# .*$", line)) && !occursin(r"^\h*##", line)

ismdline(line) = false


function parse(flavor::AbstractFlavor, content; allow_continued = true)
    lines = collect(eachline(IOBuffer(content)))
    chunks = Chunk[]
    push!(chunks, CodeChunk())  # default to code until proven otherwise

    in_md = false

    for rawline in lines
        line = rstrip(rawline)

        # --- MD block start?
        if occursin(r"^\h*#=+\h*$", line)
            if !(chunks[end] isa MDChunk)
                push!(chunks, MDChunk())
            end
            in_md = true
            continue
        end

        # --- MD block end?
        if in_md && occursin(r"^\h*=+#+?\h*$", line)
            in_md = false
            # keep MDChunk open; consecutive MD blocks will merge (see cleanup below)
            continue
        end

        # --- inside MD: copy raw line
        if in_md
            push!(chunks[end].lines, "" => rawline)  # preserve as-is
            continue
        end

        # --- region headers -> markdown section titles
        if (m = match(r"^\h*#region\s+(.*)\h*$", line)) !== nothing
            if !(chunks[end] isa MDChunk)
                push!(chunks, MDChunk())
            end
            push!(chunks[end].lines, "" => "## " * String(m.captures[1]))
            # ensure we have a code chunk ready afterwards
            push!(chunks, CodeChunk())
            continue
        elseif occursin(r"^\h*#endregion\b", line)
            # drop #endregion entirely
            continue
        end

        # --- manual chunking, as before
        if occursin(r"^\h*#-", line)         # new chunk, same kind
            push!(chunks, typeof(chunks[end])())
            continue
        elseif occursin(r"^\h*#\+", line)    # new code chunk that "continues" previous
            idx = findlast(x -> isa(x, CodeChunk), chunks)
            if idx !== nothing
                chunks[idx].continued = true
            end
            push!(chunks, CodeChunk())
            continue
        end

        # --- everything else is code (including single-line # comments)
        if !(chunks[end] isa CodeChunk)
            push!(chunks, CodeChunk())
        end
        # IMPORTANT: do NOT rewrite '## ' into '# ' anymore
        push!(chunks[end].lines, line)
    end

    # --- cleanup (same spirit as upstream)
    filter!(x -> !isempty(x.lines), chunks)
    filter!(x -> !all(y -> isempty(y) || isempty(last(y)), x.lines), chunks)
    for chunk in chunks
        while isempty(chunk.lines[1]) || isempty(last(chunk.lines[1]))
            popfirst!(chunk.lines)
        end
        while isempty(chunk.lines[end]) || isempty(last(chunk.lines[end]))
            pop!(chunk.lines)
        end
    end

    # NEW: merge adjacent MDChunks (lets consecutive #=…=# blocks flow)
    merged = Chunk[]
    for ch in chunks
        if !isempty(merged) && isa(ch, MDChunk) && isa(merged[end], MDChunk)
            append!(merged[end].lines, ch.lines)
        else
            push!(merged, ch)
        end
    end
    chunks = merged

    # If allow_continued=false logic is needed, keep existing block unchanged (it only
    # touches the chunk sequence); otherwise return.
    if !allow_continued
        merged_chunks = Chunk[]
        continued = false
        for chunk in chunks
            if continued
                @assert !isempty(merged_chunks)
                if isa(chunk, CodeChunk)
                    append!(merged_chunks[end].lines, chunk.lines)
                else
                    for line in chunk.lines
                        push!(merged_chunks[end].lines, rstrip(line.first * "# " * line.second))
                    end
                end
            else
                push!(merged_chunks, chunk)
            end
            if isa(chunk, CodeChunk)
                continued = chunk.continued
            end
        end
        chunks = merged_chunks
    end

    return chunks
end

function replace_default(
        content, sym; config::Dict, branch = "gh-pages", commit = "master"
    )
    repls = Pair{Any, Any}[]

    # add some shameless advertisement
    if config["credit"]::Bool
        if sym === :jl
            content *= """

            #-
            ## This file was generated using LiterateShuvosMod.jl, https://github.com/Shuvomoy/LiterateShuvosMod.jl
            """
        else
            content *= """

            #-
            # ---
            #
            # *This $(sym === :md ? "page" : "notebook") was generated using [LiterateShuvosMod.jl](https://github.com/Shuvomoy/LiterateShuvosMod.jl).*
            """
        end
    end

    push!(repls, "\r\n" => "\n") # normalize line endings

    # unconditionally rewrite multiline comments and
    # conditionally multiline markdown strings to regular comments
    function replace_multiline(multiline_r, str)
        while (m = match(multiline_r, str); m !== nothing)
            newlines = sprint() do io
                foreach(l -> println(io, "# ", l), eachline(IOBuffer(m[1])))
            end
            str = replace(str, multiline_r => chop(newlines); count = 1)
        end
        return str
    end


    # unconditionally remove #src lines
    push!(repls, r"^#src.*\n?"m => "") # remove leading #src lines
    push!(repls, r".*#src$\n?"m => "") # remove trailing #src lines

    if sym === :md
        push!(repls, r"^#(md|!nb|!jl) "m => "")    # remove leading #md, #!nb, and #!jl
        push!(repls, r" #(md|!nb|!jl)$"m => "")    # remove trailing #md, #!nb, and #!jl
        push!(repls, r"^#(!md|nb|jl).*\n?"m => "") # remove leading #!md, #nb and #jl lines
        push!(repls, r".*#(!md|nb|jl)$\n?"m => "") # remove trailing #!md, #nb, and #jl lines
    elseif sym === :nb
        push!(repls, r"^#(!md|nb|!jl) "m => "")    # remove leading #!md, #nb, and #!jl
        push!(repls, r" #(!md|nb|!jl)$"m => "")    # remove trailing #!md, #nb, and #!jl
        push!(repls, r"^#(md|!nb|jl).*\n?"m => "") # remove leading #md, #!nb and #jl lines
        push!(repls, r".*#(md|!nb|jl)$\n?"m => "") # remove trailing #md, #!nb, and #jl lines
        # Replace Markdown stdlib math environments
        push!(repls, r"```math(.*?)```"s => s"$$\1$$")
        push!(repls, r"(?<!`)``([^`]+?)``(?!`)" => s"$\1$")
        # Remove Documenter escape sequence around HTML
        push!(repls, r"```@raw(\h+)html(.*?)```"s => s"\2")
    else # sym === :jl
        push!(repls, r"^#(!md|!nb|jl) "m => "")    # remove leading #!md, #!nb, and #jl
        push!(repls, r" #(!md|!nb|jl)$"m => "")    # remove trailing #!md, #!nb, and #jl
        push!(repls, r"^#(md|nb|!jl).*\n?"m => "") # remove leading #md, #nb and #!jl lines
        push!(repls, r".*#(md|nb|!jl)$\n?"m => "") # remove trailing #md, #nb, and #!jl lines
    end

    # name
    push!(repls, "@__NAME__" => config["name"]::String)

    # fix links
    if get(ENV, "DOCUMENTATIONGENERATOR", "") == "true"
        ## DocumentationGenerator.jl
        base_url = get(ENV, "DOCUMENTATIONGENERATOR_BASE_URL", "DOCUMENTATIONGENERATOR_BASE_URL")
        nbviewer_root_url = "https://nbviewer.jupyter.org/urls/$(base_url)"
        push!(repls, "@__NBVIEWER_ROOT_URL__" => nbviewer_root_url)
    else
        push!(repls, "@__REPO_ROOT_URL__" => get(config, "repo_root_url", "<unknown>"))
        push!(repls, "@__NBVIEWER_ROOT_URL__" => get(config, "nbviewer_root_url", "<unknown>"))
        push!(repls, "@__BINDER_ROOT_URL__" => get(config, "binder_root_url", "<unknown>"))
    end

    # Run some Documenter specific things
    if !isdocumenter(config)
        ## - remove documenter style `@ref`s, `@extref`s and `@id`s
        push!(repls, r"\[([^]]+?)\]\(@ref\)"s => s"\1")     # [foo](@ref) => foo
        push!(repls, r"\[([^]]+?)\]\(@ref .*?\)"s => s"\1") # [foo](@ref bar) => foo
        push!(repls, r"\[([^]]+?)\]\(@extref\)"s => s"\1")     # [foo](@extref) => foo
        push!(repls, r"\[([^]]+?)\]\(@extref .*?\)"s => s"\1") # [foo](@extref bar) => foo
        push!(repls, r"\[([^]]+?)\]\(@id .*?\)"s => s"\1")  # [foo](@id bar) => foo
        # Convert Documenter admonitions to markdown quotes
        r = r"^# !!! (?<type>\w+)(?: \"(?<title>.+)\")?(?<lines>(\v^#     .*$)+)"m
        adm_to_quote = function (s)
            m = match(r, s)::RegexMatch
            io = IOBuffer()
            print(io, "# > **")
            if (title = m[:title]; title !== nothing)
                print(io, title)
            else
                type = uppercasefirst(String(m[:type]))
                print(io, type)
            end
            print(io, "**\n# >")
            for l in eachline(IOBuffer(m[:lines]); keep = true)
                print(io, replace(l, r"^#     " => "# > "))
            end
            return String(take!(io))
        end
        push!(repls, r => adm_to_quote)
    end

    # do the replacements
    for repl in repls
        content = replace(content, repl)
    end

    return content
end

filename(str) = first(splitext(last(splitdir(str))))
isdocumenter(cfg) = cfg["flavor"]::AbstractFlavor isa DocumenterFlavor

_DEFAULT_IMAGE_FORMATS = [
    (MIME("image/svg+xml"), ".svg"), (MIME("image/png"), ".png"),
    (MIME("image/jpeg"), ".jpeg"),
]

# Cache of inputfile => head branch
const HEAD_BRANCH_CACHE = Dict{String, String}()

# Guess the package (or repository) root url with "master" as fallback
# see JuliaDocs/Documenter.jl#1751
function edit_commit(inputfile, user_config)
    fallback_edit_commit = "master"
    if (c = get(user_config, "edit_commit", nothing); c !== nothing)
        return c
    end
    if (git = Sys.which("git"); git !== nothing)
        # Check the cache for the git root
        git_root = try
            readchomp(
                pipeline(
                    setenv(`$(git) rev-parse --show-toplevel`; dir = dirname(inputfile));
                    stderr = devnull,
                )
            )
        catch
        end
        if (c = get(HEAD_BRANCH_CACHE, git_root, nothing); c !== nothing)
            return c
        end
        # Check the cache for the file
        if (c = get(HEAD_BRANCH_CACHE, inputfile, nothing); c !== nothing)
            return c
        end
        # Fallback to git remote show
        env = copy(ENV)
        # Set environment variables to block interactive prompt
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_SSH_COMMAND"] = get(ENV, "GIT_SSH_COMMAND", "ssh -o \"BatchMode yes\"")
        str = try
            read(
                pipeline(
                    setenv(`$(git) remote show origin`, env; dir = dirname(inputfile)),
                    stderr = devnull,
                ),
                String,
            )
        catch
        end
        if str !== nothing && (m = match(r"^\s*HEAD branch:\s*(.*)$"m, str); m !== nothing)
            head = String(m[1])
            HEAD_BRANCH_CACHE[something(git_root, inputfile)] = head
            return head
        end
    end
    return fallback_edit_commit
end

# All flavors default to the DefaultFlavor() setting
function pick_codefence(::AbstractFlavor, execute::Bool, name::AbstractString)
    return pick_codefence(DefaultFlavor(), execute, name)
end
function pick_codefence(::DefaultFlavor, execute::Bool, name::AbstractString)
    return "````julia" => "````"
end
function pick_codefence(::DocumenterFlavor, execute::Bool, name::AbstractString)
    if execute
        return pick_codefence(DefaultFlavor(), execute, name)
    else
        return "````@example $(name)" => "````"
    end
end
function pick_codefence(::QuartoFlavor, execute::Bool, name::AbstractString)
    return "```{julia}" => "```"
end

function create_configuration(inputfile; user_config, user_kwargs, type = nothing)
    # Combine user config with user kwargs
    user_config = Dict{String, Any}(string(k) => v for (k, v) in user_config)
    user_kwargs = Dict{String, Any}(string(k) => v for (k, v) in user_kwargs)
    user_config = merge!(user_config, user_kwargs)

    # deprecation of documenter kwarg
    if (d = get(user_config, "documenter", nothing); d !== nothing)
        if type === :md
            Base.depwarn(
                "The documenter=$(d) keyword to LiterateModShuvo.markdown is deprecated." *
                    " Pass `flavor = LiterateModShuvo.$(d ? "DocumenterFlavor" : "CommonMarkFlavor")()`" *
                    " instead.", Symbol("LiterateModShuvo.markdown")
            )
            user_config["flavor"] = d ? DocumenterFlavor() : CommonMarkFlavor()
        elseif type === :nb
            Base.depwarn(
                "The documenter=$(d) keyword to LiterateModShuvo.notebook is deprecated." *
                    " It is not used anymore for notebook output.",
                Symbol("LiterateModShuvo.notebook")
            )
        elseif type === :jl
            Base.depwarn(
                "The documenter=$(d) keyword to LiterateModShuvo.script is deprecated." *
                    " It is not used anymore for script output.",
                Symbol("LiterateModShuvo.script")
            )
        end
    end

    # Add default config
    cfg = Dict{String, Any}()
    cfg["name"] = filename(inputfile)
    cfg["preprocess"] = identity
    cfg["postprocess"] = identity
    # cfg["flavor"] = type === (:md) ? DocumenterFlavor() : DefaultFlavor()
    cfg["flavor"] = type === (:md) ? DefaultFlavor() : DefaultFlavor()
    cfg["credit"] = false
    cfg["mdstrings"] = false
    cfg["softscope"] = type === (:nb) ? true : false # on for Jupyter notebooks
    cfg["keep_comments"] = false
    cfg["execute"] = type === :md ? false : true
    cfg["continue_on_error"] = false
    cfg["codefence"] = pick_codefence(
        get(user_config, "flavor", cfg["flavor"]),
        get(user_config, "execute", cfg["execute"]),
        get(user_config, "name", replace(cfg["name"], r"\s" => "_")),
    )
    cfg["image_formats"] = _DEFAULT_IMAGE_FORMATS
    cfg["edit_commit"] = edit_commit(inputfile, user_config)
    deploy_branch = "gh-pages" # TODO: Make this configurable like Documenter?
    # Strip build version from a tag (cf. JuliaDocs/Documenter.jl#1298, LiterateModShuvo.jl#162)
    function version_tag_strip_build(tag)
        m = match(Base.VERSION_REGEX, tag)
        m === nothing && return tag
        s0 = startswith(tag, 'v') ? "v" : ""
        s1 = m[1] # major
        s2 = m[2] === nothing ? "" : ".$(m[2])" # minor
        s3 = m[3] === nothing ? "" : ".$(m[3])" # patch
        s4 = m[5] === nothing ? "" : m[5] # pre-release (starting with -)
        # m[7] is the build, which we want to discard
        return "$s0$s1$s2$s3$s4"
    end

    if haskey(ENV, "HAS_JOSH_K_SEAL_OF_APPROVAL") # Travis CI
        repo_slug = get(ENV, "TRAVIS_REPO_SLUG", "unknown-repository")
        deploy_folder = if get(ENV, "TRAVIS_PULL_REQUEST", nothing) == "false"
            t = get(ENV, "TRAVIS_TAG", "")
            isempty(t) ? get(user_config, "devurl", "dev") : version_tag_strip_build(t)
        else
            "previews/PR$(get(ENV, "TRAVIS_PULL_REQUEST", "##"))"
        end
        cfg["repo_root_url"] = "https://github.com/$(repo_slug)/blob/$(cfg["edit_commit"])"
        cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(deploy_branch)/$(deploy_folder)"
        cfg["binder_root_url"] = "https://mybinder.org/v2/gh/$(repo_slug)/$(deploy_branch)?filepath=$(deploy_folder)"
    elseif haskey(ENV, "GITHUB_ACTIONS")
        repo_slug = get(ENV, "GITHUB_REPOSITORY", "unknown-repository")
        deploy_folder = if get(ENV, "GITHUB_EVENT_NAME", nothing) == "push"
            if (m = match(r"^refs\/tags\/(.*)$", get(ENV, "GITHUB_REF", ""))) !== nothing
                version_tag_strip_build(String(m.captures[1]))
            else
                get(user_config, "devurl", "dev")
            end
        elseif (m = match(r"refs\/pull\/(\d+)\/merge", get(ENV, "GITHUB_REF", ""))) !== nothing
            "previews/PR$(m.captures[1])"
        else
            "dev"
        end
        cfg["repo_root_url"] = "https://github.com/$(repo_slug)/blob/$(cfg["edit_commit"])"
        cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/github/$(repo_slug)/blob/$(deploy_branch)/$(deploy_folder)"
        cfg["binder_root_url"] = "https://mybinder.org/v2/gh/$(repo_slug)/$(deploy_branch)?filepath=$(deploy_folder)"
    elseif haskey(ENV, "GITLAB_CI")
        if (url = get(ENV, "CI_PROJECT_URL", nothing)) !== nothing
            cfg["repo_root_url"] = "$(url)/blob/$(cfg["edit_commit"])"
        end
        if (url = get(ENV, "CI_PAGES_URL", nothing)) !== nothing &&
                (m = match(r"https://(.+)", url)) !== nothing
            cfg["nbviewer_root_url"] = "https://nbviewer.jupyter.org/urls/$(m[1])"
        end
    end

    # Merge default_config with user_config
    merge!(cfg, user_config)
    return cfg
end

"""
    DEFAULT_CONFIGURATION

Default configuration for [`LiterateModShuvo.markdown`](@ref), [`LiterateModShuvo.notebook`](@ref) and
[`LiterateModShuvo.script`](@ref) which is used for everything not specified by the user.
Configuration can be passed as individual keyword arguments or as a dictionary passed
with the `config` keyword argument.
See the manual section about [Configuration](@ref) for more information.

Available options:

- `name` (default: `filename(inputfile)`): Name of the output file (excluding the file
  extension).
- `preprocess` (default: `identity`): Custom preprocessing function mapping a `String` to
  a `String`. See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing).
- `postprocess` (default: `identity`): Custom preprocessing function mapping a `String` to
  a `String`. See [Custom pre- and post-processing](@ref Custom-pre-and-post-processing).
- `credit` (default: `true`): Boolean for controlling the addition of
  `This file was generated with LiterateModShuvo.jl ...` to the bottom of the page. If you find
  LiterateModShuvo.jl useful then feel free to keep this.
- `keep_comments` (default: `false`): When `true`, keeps markdown lines as comments in the
  output script. Only applicable for `LiterateModShuvo.script`.
- `execute` (default: `true` for notebook, `false` for markdown): Whether to execute and
  capture the output. Only applicable for `LiterateModShuvo.notebook` and `LiterateModShuvo.markdown`.
- `continue_on_error` (default: `false`): Whether to continue code execution of remaining
  blocks after encountering an error. By default execution errors are re-thrown. If
  `continue_on_error = true` the error will be used as the output of the block instead and
  execution will continue. This option is only applicable when `execute = true`.
- `codefence` (default: `````"````@example \$(name)" => "````"````` for `DocumenterFlavor()`
  and `````"````julia" => "````"````` otherwise): Pair containing opening and closing
  code fence for wrapping code blocks.
- `flavor` (default: `LiterateModShuvo.DocumenterFlavor()`) Output flavor for markdown, see
  [Markdown flavors](@ref). Only applicable for `LiterateModShuvo.markdown`.
- `devurl` (default: `"dev"`): URL for "in-development" docs, see [Documenter docs]
  (https://juliadocs.github.io/Documenter.jl/). Unused if `repo_root_url`/
  `nbviewer_root_url`/`binder_root_url` are set.
- `softscope` (default: `true` for Jupyter notebooks, `false` otherwise): enable/disable
  "soft" scoping rules when executing, see e.g. https://github.com/JuliaLang/SoftGlobalScope.jl.
- `repo_root_url`: URL to the root of the repository. Determined automatically on Travis CI,
  GitHub Actions and GitLab CI. Used for `@__REPO_ROOT_URL__`.
- `nbviewer_root_url`: URL to the root of the repository as seen on nbviewer. Determined
  automatically on Travis CI, GitHub Actions and GitLab CI.
  Used for `@__NBVIEWER_ROOT_URL__`.
- `binder_root_url`: URL to the root of the repository as seen on mybinder. Determined
  automatically on Travis CI, GitHub Actions and GitLab CI.
  Used for `@__BINDER_ROOT_URL__`.
- `image_formats`: A vector of `(mime, ext)` tuples, with the default
  `$(_DEFAULT_IMAGE_FORMATS)`. Results which are `showable` with a MIME type are saved with
  the first match, with the corresponding extension.
"""
const DEFAULT_CONFIGURATION = nothing # Dummy const for documentation

function preprocessor(inputfile, outputdir; user_config, user_kwargs, type)
    # Create configuration by merging default and userdefined
    config = create_configuration(
        inputfile; user_config = user_config, user_kwargs = user_kwargs, type = type
    )

    # Quarto output does not support execute = true
    if config["flavor"] isa QuartoFlavor && config["execute"]
        throw(ArgumentError("QuartoFlavor does not support `execute = true`."))
    end

    # normalize paths
    inputfile = normpath(inputfile)
    isfile(inputfile) || throw(ArgumentError("cannot find inputfile `$(inputfile)`"))
    inputfile = realpath(abspath(inputfile))
    mkpath(outputdir)
    outputdir = realpath(abspath(outputdir))
    isdir(outputdir) || error("not a directory: $(outputdir)")
    ext = type === (:nb) ? ".ipynb" : (type === (:md) && config["flavor"] isa QuartoFlavor) ? ".qmd" : ".$(type)"
    outputfile = joinpath(outputdir, config["name"]::String * ext)
    if inputfile == outputfile
        throw(ArgumentError("outputfile (`$outputfile`) is identical to inputfile (`$inputfile`)"))
    end

    output_thing = type === (:md) ? "markdown page" :
        type === (:nb) ? "notebook" :
        type === (:jl) ? "plain script file" : error("nope")
    @info "generating $(output_thing) from `$(Base.contractuser(inputfile))`"

    # Add some information for passing around LiterateModShuvo methods
    config["literate_inputfile"] = inputfile
    config["literate_outputdir"] = outputdir
    config["literate_ext"] = ext
    config["literate_outputfile"] = outputfile

    # read content
    content = read(inputfile, String)

    # run custom pre-processing from user
    content = config["preprocess"](content)

    # run some Documenter specific things for markdown output
    if type === :md && isdocumenter(config)
        # change the Edit on GitHub link
        edit_url = relpath(inputfile, config["literate_outputdir"])
        edit_url = replace(edit_url, "\\" => "/")
        meta_block = """
        # ```@meta
        # EditURL = "$(edit_url)"
        # ```

        """
        content = meta_block * content
    end

    # default replacements
    content = replace_default(content, type; config = config)

    # parse the content into chunks
    chunks = parse(config["flavor"], content; allow_continued = type !== :nb)

    return chunks, config
end

function write_result(content, config; print = print)
    outputfile = config["literate_outputfile"]
    @info "writing result to `$(Base.contractuser(outputfile))`"
    open(outputfile, "w") do io
        print(io, content)
    end
    return outputfile
end

"""
    LiterateModShuvo.script(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)

Generate a plain script file from `inputfile` and write the result to `outputdir`.
Returns the path to the generated file.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function script(inputfile, outputdir = pwd(); config::AbstractDict = Dict(), kwargs...)
    # preprocessing and parsing
    chunks, config =
        preprocessor(inputfile, outputdir; user_config = config, user_kwargs = kwargs, type = :jl)

    # create the script file
    ioscript = IOBuffer()
    isfirst = true
    for chunk in chunks
        if isa(chunk, CodeChunk)
            isfirst ? (isfirst = false) : write(ioscript, '\n') # add a newline between each chunk
            for line in chunk.lines
                write(ioscript, line, '\n')
            end
        elseif isa(chunk, MDChunk) && config["keep_comments"]::Bool
            isfirst ? (isfirst = false) : write(ioscript, '\n') # add a newline between each chunk
            for line in chunk.lines
                write(ioscript, rstrip(line.first * "# " * line.second) * '\n')
            end
        end
    end

    # custom post-processing from user
    content = config["postprocess"](String(take!(ioscript)))

    # write to file
    outputfile = write_result(content, config)
    return outputfile
end


"""
    LiterateModShuvo.markdown(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)

Generate a markdown file from `inputfile` and write the result
to the directory `outputdir`. Returns the path to the generated file.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function markdown(inputfile, outputdir = pwd(); config::AbstractDict = Dict(), kwargs...)
    # Check if LaTeXFlavor is requested
    user_config = Dict{String, Any}(string(k) => v for (k, v) in config)
    user_kwargs = Dict{String, Any}(string(k) => v for (k, v) in kwargs)
    merged_config = merge(user_config, user_kwargs)
    
    if get(merged_config, "flavor", nothing) isa LaTeXFlavor
        # Generate markdown with default flavor first
        modified_kwargs = Dict(kwargs)
        delete!(modified_kwargs, :flavor)  # Remove LaTeXFlavor
        
        # Call markdown generation with default flavor
        md_file = markdown(inputfile, outputdir; config = config, modified_kwargs...)
        
        # Convert markdown to LaTeX
        tex_file = markdown_to_latex(md_file, outputdir, merged_config)
        
        # Return both files
        return (md = md_file, tex = tex_file)
    end
    
    # preprocessing and parsing
    chunks, config =
        preprocessor(inputfile, outputdir; user_config = config, user_kwargs = kwargs, type = :md)

    # create the markdown file
    sb = sandbox()
    iomd = IOBuffer()
    for (chunknum, chunk) in enumerate(chunks)
        if isa(chunk, MDChunk)
            for line in chunk.lines
                write(iomd, line.second, '\n') # skip indent here
            end
        else # isa(chunk, CodeChunk)
            iocode = IOBuffer()
            codefence = config["codefence"]::Pair
            write(iocode, codefence.first)
            # make sure the code block is finalized if we are printing to ```@example
            # (or ````@example, any number of backticks >= 3 works)
            if chunk.continued && occursin(r"^`{3,}@example", codefence.first) && isdocumenter(config)
                write(iocode, "; continued = true")
            end
            write(iocode, '\n')
            # filter out trailing #hide unless code is executed by Documenter
            execute = config["execute"]::Bool
            write_hide = isdocumenter(config) && !execute
            write_line(line) = write_hide || !endswith(line, "#hide")
            for line in chunk.lines
                write_line(line) && write(iocode, line, '\n')
            end
            if write_hide && REPL.ends_with_semicolon(chunk.lines[end])
                write(iocode, "nothing #hide\n")
            end
            write(iocode, codefence.second, '\n')
            any(write_line, chunk.lines) && write(iomd, seekstart(iocode))
            if execute
                cd(config["literate_outputdir"]) do
                    execute_markdown!(
                        iomd, sb, join(chunk.lines, '\n'),
                        config["literate_outputdir"];
                        inputfile = config["literate_inputfile"],
                        fake_source = config["literate_outputfile"],
                        flavor = config["flavor"],
                        image_formats = config["image_formats"],
                        file_prefix = "$(config["name"])-$(chunknum)",
                        softscope = config["softscope"],
                        continue_on_error = config["continue_on_error"],
                    )
                end
            end
        end
        write(iomd, '\n') # add a newline between each chunk
    end

    # custom post-processing from user
    content = config["postprocess"](String(take!(iomd)))

    # write to file
    outputfile = write_result(content, config)
    return outputfile
end

function execute_markdown!(
        io::IO, sb::Module, block::String, outputdir;
        inputfile::String, fake_source::String, flavor::AbstractFlavor,
        image_formats::Vector, file_prefix::String, softscope::Bool,
        continue_on_error::Bool
    )
    # TODO: Deal with explicit display(...) calls
    r, str, _ = execute_block(
        sb, block; inputfile = inputfile, fake_source = fake_source,
        softscope = softscope, continue_on_error = continue_on_error
    )
    # issue #101: consecutive codefenced blocks need newline
    # issue #144: quadruple backticks allow for triple backticks in the output
    plain_fence = "\n````\n" => "\n````"
    if r !== nothing && !REPL.ends_with_semicolon(block)
        if (flavor isa FranklinFlavor || flavor isa DocumenterFlavor) &&
                Base.invokelatest(showable, MIME("text/html"), r)
            htmlfence = flavor isa FranklinFlavor ? ("~~~" => "~~~") : ("```@raw html" => "```")
            write(io, "\n", htmlfence.first, "\n")
            Base.invokelatest(show, io, MIME("text/html"), r)
            write(io, "\n", htmlfence.second, "\n")
            return
        end
        for (mime, ext) in image_formats
            if Base.invokelatest(showable, mime, r)
                file = file_prefix * ext
                open(joinpath(outputdir, file), "w") do io
                    Base.invokelatest(show, io, mime, r)
                end
                write(io, "![](", file, ")\n")
                return
            end
        end
        if Base.invokelatest(showable, MIME("text/markdown"), r)
            write(io, '\n')
            Base.invokelatest(show, io, MIME("text/markdown"), r)
            write(io, '\n')
            return
        end
        # fallback to text/plain
        write(io, plain_fence.first)
        Base.invokelatest(show, io, "text/plain", r)
        write(io, plain_fence.second, '\n')
        return
    elseif !isempty(str)
        write(io, plain_fence.first, str, plain_fence.second, '\n')
        return
    end
end


const JUPYTER_VERSION = v"4.3.0"

parse_nbmeta(line::Pair) = parse_nbmeta(line.second)
function parse_nbmeta(line)
    # Format: %% optional ignored text [type] {optional metadata JSON}
    # Cf. https://jupytext.readthedocs.io/en/latest/formats.html#the-percent-format
    m = match(r"^%% ([^[{]+)?\s*(?:\[(\w+)\])?\s*(\{.*)?$", line)
    typ = m.captures[2]
    name = m.captures[1] === nothing ? Dict{String, String}() : Dict("name" => m.captures[1])
    meta = m.captures[3] === nothing ? Dict{String, Any}() : JSON.parse(m.captures[3])
    return typ, merge(name, meta)
end
line_is_nbmeta(line::Pair) = line_is_nbmeta(line.second)
line_is_nbmeta(line) = startswith(line, "%% ")

"""
    LiterateModShuvo.notebook(inputfile, outputdir=pwd(); config::AbstractDict=Dict(), kwargs...)

Generate a notebook from `inputfile` and write the result to `outputdir`.
Returns the path to the generated file.

See the manual section on [Configuration](@ref) for documentation
of possible configuration with `config` and other keyword arguments.
"""
function notebook(inputfile, outputdir = pwd(); config::AbstractDict = Dict(), kwargs...)
    # preprocessing and parsing
    chunks, config =
        preprocessor(inputfile, outputdir; user_config = config, user_kwargs = kwargs, type = :nb)

    # create the notebook
    nb = jupyter_notebook(chunks, config)

    # write to file
    outputfile = write_result(nb, config; print = (io, c) -> JSON.print(io, c, 1))
    return outputfile
end

function jupyter_notebook(chunks, config)
    nb = Dict()
    nb["nbformat"] = JUPYTER_VERSION.major
    nb["nbformat_minor"] = JUPYTER_VERSION.minor

    ## create the notebook cells
    cells = []
    for chunk in chunks
        cell = Dict()
        chunktype = isa(chunk, MDChunk) ? "markdown" : "code"
        if !isempty(chunk.lines) && line_is_nbmeta(chunk.lines[1])
            metatype, metadata = parse_nbmeta(chunk.lines[1])
            metatype !== nothing && metatype != chunktype && error("specifying a different cell type is not supported")
            popfirst!(chunk.lines)
        else
            metadata = Dict{String, Any}()
        end
        if isa(chunk, MDChunk)
            lines = String[x.second for x in chunk.lines] # skip indent
        else
            lines = chunk.lines
        end
        @views map!(x -> x * '\n', lines[1:(end - 1)], lines[1:(end - 1)])
        cell["cell_type"] = chunktype
        cell["metadata"] = metadata
        cell["source"] = lines
        if chunktype == "code"
            cell["execution_count"] = nothing
            cell["outputs"] = []
        end
        push!(cells, cell)
    end
    nb["cells"] = cells

    ## create metadata
    metadata = Dict()

    kernelspec = Dict()
    kernelspec["language"] = "julia"
    kernelspec["name"] = "julia-$(VERSION.major).$(VERSION.minor)"
    kernelspec["display_name"] = "Julia $(string(VERSION))"
    metadata["kernelspec"] = kernelspec

    language_info = Dict()
    language_info["file_extension"] = ".jl"
    language_info["mimetype"] = "application/julia"
    language_info["name"] = "julia"
    language_info["version"] = string(VERSION)
    metadata["language_info"] = language_info

    nb["metadata"] = metadata

    # custom post-processing from user
    nb = config["postprocess"](nb)

    if config["execute"]::Bool
        @info "executing notebook `$(config["name"] * ".ipynb")`"
        try
            cd(config["literate_outputdir"]) do
                nb = execute_notebook(
                    nb; inputfile = config["literate_inputfile"],
                    fake_source = config["literate_outputfile"],
                    softscope = config["softscope"],
                    continue_on_error = config["continue_on_error"],
                )
            end
        catch err
            @error "error when executing notebook based on input file: " *
                "`$(Base.contractuser(config["literate_inputfile"]))`"
            rethrow(err)
        end
    end
    return nb
end

function execute_notebook(
        nb; inputfile::String, fake_source::String, softscope::Bool,
        continue_on_error = continue_on_error
    )
    sb = sandbox()
    execution_count = 0
    for cell in nb["cells"]
        cell["cell_type"] == "code" || continue
        execution_count += 1
        cell["execution_count"] = execution_count
        block = join(cell["source"])
        r, str, display_dicts = execute_block(
            sb, block; inputfile = inputfile, fake_source = fake_source,
            softscope = softscope, continue_on_error = continue_on_error
        )

        # str should go into stream
        if !isempty(str)
            stream = Dict{String, Any}()
            stream["output_type"] = "stream"
            stream["name"] = "stdout"
            stream["text"] = collect(Any, eachline(IOBuffer(String(str)), keep = true))
            push!(cell["outputs"], stream)
        end

        # Some mimes need to be split into vectors of lines instead of a single string
        # TODO: Seems like text/plain and text/latex are also split now, but not doing
        # it seems to work fine. Leave for now.
        function split_mime(dict)
            for mime in ("image/svg+xml", "text/html")
                if haskey(dict, mime)
                    dict[mime] = collect(Any, eachline(IOBuffer(dict[mime]), keep = true))
                end
            end
            return dict
        end

        # Any explicit calls to display(...)
        for dict in display_dicts
            display_data = Dict{String, Any}()
            display_data["output_type"] = "display_data"
            display_data["metadata"] = Dict()
            display_data["data"] = split_mime(dict)
            push!(cell["outputs"], display_data)
        end

        # check if ; is used to suppress output
        r = REPL.ends_with_semicolon(block) ? nothing : r

        # r should go into execute_result
        if r !== nothing
            execute_result = Dict{String, Any}()
            execute_result["output_type"] = "execute_result"
            execute_result["metadata"] = Dict()
            execute_result["execution_count"] = execution_count
            dict = Base.invokelatest(IJulia.display_dict, r)
            execute_result["data"] = split_mime(dict)
            push!(cell["outputs"], execute_result)
        end
    end
    return nb
end

# Create a sandbox module for evaluation
function sandbox()
    m = Module(gensym())
    # eval(expr) is available in the REPL (i.e. Main) so we emulate that for the sandbox
    Core.eval(m, :(eval(x) = Core.eval($m, x)))
    # modules created with Module() does not have include defined
    # the source path for recursive include is set while executing the block
    Core.eval(m, :(include(x) = Base.include($m, x)))
    return m
end

# Capture display for notebooks
struct LiterateDisplay <: AbstractDisplay
    data::Vector
    LiterateDisplay() = new([])
end
function Base.display(ld::LiterateDisplay, x)
    push!(ld.data, Base.invokelatest(IJulia.display_dict, x))
    return nothing
end
# TODO: Problematic to accept mime::MIME here?
function Base.display(ld::LiterateDisplay, mime::MIME, x)
    r = Base.invokelatest(IJulia.limitstringmime, mime, x)
    display_dicts = Dict{String, Any}(string(mime) => r)
    # TODO: IJulia does this part below for unknown mimes
    # if istextmime(mime)
    #     display_dicts["text/plain"] = r
    # end
    push!(ld.data, display_dicts)
    return nothing
end

# Execute a code-block in a module and capture stdout/stderr and the result
function execute_block(
        sb::Module, block::String; inputfile::String, fake_source::String,
        softscope::Bool, continue_on_error::Bool
    )
    @debug """execute_block($sb, block)
    ```
    $(block)
    ```
    """
    # Push a capturing display on the displaystack
    disp = LiterateDisplay()
    pushdisplay(disp)
    # We use the following fields of the object returned by IOCapture.capture:
    #  - c.value: return value of the do-block (or the error object, if it throws)
    #  - c.error: set to `true` if the do-block throws an error
    #  - c.output: combined stdout and stderr
    # `rethrow = Union{}` means that we try-catch all the exceptions thrown in the do-block
    # and return them via the return value (they get handled below).
    c = IOCapture.capture(rethrow = Union{}) do
        # TODO: Perhaps `include_string` should set :SOURCE_PATH?
        task_local_storage(:SOURCE_PATH, fake_source) do
            if softscope
                include_string(REPL.softscope, sb, block, fake_source)
            else
                include_string(sb, block, fake_source)
            end
        end
    end
    popdisplay(disp) # IOCapture.capture has a try-catch so should always end up here
    if c.error
        if continue_on_error
            err = c.value
            if err isa LoadError # include_string may wrap error in LoadError
                err = err.error
            end
            all_output = c.output * "\n\nERROR: " * sprint(showerror, err)
            return nothing, all_output, disp.data
        else
            error(
                """
                $(sprint(showerror, c.value))
                when executing the following code block from inputfile `$(Base.contractuser(inputfile))`

                ```julia
                $block
                ```
                """
            )
        end
    end
    return c.value, c.output, disp.data
end

end # module
