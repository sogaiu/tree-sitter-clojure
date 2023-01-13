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

TS_LANGUAGE := $(shell grep TS_LANGUAGE script/settings | cut -d= -f2)
# XXX: duplicating stuff from scripts...not good
TS_LANG_UNDERSCORE_NAME := $(shell echo $(TS_LANGUAGE) | tr '-' '_')
# XXX: even worse because "build" is not static
SO_BUILD_PATH := build/$(TS_LANGUAGE).so
# XXX: only as bad as the first duplication
PARSER_WASM := tree-sitter-$(TS_LANG_UNDERSCORE_NAME).wasm

########################################################################

##############
# diagnostic #
##############

# XXX: using `set` can be a handy way to see what env vars got exported
dump:
	./script/dump
	@echo
	./script/dump-languages
	@echo "**********************************************************"
	@echo "** If the above output suggests running the init-config **"
	@echo "** subcommand, carefully consider whether to do so.     **"
	@echo "** It probably means tree-sitter is looking in the      **"
	@echo "** wrong location for config.json.  You might want to   **"
	@echo "** set the TREE_SITTER_DIR environment variable to      **"
	@echo "** point at the .tree-sitter directory in this grammar  **"
	@echo "** repository's root directory and try again.           **"
	@echo "**********************************************************"
	@echo
	@echo "If tree-sitter dump-languages shows info about more"
	@echo "than one language, be careful while interpreting output"
	@echo "from tree-sitter subcommands.  The shared object used by"
	@echo "tree-sitter for processing may be different from what you"
	@echo "might be expecting."
	@echo
	@echo "If tree-sitter dump-languages shows no languages, then it"
	@echo "may be time to investigate.  It may be a sign that"
	@echo "the tree-sitter cli isn't finding any shared objects or"
	@echo "it hasn't found an appropriate config.json file."

################
# symlink hack #
################

.PHONY: hack-symlink
hack-symlink:
	./script/hack-symlink

#################
# shared object #
#################

# XXX: tools that produces more than one output complicate things...
#
# https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
src/parser.c: grammar.js
	./script/gen-src

# alias for command line use
.PHONY: parser-source
parser-source: src/parser.c

$(SO_BUILD_PATH): src/parser.c
	./script/build-so

install: $(SO_BUILD_PATH)
	./script/install-so

.PHONY: uninstall
uninstall:
	./script/uninstall-so

###############
### testing ###
###############

.PHONY: corpus-test
corpus-test: src/parser.c
	./script/corpus-test

###########################
### playground and wasm ###
###########################

.PHONY: playground
playground: $(PARSER_WASM)
	./script/playground

$(PARSER_WASM): src/parser.c
	./script/build-wasm

# alias for command line use
.PHONY: parser-wasm
parser-wasm: $(PARSER_WASM)

###################
### for cleanup ###
###################

.PHONY: clean
clean:
	./script/clean
