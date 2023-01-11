# tree-sitter Grammar Dev Notes

Notes so that when maintainers return to look after the project at
some point, they will have an easier time :)

Possibly, parts of this could be handy for getting interested folks up
to speed.

## A Note on Terminology

The string "tree-sitter" may refer to:

* the name of a command line program
* the name of a library
* an adjective used in front of "grammar"

...and possibly other things.

## `grammar.js` and `src/scanner.(c|cc)`

A tree-sitter grammar is typically expressed in the form of a
`grammar.js` file.  The content should be JavaScript of some sort, but
it's somewhat vague as to what constructs are supported.  Possibly the
most notable item regarding ambiguity is support for regular
expressions.  Simple things work fine, but [it's not entirely clear
exactly what can be
used](https://github.com/tree-sitter/tree-sitter/issues/463).

If the ordinary machinery of tree-sitter is not up to the task of
handling parsing (e.g. indentation-related constructs for languages
like Python or Haskell), one may provide a C or C++ implementation of
an "external scanner" to aid in processing.  This is typically stored
in a file at `src/scanner.c` or
[`src/scanner.cc`](https://github.com/tree-sitter/tree-sitter-python/blob/9e53981ec31b789ee26162ea335de71f02186003/src/scanner.cc).
In `grammar.js`, one expresses that such handling is used via [the
`externals`
construct](https://github.com/tree-sitter/tree-sitter-python/blob/9e53981ec31b789ee26162ea335de71f02186003/grammar.js#L54-L74).

It's most likely the case that a fair bit of one's development efforts
will be focused around `grammar.js`.  It may be that an external
scanner is not necessary for a particular programming language.
Having said that, out of 58 grammars fetched locally, 37 of them had
external scanners...at least there are plenty of examples :)

## Pipeline: From Grammar to Library

Below is an edited version of a "pipeline" diagram showing stages of
processing involved in ending up at a library file, starting with
`grammar.js`.

```
              {grammar.js}  ->    [Node.js]   ->

            {grammar.json}  ->  [tree-sitter] ->

{parser.c, scanner.(c|cc)}  ->   [cc or c++]  ->

            {library file}

-------------------
| {} are files    |
| [] are programs |
-------------------
```

(The original diagram was apparently by Gregory Heytings and was seen
[here](https://lists.gnu.org/archive/html/emacs-devel/2022-12/msg01253.html).)

The [actual
processing](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/generate/mod.rs#L55-L90)
is more like:

* Someone puts together `grammar.js` (and possibly `src/scanner.(c|cc)`)
* tree-sitter reads `grammar.js`, and invokes Node.js' `node` [passing
  it some
  bits](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/generate/mod.rs#L192-L195)
  to produce `src/grammar.json`
* tree-sitter uses the received `src/grammar.json` to produce
  `src/parser.c` [1]
* A C / C++ compiler is used to produce a library using `parser.c`
  (and possibly `src/scanner.(c|cc)`)

These steps might be carried out via a `Makefile` or done
automatically by tooling.  Indeed, Neovim's nvim-treesitter plugin
will fetch files from grammar repositories to produce grammar-specific
shared libraries for use in a running editor session. Emacs 29+
currently does something similar [2].

Note that in the flow above, "tree-sitter" can refer to the command
line program or some other program that uses the tree-sitter library
[3]:

* See [these
  lines](https://github.com/nvim-treesitter/nvim-treesitter/blob/2d8e6b666297ddf19cbf7cbc2b0f1928bc49224a/lua/nvim-treesitter/install.lua#L389-L399)
  from nvim-treesitter's source code for an example of the former case
* See [this
  PR](https://github.com/emacs-tree-sitter/elisp-tree-sitter/pull/220)
  at the elisp-tree-sitter repository for an example of the latter
  case

[1] `node-types.json` is also produced.

[2] ATM emacs only [compiles fetched `.c` / `.cc` files to produce a
shared
library](https://github.com/emacs-mirror/emacs/blob/9d410f8de64e91d16999a9bb5dd884d6d06d22bd/lisp/treesit.el#L2734-L2803).
nvim-treesitter tries to do that but under certain circumstances will
get `tree-sitter` to use `grammar.js` to produce `src/grammar.json`
and `src/parser.c` first before making a compilation attempt.

[3] ...as `tree-sitter` (the cli) is also a program that uses the
tree-sitter library.

## Brief Summary of Important Files

* `grammar.js` - main expression of grammar

* `src/scanner.(c|cc)` - expresses an external scanner (not every grammar has one)

* generated files under `src`
  * `parser.c` - influenced by `grammar.js` via `grammar.json`
  * `grammar.json` - produced from `grammar.js`
  * [`node-types.json`](https://tree-sitter.github.io/tree-sitter/using-parsers#static-node-types) - influenced by `grammar.js` via `grammar.json`

## The tree-sitter Command Line Program (or CLI)

`tree-sitter` is a command line program used for development of
tree-sitter grammars.

It is [a Rust
program](https://github.com/tree-sitter/tree-sitter/tree/master/cli)
which uses the tree-sitter [library which is written in
C](https://github.com/tree-sitter/tree-sitter/tree/master/lib).

Some tasks it is used for include:

* Generating source code (`.c` and `.json`) that can be used in
  building artifacts such as shared libraries for use by the
  tree-sitter library
* Parsing source code for the target programming language
* Running tests
* Starting a local instance of a web-based playground
* Building a `.wasm` file for use by the playground

Like `git`, it has a "subcommand" interface, so typical invocations
look like `tree-sitter generate` or `tree-sitter test`.

### Some Subcommands

* `generate`
  * Given `grammar.js`, produce at least `src/parser.c`,
    `src/grammars.json`, and `src/node-types.json`
  * [`--abi`
    option](https://github.com/tree-sitter/tree-sitter/pull/1599) - at
    the time of the PR -- 2022-01 -- 13 was chosen as the default, [in
    2022-09 this changed to
    14](https://github.com/tree-sitter/tree-sitter/commit/e2fe380a08408ff42eada21f8723f653e6da6606)
    [1].
  * [`--build`](https://github.com/tree-sitter/tree-sitter/pull/2013) - also build the shared object
  * [`--libdir`](https://github.com/tree-sitter/tree-sitter/pull/2013) - specify location for the shared object requested for build via `--build`
* `parse`
  * parses source code and outputs a representation of computed tree
  * `--debug` option - produces detailed text trace
  * `--debug-graph` option - produces `log.html` with visualization of
    shift-reduce parsing + tree at end
* `test`
  * runs tests, typically stored in the `corpus` directory
  * may lead to compilation and installtion of grammar's shared object
    in a location which `tree-sitter` knows to look for when it needs
    to use the shared object later...like for parsing code or running
    tests :)
* `playground` (or `web-ui`)
   * starts a local web-based playground, needs appropriate `.wasm` file
* `build-wasm`
   * builds a `.wasm` file for a particular grammar

[1] On the topic of ABIs, maxbrunsfeld had
[this](https://github.com/tree-sitter/tree-sitter/pull/1599) to say:

> As with most ABI version bumps, new builds of the Tree-sitter
> library are compatible with old generated parsers, but the reverse
> is not true. Once we regenerate a parser with the new ABI version
> (14) old versions of the library won't be able to load it.

### Relevant Directories

For the `tree-sitter` cli to be able to parse source code for a
particular language, it needs access to a shared object that handles
that specific language.  Thus, an issue of where `tree-sitter` should
look for such files presents itself.

#### Configuration Information for `tree-sitter`

[In older versions of
`tree-sitter`](https://github.com/tree-sitter/tree-sitter/blob/162ce789bcf43693924d14232856c5ffee6da2c7/cli/src/config.rs#L20-L35),
a configuration file was checked for in the following order:

* `$TREE_SITTER_DIR/config.json`
* `$HOME/.tree-sitter/config.json`

Here `$TREE_SITTER_DIR` represents the value (if any) of a
corresponding environment variable.  If no such environment variable
existed, the user's home directory was tried as a root instead.

Among other information, `config.json` can contain location
information for `tree-sitter` to use for finding and accessing
grammar-specific shared objects as well as source code.

[At some
point](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/config/src/lib.rs#L24-L46)
this was changed.  In the new arrangement, the bits concerning
`TREE_SITTER_DIR` still apply, but the user's home directory is only
checked assuming there is no indication of a
[XDG](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)-based
configuration file.

To be more concrete, under the new arrangement, on a Linux box,
configuration might live under
`$HOME/.config/tree-sitter/config.json`.

This sounds good in theory but in practice it could mean that if
you're working on different grammars that use an unlucky combination
of different `tree-sitter` cli programs, you can easily get confused
about which configuration information applies.  That is, unless you
use the `TREE_SITTER_DIR` method.

Another point worth noting is that what XDG (or even what a user's
home directory -- e.g. on Windows) means on certain operating systems
may be unclear.

#### Shared Object Storage Location for `tree-sitter`

Once `tree-sitter` finds a configuration file, it can use it to try to
determine where grammar-specific shared object files should live.
This location is used both for saving the shared object that's a
result of compiling a grammar [1] as well as for when trying to handle
a subcommand such as `parse`or `query` as language-specific handling
becomes necessary.

In the older setup, this was typically `$TREE_SITTER_DIR/bin` or
`~/.tree-sitter/bin`.

Typical values for more recent setups include:

* `$TREE_SITTER_DIR/lib`
* `~/.cache/tree-sitter/lib`

I don't have values for Windows handy.  May be I'll add some
eventually :)

[1] Currently, tree-sitter's loader's
[`load_language_from_sources`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L347)
can trigger a recompilation.  It's not clear to me yet exactly what
can trigger this, but I believe at least `tree-sitter test` can.  It
may be that other subcommands can trigger it too.  One reason this
might be worth knowing about is that specifically which
grammar-specific shared object is being used by `tree-sitter` to
handle a subcommand might matter to you (e.g. when testing).

AFAIK, only
[`load_language_at_path`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L314)
calls `load_language_from_sources`.  Further, `load_language_at_path`
is only called by
[`language_for_id`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L304).
However, `language_for_id` appears to be called from multiple places:

* [`language_configuration_for_injection_string`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L277)
* [`language_configuration_for_file_name`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L206)
* [`language_configuration_for_scope`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L193)
* [`languages_at_path`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L169)

Following those trails was a bit too much for me manually so I
confirmed that the subcommands below lead to recompilation sometimes
by directly invoking `tree-sitter` after removing an appropriate
shared object:

* `generate` -- in 2023-01 `--build` was added; if it's present, yes
* `highlight`
* `parse`
* `query`
* `tags`
* `test`

N.B. if you want to force a recompilation via the execution of a
`tree-sitter` subcommand, first remove the shared object from where it
lives and then use the `test` subcommand.  The other subcommands may
lead to an unexpected shared object replacing the erased one because
the order in which the scanning of "tree-sitter-*" directories is done
may yield unexpected results.

There is [a bit in the official docs about "automatic
compilation"](https://tree-sitter.github.io/tree-sitter/creating-parsers#automatic-compilation)
:

> Automatic Compilation

> You might notice that the first time you run tree-sitter test after
> regenerating your parser, it takes some extra time. This is because
> Tree-sitter automatically compiles your C code into a
> dynamically-loadable library. It recompiles your parser as-needed
> whenever you update it by re-running tree-sitter generate.

I think what's meant by this is that if one first invokes `tree-sitter
generate`, a subsequent invocation of `tree-sitter test` can lead to a
build (and install) of a grammar-specific shared object.

There doesn't appear to be mention of other subcommands leading to
building in the docs, but [this
explanation](https://github.com/tree-sitter/tree-sitter/issues/2017#issuecomment-1374932752) mentioned:

> Automatic compilation may trigger on every subcommand that requires
> a parser for its function, that happens in the tree-sitter-loader
> crate.

#### Parser Directories

A `config.json` file created via the `init-config` subcommand will
specify that `~/github`, `~/src`, and `~/source` are to be scanned for
grammar repositories particularly when `tree-sitter` is executing any of
the following subcommands:

* [`parse`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/main.rs#L371-L399)
* [`query`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/main.rs#L442-L446)
* [`tags`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/main.rs#L468-L470)
* [`highlight`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/main.rs#L481-L485)
* [`dump-languages`](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/src/main.rs#L560-L562)

In the tree-sitter source code, these are stored under the name
`parser_directories`.  In `config.json`, the string
"parser-directories" is used.

IIUC, every directory that lives under a parser directory that starts
with the name "tree-sitter-" is scanned.

Depending on one's setup, that can lead to not so desirable
situations.  For example, if you happen to be in the habit of checking
out different versions of a particular grammar, you might end up with
directory names like `tree-sitter-c.alice` and `tree-sitter-c.bob`
because you happen to work with alice's and bob's forks.  Prepare to
be confused after a while if you do this kind of thing and your
`tree-sitter` configuration setup scans these directories.

The `dump-languages` subcommand will make it clear which directories
were identified so that might help with diagnosing issues.

This situation can be worked around, but it can be surprising and a
time sink at first if it happens to you and you are not aware of how
these things work.  Can you tell I got stuck?

One work-around is to not name forks in the manner mentioned before --
that's doable, but when it's a convention you've been following for
years, it's not very nice.

Another work-around is to not place those directories where you
usually place your source...but see the previous point.

Yet another work-around is to create a user account for each grammar
repository you work with...possibly cleaner in some sense, but the
increased overhead for setup doesn't seem so nice.  Then there's the
matter of when to get rid of such extra accounts...

So far I've been placing forks in a different location, but I'm not
really happy with it.  Perhaps I'll try the former.

#### Tips

If things seems strange, on Linux you can use `strace` to figure out
which files and directories are being accessed by `tree-sitter`.  On
Windows you can use [Sysinternals' ProcMon / Process
Monitor](https://en.wikipedia.org/wiki/Process_Monitor) -- available
via scoop: `scoop install sysinternals`.

The tree-sitter source code might also come in handy to figure things
out on occasion.  Isn't source access amazing?

### Local Web Browser Playground

If you've looked at the tree-sitter site, you may have seen [the
playground](https://tree-sitter.github.io/tree-sitter/playground).

It's possible to run a local version of this and for it to use the
grammar you are working on.  This can be a nice interactive way of
trying out / testing your grammar.

Getting (and keeping) it working can be a bit tricky though.

#### Emscripten and `.wasm` Files

One of the key things behind the playground is the use of WebAssembly.

In `tree-sitter`'s case, it uses [Emscripten](https://emscripten.org/)
for WebAssembly matters,

According to its web site, Emscripten is:

> a complete compiler toolchain to WebAssembly, using LLVM, with a
> special focus on speed, size, and the Web platform.

One of the programs it provides is `emcc` -- perhaps short for
"Emscripten C Compiler"?  To get the playground working locally, part
of the idea is to feed `emcc` a grammar's C / C++ source and get back
a `.wasm` file.  The `.wasm` file is typically created using
`tree-sitter`'s `build-wasm` subcommand which uses `emcc` behind the
scenes.

Once the `.wasm` file is available, it can be used by a web page in a
web browser (or other things such as for cross-platform editor
plugins).  A suitable web page is arranged for by invoking a
subcommand of `tree-sitter` currently named `playground` -- though it
used to be called `web-ui` (still a valid alias, FWIW).

This doesn't sound too bad in theory but in practice it turns out that
the precise combination of `tree-sitter` version and Emscripten can
matter.  See below for details.

#### Install and Enable Emscripten Environment

The [Download and
Install](https://emscripten.org/docs/getting_started/downloads.html)
section of the Emscripten web site has the relevant details, but
briefly for a *nix-like system using `sh`:

```
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install <version>
./emsdk activate <version>
source ./emsdk_env.sh
```

where `<version>` may matter.  At the time of writing, the version
number that works with the latest master branch of tree-sitter is
allegedly, `3.1.29`, but that may not work with any currently released
`tree-sitter`.  See an upcoming section for hints on how to determine
an appropriate version.

Note: if using `csh` or `fish`, there are specific `emsdk_env.*`
scripts to use instead.

For Windows (if using `cmd.exe`):

```
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
.\emsdk install <version>
.\emsdk activate <version>
.\emsdk_env.bat
```

Note: if using Powershell, there's a `emsdk_env.ps1` script to use
instead.

Please be aware that the last step involving `emsdk_env.*` is
important to perform each time before using the upcoming `tree-sitter
build-wasm` invocation.

#### Create `.wasm` File and Start Playground

Assuming success so far, this part should be straight-forward.

First, set the current working directory to be your grammar's root
directory, e.g. that might be something like:

```
cd ~/src/tree-sitter-<name>
```

To build the `.wasm` file (remember that `emsdk_env.*` needs to be
used first):

```
tree-sitter build-wasm
```

This should produce a file named `tree-sitter-<name>.wasm` where
`<name>` might be something like `c`, `clojure`, `c-sharp`, etc.

With that file available, the playground may be started by:

```
tree-sitter playground
```

That should lead to a web browser starting up -- if all went well, a
web page with a playground should appear in it.

#### Version Woes

At the time of this writing, [this
file](https://github.com/tree-sitter/tree-sitter/blob/master/cli/emscripten-version)
indicates a version that might be appropriate. That has sometimes
depended on precisely what version of the `tree-sitter` cli is in use,
so if something doesn't work right away, you might consider [trying
different versions that have been
recorded](https://github.com/tree-sitter/tree-sitter/commits/master/emscripten-version).

There are a few specifics mentioned
[here](https://github.com/sogaiu/tree-sitter-clojure/issues/17#issue-968695001)
and [here](https://github.com/sogaiu/tree-sitter-clojure/issues/34)
too.

For reference here are some reports of issues that have been reported:

[#571](https://github.com/tree-sitter/tree-sitter/issues/571),
[#873](https://github.com/tree-sitter/tree-sitter/issues/873),
[#1088](https://github.com/tree-sitter/tree-sitter/issues/1088),
[#1098](https://github.com/tree-sitter/tree-sitter/issues/1098),
[#1131](https://github.com/tree-sitter/tree-sitter/issues/1131),
[#1560](https://github.com/tree-sitter/tree-sitter/issues/1560),
[#1593](https://github.com/tree-sitter/tree-sitter/issues/1593),
[#1652](https://github.com/tree-sitter/tree-sitter/issues/1652),
[#1829](https://github.com/tree-sitter/tree-sitter/issues/1829),
[#2005](https://github.com/tree-sitter/tree-sitter/discussions/2005)

### Examining `tree-sitter parse` Output

For this section we'll look at the output of the `parse` subcommand of
`tree-sitter` with various flags.  It's likely that at some point
you'll find yourself wondering why your current grammar isn't behaving
as it should.  The `parse` command's output can sometimes shed some
light on the matter.

For the following sections, we'll be using the following Clojure code
as input to the `parse` subcommand.  I typically put the code in a
file and specify it as an argument.

```clojure
(def a 1)

(def b 2)

(def c 3)
```

#### `tree-sitter parse`

The "vanilla" version of the subcommand produces an s-expression tree
representation:

```
(source [0, 0] - [5, 0]
  (list_lit [0, 0] - [0, 9]
    value: (sym_lit [0, 1] - [0, 4]
      name: (sym_name [0, 1] - [0, 4]))
    value: (sym_lit [0, 5] - [0, 6]
      name: (sym_name [0, 5] - [0, 6]))
    value: (num_lit [0, 7] - [0, 8]))
  (list_lit [2, 0] - [2, 9]
    value: (sym_lit [2, 1] - [2, 4]
      name: (sym_name [2, 1] - [2, 4]))
    value: (sym_lit [2, 5] - [2, 6]
      name: (sym_name [2, 5] - [2, 6]))
    value: (num_lit [2, 7] - [2, 8]))
  (list_lit [4, 0] - [4, 9]
    value: (sym_lit [4, 1] - [4, 4]
      name: (sym_name [4, 1] - [4, 4]))
    value: (sym_lit [4, 5] - [4, 6]
      name: (sym_name [4, 5] - [4, 6]))
    value: (num_lit [4, 7] - [4, 8])))
```

Some things to note:

* There are nodes for:
  * [`source`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L219)
  * [`list_lit`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L353)
  * [`sym_lit`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L316)
  * [`sym_name`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L326-L328) -
    actually an alias
  * [`num_lit`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L269)

* There are fields for:
  * [`value`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L359)
  * [`name`](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/grammar.js#L326)

* The square-bracketed pairs of numbers refer to locations in the source.
  * The first number is a row or line number -- 0-based [1]
  * The second number is a sort of a column-ish index number -- 0-based

Let's look at a specific example:

```
(num_lit [0, 7] - [0, 8])
```

This tells us that:

* A `num_lit` node was found

* The starting location is indicated by `[0, 7]` and means:
  * line / row 0 (the first line)
  * 7 refers to "before" a byte (character?) at position 7 (since the
    index is 0-based, this would be right before the eighth character
    / byte)

* The ending location is indicated by `[0, 8]` and means:
  * line / row 0 (the same line as the starting position)
  * 8 refers to "before" a character / byte at position 8

This "before" business is a way of articulating that we think of these
numbers as referring to the "gap" between two successive bytes /
characters.  Below is an attempt at visualizing the first line of the
sample code where the string has been spaced out a bit to provide gaps for
illustrative purposes:

```
     nth byte:  1 2 3 4 5 6 7 8 9
----------------------------------
byte position:  0 1 2 3 4 5 6 7 8
----------------------------------
       string:  ( d e f   a   1 )
      indeces: 0 1 2 3 4 5 6 7 8 9
```

For our `num_lit` -- "1" -- is at byte position 7, and the index that
refers to where it starts is 7, though it refers to the gap between
byte positions 6 and 7.  The index that refers to where "1" ends is 8,
which is between byte positions 7 and 8.

The notation is similar to what is typically used [in corpus
tests](https://github.com/sogaiu/tree-sitter-clojure/blob/50468d3dc38884caa682800343d9a1d0fda46c9b/corpus/sym_lit.txt#L33-L35)
as expected values, e.g.:

```
(source
  (sym_lit
    (sym_name)))
```

However, the corpus test expected value notation doesn't contain
location or field information.

[1] On the topic of 0-based numbers for rows, at one point there was
[a PR to change UI ouput for rows to be
1-based](https://github.com/tree-sitter/tree-sitter/pull/304), but I'm
not clear on whether this is still the case.

#### `tree-sitter parse --debug`

If the `--debug` option is specified, before the s-expression tree is
printed, one will get a detailed shift-reduce + lexer activity log.

Let's go over a bit of the log.

At the beginning of the parsing we see typically see this:

```
new_parse
```

That corresponds to [this
line](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/lib/src/parser.c#L1904)
in `ts_parser_parse`.

Then we'll typically see the following sorts of lines repeatedly.

For something with just lexing and shifting:

```
process version:0, version_count:1, state:1, row:0, col:0
lex_internal state:0, row:0, column:0
consume character:'('
lexed_lookahead sym:(, size:1
shift state:7
```

For something with lexing, shifting, and reducing:

```
process version:0, version_count:1, state:97, row:0, col:4
lex_internal state:0, row:0, column:4
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
shift state:2
```

We might go into some of these details later [1], but first let's
finish up by examining the tail end:

```
accept
done
```

`accept` corresponds to [this
line](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/lib/src/parser.c#L1519)
from `ts_parser__advance`.

`done` corresponds to [this line](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/lib/src/parser.c#L1961) from `ts_parser_parse`.

Full log can be seen below.

<details><pre>
new_parse
process version:0, version_count:1, state:1, row:0, col:0
lex_internal state:0, row:0, column:0
consume character:'('
lexed_lookahead sym:(, size:1
shift state:7
process version:0, version_count:1, state:7, row:0, col:1
lex_internal state:0, row:0, column:1
consume character:'d'
consume character:'e'
consume character:'f'
lexed_lookahead sym:sym_lit_token1, size:3
shift state:97
process version:0, version_count:1, state:97, row:0, col:4
lex_internal state:0, row:0, column:4
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
shift state:2
process version:0, version_count:1, state:2, row:0, col:5
lex_internal state:0, row:0, column:5
consume character:'a'
lexed_lookahead sym:sym_lit_token1, size:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:97
process version:0, version_count:1, state:97, row:0, col:6
lex_internal state:0, row:0, column:6
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:2
process version:0, version_count:1, state:2, row:0, col:7
lex_internal state:0, row:0, column:7
consume character:'1'
lexed_lookahead sym:num_lit, size:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:169
process version:0, version_count:1, state:169, row:0, col:8
lex_internal state:0, row:0, column:8
consume character:')'
lexed_lookahead sym:), size:1
reduce sym:_bare_list_lit_repeat1, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:96
process version:0, version_count:1, state:96, row:0, col:9
lex_internal state:0, row:0, column:9
consume character:10
consume character:10
lexed_lookahead sym:_ws, size:2
reduce sym:_bare_list_lit, child_count:3
reduce sym:list_lit, child_count:1
shift state:5
process version:0, version_count:1, state:5, row:2, col:0
lex_internal state:0, row:2, column:0
consume character:'('
lexed_lookahead sym:(, size:1
reduce sym:source_repeat1, child_count:2
shift state:7
process version:0, version_count:1, state:7, row:2, col:1
lex_internal state:0, row:2, column:1
consume character:'d'
consume character:'e'
consume character:'f'
lexed_lookahead sym:sym_lit_token1, size:3
shift state:97
process version:0, version_count:1, state:97, row:2, col:4
lex_internal state:0, row:2, column:4
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
shift state:2
process version:0, version_count:1, state:2, row:2, col:5
lex_internal state:0, row:2, column:5
consume character:'b'
lexed_lookahead sym:sym_lit_token1, size:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:97
process version:0, version_count:1, state:97, row:2, col:6
lex_internal state:0, row:2, column:6
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:2
process version:0, version_count:1, state:2, row:2, col:7
lex_internal state:0, row:2, column:7
consume character:'2'
lexed_lookahead sym:num_lit, size:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:169
process version:0, version_count:1, state:169, row:2, col:8
lex_internal state:0, row:2, column:8
consume character:')'
lexed_lookahead sym:), size:1
reduce sym:_bare_list_lit_repeat1, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:96
process version:0, version_count:1, state:96, row:2, col:9
lex_internal state:0, row:2, column:9
consume character:10
consume character:10
lexed_lookahead sym:_ws, size:2
reduce sym:_bare_list_lit, child_count:3
reduce sym:list_lit, child_count:1
reduce sym:source_repeat1, child_count:2
shift state:5
process version:0, version_count:1, state:5, row:4, col:0
lex_internal state:0, row:4, column:0
consume character:'('
lexed_lookahead sym:(, size:1
reduce sym:source_repeat1, child_count:2
shift state:7
process version:0, version_count:1, state:7, row:4, col:1
lex_internal state:0, row:4, column:1
consume character:'d'
consume character:'e'
consume character:'f'
lexed_lookahead sym:sym_lit_token1, size:3
shift state:97
process version:0, version_count:1, state:97, row:4, col:4
lex_internal state:0, row:4, column:4
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
shift state:2
process version:0, version_count:1, state:2, row:4, col:5
lex_internal state:0, row:4, column:5
consume character:'c'
lexed_lookahead sym:sym_lit_token1, size:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:97
process version:0, version_count:1, state:97, row:4, col:6
lex_internal state:0, row:4, column:6
consume character:' '
lexed_lookahead sym:_ws, size:1
reduce sym:sym_lit, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:2
process version:0, version_count:1, state:2, row:4, col:7
lex_internal state:0, row:4, column:7
consume character:'3'
lexed_lookahead sym:num_lit, size:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:169
process version:0, version_count:1, state:169, row:4, col:8
lex_internal state:0, row:4, column:8
consume character:')'
lexed_lookahead sym:), size:1
reduce sym:_bare_list_lit_repeat1, child_count:1
reduce sym:_bare_list_lit_repeat1, child_count:2
shift state:96
process version:0, version_count:1, state:96, row:4, col:9
lex_internal state:0, row:4, column:9
consume character:10
lexed_lookahead sym:_ws, size:1
reduce sym:_bare_list_lit, child_count:3
reduce sym:list_lit, child_count:1
reduce sym:source_repeat1, child_count:2
shift state:5
process version:0, version_count:1, state:5, row:5, col:0
lex_internal state:0, row:5, column:0
lexed_lookahead sym:end, size:0
reduce sym:source_repeat1, child_count:2
reduce sym:source, child_count:1
accept
done
</pre></details>

[1] At some point I may get around to describing the details here, but
in the mean time, some of the info in
[#1309](https://github.com/tree-sitter/tree-sitter/issues/1309) might
help for investigation.

#### `tree-sitter parse --debug-graph`

As with the other output types described before, the s-expression tree
is printed out, but in addition, a file named `log.html` will be
produced.

This `log.html` file contains concatenated bits of SVG.  Conceptually,
the file contains 2 portions.

An initial portion corresponds to the lexer + shift + reduce activity
log like for `--debug` output though there is more visualization of
nodes and "states".

![debug-graph-output](log.html.png?raw=true "debug-graph output")

Note that the image's colors have been inverted to protect my eyes :P

The other portion is a visualization of the final tree

![debug-graph-tree-output](log.html.tree.png?raw=true "debug-graph tree output")

A neat feature of this tree is that hovering over different areas can
sometimes reveal relevant information.

[Here](log.html) is a sample `log.html` file.  You may need to
download it to a local file first to be able to view it properly.
Note that the background is all white.

#### Other Flags and Options

I have not used the following, but may be they could be handy in some
situations:

* [`--debug-build`](https://github.com/tree-sitter/tree-sitter/pull/1383)

* [`--stat`](https://github.com/tree-sitter/tree-sitter/pull/746)

* [`--xml`](https://github.com/tree-sitter/tree-sitter/pull/863)

To find out what other flags and options exist, invoke `tree-sitter
parse --help`.

### Building `tree-sitter`, the CLI

It's sometimes helpful to use different versions of `tree-sitter` or
to customize it for various purposes (e.g. investigating issues,
debugging, etc.) so it's handy to be able to build from source.

There are [official
instructions](https://tree-sitter.github.io/tree-sitter/contributing#developing-tree-sitter)
[1] that are worth taking a look at.

XXX: Note that the `dot` command may be necessary for working with
`--debug-graph`.

Below are descriptions of the sorts of things I do.  Welcome to the
platform fork-in-the-road.

#### Linux and Other *nix-likes

I'm only familiar with getting `rustc`, `cargo`, and friends using
[`rustup`](https://rustup.rs/).  Perhaps a version via a package
manager on one's system would suffice as well.

Assuming appropriate Rust development bits are in place:

* `git clone https://github.com/tree-sitter/tree-sitter` to get a
  local copy of the tree-sitter repository
* `cd tree-sitter && cargo build --release` to build appropriately
* `ln -s ~/src/tree-sitter/target/release/tree-sitter
  ~/bin/tree-sitter` to make an appropriate symlink so that
  `tree-sitter` is available via `PATH`

Unless you need to work with Windows, I suggest skipping the next
section.

XXX: if intending to use `build-wasm` or `playground`, it's important
to run `script/build-wasm` before building the `tree-sitter` cli.
`script/build-wasm` creates `tree-sitter.js` and `tree-sitter.wasm`
which are served by `tree-sitter playground`.  the tree-sitter
repository does not appear to have these two files checked in at the
time of this writing.

note that the docs [claim that not doing this will result in requiring
an internet connection to use the
playground](https://github.com/tree-sitter/tree-sitter/blob/master/docs/section-6-contributing.md#building)
-- that may not work in practice if the fetched `.wasm` and/or `.js`
files are not compatible with the `.wasm` file for the grammar, so for
reliability purposes, it may be better to build with
`script/build-wasm` as mentioned above.

XXX: from time to time it may be good to check [these ci
lines](https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/.github/workflows/ci.yml#L66-L75)
for what's necessary to build the cli.

XXX: windows instructions probably need to be updated with this info
too

#### Windows

(I don't use WSL* for reasons (TM), but if that works for your
situation, you may be able to just follow the non-Windows instructions
above with your WSL* setup, but note that that might mean staying and
working within a WSL* environment.  I'm not sure though :) )

For historical reasons development bits have been much more work to
prepare on Windows.  Things are significantly better than before but
it's still almost always more of a hassle than on many *nix machines.

To cope with the situation I often reach for
[scoop](https://scoop.sh/).  There are other alternatives such as
Chocolatey but it wasn't to my taste.  There is even the upcoming
[`winget`](https://github.com/microsoft/winget-cli) from Microsoft
itself, but I haven't tried it yet.

I suggest taking a look at the official instructions at the top of
[their main page](https://scoop.sh/), but for the record, what worked
here was pretty much what's in their Quickstart text:

> Open a PowerShell terminal (version 5.1 or later) and run:

```
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
> irm get.scoop.sh | iex
```

Note that this is a "do at your own risk" sort of thing.

Once scoop is installed, to install `rustup`, open a new Powershell
terminal and:

```
> scoop install rustup
```

to set up Rust bits.

Then I installed [msys2 / mingw64](https://www.msys2.org/), which
is:

> a collection of tools and libraries providing you with an
> easy-to-use environment for building, installing and running native
> Windows software

msys2 / mingw-w64 can also be installed via scoop, but the
resulting installation path is rather deep for my taste so I opted for
[following the steps here](https://www.msys2.org/#installation).

If you'd prefer to go the scoop route, in a Powershell terminal, try:

```
> scoop install msys2
```

(Have you pinned Powershell to your taskbar yet?)

You'll probably want to learn where the msys2 bits ended up on your
system.  It's likely under `C:\Users\<username>\AppData\` somewhere.
The `AppData` directory might not be visible at first but that can be
remedied via Windows Explorer's settings.

But back to the non-scoop method...

0. View [the installation steps](https://www.msys2.org/#installation)

1. Download the installer.  Mine was called
   `msys2-x86_64-20221216.exe`, but don't be surprised if yours has a
   different name.  Specifically, the filename has a date embedded in
   it, so that might be different.

2. Verify the checksum.  Since the file you get will most likely be
   different, the file content may also differ and thus the checksum
   may be different too.  For reference, what I saw was:

   `de5b410dd0813e5904aeed082bfc3d9a8167e0f93b296f52d80bee2dfec9f13d`

   I used the certutil program via a Powershell terminal:

    ```
    > certutil -hashfile msys2-x86_64-20221216.exe SHA256
    ```

   That produced a long string matching the long one on the site so I
   didn't do the GPG Signature method (which is security-wise the much
   more recommended method).  I did however search for the checksum to
   see if anyone else had mentioned it.  There were some hits so I
   took a look and decided to risk not doing the public key stuff.

3. Run the installer and choose `C:\msys64` as the "Installation
   Folder".

4. Follow the rest of the steps except uncheck the "Run MSYS2 now"
   checkbox.  I prefer not to let the installers do more than they
   need to.

The advantage of this approach is that the length of the string I end
up having to use repeatedly -- `C:\msys64\mingw64\bin` -- is much
shorter than for the one you'd get with the scoop one.

I don't tend to add environment variable settings to my system
settings because AFAIU that affects too many things and makes it more
difficult to accurately document what I've done.

Note that to make use of msys2 / mingw64 in our build, right before we
enter the build command, we'll want to change `PATH` so the
appropriate bits are available for use.  For me, that ends up looking
like:

```
C:\> set PATH=C:\msys64\mingw64\bin;%PATH%
```

Note that that's via a `cmd.exe` command prompt.

For Powershell it can be something like:

```
> $env:Path = "C:\msys64\mingw64\bin;$env:Path"
```

Note that "Path" is used above though "PATH" works too.  "Path" is
something you can end up with via Tab-completion :)

If you don't already have `git` in your environment...

`scoop install git`

is one way to arrange for it :)

Finally, we can work on building!  Via a `cmd.exe` command prompt:

* `git clone https://github.com/tree-sitter/tree-sitter` to get a
  local copy of the tree-sitter repository
* `cd tree-sitter`
* `set PATH=C:\msys64\mingw64\bin;%PATH%` to make the msys2 / mingw64
  stuff available
* `cargo build --release` to build appropriately

[Here's a log of the Windows
build](https://gist.github.com/sogaiu/10534158414b7109581e7670f4736b38)
for reference.

For comparison, via Powershell that might be:

* `git clone https://github.com/tree-sitter/tree-sitter` to get a
  local copy of the tree-sitter repository
* `cd tree-sitter`
* `$env:Path = "C:\msys64\mingw64\bin;$env:Path"` to make the msys2 / mingw64
  stuff available
* `cargo build --release` to build appropriately

(On the off-chance you're wondering if scoop has `tree-sitter`...it
does, but that gets you a precompiled version.)

#### ...and we're back from the fork!

It might be obivous, but to build a specific version, use `git
checkout` first to arrange for the local working tree to correspond to
a particular commit / tag / whatever.  Then do the build.

[1] If you take a look you'll notice that NPM is listed as required.
Though most grammar repositories show evidence of using NPM, it's not
strictly necessary.  ATM, Node.js is necessary, but
[experiments](https://github.com/tree-sitter/tree-sitter/issues/465#issuecomment-1371911897)
suggest it wouldn't have to be.

### Subcommand Use Frequency

I will probably continue to use:

* `generate` - essential to create `src/parser.c` and friends
* `parse` - debugging and testing
* `test` - sanity checking grammar tweaks and changes

I suspect I may using occasionally:

* `dump-languages` - to diagnose "scanning issues"
* `query` - to diganose occasional issues

Initially I also used, but currently never use:

* `build-wasm` - for playground but used to write VSCode extensions using `.wasm`
* `playground` - was useful for early grammar development

I nearly never use the following subcommands:

* `init-config` - not much until it becomes `TREE_SITTER_DIR`-aware
* `highlight` - used it out of curiosity once or twice
* `tags` - not likely to be applicable to tree-sitter-clojure ATM

## Testing

The `test` subcommand of `tree-sitter` provides some functionality to
aid in some basic sanity testing.

The [official
docs](https://tree-sitter.github.io/tree-sitter/creating-parsers#command-test)
say:

> The tree-sitter test command allows you to easily test that your
> parser is working correctly.

but this seems on the optimistic side.  It's certainly helpful to
have, but:

* Tests still need to be conceived of and written properly
* Unimagined scenarios don't get tested with this method

With that in mind, it still seems worth using not only for quick
sanity tests but also to specifically express cases that are intended
to be handled.

Quite a few repositories [1] also make use of the `parse` subcommand
across collections of code.  Though this won't catch every kind of
issue, this provides another type of checking that I have found
helpful in practice.

I've also used
[Hypothesis](https://github.com/HypothesisWorks/hypothesis) in
combination with the [Python bindings for the tree-sitter
library](https://github.com/tree-sitter/py-tree-sitter) to do some
generative / property-based testing.  I found the maintenance of the
testing code to be cumbersome though and wouldn't recommend the
approach while a fair bit of change is happening in a grammar.  YMMV.

FWIW, it did turn up one issue that all other methods failed to find.

[1] It's not uncommon for the `parse` subcommand to be used against a
collection of real-world code, though the size of the collection seems
to vary a fair bit.  Below are some examples.  By looking at some of
the top-level files (often `package.json`) one can get an idea of what
kind of testing is performed.

* [tree-sitter-agda](https://github.com/tree-sitter/tree-sitter-agda)
* [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash)
* [tree-sitter-c](https://github.com/tree-sitter/tree-sitter-c)
* [tree-sitter-cpp](https://github.com/tree-sitter/tree-sitter-cpp)
* [tree-sitter-css](https://github.com/tree-sitter/tree-sitter-css)
* [tree-sitter-elm](https://github.com/elm-tooling/tree-sitter-elm)
* [tree-sitter-go](https://github.com/tree-sitter/tree-sitter-go)
* [tree-sitter-haskell](https://github.com/tree-sitter/tree-sitter-haskell)
* [tree-sitter-html](https://github.com/tree-sitter/tree-sitter-html)
* [tree-sitter-java](https://github.com/tree-sitter/tree-sitter-java)
* [tree-sitter-javascript](https://github.com/tree-sitter/tree-sitter-javascript)
* [tree-sitter-julia](https://github.com/tree-sitter/tree-sitter-julia)
* [tree-sitter-org](https://github.com/milisims/tree-sitter-org)
* [tree-sitter-perl](https://github.com/ganezdragon/tree-sitter-perl)
* [tree-sitter-php](https://github.com/tree-sitter/tree-sitter-php)
* [tree-sitter-python](https://github.com/tree-sitter/tree-sitter-python)
* [tree-sitter-ruby](https://github.com/tree-sitter/tree-sitter-ruby)
* [tree-sitter-scala](https://github.com/tree-sitter/tree-sitter-scala)
* [tree-sitter-sql](https://github.com/m-novikov/tree-sitter-sql)
* [tree-sitter-typescript](https://github.com/tree-sitter/tree-sitter-typescript)

### `test` subcommand

The `test` subcommand invokes "corpus tests".

From the [official
docs](https://tree-sitter.github.io/tree-sitter/creating-parsers#command-test):

> For each rule that you add to the grammar, you should first create a
> test that describes how the syntax trees should look when parsing
> that rule. These tests are written using specially-formatted text
> files in the corpus/ or test/corpus/ directories within your
> parser’s root folder.

Here is an example from tree-sitter-clojure:

```
================================================================================
BigInt Integer
================================================================================

11N

--------------------------------------------------------------------------------

(source
  (num_lit))
```

One might decompose that as:

* Header - text naming test bounded above and below by `=` [1]
* Test Input - source code fragment to be parsed for testing
* Separator - multiple (at least how many?) instances of `-`
* Expected Value - s-expression representing expected value

(Though this leaves the unanswered question of what the empty lines
between the header and the separator count as...)

So the header is:

```
================================================================================
BigInt Integer
================================================================================
```

The test input is:

```
11N
```

The separator is:

```
--------------------------------------------------------------------------------
```

The expected value is:
```
(source
  (num_lit))
```

[1] There is a type of tweaking that is possible for the header:
[#982](https://github.com/tree-sitter/tree-sitter/issues/982),
[#1348](https://github.com/tree-sitter/tree-sitter/pull/1348)

#### Miscellanous Bits

* Comments may also be present using a lisp-ish `;` construct:
  [#752](https://github.com/tree-sitter/tree-sitter/issues/752),
  [Answer in
  discussions](https://github.com/tree-sitter/tree-sitter/discussions/1586#discussioncomment-1965131)

    I have not used this.

* Test expectation values can be updated programmatically via
  `--update`:
  [#442](https://github.com/tree-sitter/tree-sitter/pull/442)

    Note that there is at least [one report of problematic
    behavior](https://github.com/tree-sitter/tree-sitter/issues/835).

    I've used the feature on occasion without issues.  There do seem
    to be uses for this but without some care it seems possible that
    an incorrect expected value will sneak in to tests.

* Tests can be constrained to specific ones by matching against the
  test name via `--filter`:
  [#991](https://github.com/tree-sitter/tree-sitter/issues/991)

* Doesn't seem possible to express that a test should result in an
  error in a generic way:
  [#992](https://github.com/tree-sitter/tree-sitter/issues/992)

## Performance Measurement

One of the major use cases for tree-sitter is in the context of text
editors.  That often means there is a human attention span involved.
Thus there are certain durations that are practically unacceptable for
parsing.

The `parse` subcommand has a `--time` flag that can be used to get
some duration information.

Multiple measurements can be obtained using things like
[`multitime`](https://github.com/ltratt/multitime) to somewhat
mitigate single invocation issues.

I also measure how long it takes to complete parsing across a large
collection of source files to see if there are noticeable changes.

## tree-sitter Project Info

* tree-sitter maintainers appear to be quite busy and it may be that
  they are all volunteers.

* The [official tree-sitter
  docs](https://tree-sitter.github.io/tree-sitter/) have come a long
  way since their early days thanks to contributions from various
  folks.

* tree-sitter itself has been in [a pre-1.0
  state](https://github.com/tree-sitter/tree-sitter/issues/930) for
  some time.

## Some tree-sitter Version Highlights

* Unreleased
  * [loader: add TREE_SITTER_LIBDIR; cli: add --libdir to `tree-sitter generate`](https://github.com/tree-sitter/tree-sitter/commit/108d0ecede9312e88ac12475ffac62af9fba5dbf)
  * [cli: add -b, --build flags for tree-sitter generate](https://github.com/tree-sitter/tree-sitter/commit/5088781ef965c5cd7187c5308e3cb45f8f892860)
  * [Bump Emscripten version to 3.1.29](https://github.com/tree-sitter/tree-sitter/commit/88fe1d00c42760beda7cc01f5259da3d7fc5265e)
  * [Upgrade to emscripten 3.1.25](https://github.com/tree-sitter/tree-sitter/commit/1f36bf091e1faaec5d9282f47c9dab00f7435e06)
https://github.com/tree-sitter/tree-sitter/pull/1913
  * [Merge pull request #1913 from J3RN/browser-fixes](https://github.com/tree-sitter/tree-sitter/commit/b31f9e6e90933a4d87b81cc9f09f0399ec1711a4)

* [0.20.7](https://github.com/tree-sitter/tree-sitter/commit/b268e412ad4848380166af153300464e5a1cf83f) - 2022-09-03
  * [Generate parsers with ABI version 14 by default](https://github.com/tree-sitter/tree-sitter/commit/e2fe380a08408ff42eada21f8723f653e6da6606)

* [0.20.3](https://github.com/tree-sitter/tree-sitter/commit/3ff5c19403ccb8e6139a048b3257302a8da6139e) - 2022-01-22
  * [Add --abi flag to the generate command, generate version 13 by default](https://github.com/tree-sitter/tree-sitter/pull/1599/commits/516fd6f6def1615cb5dc004ab41c348c7de6d182)

* [0.20.2](https://github.com/tree-sitter/tree-sitter/commit/4ee52ee99e63f32e7307705e4cbb85c28aacb412) - 2022-01-02

* [0.20.1](https://github.com/tree-sitter/tree-sitter/commit/062421dece3315bd6f228ad6d468cba083d0a2d5) - 2021-11-22
  * [Put emscripten-version file in cli directory](https://github.com/tree-sitter/tree-sitter/commit/4d64c2b939d4bb1074b5ae5631cf2616368f78d8)

* [0.20.0](https://github.com/tree-sitter/tree-sitter/commit/e85a279cf29da1b08648e27214dda20a841e57c8) - 2021-06-30
  * [Bump emscripten version to 2.0.24](https://github.com/tree-sitter/tree-sitter/commit/a286f831c749d1cb00d577cceb19d28c9d0f3338)
  * [Refactor emscripten/emsdk version to a single file](https://github.com/tree-sitter/tree-sitter/commit/b14ea51e3df4f5614d8913513a4d1eed8be07d71)
  * [Pin emscripten/emsdk Docker version ](https://github.com/tree-sitter/tree-sitter/commit/725f3f7f2b7da6f71fb4254445bc300ba7681025)
  * [cli: Extract CLI configuration into separate crate](https://github.com/tree-sitter/tree-sitter/pull/1157)
  * [rust: Extract runtime language detection into separate crate](https://github.com/tree-sitter/tree-sitter/commit/66c30648c2c6f1bfe76c0763dc712f29d4b2a1a0)

* [0.19.5](https://github.com/tree-sitter/tree-sitter/commit/8d8690538ef0029885c7ef1f163b0e32f256a5aa) - 2021-05-21
  * [Fix build-wasm on Windows](https://github.com/tree-sitter/tree-sitter/commit/919eab023f4bd7ea78eca06adea3b8de5b388d8e)

* [0.19.4](https://github.com/tree-sitter/tree-sitter/commit/56c7c6b39d908c2df059e2c7f75860f819010671) - 2021-03-20
  * [Add --no-bindings flag to generate subcommand](https://github.com/tree-sitter/tree-sitter/commit/8e894ff3f1898fcaa09ae125bbd5fde8467aea42)

* [0.19.3](https://github.com/tree-sitter/tree-sitter/commit/24785cdb39ad2740ca33c111490984333787f5d3) - 2021-03-10

## Misc Things To Be Incorporated Somewhere :)

* `TREE_SITTER_LIBDIR` now exists for customizing the path to the
  generated shared objects:
  [#2013](https://github.com/tree-sitter/tree-sitter/pull/2013)

* Acoording to [this
  comment](https://github.com/tree-sitter/tree-sitter/issues/1870#issuecomment-1248659929),
  it's by design that the grammar writer gets little to no control
  over error recovery.

* The `--report-states-for-rule` flag for `generate` might be worth
  investigating: [Answer in
  #994](https://github.com/tree-sitter/tree-sitter/discussions/994)

XXX: reasons to get away from doing node bindings

https://github.com/tree-sitter/tree-sitter/issues/175

XXX: not into documenting minimum versions of things?

https://github.com/tree-sitter/tree-sitter/issues/423

XXX: not all grammars keep generated source under src

https://github.com/tree-sitter/tree-sitter-typescript

XXX: not all grammars keep the generated parser.c + other things in the repository

https://github.com/CyberShadow/tree-sitter-d

XXX: `tree-sitter init-config` doesn't appear to honor
     `TREE_SITTER_DIR`.  I tried making a patch for it:

https://gist.github.com/sogaiu/022c6eaadd9698878aa97c9880e41ca5

XXX: compiling on windows with gcc msys2 / mingw64 needs a tweak to tree-sitter cli

https://github.com/tree-sitter/tree-sitter/pull/1835

XXX: info on some debugging-related TREE_SITTER_* env vars

https://github.com/tree-sitter/tree-sitter/issues/2021

XXX: there is some hard-wired code that expects to find
     `package.json`.  for certain subcommands (e.g. `parse`, `query`,
     `highlight`, etc.) to function `package.json` appears to be
     required.

   however, the only necessary content in `package.json` is:

```
    {
      "tree-sitter": [
        {
          "scope": "source.clojure",
          "file-types": [
            "bb",
            "clj",
            "cljc",
            "cljs"
          ]
        }
      ]
    }
```

https://github.com/tree-sitter/tree-sitter/blob/0d3fd603e1b113d3ff6f1a57cadae25d403a3af2/cli/loader/src/lib.rs#L536-L591

XXX: cursorless' vscode-parse-tree uses yarn to fetch and "install"
     tree-sitter-clojure.  `package.json` appears necessary for this
     to work.  Further, at least the "name" and "version" fields
     appear necessary.  for the moment, I've added those back.
