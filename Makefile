# trying to make this Makefile generic
TS_LANGUAGE ?= clojure

# path to tree-sitter cli binary
# XXX: version must be at least 0.19.4
TS_PATH ?= tree-sitter

# example tree-sitter --version output:
#
#   tree-sitter 0.20.7 (9ac55f79d191f6fa200b1894ddac449fa3df70c1)
#
#   1           2      3
#
# so split on spaces and take the 2nd and 3rd fields
TS_VERSION = `$(TS_PATH) --version | cut -d' ' -f2-3`

# the directory this Makefile lives in
GRAMMAR_PROJ_DIR = $(shell pwd)

# by default, try to limit scanning to the directory containing this
# file
#
# XXX: have made a symlink in the same dir from tree-sitter-clojure to
#      the project directory itself.  on windows may new developer
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
#      limits scanning to the grammar's directory only
#
#      at least, that is the hope :)
TREE_SITTER_DIR ?= $(GRAMMAR_PROJ_DIR)/.tree-sitter
# XXX: the env var TREE_SITTER_LIBDIR only affects the tree-sitter cli
#      for versions beyond 0.20.7 -- we want to use the --libdir
#      flag for the generate subcommand, but that was added at the
#      same time.
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
	@echo "            TS_PATH:" $(TS_PATH)
	@echo "         TS_VERSION:" $(TS_VERSION)
	@echo "    TREE_SITTER_DIR:" $(TREE_SITTER_DIR)
	@echo " TREE_SITTER_LIBDIR:" $(TREE_SITTER_LIBDIR)
	@echo "     SO_INSTALL_DIR:" $(SO_INSTALL_DIR)

#################
# shared object #
#################

src/parser.c: grammar.js
	$(TS_PATH) generate --no-bindings

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
	$(TS_PATH) build-wasm

###################
### for cleanup ###
###################

.PHONY: clean
clean:
	- rm -rf src
	- rm -f tree-sitter-$(TS_LANGUAGE).wasm

