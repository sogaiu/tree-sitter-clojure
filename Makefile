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
PARSER_WASM := tree-sitter-$(TS_LANGUAGE).wasm

########################################################################

##############
# diagnostic #
##############

# XXX: using `set` can be a handy way to see what env vars got exported
dump:
	./script/dump
	@echo
	./script/dump-languages
	@echo "If tree-sitter dump-languages shows info about more"
	@echo "than one language, be careful while interpreting output"
	@echo "from tree-sitter subcommands.  The shared object used by"
	@echo "tree-sitter for processing may be different from what you"
	@echo "might be expecting."
	@echo
	@echo "If tree-sitter dump-languages shows no languages, then it"
	@echo "may be time to investigate.  It may be a sign that"
	@echo "the tree-sitter cli isn't finding any shared objects."

################
# symlink hack #
################

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

shared-object: src/parser.c
	./script/build-so

install: shared-object
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
