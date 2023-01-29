# XXX: it's assumed that certain env vars are set before this file is
#      used via make.  for the moment, see tsclj_env.sh for details.

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
              $(shell find src -type f 2> /dev/null)
	@echo
	@echo "        Compiled SO:" \
              $(shell ls $(BUILD_DIR)/$(SO_NAME) 2> /dev/null)
	@echo "       Installed SO:" \
              $(shell ls $(SO_INSTALL_PATH) 2> /dev/null)
	@echo
	@echo "               WASM"
	@echo "               ----"
	@echo "        Parser wasm:" \
              $(shell ls $(PARSER_WASM) 2> /dev/null)
	@echo
	@echo "         EMSCRIPTEN:" $(EMSCRIPTEN)
	@echo
	@echo "           OLD_PATH:" $(OLD_PATH)
	@echo
	@echo "          LINK_NAME:" $(LINK_NAME)
	@echo "          Exists at:" $(shell ls -d $(LINK_NAME) 2> /dev/null)
	@echo "  Ultimately points:" $(shell realpath $(LINK_NAME) 2> /dev/null)
	@echo
	@echo "tree-sitter dump-languages:"
	@echo
	@$(TS_PATH) dump-languages
	@echo "If tree-sitter dump-languages shows info about more"
	@echo "than one language, be careful while interpreting output"
	@echo "from tree-sitter subcommands.  The shared object used by"
	@echo "tree-sitter for processing may be different from what you"
	@echo "might be expecting."

##############
# symlink hack
##############

# for msys2 / mingw64, need env var MSYS to be set to winsymlinks:nativestrict
# from some version of windows 10 and beyond(?), setting up developer mode
# allows use of symlinks
hack-symlink:
ifeq ($(SYS_TYPE), MINGW64)
	MSYS=winsymlinks:nativestrict ln -sf . $(LINK_NAME)
else
	ln -sf . $(LINK_NAME)
endif

###############
# shared object
###############

# XXX: tools that produces more than one output may not be handled so
#      well by make (e.g. if input and output files don't all share a
#      common pre-file-extension portion).  note that redo may have a
#      similar issue (and may not handle the case that make can
#      appropriately).
#
# https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
src/parser.c: grammar.js
	$(TS_PATH) generate --abi 13 --no-bindings

# XXX: could set things up to use quickjs to create grammar.json?
# XXX: not using this target explicitly
#src/grammar.json: grammar.js
#	$(TS_PATH) generate --abi 13 --no-bindings

# alias for command line use
.PHONY: gen-src
gen-src: src/parser.c

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
	- rm -rf src/parser.c src/grammar.json src/node-types.json
	- rm -rf src/tree_sitter
	- rm -rf $(BUILD_DIR)
	- rm -f $(PARSER_WASM)
