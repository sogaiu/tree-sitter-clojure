# trying to make this Makefile generic
TS_LANGUAGE ?= clojure

# path to tree-sitter cli binary
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

# name of the directory the shared object is built to
BUILD_DIR_NAME ?= build

# XXX: most likely it's stuff above this line one might want to tweak

# where the shared object is looked for by tree-sitter cli
SO_INSTALL_DIR ?= $(TREE_SITTER_LIBDIR)

# full path of the directory the shared object is built to
BUILD_DIR = $(GRAMMAR_PROJ_DIR)/build

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
	@echo "          BUILD_DIR:" $(BUILD_DIR)
	@echo "     SO_INSTALL_DIR:" $(SO_INSTALL_DIR)

#################
# shared object #
#################

# XXX: --no-bindings became available in 0.19.4
src: grammar.js
	$(TS_PATH) generate --no-bindings
#	$(TS_PATH) generate
	# XXX: node and rust bindings get created by default
	#      once tree-sitter is upgraded to 0.19.4 or
	#      beyond, should be able to use --no-bindings
	#      to avoid having them get generated
#	- rm -rf binding.gyp
#	- rm -rf bindings
#	- rm -rf Cargo.toml
#       - rm -rf package.json

# XXX: put build result other than ultimate install location initially?
shared-object:
	mkdir -p $(BUILD_DIR)
	$(TS_PATH) generate --no-bindings --build --libdir $(BUILD_DIR)

# XXX: could also provide an uninstall target
install-shared-object: shared-object
	cp $(BUILD_DIR)/$(TS_LANGUAGE).$(SO_EXT) $(SO_INSTALL_DIR)

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

# XXX: arrange for emsdk?
tree-sitter-$(TS_LANGUAGE).wasm: src
	$(TS_PATH) build-wasm

###################
### for cleanup ###
###################

# XXX: what about clearing out shared object from TREE_SITTER_LIBDIR?
.PHONY: clean
clean:
	- rm -rf src
	- rm -f tree-sitter-$(TS_LANGUAGE).wasm
	- rm -f $(BUILD_DIR)/$(TS_LANGUAGE).$(SO_EXT)

# XXX: would be nice to get rid of

.PHONY: clean-all-bindings
clean-all-bindings: clean-node-bindings clean-rust-bindings clean-bindings-dir clean-package-json

.PHONY: clean-node-bindings
clean-node-bindings:
	- rm -rf binding.gyp
	- rm -rf bindings/node

.PHONY: clean-rust-bindings
clean-rust-bindings:
	- rm -rf Cargo.toml
	- rm -rf bindings/rust

.PHONY: clean-bindings-dir
clean-bindings-dir:
	- rm -rf bindings

.PHONY: clean-package-json
clean-package-json:
	- rm -rf package.json
