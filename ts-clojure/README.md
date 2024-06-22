# ts-clojure

Testing and development bits for
[tree-sitter-clojure](https://github.com/sogaiu/tree-sitter-clojure),
including:

* Fetching and testing of real-world code sample sets
* Intentional generation of `src/parser.c` and friends
* Related instructions

See [here](doc/background.md) for some background.

## Prerequisites

The prerequisites are what you typically need to work with
tree-sitter, with the exception of Babashka which is used for task
automation:

* [tree-sitter](https://github.com/tree-sitter/tree-sitter) cli
* [tree-sitter dependencies](https://tree-sitter.github.io/tree-sitter/creating-parsers#dependencies)
* [babashka](https://github.com/babashka/babashka) - shell completion
  setup highly recommended: [Option
  1](https://book.babashka.org/#_terminal_tab_completion), [Option
  2](https://github.com/babashka/babashka/discussions/1615)

If you want to test against ClojureDart samples, the `git` cli program
is needed for fetching the samples.  Perhaps it is likely it's already
available for other reasons :)

See [here](doc/prerequisites.md) for more details.

## Tweak settings

ts-clojure's scripts can be configured a bit via the file
`conf/conf.clj`.

Some included settings are:

* `abi` - ABI number to use when generating `parser.c` from
  `grammar.js`
* `grammar-dir` - path to cloned tree-sitter-clojure directory
* `repos` - which set of source samples to test against
* `ts-bin-path` - path to or name of `tree-sitter` cli binary

See [here](doc/tweak-settings.md) for more details.

## Checking the Setup

Note that once Babashka is available, you can repeatedly use:

```
bb check-setup
```

as you follow the setup instructions to get some help regarding
whether settings are appropriate.

## One-time (Mostly) Setup

### A Brief Warning

Consider working in a new user account.  This is not required, but you
might want to read near the end of the document for potential
consequences of not doing so.

### A Fork in the Road...Sort Of

It is possible to use ts-clojure in a variety of ways:

1. ts-clojure is a subdirectory of tree-sitter-clojure
2. tree-sitter-clojure is a subdirectory of ts-clojure
3. no particular parent-child relationship

The currently favored approach is option 1 - i.e. ts-clojure being a
subdirectory of tree-sitter-clojure.

For the other approaches, there is some documentation
[here](doc/tsc-not-parent-dir.md).

### Verify tree-sitter setup

Verify what version of `tree-sitter` you have installed and confirm
that you know where it looks to find parser repositories.

See [here](doc/verify-tree-sitter-setup.md) for more details.

### Prepare source samples

The source code samples do not come bundled.  To get meaningful
testing over real-world code, it's necessary to arrange for some
samples.

To fetch some source code samples:

* For clojars:
  * Change working directory to the `clojars-samples` subdirectory
  * Fetch 11 jars by: `bb fetch-jars 11`
  * Extract the jars by: `bb extract-jars`

* For clojuredart samples:
  * Change working directory to the `clojuredart-samples` subdirectory
  * Fetch some clojuredart code by: `bb fetch-samples`

* For core_regression samples:
  * Change working directory to the `core-regression-samples` subdirectory
  * Fetch samples by: `bb fetch-samples`

* For test.regression samples:
  * Change working directory to the `test-regression-samples` subdirectory
  * Fetch samples by: `bb fetch-samples`

Change the value of `repos` in `conf/conf.clj` to specify which set of
samples to test against.

Note that in the case of clojars, if you are serious about testing,
please consider getting more jars.

See [here](doc/prepare-source-samples.md) for more details.

### Final Steps

Consider using the `bb check-setup` task to get a sense of whether
your setup has any obvious issues.

## Things You Can Do

### Generate `parser.c`

To generate tree-sitter-clojure's `src/parser.c` file:

```
bb generate-parser
```

This will invoke `tree-sitter`'s `generate` subcommand:

* using the ABI number specified in `conf/conf.clj` via `abi` and
* using the `--no-bindings` argument to avoid generating binding code

### Build and Install Shared Library

To build and install a shared library based on the generated
`parser.c`:

```
bb corpus-test
```

This will run tree-sitter-clojure's corpus tests via `tree-sitter
test`, which has a side-effect that achieves the desired aim.

See [here](doc/build-and-install-shared-library.md) for more
details.

### Run Real-World Code Tests

To test the parser on real-world code:

```
bb parse-samples
```

This will invoke `tree-sitter`'s `parse` command across a set of
source code samples.

Which set of samples is tested against can be specified by:

* adjusting the `repos` value in `conf/conf.clj`, or
* passing an extra argument to the task, e.g. `bb parse-samples clojars`

Assuming the samples have been obtained, the value can be one of:

* `clojars`
* `clojuredart`
* `core-regression`
* `test-regression`

See [here](doc/run-real-world-code-tests.md) for more
details.

## Misc Notes

### About Being Future-Proof

At this time, `tree-sitter` cli subcommand backward compatibility does
not appear to be a high priority, so it may be good to expect to have
to adjust some `tree-sitter` invocations in the various Babashka
(`.clj`) scripts.

As a specific example of a potential backward incompatibility, at the
time of this writing, [there are plans to phase out the `build-wasm`
subcommand](https://github.com/tree-sitter/tree-sitter/blob/fc146ad5101334cb316f905657e79fe5e4fe7876/cli/src/main.rs#L522).

### Windows Support

Have not tested yet but might work via mingw-w64 / msys2 or similar.
No idea about WSL, not a fan and haven't tested.

### Isolation

I had trouble at various points with `tree-sitter` behavior being
influenced by things that I was unaware of.  I believe this was the
result of a combination of:

* testing with different versions of `tree-sitter` (various
  configuration and operation file paths changed between versions),
* having multiple versions of grammars under my home directory,
* not understanding the workings of [tree-sitter's automatic
compilation](https://github.com/tree-sitter/tree-sitter/issues/2017)

One way to avoid some of this kind of thing is to use some kind of
isolation / simplification mechanism such as a fresh user account.

