#=
% Preview source code

%% LyX 2.3.8 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing.
\documentclass[english,nohyper]{tufte-handout}
\usepackage{amsmath}
\usepackage{amsthm}
\usepackage{amssymb}
\usepackage{fontspec}
\usepackage{xcolor}
\usepackage{url}
\usepackage[unicode=true,pdfusetitle,
 bookmarks=true,bookmarksnumbered=true,bookmarksopen=true,bookmarksopenlevel=1,
 breaklinks=true,pdfborder={0 0 0},pdfborderstyle={},backref=false,colorlinks=false]
 {hyperref}

\makeatletter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LyX specific LaTeX commands.

\title{Lecture 1: CMOR 537}

\author{Shuvomoy Das Gupta}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User specified LaTeX commands.
\usepackage{ stmaryrd }
\usepackage{ textcomp }

\usepackage{abstract} % Make abstract

\usepackage{graphicx,psfrag,amsfonts,verbatim, url}


\usepackage[
left=1in,
top=1in,
headsep=2\baselineskip,
textwidth=7in,
marginparsep=0.3in,
marginparwidth=2in,
%textheight=44\baselineskip,
headheight=\baselineskip, 
paperwidth= 11 in,
paperheight=165in]{geometry}

% In using geometry package 
% Ensure that the sum of textwidth+marginparsep+marginparwidth+left
% is strictly less than paperwidth



\usepackage{ifxetex}
\usepackage{lipsum}

\usepackage{xcolor}

\usepackage[minted]{tcolorbox}


