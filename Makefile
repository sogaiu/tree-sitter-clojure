# "Builds are programs"
#
# -- clojure.core folks
#
# “The principal lesson of Emacs is that a language for extensions
# should not be a mere “extension language”. It should be a real
# programming language, designed for writing and maintaining
# substantial programs. Because people will want to do that!”
#
# -- RMS
#
# Make is not a programming language!
#
# -- More than one programmer
#
# https://youtu.be/lgyOAiRtZGw?t=475

# XXX: process rules of makefiles
#
# https://make.mad-scientist.net/papers/rules-of-makefiles/

# XXX: additional targets?
#
#      * default?
#      * deps (or similar) to report versions of dependencies?
#
# https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html

# XXX: different ways to assign in Makefiles...
#
# https://www.gnu.org/software/make/manual/html_node/Flavors.html
# https://austingroupbugs.net/view.php?id=330

# trying to make this Makefile generic -- though no support for multiple languages
#
# XXX: get this info from outside the file somehow?
TS_LANGUAGE ?= clojure

OLD_PATH := $(PATH)

# path to tree-sitter cli binary
#
# >= 0.19.4 added --no-bindings
# >= 0.20.3 added --abi
# <= 0.20.7 didn't have TREE_SITTER_LIBDIR support
#
# XXX: note that version string from binary may not be a good way to
#      compare versions because unreleased things appear to use the
#      same version string
TS_PATH ?= tree-sitter

# the directory this Makefile lives in
GRAMMAR_PROJ_DIR := $(shell pwd)

# XXX: various tree-sitter subcommands can lead to scanning of
#      directories looking for grammar directories that can have their
#      content automatically compiled and made accessible to
#      tree-sitter.  there may be more than one problem with this
#      functionality, but one clear problem is that it can lead to
#      different versions of the same language's grammar having .so
#      files be used by tree-sitter.  this can be confusing during
#      testing or otherwise interpreting the results of tree-sitter
#      subcommands.
#
#      there doesn't appear to be a nice way to turn off this scanning
#      behavior nor a way to explicitly tell tree-sitter to use one
#      specific .so or perhaps to only use specifically one grammar.
#
#      there is a way to work around this provided one only executes
#      tree-sitter subcommands in the top level of one's grammar
#      directory, but it requires an as yet unreleased tree-sitter
#      that has TREE_SITTER_LIBDIR functionality built in.  the
#      release after 0.20.7 may end up having this.
#
#      in any case, the steps to set this up are:
#
#      1. create symlink in grammar directory with a name that starts
#         with tree-sitter- and have it point to "." (no quotes).
#         it's likely less confusing to name the link
#         "tree-sitter-<name>" where <name> refers to the language for
#         the grammar as it will appear in output for at least one
#         tree-sitter subcommand.
#
#      2. create a .tree-sitter subdirectory in the grammar directory
#
#      3. arrange for the TREE_SITTER_DIR env var to point at the
#         .tree-sitter subdirectory.
#
#      4. put a config.json file in the aforementioned .tree-sitter
#         directory.
#
#      5. put an entry for "parser-directories" (an array or list)
#         that has a single element "."  (yes quotes this time).  so
#         the file might contain:
#
#         {
#           "parser-directories": [
#             "."
#           ]
#         }
#
#      run `tree-sitter dump-languages` to verify which gramamars are
#      recognized and how many there are.
#
#      the goal is to have one and have it be the current one.
LINK_NAME := tree-sitter-$(TS_LANGUAGE)
HACK_LINK := $(shell ls -d $(LINK_NAME) 2> /dev/null || echo "None")
HACK_LINK_DEREF := $(shell readlink $(LINK_NAME) 2> /dev/null || echo "None")

TREE_SITTER_DIR ?= $(GRAMMAR_PROJ_DIR)/.tree-sitter
export TREE_SITTER_DIR

# XXX: the env var TREE_SITTER_LIBDIR only affects the tree-sitter cli
#      for versions beyond 0.20.7 -- we use it here for convenient
#      expression but just put its value in SO_INSTALL_DIR and use
#      that instead
TREE_SITTER_LIBDIR ?= $(TREE_SITTER_DIR)/lib
export TREE_SITTER_LIBDIR

