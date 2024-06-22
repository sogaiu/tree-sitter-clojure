# Build and Install Shared Library

It may seem a bit odd to be executing the corpus tests (i.e. invoking
`tree-sitter test`) to build and install a shared library for
tree-sitter-clojure, but the `tree-sitter` cli doesn't appear to
provide a direct way of building AND installing an appropriate library
at the time of writing.

N.B. if there is already a shared object in place from before the
generation of `parser.c`, it may need to be moved out of the way or
deleted first.

On a Linux system, the shared object might be found at
`~/.cache/tree-sitter/lib/clojure.so` for relatively recent versions
of `tree-sitter`.