\ifxetex
  \newcommand{\textls}[2][5]{%
    \begingroup\addfontfeatures{LetterSpace= #1}#2\endgroup
  }
  \renewcommand{\allcapsspacing}[1]{\textls[15]{#1}}
  \renewcommand{\smallcapsspacing}[1]{\textls[10]{#1}}
  \renewcommand{\allcaps}[1]{\textls[15]{\MakeTextUppercase{#1}}}
  \renewcommand{\smallcaps}[1]{\smallcapsspacing{\scshape\MakeTextLowercase{#1}}}
  \renewcommand{\textsc}[1]{\smallcapsspacing{\textsmallcaps{#1}}}
  \usepackage{fontspec}
  \setmainfont[
SmallCapsFont = Fontin-SmallCaps.otf,
BoldFont = et-bembo-bold.ttf,
ItalicFont = et-bembo-italic.ttf,
Scale = 1 % scale font size
]
{et-bembo-roman.ttf}
\setmonofont{JuliaMono}[
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
  ItalicFont=*-RegularItalic,
  BoldItalicFont=*-BoldItalic,
  Contextuals=Alternate,
  Scale = 0.8
]
\fi

\usepackage{newunicodechar}



\ifdefined\soulregister
  \soulregister\MakeTextUppercase{1}%
  \soulregister\MakeTextLowercase{1}%
\fi


\newcommand{\filler}[1][10]%
{   \foreach \x in {1,...,#1}
    {   test 
    }
}

\def\mathnote#1{%
  \tag*{\rlap{\hspace\marginparsep\smash{\parbox[t]{\marginparwidth}{%
  \footnotesize#1}}}}
}

\usepackage{polyglossia}
\usepackage{unicode-math}

\usepackage{tikz}
\usetikzlibrary{fit, arrows, shapes, positioning, shadows, matrix, calc}
\usepackage[]{subfig}

\usepackage{siunitx, threeparttable}

\captionsetup[table]{justification=raggedright,singlelinecheck=off}
\sisetup{separate-uncertainty=true}

% pgfplot
\RequirePackage{luatex85}
%\documentclass[tikz]{standalone}
% Default preamble
\usepackage{pgfplots}
\pgfplotsset{compat=newest}
\usepgfplotslibrary{groupplots}
\usepgfplotslibrary{polar}
\usepgfplotslibrary{smithchart}
\usepgfplotslibrary{statistics}
\usepgfplotslibrary{dateplot}
\interfootnotelinepenalty=10000

\allowdisplaybreaks

\renewcommand\allcapsspacing[1]{{\addfontfeature{LetterSpace=15}#1}}
\renewcommand\smallcapsspacing[1]{{\addfontfeature{LetterSpace=10}#1}}

\makeatletter
% Paragraph indentation and separation for normal text (mimicking parskip)
\renewcommand{\@tufte@reset@par}{%
  \setlength{\RaggedRightParindent}{0pt}%
  \setlength{\JustifyingParindent}{0pt}%
  \setlength{\parindent}{0pt}%
  \setlength{\parskip}{1ex plus 0.5ex minus 0.2ex}%
}
\@tufte@reset@par

% Paragraph indentation and separation for marginal text (mimicking parskip)
\renewcommand{\@tufte@margin@par}{%
  \setlength{\RaggedRightParindent}{0pt}%
  \setlength{\JustifyingParindent}{0pt}%
  \setlength{\parindent}{0pt}%
  \setlength{\parskip}{1ex plus 0.5ex minus 0.2ex}%
}
\makeatother

\makeatother

\usepackage{polyglossia}
\setdefaultlanguage[variant=american]{english}
\begin{document}
\maketitle
\begin{abstract}
This is a short blog to show the connection between Fenchel-Rockafellar Dualilty to Lagrangian Duality. 
\end{abstract}

\section{\textcolor{red}{Fenchel-Rockafellar duality.}}

\subsection{\textcolor{blue}{Install }\texttt{\textcolor{blue}{PyCall}}\textcolor{blue}{{} and }\texttt{\textcolor{blue}{Conda}}}

We will install \texttt{PyCall} first for running Python code within \texttt{Julia} and the \texttt{Conda
}for installing \texttt{Python} modules.\marginnote{\texttt{Pycall} is available at \url{https://github.com/JuliaPy/PyCall.jl}, and \texttt{Conda} is available
at \url{https://github.com/JuliaPy/Conda.jl}.} 
=#

# Install PyCall and Conda

using Pkg

Pkg.add("PyCall")

Pkg.add("Conda")

# Let us now install a Python module from Julia

Conda.add("numpy")

#=
\marginnote{\textbf{\textcolor{blue}{\scriptsize{}Notation and notions.}}{\scriptsize\par}
\begin{itemize}
\item \textcolor{blue}{\scriptsize{}$\mathbb{R}_{-}^{n}=\{y\in\mathbb{R}^{n}\mid\forall_{i\in[1:n]}\,y_{i}\leq0\}$
and $\mathbb{R}_{+}^{n}=\{y\in\mathbb{R}^{n}\mid\forall_{i\in[1:n]}\,y_{i}\geq0\}$, where both are
closed convex cones. }{\scriptsize\par}
\item \textcolor{blue}{\scriptsize{}A CCP function is closed, convex, and proper (lower-semicontinuous).}{\scriptsize\par}
\item \textcolor{blue}{\scriptsize{}For a nonempty closed convex set $S$ in $\mathbb{R}^{n}$, its indicator
function is:
$$
\delta_{S}(x)=\begin{cases}
0, & \textrm{if }x\in S\\
\infty, & \textrm{else}.
\end{cases}
$$
}{\scriptsize\par}
\item \textcolor{blue}{\scriptsize{}For a nonempty closed convex set $S$ in $\mathbb{R}^{n}$, its support
function is: 
$$
\sigma_{S}(u)=\sup_{x\in S}\left\langle x\mid s\right\rangle 
$$
}{\scriptsize\par}
\item \textcolor{blue}{\scriptsize{}The conjugate function of a function $\phi:\mathbb{R}^{n}\to\mathbb{R}$
is defined as 
$$
\phi^{*}(u)=\sup_{x\in\mathbb{R}^{n}}\left(-\phi(x)+\left\langle x\mid u\right\rangle \right),
$$
 and if $\phi$ is CCP then $\phi^{**}=\phi$.}{\scriptsize\par}
\item \textcolor{blue}{\scriptsize{}For a nonempty closed convex set $S$ in $\mathbb{R}^{n},$
$$
\delta_{S}^{*}=\sigma_{S},\textrm{ and }\sigma_{S}^{*}=\delta_{S}.
$$
}{\scriptsize\par}
\end{itemize}
}

\subsection*{Setup.}

Let $f$ be a CCP function on $\mathbb{R}^{n}$ and $g$ be a CCP function on $\mathbb{R}^{m}$. Let
$H$ be a vector-valued map from $\mathbb{R}^{n}$ to $\mathbb{R}^{m}$, and $\widetilde{H}$ be another
vector-valued map form $\mathbb{R}^{m}$ to $\mathbb{R}^{n}$ such that 
$$
\forall_{x\in\mathbb{R}^{n},u\in\mathbb{R}^{m}}\;\left\langle u\mid H(x)\right\rangle =\left\langle \widetilde{H}(u)\mid x\right\rangle ,
$$
e.g., if $H=A\in\mathbb{R}^{m\times n},$ $A$ being some $m\times n$ matrix, then $\widetilde{H}=A^{\top}$.\emph{ }

\subsection*{Lagrangian associated with Fenchel-Rockafellar Dualilty.}

Consider the Lagrangian function: 
$$\begin{equation}
L(x,u)=f(x)+\left\langle u\mid H(x)\right\rangle -g^{*}(u),\tag{\ensuremath{\mathcal{L}}}\label{eq:lagrangian}
\end{equation}$$
 which generates the primal problem\sidenote{\textcolor{teal}{\scriptsize{}We have 
$$
\sup_{u\in\mathbb{R}^{m}}L(x,u)=f(x)+g(H(x))
$$
 because:
$$\begin{align*}
 & \sup_{u\in\mathbb{R}^{m}}L(x,u)\\
= & \sup_{u\in\mathbb{R}^{m}}f(x)+\left\langle u\mid H(x)\right\rangle -g^{*}(u)\\
= & f(x)+\sup_{u\in\mathbb{R}^{m}}\left(-g^{*}(u)+\left\langle u\mid H(x)\right\rangle \right)\\
= & f(x)+\underbrace{g^{**}\left(H(x)\right)}_{g(H(x))}\;\text{\ensuremath{\rhd\textrm{ as }}}g\textrm{ ccp}\\
= & f(x)+g(H(x)).
\end{align*}$$
}}

$$
\begin{equation} \begin{aligned} & \underset{x\in\mathbb{R}^{n}}{\mbox{minimize}}\sup_{u\in\mathbb{R}^{m}}L(x,u)\\ = & \begin{array}{ll} \underset{x\in\mathbb{R}^{n}}{\mbox{minimize}} & f(x)+g\left(H(x)\right)\end{array}, \end{aligned}\end{equation}
$$

 and the dual problem\sidenote{\textcolor{purple}{\scriptsize{}We have 
$$
\inf_{x\in\mathbb{R}^{n}}L(x,u)=-f^{\star}\left(-\widetilde{H}(u)\right)-g^{*}(u)
$$
 because:
$$\begin{align*}
 & \inf_{x\in\mathbb{R}^{n}}L(x,u)\\
= & \inf_{x\in\mathbb{R}^{n}}f(x)+\left\langle u\mid H(x)\right\rangle -g^{*}(u)\\
= & -g^{*}(u)+\inf_{x\in\mathbb{R}^{n}}\left(f(x)+\left\langle u\mid H(x)\right\rangle \right)\\
= & -g^{*}(u)-\sup_{x\in\mathbb{R}^{n}}\left(-f(x)-\left\langle u\mid H(x)\right\rangle \right)\\
= & -g^{*}(u)-\sup_{x\in\mathbb{R}^{n}}\left(-f(x)-\left\langle \widetilde{H}(u)\mid x\right\rangle \right)\\
= & -g^{*}(u)-\sup_{x\in\mathbb{R}^{n}}\left(-f(x)+\left\langle -\widetilde{H}(u)\mid x\right\rangle \right)\\
= & -g^{*}(u)-f^{*}\left(-\widetilde{H}(u)\right).
\end{align*}$$
}}

$$\begin{equation}
\begin{aligned} & \underset{u\in\mathbb{R}^{n}}{\mbox{maximize}}\inf_{x\in\mathbb{R}^{n}}L(x,u)\\
= & \begin{array}{ll}
\underset{u\in\mathbb{R}^{m}}{\mbox{maximize}} & -f^{\star}\left(-\widetilde{H}(u)\right)-g^{*}(u)\end{array}.
\end{aligned}
\tag{\ensuremath{\mathcal{D}}}\label{eq:dual}
\end{equation}$$
 

\section{\textcolor{red}{From Fenchel-Rockafellar to Lagrangian duality. }}

Consider the convex optimization problem: 
$$\begin{equation}
\left(\begin{array}{ll}
\underset{x\in\mathbb{R}^{n}}{\mbox{minimize}} & f_{0}(x)\\
\textup{subject to} & f_{i}(x)\leq0,\quad i=1,2,\ldots,m,
\end{array}\right)\label{eq:primal_constraint}
\end{equation}$$
where $f_{0},f_{1},\ldots,f_{m}$ are CCP functions.

Now define the map, $\bar{H}:\mathbb{R}^{n}\to\mathbb{R}^{m}$ as 
$$
\bar{H}(x)\triangleq\begin{bmatrix}f_{1}(x)\\
f_{2}(x)\\
f_{3}(x)\\
\vdots\\
f_{m}(x)
\end{bmatrix},
$$
 hence a feasible point $\tilde{x}$ satisfies $\bar{H}(\tilde{x})\in\mathbb{R}_{-}^{m}$. 

Then \eqref{eq:primal_constraint} is equivalent to 
$$\begin{equation}
\left(\begin{array}{ll}
\underset{x\in\mathbb{R}^{n}}{\mbox{minimize}} & f_{0}(x)+\delta_{\mathbb{R}_{-}^{m}}\left(\bar{H}(x)\right)\end{array}\right)\label{eq:primal_con_2}
\end{equation}$$

Comparing \eqref{eq:primal_con_2} with \eqref{eq:primal}, in \eqref{eq:lagrangian} we can set $f\gets f_{0}$,
$H\gets\bar{H}$, and $g\gets\delta_{\mathbb{R}_{-}^{m}}$ thus leading to the Lagrangian in this case:\marginnote{\textcolor{blue}{\scriptsize{}We have $\sigma_{\mathbb{R}_{-}^{m}}(u)=\delta_{\mathbb{R}_{+}^{m}}(u)$
because}{\scriptsize\par}

\textcolor{blue}{\scriptsize{}
$$\begin{align*}
\sigma_{\mathbb{R}_{-}^{m}}(u) & =\sup_{v\in\mathbb{R}_{-}^{m}}\left\langle v\mid u\right\rangle \quad\text{\ensuremath{\rhd\textrm{ using definition}}}\\
 & =\sup_{v}\left\{ \sum_{i=1}^{m}v_{i}u_{i}\mid v_{i}\leq0,\,i\in[1:m]\right\} \\
 & =\sum_{i=1}^{m}\Big(\underbrace{\sup_{v_{i}\leq0}v_{i}u_{i}}_{\begin{cases}
0, & \textrm{if }u_{i}\geq0\\
\infty, & \textrm{if }u_{i}<0
\end{cases}}\Big)\quad\text{\ensuremath{\rhd\textrm{ using seperability}}}\\
 & =\delta_{\mathbb{R}_{+}^{m}}(u).\quad\text{\ensuremath{\rhd\textrm{ through observation}}}
\end{align*}$$
}{\scriptsize\par}} 
$$\begin{align*}
 & L(x,u)\\
= & f_{0}(x)+\left\langle u\mid\bar{H}(x)\right\rangle -\delta_{\mathbb{R}_{-}^{m}}^{\star}(u)\\
= & f_{0}(x)+\left\langle u\mid\bar{H}(x)\right\rangle -\sigma_{\mathbb{R}_{-}^{m}}(u)\;\text{\ensuremath{\rhd\textrm{ as }\delta_{S}^{\star}}=\ensuremath{\sigma_{S}}}\\
= & f_{0}(x)+\left\langle u\mid\bar{H}(x)\right\rangle -\delta_{\mathbb{R}_{+}^{m}}(u)\;\text{\ensuremath{\rhd\textrm{ as \ensuremath{\sigma_{\mathbb{R}_{-}^{m}}}=\ensuremath{\delta_{\mathbb{R}_{+}^{m}}} (see sidenote)}}}\\
= & f_{0}(x)+\sum_{i=1}^{m}u_{i}f_{i}(x)-\delta_{\mathbb{R}_{+}^{m}}(u)
\end{align*}$$
and the corresponding dual problem will be: 
$$\begin{align*}
 & \underset{u\in\mathbb{R}^{n}}{\mbox{maximize}}\inf_{x}\left(f_{0}(x)+\sum_{i=1}^{m}u_{i}f_{i}(x)-\delta_{\mathbb{R}_{+}^{m}}(u)\right)\\
= & \left(\begin{array}{ll}
\underset{u\in\mathbb{R}^{n}}{\mbox{maximize}} & \overbrace{\inf_{x}\left(f_{0}(x)+\sum_{i=1}^{m}u_{i}f_{i}(x)\right)}^{\textrm{dual function}}\\
\textup{subject to} & u_{i}\geq0,\;i=1,2,\ldots,m,
\end{array}\right)
\end{align*}$$
which is the classical Lagrangian dual.

\paragraph{Sample Code}

Sample code is below.

% \usepackage[minted]{tcolorbox}
% \usepackage{xcolor} % Required for bgcolor in minted
%  \definecolor{lightgray}{rgb}{0.9,0.9,0.9} % Define lightgray if not already defined
% \usepackage{fontspec} %fontspec is required for code font
% \setmonofont{JuliaMono}[Extension=.ttf, UprightFont=*-Regular, BoldFont=*-Bold, ItalicFont=*-RegularItalic, BoldItalicFont=*-BoldItalic, Contextuals=Alternate, Scale = 0.8]
=#


## First, load the packages
using JuMP, MosekTools, Mosek, LinearAlgebra

# Load $a^2 = b^2$

a = sqrt(β)  # Defining $a = \sqrt(\beta)$



#=
\end{document}
=#

