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
TS_VERSION = `$(TS_PATH) --version | cut -d' ' -f2`
TS_COMMIT = `$(TS_PATH) --version | cut -d' ' -f3`

#MIN_VERSION := "0.19.4"
MIN_VERSION := "0.20.8"

# the directory this Makefile lives in
GRAMMAR_PROJ_DIR = $(shell pwd)

# by default, try to limit scanning to the directory containing this
# file
#
# XXX: have made a symlink in the same dir from tree-sitter-clojure to
#      the project directory itself.  on windows may need developer
#      mode for this to work.
#
#      that symlink in combination with the entry in config.json for
#      parser_directories:
#
#      {
#        "parser-directories": [
#          "."
#        ],
#
#      make scanning happen only inside the grammar directory as
#      long as `tree-sitter` is invoked only inside the grammar
#      directory (actually at its top-level)
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

# XXX: various tree-sitter commands can lead to scanning
#      of directories looking for grammar directories that
#      can have their content automatically compiled and
#      made accessible to tree-sitter.  there may be
#      more than one problem with this functionality, but
#      one clear problem is that it can lead to different
#      versions of the same language's grammar having
#      .so files be used by tree-sitter.  this can be
#      confusing during testing or otherwise interpreting
#      the results of tree-sitter commands.
#
#      there doesn't appear to be a nice way to turn off
#      this scanning behavior nor a way to explicitly
#      tell tree-sitter to use one specific .so or
#      perhaps to only use specifically one grammar.
#
#      there is a way to work around this provided one
#      only executes tree-sitter subcommands in the top
#      level of one's grammar directory, but it requires
#      an as yet unreleased tree-sitter that has
#      TREE_SITTER_LIBDIR functionality built in.
#      the release after 0.20.7 may end up having this.
#
#      in any case, the steps to set this up are:
#
#      1. create symlink in grammar directory with
#         a name that starts with tree-sitter- and have
#         it point to "." (no quotes).  it's likely less
#         confusing to name the link "tree-sitter-<name>"
#         where <name> refers to the language for the
#         grammar as it will appear in output for
#         at least one tree-sitter subcommand.
#
#      2. arrange for the TREE_SITTER_DIR env var to
#         point at a .tree-sitter subdirectory of the
#         grammar's directory.
#
#      3. put a config.json file in the aforementioned
#         .tree-sitter directory.
#
#      4. put an entry for "parser-directories" (an
#         array or list) that has a single element "."
#         (yes quotes this time).  so the file might
#         contain:
#
#         {
#           "parser-directories": [
#             "."
#           ]
#         }
#
#      run `tree-sitter dump-languages` to verify which
#      gramamars are recognized and how many there are.
#
#      the goal is to have one and have it be the current one.
HACK_LINK = `ls -d tree-sitter-* 2> /dev/null`
HACK_LINK_DEREF = `readlink tree-sitter-*`

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
	@echo "from tree-sitter commands.  The shared object used by"
	@echo "tree-sitter for processing may be different from what is"
	@echo "expected."

#################
# shared object #
#################

src/parser.c: grammar.js
	$(TS_PATH) generate --abi 13 --no-bindings

# XXX: not relying on the tree-sitter cli for building seems more
#      flexible
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

