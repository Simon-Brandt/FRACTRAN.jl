<!--
###############################################################################
#                                                                             #
# Copyright 2026 Simon Brandt                                                 #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License");             #
# you may not use this file except in compliance with the License.            #
# You may obtain a copy of the License at                                     #
#                                                                             #
#     http://www.apache.org/licenses/LICENSE-2.0                              #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
#                                                                             #
###############################################################################
-->

# Contribution guide

You're very welcome to contribute to FRACTRAN.jl!  Be it by fixing spelling mistakes or small bugs, adding to or clarifying the [documentation](docs), or even adding new functionality to FRACTRAN.jl itself, any improvement is highly appreciated.

In order to facilitate the seamless integration of your commits with the FRACTRAN.jl codebase, please try to comply with the following guidelines.  Most of them are rather irrelevant for small fixes, so you probably would follow them, anyways.  If you have reasons *not* to comply, it would likely not mean that your commit can't be merged, but you should explain *why* the guideline does not apply.  After all, it's a *guideline*, not a *law*.  And its always possible to adjust things at a later stage.

## Table of contents

1. [General advice](#1-general-advice)
   1. [Language](#11-language)
   1. [Commit messages](#12-commit-messages)
   1. [Artificial intelligence tools](#13-artificial-intelligence-tools)
1. [Code](#2-code)
   1. [Adding functionality](#21-adding-functionality)
   1. [Coding style](#22-coding-style)
1. [Documentation](#3-documentation)
   1. [Files](#31-files)
   1. [Documentation style](#32-documentation-style)

## 1. General advice

### 1.1. Language

Whatever you may change, the edits must be written in English, preferably American English.  This also applies to the text in [issues](https://github.com/Simon-Brandt/FRACTRAN.jl/issues/new), but especially to the documentation and code itself.

### 1.2. Commit messages

Keep the commit messages brief.  Rather explain the reasons in the issue or pull request comment.  Write the commit message in the active form, in the simple past, like "Added comma", or "Fixed off-by-one error".  By this, the message could be directly used for the release notes of a new FRACTRAN.jl version.

### 1.3. Artificial intelligence tools

> [!IMPORTANT]
> These guidelines are *compulsory* for *all* contributions involving AI tools, chiefly LLMs.

Some people just love their LLMs and have unlearned how to write themselves.  If you're part of them, you can still contribute to FRACTRAN.jl, but please review *anything* AI-generated *even more carefully* than when you had written it yourself.  In other words, there is *no ban* on AI-generated content (AIGC), as long as you take *full responsibility* on the committed output, and *disclose* your usage of AI tools in the pull request.  Vibe-coding is prohibited—please keep the code in your fork, then.

Furthermore, do *not* list LLMs as commit authors or co-authors.  This is as pointless as listing your text editor or its snippets as authors—LLMs cannot be held responsible for their "contributions", they're just programs—albeit very powerful ones.

Should, at some point, the legislation be refined to prohibit AIGC in some countries, or set rules on the license AIGC can be release under, and should this then violate the FRACTRAN.jl license (the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)), it would, in theory, be on *you* to rectify the legal problems.  So, to save us all from legal trouble: Rather perform the changes *yourself*.

Additionally, please *don't* paste LLM output (vetted or not) into commit messages or issue or pull request texts.  Instead, please write them yourself.  You are free to use spellcheckers, translators, and the like to fix single words, but please avoid tools that rewrite entire paragraphs.  LLMs tend to extreme verbosity (and flattery!), and that makes it very hard to grasp what "you" actually want.

Most importantly: *Never* copy a message (like a comment from a contributor asking for clarification) into an LLM and paste its output verbatim as answer.  Rather use it to understand the issue better, and then answer *in your own words*.

Spelling mistakes and grammar errors are just fine—I do them all the time.  They're fixable in the process of reviewing your PRs (or even years later).  Mountains of LLM output however, especially of dubious quality, are not.

So, in short: Feel free to use LLMs as assistants for coding and understanding problems.  But please *don't* use them in communicating with me or other contributors.

## 2. Code

### 2.1. Adding functionality

If you want to add features to FRACTRAN.jl, you usually should write the respective function(s) directly into the main [source file](src/FRACTRAN.jl).  Novel features require dedicated [tests](test/runtests.jl), as well as [tutorial](docs/src/tutorial.md) and [reference](docs/src/reference.md) sections with extensive docstrings.  When writing the tests, take the existing ones in [`runtests.jl`](test/runtests.jl) as reference—see the [Test stdlib documentation](https://docs.julialang.org/en/v1/stdlib/Test/) for examples.

### 2.2. Coding style

The coding style for FRACTRAN.jl is inspired by [Python's PEP 8](https://peps.python.org/pep-0008/) and the [Blue style guide](https://github.com/JuliaDiff/BlueStyle) with some project-specific modifications.  When in doubt, look at what you find in the existing codebase, or ask in an issue comment.  Briefly, the following style is recommended (and in part enforced):

- ***Comments:***
  - Write comments as full sentences, and end them in a period.
  - Use an imperative, rather than declarative style, unless explaining the code's intentions.  It is better to comment more, than less, to help understanding the code, later on.
  - Avoid in-line comments, unless necessary and fitting in the line.
  - Separate sentences by two spaces, or a newline for an unrelated thought.  This helps the readability within monospaced fonts.
- ***Indentation:***
  - Indent with four spaces per level.  Don't use tabs.
  - Indent blocks in functions, loops, conditions, *etc.*, as well as wrapped lines (within parentheses).
- ***Line length:***
  - A line should not exceed 79 characters (80 including the newline character).  Wrap an overly long line, indenting any subsequent line from the same command by four additional spaces.
  - For conditionals, wrap the line *before* the `&&` or `||`.
  - Comments should wrap at 72 characters (exception: in-line comments).
  - If a line contains a URL or a similarly long string that can't be reasonably wrapped, consider putting it on a separate line.  It's okay if it's still too long (don't add line breaks within URLs!).
- ***Whitespace:***
  - Be rather generous with whitespace.  Use a space around conditionals and arithmetic or logical operators.
  - Use blank lines to separate blocks of related code from each other.
  - Use Unix linebreaks (LF), not DOS linebreaks (CRLF).
- ***Imports:***
  - Import modules with `using`, not `import`, as `using Module: Module`.  By this, it is impossible to inadvertently add methods to foreign (unqualified) functions.  Besides, it is much clearer where a used symbol comes from.
  - Avoid "wildcard" imports (`using Module`).  Only import names that you actually need.  In most cases, this should be only the module (`using Module: Module`), and in some cases, a specific symbol (`using Module: symbol`).
  - Wildcard imports are acceptable in the [tests](test/runtests.jl) (only for FRACTRAN.jl) and [documentation creation](docs/make.jl) (for FRACTRAN.jl and Documenter-related functions).
- ***Functions:***
  - Put all code in functions.  This facilitates re-usability, but, more importantly, helps the  Julia compiler.
  - Use a verb in imperative mode as function name, usually followed by some other words.  Abbreviate only very common and often used words.  Use `lowercase_with_underscores` ("snake case") for the name.  Prefix private functions with an underscore.
  - Mark a function as `public` if it should be part of the API, but not directly available by an unqualified name (without the module as prefix).  Mark it as `export`ed if it should be directly available—this should apply to rather few functions.
  - Always use type annotations for the function's arguments *and* return value(s).  Make sure, however, that the return type annotation is a no-op and does not impose an implicit type conversion.  In other words, inspect the function's return type *without* an annotation, and use that expression as annotation.  Make sure that no code path may create a different type.  For argument types, use abstract types whenever they make sense for the function.  Private functions, where the API can change when needed, are free to be annotated with concrete types, only.
  - Start the function with a docstring describing its purpose, `jldoctest`-style usage examples, and possibly some extended help.
  - Always use an explicit `return`.  If there is no value to return, use `return nothing`.
- ***Variables:***
  - Always use local variables.  Pass globals as arguments, not as actual globals.
  - Try using a noun as variable identifier.  Like for functions, abbreviate only very common and often used words.  Use `lowercase_with_underscores` ("snake case") for the identifier.  Don't use a leading underscore to indicate private use, since *all* variables are local.
  - Use descriptive variable names.  This still includes `i`, `j`, *etc.* as loop variables, when they just hold an integer.
- ***Unicode***:
  - Use as few Unicode characters in the actual source code as possible.  This dramatically simplifies seraching for them.  *I.e.*, prefer `>=` over `≥`, `!in()` over `∉`, *etc.*  
  *Note: This rule is currently under consideration and may be removed in the future.*
  - In comments and docstrings (except code blocks), Unicode characters are fine, *e.g.*, for formatting tables.

## 3. Documentation

### 3.1. Files

All files must reside in the [`docs/src`](docs/src/) directory and be added to [`make.jl`](docs/make.jl) for inclusion.  [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) then handles the build step on each `git push` to the `main` branch.  Alternatively, you can build it locally with `julia --project make.jl`.

### 3.2. Documentation style

The documentation (including docstrings) is written in [Julia Markdown](https://docs.julialang.org/en/v1/stdlib/Markdown/).  While much less lenient than [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/), a few additional, project-specific stylistic guides are needed.  If you're using [Visual Studio Code](https://code.visualstudio.com/), the [Markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint) extension may help you accord to them.

- ***Line length:*** There is no limit to the line length for non-code blocks.  To avoid the need for re-ordering the words whenever a word on a previous line is deleted, don't wrap the lines by hand.  Instead, use the automatic line wrapping ability of your text editor of choice.
- ***Paragraphs:*** Paragraphs should be separated by one blank line from each other.
- ***Sentences:*** Separate sentences with two spaces.
- ***Headings:***
  - Headings must be surrounded by one blank line each.
  - Use little formatting within headings.  In-line code is fine, since headings often reflect *e.g.* the name of an environment variable, and need to be typeset accordingly.
  - When a section is large enough to deserve its own documentation file, put it into its own file.  The is no restriction on the number of files.
- ***Lists:***
  - Use hyphens (`-`) to markup unnumbered lists, not asterisks (`*`) or plus signs (`+`).  Use a literal `1.` for numbered lists, irrespective of the actual number.  This facilitates re-ordering the list and deleting elements, without needing to refactor it in its entirety.
  - Top-level lists must be surrounded by one blank line each.  Nested lists only need blank lines when containing other top-level blocks.
- ***Admonitions:***
  - Admonitions (warnings, notes, tips, *etc.*) are useful, but avoid using too many, and nesting them.  When necessary, however, they're completely fine to use.
- ***Code blocks:***
  - Feel free to use a copious number of code blocks to show code examples.
  - Surround code blocks by blank lines and triple backticks (```` ``` ````).  Use a language specification to enable syntax highlighting (usually `julia` or `jldoctest`), even when none exists (like for `text`).  Only use indented code blocks for the leading symbol signature in docstrings.
- ***In-line code:***
  - Be aware of the difference between backticks for code and LaTeX elements:  An odd number of backticks (like `` `...` `` and ```` ```...``` ````) means code, an even number (like ``` ``...`` ``` and ````` ````...```` `````) LaTeX elements.
- ***Emphasis:***
  - Use bold font sparingly, to draw attention to a certain point.  Use italics for normal emphasis and foreign-language words like Latin abbreviations.
