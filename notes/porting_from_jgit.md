# Some Comments on Porting from Jgit

This project is a port of [jgit](https://www.eclipse.org/jgit/), which is an all-Java implementation of git.

While I've chosen to follow many of the design patterns present in jgit, in my opinion, it's far more important that this project feel comfortably at home in the Elixir ecosystem. In this file, I document some of the porting design decisions that I've made, especially where they differ from jgit.

## Localization

jgit has its own localization mechanism (see class `JGitText`). I've decided not to port that mechanism, but rather to use the Elixir module [`gettext`](https://github.com/elixir-lang/gettext).

## Exceptions vs errors

In keeping with Elixir convention, jgit class names that end with `Exception` are renamed to Elixir modules that end with `Error`.
