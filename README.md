# Xgit

Pure Elixir native implementation of git


## Why an all-Elixir implementation?

With all of git already implemented in [libgit2](https://github.com/libgit2/libgit2), why do it again?

I considered that, and then I read [Andrea Leopardi](https://andrealeopardi.com/posts/using-c-from-elixir-with-nifs/):

> **NIFs are dangerous.** I bet you’ve heard about how Erlang (and Elixir) are reliable and fault-tolerant, how processes are isolated and a crash in a process only takes that process down, and other resiliency properties. You can kiss all that good stuff goodbye when you start to play with NIFs. A crash in a NIF (such as a dreaded segmentation fault) will **crash the entire Erlang VM.** No supervisors to the rescue, no fault-tolerance, no isolation. This means you need to be extremely careful when writing NIFs, and you should always make sure that you have a good reason to use them.

libgit2 is a big, complex library. And while it's been battle-tested, it's also a large C library, which means it takes on the risks cited above, will interfere with the Erlang VM scheduler, and make the build process far more complicated. I also hope to make it easy to make portions of the back-end (notably, storage) configurable; that will be far easier with an all-Elixir implementation.

## Credits

xgit is heavily influenced by [jgit](https://www.eclipse.org/jgit/), an all-Java implementation of git. Many thanks to the jgit team for their hard work.
