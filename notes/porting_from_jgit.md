# Some Comments on Porting from Jgit

This project is a port of [jgit](https://www.eclipse.org/jgit/), which is an all-Java implementation of git.

While I've chosen to follow many of the design patterns present in jgit, in my opinion, it's far more important that this project feel comfortably at home in the Elixir ecosystem. In this file, I document some of the porting design decisions that I've made, especially where they differ from jgit.

## String Buffers -> Charlists

The jgit APIs often speak in byte arrays with offset (pointers). In xgit, we instead pass around charlists. Since a charlist is a singly-linked list, we pass around updated charlist references without offset parameters because it is conceptually easier (and more performant) to do so.

## Localization

jgit has its own localization mechanism (see class `JGitText`). I've decided not to port that mechanism, but rather to use the Elixir module [`gettext`](https://github.com/elixir-lang/gettext). Unlike jgit, we do not localize internal exception messages, only the publicly-facing interface.

## Exceptions -> Errors

In keeping with Elixir convention, jgit class names that end with `Exception` are renamed to Elixir modules that end with `Error`.

## Listeners

Instead of porting the `Listener` and `ListenerList` mechanism from jgit, we use [`pg2`](http://erlang.org/doc/man/pg2.html) to manage inter-process messaging and the related lifetime issues.

## Windows OS Support

In this initial (experimental) version of xgit, I've decided not to explicitly support Windows. This lets me avoid the time that would be spent porting some of jgit's abstractions. Instead, we'll rely as much as possible on the Erlang VM. Some of the abstractions explicitly avoided:

* FS (file system)

I recognize that retrofitting these abstractions into the system later will be at best, difficult, but I can't justify the cost in porting them for my purposes here.
