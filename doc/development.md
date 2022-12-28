## Development

This page touches on the following development-related items:

* Prerequisites
* Setup Steps
* Grammar Development
* Performance Measurement
* Building a .wasm File
* Testing
* Formatting
* Known Issues

### Prerequisites

The official docs have a [Dependencies section in the "Creating
Parsers"
section](https://tree-sitter.github.io/tree-sitter/creating-parsers#dependencies).
However, that information is not sufficiently detailed for the use of
this repository.

* At a minimum:

    * Node.js >= 12, <= 14 - recently tested 12.9.1, 12.16.1, 12.22.12
        * *nix and macos - an nvm-based setup may be good
        * Windows - might have luck with a nvm-windows-based setup (e.g. via scoop)

    * Python (used by node-gyp (which Node.js has a bundled version of))
        * *nix and macos - likely an appropriate version is already installed
        * Windows - may need to install separately (e.g. via scoop)

    * C/C++ compiler
        * *nix - recent versions of gcc or clang may work
        * macos - Xcode command line tools may be enough
        * Windows - an appropriate Visual Studio based setup with the
          "Desktop Development with C++" workload

* If interactive exploration via a web browser and/or building a
  `.wasm` file is desired:

    * Emscripten / emsdk
        * *nix - clone from repository, get from https://emscripten.org, etc.
        * macos - emscripten via homebrew worked at least once, but see below
        * Windows - clone from repository, get from https://emscripten.org, etc.

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

Suppose typical development sources are stored under `~/src`.

#### Short Version

If this brief version doesn't work (e.g. on Windows), try the "Long
Version" below.

```
# clone repository
cd ~/src
git clone https://github.com/sogaiu/tree-sitter-clojure
cd tree-sitter-clojure

# install tree-sitter-cli and dependencies, then build
npm ci
```

#### Long Version

```
# clone repository
cd ~/src
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

Note: on Windows, the command prompt the commands are invoked from may
make a difference.  Look for something named like [x64 Native Tools
Command Prompt for
VS...](https://stackoverflow.com/questions/61209155/how-do-i-get-the-x64-native-tools-developer-command-prompt-for-visual-studio-com).

### A Note on Further Instructions...

Where applicable, the instructions below assume emsdk has been
installed, but `emcc` (tool that can be used to compile to wasm) is
not necessarily on one's `PATH`.  If an appropriate `emcc` is on one's
`PATH` (e.g. emscripten installed via homebrew), the emsdk steps
(e.g. `source ~/src/emsdk/emsdk_env.sh`) below may be ignored.


### Grammar Development

Hack on grammar.

```
# edit grammar.js using some editor

# regenerate and rebuild tree-sitter stuff
npx tree-sitter generate && \
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
source ~/src/emsdk/emsdk_env.sh

# build .wasm bits and invoke web-ui for interactive testing
npx tree-sitter build-wasm && \
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

# mutliple measurements with `multitime`
multitime -n10 -s1 npx tree-sitter parse --time --quiet sample.clj
```

### Building a .wasm File

Assuming emsdk is installed appropriately under `~/src/emsdk`.

```
# prepare emsdk (specifically emcc) for use
source ~/src/emsdk/emsdk_env.sh

# create `tree-sitter-clojure.wasm`
npx tree-sitter build-wasm
```

### Testing

See the [testing page](testing.md).

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

### Known Issues

* `node-gyp` (tool for compiling native addon modules for Node.js)
  related things may fail on a machine upgraded to macos Catalina --
  [this
  document](https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md)
  may help cope with such a situation.

* Generally, setting things up for Windows is more labor- and
  detail-intensive than other platforms.  The following issues might
  be encountered:

    * An appropriate C compiler does not come pre-installed and
      compared to other platforms, the installation steps tend to vary
      over time with Visual Studio versions and names of things
      changing.  Specifically which extra bits might be necessary is
      not always easy to determine.  Recently, one of the needed
      "workloads" was named "Desktop development with C++".  If you
      know what you're doing you can install a minimum of necessary
      pieces (e.g. BuildTools + 1 particular workload), but figuring
      out the details can be time-consuming.

    * A specific command prompt needs to be used (or prepared) before
      performing commands that involve the C compiler.  See note above
      concerning "x64 Native Tools Command Prompt for VS..".

    * The "Short Version" instructions under "Setup Steps" may not
      work (the "Long Version" instructions should though).

    * Python does not come pre-installed (needed for Node.js' node-gyp).

    * The nvm-like option (for managing various Node.js versions) for
      Windows --
      [nvm-windows](https://github.com/coreybutler/nvm-windows) -- is
      not quite the same as [nvm](https://github.com/nvm-sh/nvm) for
      *nix.  For example, nvm-windows requires the use of `nvm on`
      before doing things in a command prompt.

  Except for installing appropriate Visual Studio bits, the other
  pieces seem to be relatively easy to get into place using
  [scoop](https://scoop.sh/).  Other things may work too.
