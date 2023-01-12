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

# XXX: eventually work on portability?
#
# portable makefile tutorial
#   https://nullprogram.com/blog/2017/08/20/
#
# posix makefile spec
#   https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html
#
# consider bmake and fmake for testing portability on occasion

# XXX: additional targets?
#
#      * default?
#      * deps (or similar) to report versions of dependencies?

# XXX: different ways to assign in Makefiles...
#
# https://www.gnu.org/software/make/manual/html_node/Flavors.html#Flavors

# trying to make this Makefile generic
TS_LANGUAGE ?= clojure

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

# example tree-sitter --version output:
#
#   tree-sitter 0.20.7 (9ac55f79d191f6fa200b1894ddac449fa3df70c1)
#
#   1           2      3
#
# so split on spaces and take the 2nd and 3rd fields
TS_VERSION = $(shell $(TS_PATH) --version | cut -d' ' -f2)
# also remove surrounding parens -- otherwise can interfere with things
TS_COMMIT = $(shell $(TS_PATH) --version | cut -d' ' -f3 | tr -d '()')

#MIN_VERSION := "0.19.4"
MIN_VERSION := "0.20.8"

# the directory this Makefile lives in
GRAMMAR_PROJ_DIR = $(shell pwd)

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
HACK_LINK = $(shell ls -d tree-sitter-* 2> /dev/null)
HACK_LINK_DEREF = $(shell readlink tree-sitter-*)

TREE_SITTER_DIR ?= $(GRAMMAR_PROJ_DIR)/.tree-sitter
# XXX: the env var TREE_SITTER_LIBDIR only affects the tree-sitter cli
#      for versions beyond 0.20.7 -- we use it here for convenient
#      expression but just put its value in SO_INSTALL_DIR and use
#      that instead
TREE_SITTER_LIBDIR ?= $(TREE_SITTER_DIR)/lib

# XXX: most likely it's stuff above this line one might want to tweak

# where the shared object is looked for by tree-sitter cli
SO_INSTALL_DIR ?= $(TREE_SITTER_LIBDIR)

# XXX: cache value and reuse?
ifeq ("$(shell uname -s)", "Linux")
    SO_EXT=so
endif
ifeq ("$(shell uname -s)", "Darwin")
    SO_EXT=dylib
endif

########################################################################

##############
# diagnostic #
##############

dump:
	@echo "   GRAMMAR_PROJ_DIR:" $(GRAMMAR_PROJ_DIR)
	@echo "        TS_LANGUAGE:" $(TS_LANGUAGE)
	@echo
	@echo "            TS_PATH:" $(TS_PATH)
	@echo "         TS_VERSION:" $(TS_VERSION)
	@echo "          TS_COMMIT:" $(TS_COMMIT)
	@echo "        MIN_VERSION:" $(MIN_VERSION)
	@echo
	@echo "    TREE_SITTER_DIR:" $(TREE_SITTER_DIR)
	@echo " TREE_SITTER_LIBDIR:" $(TREE_SITTER_LIBDIR)
	@echo "     SO_INSTALL_DIR:" $(SO_INSTALL_DIR)
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
	@echo "tree-sitter for processing may be different from what is"
	@echo "expected."

################
# symlink hack #
################

hack-symlink:
	ln -sf . tree-sitter-$(TS_LANGUAGE)

#################
# shared object #
#################

src/parser.c: grammar.js
	$(TS_PATH) generate --abi 13 --no-bindings

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
shared-object: src/parser.c
	# Compiling parser
	cc -fPIC -c -Isrc src/parser.c -o src/parser.o
	# May be compiling scanner.c
	if test -f src/scanner.c; then \
	  cc -fPIC -c -Isrc src/scanner.c -o src/scanner.o; \
	fi
	# May be compiling scanner.cc
	if test -f src/scanner.cc; then \
	  c++ -fPIC -Isrc -c src/scanner.cc -o src/scanner.o; \
	fi
	# Linking
	if test -f src/scanner.cc; then \
	  c++ -fPIC -shared src/*.o -o src/$(TS_LANGUAGE).$(SO_EXT); \
	else \
	  cc -fPIC -shared src/*.o -o src/$(TS_LANGUAGE).$(SO_EXT); \
	fi

install: shared-object
	cp src/$(TS_LANGUAGE).$(SO_EXT) $(SO_INSTALL_DIR)

.PHONY: uninstall
uninstall:
	rm -rf $(SO_INSTALL_DIR)/$(TS_LANGUAGE).$(SO_EXT)

###############
### testing ###
###############

.PHONY: corpus-test
corpus-test: src
	$(TS_PATH) test

###########################
### playground and wasm ###
###########################

.PHONY: playground
playground: tree-sitter-$(TS_LANGUAGE).wasm
	$(TS_PATH) playground

# XXX: arrange for emsdk?  may need cross-platform detection because
#      script name is different
tree-sitter-$(TS_LANGUAGE).wasm: src/parser.c
	@echo "Did you arrange for the appropriate emsdk_env to be used?"
	$(TS_PATH) build-wasm

###################
### for cleanup ###
###################

.PHONY: clean
clean:
	- rm -rf src
	- rm -f tree-sitter-$(TS_LANGUAGE).wasm