# XXX: most likely it's stuff above this line one might want to tweak

# where the shared object is looked for by tree-sitter cli
SO_INSTALL_DIR ?= $(TREE_SITTER_LIBDIR)

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S), Linux)
    SYS_TYPE := Linux
else ifeq ($(UNAME_S), Darwin)
    SYS_TYPE := Darwin
else ifeq ($(shell echo $(UNAME_S) | head -c 7), \
           $(shell echo "MINGW64" | head -c 7))
    SYS_TYPE := MINGW64
else
    SYS_TYPE := UNKNOWN
endif

ifeq ($(SYS_TYPE), Linux)
    SO_EXT := so
else ifeq ($(SYS_TYPE), Darwin)
    SO_EXT := dylib
else ifeq ($(SYS_TYPE), MINGW64)
    SO_EXT := dll
else
    SO_EXT := so
endif

SO_NAME := $(TS_LANGUAGE).$(SO_EXT)

# build directory for shared object
#
# NOTE: making this the same as src will make some values in this program
#       incorrect so don't do that
#
# XXX: bindings/c is another possibility
BUILD_DIR_NAME ?= build/c
BUILD_DIR := $(GRAMMAR_PROJ_DIR)/$(BUILD_DIR_NAME)

PARSER_WASM := tree-sitter-$(TS_LANGUAGE).wasm
PARSER_WASM_PATH := $(GRAMMAR_PROJ_DIR)/$(PARSER_WASM)

BUILT_SO_PATH := $(BUILD_DIR)/$(SO_NAME)
SO_INSTALL_PATH := $(SO_INSTALL_DIR)/$(SO_NAME)

#######
# emsdk
#######

# XXX: not sure how to integrate emsdk_env.sh...
#
#      possibly that could be parsed...but seems like a lot of work, and like
#      sourcing, could be a potential security issue.
#
#      apparently PATH only needs to be prepended with something like:
#
#        $EMSDK/upstream/emscripten
#
#      at least according to:
#
#        https://github.com/emscripten-core/emsdk/issues/1142#issuecomment-1334065131

# XXX: doing the following as an experiment.  may be brittle though if
#      emscripten changes certain things
EMSDK ?= $(shell realpath $(GRAMMAR_PROJ_DIR)/../emsdk)
EMSCRIPTEN := $(EMSDK)/upstream/emscripten
OLD_PATH := $(PATH)

########################################################################

############
# diagnostic
############

# XXX: using `set` can be a handy way to see what env vars got exported
dump:
	@echo "        TS_LANGUAGE:" $(TS_LANGUAGE)
	@echo "   GRAMMAR_PROJ_DIR:" $(GRAMMAR_PROJ_DIR)
	@echo
	@echo "            TS_PATH:" $(TS_PATH)
	@echo
	@echo "           SYS_TYPE:" $(SYS_TYPE)
	@echo
	@echo "      Make Env Vars"
	@echo "      -------------"
	@echo "    TREE_SITTER_DIR:" $(TREE_SITTER_DIR)
	@echo " TREE_SITTER_LIBDIR:" $(TREE_SITTER_LIBDIR)
	@echo " ------------------"
	@echo
	@echo "      Shared Object"
	@echo "      -------------"
	@echo "             SO_EXT:" $(SO_EXT)
	@echo
	@echo "     SO_INSTALL_DIR:" $(SO_INSTALL_DIR)
	@echo
	@echo "   Generated source:" \
              $(shell find src -type f 2> /dev/null || echo "None")
	@echo
	@echo "        Compiled SO:" \
              $(shell ls $(BUILD_DIR)/$(SO_NAME) 2> /dev/null || echo "None")
	@echo "       Installed SO:" \
              $(shell ls $(SO_INSTALL_PATH) 2> /dev/null || echo "None")
	@echo
	@echo "               WASM"
	@echo "               ----"
	@echo "        Parser wasm:" \
              $(shell ls $(PARSER_WASM_PATH) 2> /dev/null || echo "None")
	@echo
	@echo "              EMSDK:" $(EMSDK)
	@echo
	@echo "           OLD_PATH:" $(OLD_PATH)
	@echo
	@echo "          HACK_LINK:" $(HACK_LINK)
	@echo "    HACK_LINK_DEREF:" $(HACK_LINK_DEREF)
	@echo
	@echo "tree-sitter dump-languages:"
	@echo
	@$(TS_PATH) dump-languages
	@echo "If tree-sitter dump-languages shows info about more"
	@echo "than one language, be careful while interpreting output"
	@echo "from tree-sitter subcommands.  The shared object used by"
	@echo "tree-sitter for processing may be different from what you"
	@echo "might be expecting."

