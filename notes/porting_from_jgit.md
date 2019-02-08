# Some Comments on Porting from Jgit

This project is a port of [jgit](https://www.eclipse.org/jgit/), which is an all-Java implementation of git.

While I've chosen to follow many of the design patterns present in jgit, in my opinion, it's far more important that this project feel comfortably at home in the Elixir ecosystem. In this file, I document some of the porting design decisions that I've made, especially where they differ from jgit.

## String Buffers -> Charlists

The jgit APIs often speak in byte arrays with offset (pointers). In xgit, we instead pass around charlists. Since a charlist is a singly-linked list, it is conceptually easier (and more performant) to pass around an updated charlist reference and omit the offset parameter, so we do this.

## Localization

jgit has its own localization mechanism (see class `JGitText`). I've decided not to port that mechanism, but rather to use the Elixir module [`gettext`](https://github.com/elixir-lang/gettext). Unlike jgit, we do not localize internal exception messages, only the publicly-facing interface.

## Exceptions -> Errors

In keeping with Elixir convention, jgit class names that end with `Exception` are renamed to Elixir modules that end with `Error`.
