
## ARCHIVED? WHAT?!?

After careful consideration, I am setting aside this project for now. I am finding that porting from the jgit implementation is leading to an approach that is more complicated than I had hoped. Patterns that are appropriate in Java (complex object hierarchies, shared state across threads) do not translate well into the Erlang / OTP world.

From the ashes of this effort, there arises a new one. I am currently working on a new version of the project which is a from-the-ground-up implementation of git in Elixir. That project will occasionally draw upon work done here, so all is not lost.

I'm happy enough with the new effort to let it take on the mantle of being called [xgit](https://github.com/elixir-git/archived-jgit-port).

I hope to see you there.

What follows is the README before I undertook this decision:

----

# Xgit

Pure Elixir native implementation of git [![Build Status](https://travis-ci.org/elixir-git/archived-jgit-port.svg?branch=master)](https://travis-ci.org/elixir-git/archived-jgit-port) [![Coverage Status](https://coveralls.io/repos/github/elixir-git/archived-jgit-port/badge.svg?branch=master)](https://coveralls.io/github/elixir-git/archived-jgit-port?branch=master)

## WORK IN PROGRESS

**This is very much a work in progress and not ready to be used in production.** What is implemented is well-tested and believed to be correct and stable, but much of the core git infrastructure is not yet implemented. There has been little attention, as yet, to measuring performance.

## Where Can I Help?

**The current plan is to implement core git infrastructure (often referred to as "plumbing").** Once most of the plumbing is in place, then we can build on specific porcelain-level APIs and/or server infrastructure (push, pull, clone, etc.).

**The current major infrastructure being targeted is porting the jgit `RevWalk` class.** This provides core infrastructure for walking commit history and object graphs. Progress on this project is tracked as follows:

* [Porting Roadmap](./notes/porting_roadmap.txt)
* [GitHub project for porting `RevWalk`](https://github.com/elixir-git/archived-jgit-port/projects/3)

**There is also important work to be done in backfilling existing porting work.** Please see:

* [Issues tagged "good first issue"](https://github.com/elixir-git/archived-jgit-port/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
* [Issues tagged "help wanted"](https://github.com/elixir-git/archived-jgit-port/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22) _more issues, but potentially more challenging_
* [Project "Backfill incomplete implementations"](https://github.com/elixir-git/archived-jgit-port/projects/2)


## Why an All-Elixir Implementation?

With all of git already implemented in [libgit2](https://github.com/libgit2/libgit2), why do it again?

I considered that, and then I read [Andrea Leopardi](https://andrealeopardi.com/posts/using-c-from-elixir-with-nifs/):

> **NIFs are dangerous.** I bet you’ve heard about how Erlang (and Elixir) are reliable and fault-tolerant, how processes are isolated and a crash in a process only takes that process down, and other resiliency properties. You can kiss all that good stuff goodbye when you start to play with NIFs. A crash in a NIF (such as a dreaded segmentation fault) will **crash the entire Erlang VM.** No supervisors to the rescue, no fault-tolerance, no isolation. This means you need to be extremely careful when writing NIFs, and you should always make sure that you have a good reason to use them.

libgit2 is a big, complex library. And while it's been battle-tested, it's also a large C library, which means it takes on the risks cited above, will interfere with the Erlang VM scheduler, and make the build process far more complicated. I also hope to make it easy to make portions of the back-end (notably, storage) configurable; that will be far easier with an all-Elixir implementation.

## Credits

xgit is a port of [jgit](https://www.eclipse.org/jgit/), an all-Java implementation of git. Many thanks to the jgit team for their hard work.
