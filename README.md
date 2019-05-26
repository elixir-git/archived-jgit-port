# Xgit

Pure Elixir native implementation of git [![Build Status](https://travis-ci.org/elixir-git/xgit.svg?branch=master)](https://travis-ci.org/elixir-git/xgit) [![Coverage Status](https://coveralls.io/repos/github/elixir-git/xgit/badge.svg?branch=master)](https://coveralls.io/github/elixir-git/xgit?branch=master)


## WORK IN PROGRESS

**This is very much a work in progress and not ready to be used in production.** What is implemented is well-tested and believed to be correct and stable, but much of the core git infrastructure is not yet implemented. There has been little attention, as yet, to measuring performance.

If you are interested in contributing, please reach out. I'll be adding notes on the current work at hand and items where first-time contributions would be especially welcome in the near future.

The currently active project is to implement the API equivalent of the `git add` command. This project can be tracked via https://github.com/elixir-git/xgit/projects/1.

First time contributors: Please see https://github.com/elixir-git/xgit/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22.


## Why an all-Elixir implementation?

With all of git already implemented in [libgit2](https://github.com/libgit2/libgit2), why do it again?

I considered that, and then I read [Andrea Leopardi](https://andrealeopardi.com/posts/using-c-from-elixir-with-nifs/):

> **NIFs are dangerous.** I bet you’ve heard about how Erlang (and Elixir) are reliable and fault-tolerant, how processes are isolated and a crash in a process only takes that process down, and other resiliency properties. You can kiss all that good stuff goodbye when you start to play with NIFs. A crash in a NIF (such as a dreaded segmentation fault) will **crash the entire Erlang VM.** No supervisors to the rescue, no fault-tolerance, no isolation. This means you need to be extremely careful when writing NIFs, and you should always make sure that you have a good reason to use them.

libgit2 is a big, complex library. And while it's been battle-tested, it's also a large C library, which means it takes on the risks cited above, will interfere with the Erlang VM scheduler, and make the build process far more complicated. I also hope to make it easy to make portions of the back-end (notably, storage) configurable; that will be far easier with an all-Elixir implementation.

## Credits

xgit is a port of [jgit](https://www.eclipse.org/jgit/), an all-Java implementation of git. Many thanks to the jgit team for their hard work.
