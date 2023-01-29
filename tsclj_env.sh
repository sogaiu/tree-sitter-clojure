#! /bin/sh

# XXX: consider a design where before invoking make to use the Makefile
#      in the directory this file is in is meant to be preceded by
#      having certain environment variables set.
#
#      this file arranges for those env vars to be set.  note that
#      although this file is a shell script, it could be implemented
#      using some other programming language.
#
#      what we might get from this includes:
#
#      * the Makefile becomes simpler
#      * the env var values are usable by other programs
#      * the Makefile can be made more generic (e.g. TS_LANGUAGE can be
#        set outside of the Makefile)

# XXX: rename the env vars so they are not so likely to conflict.
#      make most of them have a common prefix that is unique?  might
#      not be good to choose TSCLJ though because that would appear to
#      make this whole scheme specific to this grammar.

TS_LANGUAGE=clojure
# XXX: for debugging / dump
export TS_LANGUAGE

OLD_PATH=${PATH}
# XXX: for debugging / dump
export OLD_PATH

# path to tree-sitter cli binary
#
# >= 0.19.4 added --no-bindings
# >= 0.20.3 added --abi
# <= 0.20.7 didn't have TREE_SITTER_LIBDIR support
#
# XXX: note that version string from binary may not be a good way to
#      compare versions because unreleased things appear to use the
#      same version string
TS_PATH=tree-sitter
export TS_PATH

# the directory the Makefile lives in
GRAMMAR_PROJ_DIR=$(pwd)
export GRAMMAR_PROJ_DIR

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
LINK_NAME=tree-sitter-${TS_LANGUAGE}
export LINK_NAME
HACK_LINK=$(ls -d ${LINK_NAME} 2> /dev/null)
export HACK_LINK
HACK_LINK_DEREF=$(readlink ${LINK_NAME} 2> /dev/null)
export HACK_LINK_DEREF

TREE_SITTER_DIR=${GRAMMAR_PROJ_DIR}/.tree-sitter
export TREE_SITTER_DIR

# XXX: the env var TREE_SITTER_LIBDIR only affects the tree-sitter cli
#      for versions beyond 0.20.7 -- we use it here for convenient
#      expression but just put its value in SO_INSTALL_DIR and use
#      that instead
TREE_SITTER_LIBDIR=${TREE_SITTER_DIR}/lib
export TREE_SITTER_LIBDIR

# XXX: most likely it's stuff above this line one might want to tweak

# where the shared object is looked for by tree-sitter cli
SO_INSTALL_DIR=${TREE_SITTER_LIBDIR}
export SO_INSTALL_DIR

uname_s=$(uname -s)

if [ "${uname_s}" = "Linux" ]; then
    SYS_TYPE=Linux
elif [ "${uname_s}" = "Darwin" ]; then
    SYS_TYPE=Darwin
elif [ "$(echo "${uname_s}" | head -c 7)" = \
       "$(echo "MINGW64" | head -c 7)" ]; then
    SYS_TYPE=MINGW64
else
    SYS_TYPE=UNKNOWN
fi

export SYS_TYPE

if [ ${SYS_TYPE} = "Linux" ]; then
    SO_EXT=so
elif [ ${SYS_TYPE} = "Darwin" ]; then
    SO_EXT=dylib
elif [ ${SYS_TYPE} = "MINGW64" ]; then
    SO_EXT=dll
else
    SO_EXT=so
fi

export SO_EXT

SO_NAME=${TS_LANGUAGE}.${SO_EXT}
export SO_NAME

# build directory for shared object
#
# NOTE: making this the same as src will make some values in this program
#       incorrect so don't do that
#
# XXX: bindings/c is another possibility
BUILD_DIR_NAME=${BUILD_DIR_NAME:-build/c}
BUILD_DIR=${GRAMMAR_PROJ_DIR}/${BUILD_DIR_NAME}
export BUILD_DIR

PARSER_WASM=tree-sitter-${TS_LANGUAGE}.wasm
export PARSER_WASM

SO_INSTALL_PATH=${SO_INSTALL_DIR}/${SO_NAME}
export SO_INSTALL_PATH

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
EMSDK=$(realpath "${GRAMMAR_PROJ_DIR}"/../emsdk)
EMSCRIPTEN=${EMSDK}/upstream/emscripten
export EMSCRIPTEN
