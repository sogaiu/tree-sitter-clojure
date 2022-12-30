## Development on Windows

This page touches on the following development-related items:

* Prerequisites
* Setup Steps
* Grammar Development
* Performance Measurement
* Building a .wasm File
* Formatting
* Troubleshooting

### Background

Primary development for tree-sitter-clojure occurs in some kind of
Linux environment.  Periodically, attempts are made to get things to
work on Windows.

To make installation and upgrading of various pieces more manageable,
[scoop](https://scoop.sh) is used.  After scoop is installed,
installation is usually a matter of an invocation like: `scoop install
git` from a PowerShell prompt.

scoop is used to install:

* git
* [nvm-windows](https://github.com/coreybutler/nvm-windows)
* python

nvm-windows is used to install and manage different versions of
Node.js.

git is used to fetch:

* emsdk (may be optional depending on situation, see below)
* tree-sitter-clojure

### Prerequisites

The official docs have a [Dependencies section in the "Creating
Parsers"
section](https://tree-sitter.github.io/tree-sitter/creating-parsers#dependencies).
However, that information is not sufficiently detailed for the use of
this repository.

* At a minimum:

    * Node.js >= 12, <= 14 - recently tested 12.9.1, 12.16.1, 12.22.12.
      * Use an nvm-windows-based setup (e.g. via scoop)

    * Python (used by node-gyp (which Node.js has a bundled version of))
      * May need to install separately (e.g. via scoop)

    * C/C++ compiler
      * Windows - an appropriate Visual Studio based setup with the
        "Desktop Development with C++" workload (via Microsoft)

* If interactive exploration via a web browser and/or building a
  `.wasm` file is desired [Emscripten / emsdk](https://emscripten.org)
  should be installed.

    At the time of this writing, [this
    file](https://github.com/tree-sitter/tree-sitter/blob/master/cli/emscripten-version)
    indicates a version that might be appropriate.  That may depend on
    precisely what the version of the tree-sitter command line tool is
    though, so if something doesn't work right away, you might
    consider trying [different versions that have been
    recorded](https://github.com/tree-sitter/tree-sitter/commits/master/emscripten-version).

    Due to the version-related complications, it might be better to
    learn how to [work with different versions of
    emsdk](https://emscripten.org/docs/getting_started/downloads.html).

### Setup Steps

The command prompt the commands below are invoked from may make a
difference.  Look for something named like [x64 Native Tools Command
Prompt for
VS...](https://stackoverflow.com/questions/61209155/how-do-i-get-the-x64-native-tools-developer-command-prompt-for-visual-studio-com).

```
# clone repository
git clone https://github.com/sogaiu/tree-sitter-clojure
cd tree-sitter-clojure

# ensure tree-sitter-cli is avaliable as a dev dependency
npm install --save-dev --save-exact tree-sitter-cli

# create `src` and populate with tree-sitter `.c` goodness
npx tree-sitter generate

# populate `node_modules` with dependencies and don't run install bits
npm install --ignore-scripts

# short for node-gyp clean, configure, build
npx node-gyp rebuild

# verify library was built and is operational
npx tree-sitter test
```

### A Note on Further Instructions...

Commands below are assumed to be invoked from within the
tree-sitter-clojure directory and emsdk is assumed to be installed in
a sibling directory of tree-sitter-clojure.

### Grammar Development

Hack on grammar.

```
# edit grammar.js using some editor

# regenerate and rebuild tree-sitter stuff
npx tree-sitter generate
npx node-gyp rebuild
```

Parse individual files.

```
# create and populate sample code file for parsing named `sample.clj`

# parse sample file
npx tree-sitter parse sample.clj

# if output has errors, figure out what's wrong
```

Interactively test in the browser (requires emsdk).

```
# prepare emsdk (specifically emcc) for building .wasm
..\emsdk\emsdk_env.bat

# build .wasm bits and invoke web-ui for interactive testing
npx tree-sitter build-wasm
npx tree-sitter web-ui

# in appropriate browser window, paste code in left pane

# examine results in right pane -- can even click on nodes

# if output has errors, figure out what's wrong
```

### Performance Measurement

Speed is not the most important aspect, but paying attention to how
performance varies as one makes adjustments to the grammar seems like
a good idea :)

```
# single measurement
npx tree-sitter parse --time sample.clj
```

### Building a .wasm File

```
# prepare emsdk (specifically emcc) for use
..\emsdk\emsdk_env.bat

# create `tree-sitter-clojure.wasm`
npx tree-sitter build-wasm
```

### Formatting

The formatting used in `grammar.js` may appear peculiar.  A brief
explanation is that it is a compromise between what maintainers found
they could readily comprehend (e.g. `prettier` does not seem to handle
content with numerous nested calls in an appropriate manner) and what
seemed practical for an editor to support.

If editing with Emacs, code can be made to match the style via
information at the bottom of `grammar.js`.

There is also a script to process `grammar.js` appropriately.  This
enables one to use a non-Emacs editor to edit `grammar.js` and then to
later invoke the script to help tidy things up.  Emacs is invoked by
this script, so it's necessary to have Emacs installed for this
purpose.  See the `format` directory.

### Troubleshooting

* It may be necessary to invoke `nvm on` to activate nvm-windows before
  using npm or npx.

* Consider executing the `--verbose` versions of various commands if
  errors occur to gain hints about what factors might be relevant.

* For switching between different versions of emsdk, learn to use the
  `install` and `activate` subcommands.

