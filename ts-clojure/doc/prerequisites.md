# Prerequisites

## Overview

Briefly, the minimal necessities include:

* Babashka
* tree-sitter cli
  * Node.js (can reuse what's in emsdk)
  * C compiler

However, version details may matter depending on the situation.  See
below for details.

## Babashka

Babashka tasks are used to execute some common tasks.  The idea with
using Babashka is that most people who might take an interest in
tree-sitter-clojure and consider joining in the maintenance fun (hah!)
would likely be at least somewhat Clojure-proficient...so why choose
Node, shell, or other things, right?

It's likely most recent version of Babashka will work, but for
reference, the following versions have been used successfully:

* 1.2.174
* 1.3.182
* 1.3.189

## tree-sitter CLI

The `tree-sitter` cli is used to:

* generate tree-sitter-clojure's `src/parser.c`
* build and install an associated shared library
* run tests

The following versions of the tree-sitter cli have been used (though
others may work too):

* 0.20.8
* 0.20.9
* 0.22.6

Note that the version chosen here can impact which ABI number can be
specified during generation of `src/parser.c`.

At the time of this writing, the most commonly used ABI number appears
to be `14` and this should be specifiable with any of the versions
listed above.

## For Using tree-sitter CLI

The official docs for tree-sitter are on the vague side regarding
versions.  This is also the case for the listed dependencies for using
the `tree-sitter` cli:

* Node.js
* C compiler

There are specific versions listed below that were tested at various
points for reference:

* Node.js (tested with 12.x, 14.x, 16.x, 18.x)
* Recent C compiler (tested with gcc 11.3.0, 12.2.0 clang 14.0.0)

It's possible that earlier / later versions may also work but it's
also possible that some versions may not work depending on which
version of the `tree-sitter` cli is being used (e.g. early version of
Node.js might not work with more recent versions of `tree-sitter`).

Note that an appropriate version of Node.js is available as part of
emsdk and can be used instead of separately installing one.  See the
[ts-questions](https://github.com/sogaiu/ts-questions) question about
which version of emscripten should be used for the playground for more
details on appropriate versions and emsdk setup instructions.

Node.js is currently required as part of `tree-sitter`'s `parser.c`
generation process.  IIUC, [some work is underway to make it possible
to use some other JS
option](https://github.com/tree-sitter/tree-sitter/pull/3355), but at
the time of this writing, that has not come to pass.  Even if it did
at some point, if it's important to use older versions of
`tree-sitter`, those would require some version of Node.js...

The C compiler is necessary to build the shared libary from
`parser.c`.

## For Building tree-sitter CLI

If building `tree-sitter` from source, the following are some hints
for versions of things that have worked at various points:

* Rust Tooling (tested with rustc 1.67, 1.72.1 and cargo 1.67, 1.72.1)
* Recent C compiler (tested with gcc 11.3.0, 12.2.0 clang 14.0.0)

To get a version of `tree-sitter` that can build `.wasm` files, emsdk
is necessary.  Before running `cargo build`, it's important to run
`bash script/build-wasm --debug`, but before that, an appropriate
emsdk version needs to be activated.  More info about that is
available at the aforementioned
[ts-questions](https://github.com/sogaiu/ts-questions).

