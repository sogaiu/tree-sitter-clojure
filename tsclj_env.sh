#! /bin/sh

# XXX: consider a design where before invoking make (to use the
#      Makefile in the directory this file is in), that is meant to be
#      preceded by having certain environment variables set.
#
#      this file arranges for those env vars to be set.  note that
#      this only works because this is a shell script.
#
#      to be able to use another programming language, possibly such
#      a program could generate a shell script which would then be
#      sourced...
#
#      https://github.com/emscripten-core/emsdk/blob/ \
#        592b7b74e4d250169a702e4b43836756bbc77319/emsdk.bat#L53-L59
#
#      (see various emsdk files for more details)
#
#      what we might get from this includes:
#
#      * the Makefile becomes simpler
#      * the env var values are usable by other programs
#      * the Makefile can be made more generic (e.g. TS_LANGUAGE can be
#        set outside of the Makefile)

########################################################################

# XXX: ATSP should be changed to match the grammar name in grammar.js

ATSP_LANG=clojure
# XXX: for debugging / dump
export ATSP_LANG

# XXX: might want to change the following on occasion when testing
#      different versions of the cli

# path to tree-sitter cli binary
#
# >= 0.19.4 added --no-bindings
# >= 0.20.3 added --abi
# <= 0.20.7 didn't have TREE_SITTER_LIBDIR support
#
# XXX: note that version string from binary may not be a good way to
#      compare versions because unreleased things appear to use the
#      same version string
#
# XXX: should we try to get a full path here?
ATSP_TS_PATH=tree-sitter
export ATSP_TS_PATH

########################################################################

ATSP_OLD_PATH=${PATH}
# XXX: for debugging / dump
export ATSP_OLD_PATH

# the directory the Makefile lives in
ATSP_LANG_ROOT=$(pwd)
export ATSP_LANG_ROOT

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
ATSP_LINK_NAME=tree-sitter-${ATSP_LANG}
export ATSP_LINK_NAME

# XXX: don't prefix with ATSP_?
TREE_SITTER_DIR=${ATSP_LANG_ROOT}/.tree-sitter
export TREE_SITTER_DIR

# XXX: the env var TREE_SITTER_LIBDIR only affects the tree-sitter cli
#      for versions beyond 0.20.7 -- we use it here for convenient
#      expression but just put its value in SO_INSTALL_DIR and use
#      that instead
# XXX: don't prefix with ATSP_?
TREE_SITTER_LIBDIR=${TREE_SITTER_DIR}/lib
export TREE_SITTER_LIBDIR

# XXX: most likely it's stuff above this line one might want to tweak

# where the shared object is looked for by tree-sitter cli
ATSP_SO_INSTALL_DIR=${TREE_SITTER_LIBDIR}
export ATSP_SO_INSTALL_DIR

uname_s=$(uname -s)

if [ "${uname_s}" = "Linux" ]; then
    ATSP_SYS_TYPE=Linux
elif [ "${uname_s}" = "Darwin" ]; then
    ATSP_SYS_TYPE=Darwin
elif [ "$(echo "${uname_s}" | head -c 7)" = \
       "$(echo "MINGW64" | head -c 7)" ]; then
    ATSP_SYS_TYPE=MINGW64
else
    ATSP_SYS_TYPE=UNKNOWN
fi

export ATSP_SYS_TYPE

if [ ${ATSP_SYS_TYPE} = "Linux" ]; then
    ATSP_SO_EXT=so
elif [ ${ATSP_SYS_TYPE} = "Darwin" ]; then
    ATSP_SO_EXT=dylib
elif [ ${ATSP_SYS_TYPE} = "MINGW64" ]; then
    ATSP_SO_EXT=dll
else
    ATSP_SO_EXT=so
fi

export ATSP_SO_EXT

ATSP_SO_NAME=${ATSP_LANG}.${ATSP_SO_EXT}
export ATSP_SO_NAME

# build directory for shared object
#
# NOTE: making this the same as src will make some values in this program
#       incorrect so don't do that
#
# XXX: bindings/c is another possibility
ATSP_BUILD_DIR_NAME=${ATSP_BUILD_DIR_NAME:-build/c}
ATSP_BUILD_DIR=${ATSP_LANG_ROOT}/${ATSP_BUILD_DIR_NAME}
export ATSP_BUILD_DIR

ATSP_PARSER_WASM=tree-sitter-${ATSP_LANG}.wasm
export ATSP_PARSER_WASM

ATSP_SO_INSTALL_PATH=${ATSP_SO_INSTALL_DIR}/${ATSP_SO_NAME}
export ATSP_SO_INSTALL_PATH

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
EMSDK=$(realpath "${ATSP_LANG_ROOT}"/../emsdk)
ATSP_EMSCRIPTEN=${EMSDK}/upstream/emscripten
export ATSP_EMSCRIPTEN
