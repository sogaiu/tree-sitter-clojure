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

ifndef ATSP_LANG
  $(warning Expected env vars (e.g. ATSP_LANG) not set.)
  $(warning Hint: was an appropriate script sourced?)
  $(error Exiting.)
endif

########################################################################

############
# diagnostic
############

# XXX: using `set` can be a handy way to see what env vars got exported

#: Show env var and other state
dump:
	@echo "          ATSP_LANG:" $(ATSP_LANG)
	@echo "     ATSP_LANG_ROOT:" $(ATSP_LANG_ROOT)
	@echo
	@echo "       ATSP_TS_PATH:" $(ATSP_TS_PATH)
	@echo
	@echo "      ATSP_SYS_TYPE:" $(ATSP_SYS_TYPE)
	@echo
	@echo "      Make Env Vars"
	@echo "      -------------"
	@echo "    TREE_SITTER_DIR:" $(TREE_SITTER_DIR)
	@echo " TREE_SITTER_LIBDIR:" $(TREE_SITTER_LIBDIR)
	@echo " ------------------"
	@echo
	@echo "      Shared Object"
	@echo "      -------------"
	@echo "        ATSP_SO_EXT:" $(ATSP_SO_EXT)
	@echo "       ATSP_SO_NAME:" $(ATSP_SO_NAME)
	@echo
	@echo "ATSP_SO_INSTALL_DIR:" $(ATSP_SO_INSTALL_DIR)
	@echo
	@echo "   Generated source:" \
              $(shell find src -type f 2> /dev/null)
	@echo
	@echo "        Compiled SO:" \
              $(shell ls $(ATSP_BUILD_DIR)/$(ATSP_SO_NAME) 2> /dev/null)
	@echo "       Installed SO:" \
              $(shell ls $(ATSP_SO_INSTALL_PATH) 2> /dev/null)
	@echo
	@echo "               WASM"
	@echo "               ----"
	@echo "        Parser wasm:" \
              $(shell ls $(ATSP_PARSER_WASM) 2> /dev/null)
	@echo
	@echo "    ATSP_EMSCRIPTEN:" $(ATSP_EMSCRIPTEN)
	@echo
	@echo "      ATSP_OLD_PATH:" $(ATSP_OLD_PATH)
	@echo
	@echo "     ATSP_LINK_NAME:" $(ATSP_LINK_NAME)
	@echo
	@echo "          Exists at:" $(shell ls -d $(ATSP_LINK_NAME) 2> /dev/null)
	@echo "  Ultimately points:" $(shell realpath $(ATSP_LINK_NAME) 2> /dev/null)
	@echo
	@echo "tree-sitter dump-languages:"
	@echo
	@$(ATSP_TS_PATH) dump-languages
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

#: Create hack symlink to deal with tree-sitter scanning issue
hack-symlink:
ifeq ($(ATSP_SYS_TYPE), MINGW64)
	MSYS=winsymlinks:nativestrict ln -sf . $(ATSP_LINK_NAME)
else
	ln -sf . $(ATSP_LINK_NAME)
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
	$(ATSP_TS_PATH) generate --abi 13 --no-bindings

# XXX: could set things up to use quickjs to create grammar.json?
# XXX: not using this target explicitly
#src/grammar.json: grammar.js
#	$(ATSP_TS_PATH) generate --abi 13 --no-bindings

# alias for command line use
.PHONY: gen-src
#: Generate parser C source
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

#: Build shared object / dynamic library
build-so: src/parser.c
	mkdir -p $(ATSP_BUILD_DIR)
	# Compiling parser
	cc -fPIC -c -Isrc src/parser.c -o $(ATSP_BUILD_DIR)/parser.o
	# May be compiling scanner.c
	if test -f src/scanner.c; then \
	  cc -fPIC -c -Isrc src/scanner.c -o $(ATSP_BUILD_DIR)/scanner.o; \
	fi
	# May be compiling scanner.cc
	if test -f src/scanner.cc; then \
	  c++ -fPIC -Isrc -c src/scanner.cc -o $(ATSP_BUILD_DIR)/scanner.o; \
	fi
	# Linking
	if test -f src/scanner.cc; then \
	  c++ -fPIC -shared $(ATSP_BUILD_DIR)/*.o \
              -o $(ATSP_BUILD_DIR)/$(ATSP_SO_NAME); \
	else \
	  cc -fPIC -shared $(ATSP_BUILD_DIR)/*.o \
             -o $(ATSP_BUILD_DIR)/$(ATSP_SO_NAME); \
	fi

#: Install shared object
install-so: build-so
	mkdir -p $(ATSP_SO_INSTALL_DIR)
	cp $(ATSP_BUILD_DIR)/$(ATSP_SO_NAME) $(ATSP_SO_INSTALL_DIR)

.PHONY: uninstall-so
#: Uninstall shared object
uninstall-so:
	rm -rf $(ATSP_SO_INSTALL_PATH)

#########
# testing
#########

.PHONY: corpus-test
#: Run corpus tests
corpus-test: src/parser.c
	$(ATSP_TS_PATH) test

#####################
# playground and wasm
#####################

.PHONY: playground
#: Start web playground
playground: $(ATSP_PARSER_WASM)
	$(ATSP_TS_PATH) playground

# XXX: if experiment with setting emsdk env vars is aborted, put
#      the following back:
#
# @echo "Did you arrange for the appropriate emsdk_env to be used?"

# https://github.com/emscripten-core/emsdk/issues/1142#issuecomment-1334065131
$(ATSP_PARSER_WASM): src/parser.c
	PATH=$(ATSP_EMSCRIPTEN):$(ATSP_OLD_PATH) \
	$(ATSP_TS_PATH) build-wasm

# alias for command line use
.PHONY: build-wasm
#: Build grammar's wasm file
build-wasm: $(ATSP_PARSER_WASM)

#########
# cleanup
#########

.PHONY: clean
#: Remove built files / directories
clean:
	- rm -rf src/parser.c src/grammar.json src/node-types.json
	- rm -rf src/tree_sitter
	- rm -rf $(ATSP_BUILD_DIR)
	- rm -f $(ATSP_PARSER_WASM)
