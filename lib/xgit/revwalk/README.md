# Porting Notes for RevWalk

## Simplifications Taken

Some jgit classes from this package were deemed unnecessary in the Erlang/Elixir environment.

Specifically:

* `RevFlag`: translates neatly to an atom
* `RevFlagSet`: translates to a `MapSet` of atoms
