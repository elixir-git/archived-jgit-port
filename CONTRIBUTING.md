# Contributing

This project is obviously in its very early stages. This guide is similarly incomplete for now. (Contributions here are welcome, of course!)

As a very basic starting point, please interact with the xgit team in a manner that honors the [Elixir Code of Conduct](https://github.com/elixir-lang/elixir/blob/master/CODE_OF_CONDUCT.md).

## Code Style Guidelines

**This project uses the Elixir code formatter.** You must run `mix format` from the root level of this repo before submitting code. Pull request validations will fail if the code formatter says it would rewrite any files.

**This project uses the [Credo static analysis tool](https://github.com/rrrene/credo).** Pull request validations will fail if Credo issues any warnings. Please fix such issues if they are flagged.

**This project uses [Coveralls](https://coveralls.io/github/scouten/xgit) to enforce code coverage.** Thus far, I have been able to maintain very high code coverage through unit testing. I would like to keep it that way. Pull request validations will fail any time that new coverage gaps are introduced. It _may_ be possible to merge a PR with new gaps, but I would want to have an unusually strong justification for doing so.

### Additional Guidelines

The following guidelines are not automatically enforced. (I would welcome PRs that add automated enforcement for these guidelines.)

**Use short-form `do:` and `else:` clauses whenever possible.**

```elixir
# PREFERRED
defp do_mumble(_foo), do: :mumble

# NOT PREFERRED
defp do_mumble(_foo) do
  :mumble
end
```

**Exception: Do NOT use short-form `do:` and `else:` clauses when they could hide branch coverage gaps.** Elixir's code coverage tools are only able to generate line-level coverage. If multiple branches occur on the same line, it would be possible to observe one side of a branch and not another.

```elixir
# PREFERRED
if mumble? do
  :mumble
else
  :not_mumble
end

# NOT PREFERRED
if mumble?, do: :mumble, else: :not_mumble
```

**Use `alias` to avoid writing full module names inside a module.**

```elixir
# PREFERRED
alias Xgit.Lib.Repository

def mumble(repository), do: Repository.valid?(repository)

# NOT PREFERRED
# no alias statement

def mumble(repository), do: Xgit.Lib.Repository.valid?(repository)
```

**Alias, import, etc., references should be alphabetized by the full module name.** The intent here is to have a deterministic sequence for a set of `alias` (or similar) references and to avoid the risk of redundant references.

```elixir
# PREFERRED
alias Xgit.Lib.Constants
alias Xgit.Lib.Repository
alias Xgit.Storage.File.FileRepository

# NOT PREFERRED
alias Xgit.Lib.Constants
alias Xgit.Storage.File.FileRepository
alias Xgit.Lib.Repository

# NOT PREFERRED
alias Xgit.Lib.Repository
alias Xgit.Lib.Constants
alias Xgit.Storage.File.FileRepository
```

**References at the start of a file should follow a deterministic sequence.** If references of more than one of following types occur, they should occur in the following sequence, with a single blank line between each group:

* `defstruct` (or `defexception`)
* `use`
* `alias`
* `import`
* `require`
* `doctest`

```elixir
# PREFERRED
use Xgit.Lib.Repository

alias Xgit.Lib.Constants
alias Xgit.Util.SystemReader

require Logger

# NOT PREFERRED
use Xgit.Lib.Repository
require Logger
alias Xgit.Lib.Constants
alias Xgit.Util.SystemReader
```

**Aliases should (generally) not introduce new acronyms for aliased modules.** (Exception: In test code, a short name for the module under test is acceptable.)

```elixir
# PREFERRED
alias Xgit.Lib.Repository

# NOT PREFERRED
alias Xgit.Lib.Repository, as: Repo

# ACCEPTABLE (in test code only)
alias Xgit.Util.RawParseUtils, as: RPU
```
