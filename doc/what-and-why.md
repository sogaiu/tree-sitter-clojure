# What the Repository Provides and Why

This document describes what files and directories the repository
provides and associated reasoning.  First it covers things which are
likely to remain in place for some time (except perhaps the `src`
directory).  This is followed by a description of things that are more
likely to change or be removed.

One might be interested in this content out of academic curiosity but
more likely it might be because one is thinking of depending on the
repository in some way.

## What and Why

The order of the following files and directories is alphabetical and
not meant to reflect relative importance.

* `CHANGELOG.md` - this file contains a changelog.

* `COPYING.txt` - this file contains license information for the
  repository.

* `grammar.js` - this file contains a grammar description and is used
  in the process of generating parser source code that lives in `src`.
  It's likely that this (or something comparable) will continue to be
  provided assuming tree-sitter doesn't change the way it works.

* `package.json` - this file is needed by a
  [component](https://github.com/cursorless-dev/vscode-parse-tree/) of
  [Cursorless](https://www.cursorless.org/).  It uses our grammar via
  yarn and `package.json` seems to be essential [1].

* `queries` - this directory and the simple file it contains are
  provided on request from
  [`difftastic`](https://github.com/Wilfred/difftastic) folks.  The
  file it contains doesn't contain much and is not likely to be the
  sort of thing one expects to be used in an editor.

* `README.md` - this file contains the repository's README content.

* `src` - this directory contains source files that are generated [2]
  from `grammar.js`.  The files are typically used to generate a
  dynamic library / shared object that can be used by the tree-sitter
  library to handle Clojure / ClojureScript source code.  Although the
  content of this directory is generated, the files are provided
  because in practice, multiple parties have already become dependant
  on them.  There have been opinions voiced that this should not
  remain so, but change in that direction has not been widespread.  We
  would prefer not to be hosting this directory and its content, but
  are leaving it in place for the time being.  See
  [here](https://github.com/sogaiu/ts-questions/blob/master/questions/should-parser-source-be-committed/README.md)
  for more on the topic if interested.

* `test/corpus` - this directory contains tree-sitter's corpus
  test-related files.

## Other Content

The rest of the content of the repository is much more subject to
change / removal so depending on such remaining in place is likely not
a good idea.

ATM, some of that includes:

* documentation
* Node.js bindings
* Rust bindings

### About the Bindings

The bindings are not tested in any way and only really exist as a
side-effect of running the `tree-sitter` cli's `generate` subcommand.
They may be removed at some point, but they should be straight-forward
to generate as long as one has a suitable `tree-sitter` cli and the
`grammar.js` file mentioned above, but see below for details and/or
have a look at some [official
docs](https://github.com/tree-sitter/tree-sitter/blob/master/docs/section-3-creating-parsers.md#command-generate).

### Rust Bindings

Invoking `tree-sitter generate` should lead to the creation of the
`bindings/rust` directory (plus files within) and `Cargo.toml` if
these don't already exist.

To build the bindings, use `cargo build` for a debug build or `cargo
build --release` for a release build.  The results should end up under
the `target/debug` and `target/release` directories respectively.

### Node.js Bindings

In order to successfully build the Node.js bindings (say, by an
invocation of `npx node-gyp rebuild`), first do the following:

* Remove `package.json` (or rename it)
* Invoke `tree-sitter generate`

This will create a new `package.json` with allegedly correct values
for properties like `dependencies` and `main`.  It might be worth
tweaking some of the other properties such as `version` to avoid
confusion.  The `generate` subcommand should also create `binding.gyp`
and the `bindings/node` directory (plus files within), if these don't
already exist.

Once the new `package.json` has been arranged for, invoking `npm
install` should lead to appropriate dependencies being installed.

Executing `npx node-gyp rebuild` should then be enough to build the
Node.js bindings.  The result should end up in the `build/Release`
directory.

Note that though I have tried the above instructions, I don't use or
test the bindings and it may be that they will be out-of-date at some
point.  I suggest checking the aforementioned [official
docs](https://github.com/tree-sitter/tree-sitter/blob/master/docs/section-3-creating-parsers.md#command-generate)
or asking at the tree-sitter repository.

## Footnotes

[1] The file `package.json` may also be required if it's important to
use some of the capabilities of the `tree-sitter` cli such as the
`tags` and `highlight` subcommands (which we don't typically use).

It's not necessary for all subcommands though (e.g. neither the
`generate` nor `test` subcommands seem to require it).  Its presence
also doesn't signify necessary use of `npm`.

Possibly contrary to what might be indicated elsewhere, `npm` is
not necessary for certain core parts of tree-sitter grammar
development.  However, at the moment, an appropriate version of `node`
_is_ required for the `generate` subcommand to work.

[2] If the grammar uses an external scanner, `src` may contain
non-generated files such as `scanner.c`, `scanner.cc`, etc.  In the
current case, no external scanner is used and the `src` directory
content is entirely generated.