################
# symlink hack #
################

# for msys2 / mingw64, need env var MSYS to be set to winsymlinks:nativestrict
# from some version of windows 10 and beyond(?), setting up developer mode
# allows use of symlinks
hack-symlink:
ifeq ($(SYS_TYPE), MINGW64)
	MSYS=winsymlinks:nativestrict ln -sf . $(LINK_NAME)
else
	ln -sf . $(LINK_NAME)
endif

#################
# shared object #
#################

# XXX: tools that produces more than one output complicate things...
#
# https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
src/parser.c: grammar.js
	$(TS_PATH) generate --abi 13 --no-bindings

# XXX: could set things up to use quickjs to create grammar.json?
# XXX: not using this target explicitly
#src/grammar.json: grammar.js
#	$(TS_PATH) generate --abi 13 --no-bindings

# alias for command line use
.PHONY: parser-source
parser-source: src/parser.c

# XXX: not relying on the tree-sitter cli for building seems more
#      flexible.
#
#      on windows i had problems compiling using msys2 / mingw64 when
#      trying to use various tree-sitter subcommands.  to debug, i
#      ended up modifying the tree-sitter cli's source code to print
#      out precisely what the compiler invocation was.  that involved
#      writing some rust, recomplining the tree-sitter cli, and
#      running the invocation again.  that kind of thing seems like it
#      could be avoided by externalization as is dones below.
build-so: src/parser.c
	mkdir -p $(BUILD_DIR)
	# Compiling parser
	cc -fPIC -c -Isrc src/parser.c -o $(BUILD_DIR)/parser.o
	# May be compiling scanner.c
	if test -f src/scanner.c; then \
	  cc -fPIC -c -Isrc src/scanner.c -o $(BUILD_DIR)/scanner.o; \
	fi
	# May be compiling scanner.cc
	if test -f src/scanner.cc; then \
	  c++ -fPIC -Isrc -c src/scanner.cc -o $(BUILD_DIR)/scanner.o; \
	fi
	# Linking
	if test -f src/scanner.cc; then \
	  c++ -fPIC -shared $(BUILD_DIR)/*.o \
              -o $(BUILD_DIR)/$(SO_NAME); \
	else \
	  cc -fPIC -shared $(BUILD_DIR)/*.o \
             -o $(BUILD_DIR)/$(SO_NAME); \
	fi

install-so: build-so
	mkdir -p $(SO_INSTALL_DIR)
	cp $(BUILD_DIR)/$(SO_NAME) $(SO_INSTALL_DIR)

.PHONY: uninstall-so
uninstall-so:
	rm -rf $(SO_INSTALL_PATH)

#########
# testing
#########

.PHONY: corpus-test
corpus-test: src/parser.c
	$(TS_PATH) test

#####################
# playground and wasm
#####################

.PHONY: playground
playground: $(PARSER_WASM)
	$(TS_PATH) playground

# XXX: if experiment with setting emsdk env vars is aborted, put
#      the following back:
#
# @echo "Did you arrange for the appropriate emsdk_env to be used?"

# https://github.com/emscripten-core/emsdk/issues/1142#issuecomment-1334065131
$(PARSER_WASM): src/parser.c
	PATH=$(EMSCRIPTEN):$(OLD_PATH) \
	$(TS_PATH) build-wasm

# alias for command line use
.PHONY: build-wasm
build-wasm: $(PARSER_WASM)

#########
# cleanup
#########

.PHONY: clean
clean:
	- rm -rf src/parser.c src/scanner.c src/scanner.cc
	- rm -rf src/grammar.json src/node-types.json
	- rm -rf src/tree_sitter
	- rm -rf $(BUILD_DIR)
	- rm -f $(PARSER_WASM)
