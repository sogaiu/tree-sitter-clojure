#! /bin/sh
# shellcheck disable=SC2034

# common values across scripts

# https://stackoverflow.com/a/1638397
#
# account for symlink use
SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=settings
. "${SCRIPT_DIR}/settings"

OLD_PATH=${PATH}

# path to tree-sitter cli binary
#
# >= 0.19.4 added --no-bindings
# >= 0.20.3 added --abi
# <= 0.20.7 didn't have TREE_SITTER_LIBDIR support
#
# XXX: note that version string from binary may not be a good way to
#      compare versions because unreleased things appear to use the
#      same version string
TS_PATH=${TS_PATH:-tree-sitter}

# example tree-sitter --version output:
#
#   tree-sitter 0.20.7 (9ac55f79d191f6fa200b1894ddac449fa3df70c1)
#
#   1           2      3
#
# so split on spaces and take the 2nd and 3rd fields
TS_VERSION=$($TS_PATH --version | cut -d' ' -f2)
# also remove surrounding parens -- otherwise can interfere with things
TS_COMMIT=$($TS_PATH --version | cut -d' ' -f3 | tr -d '()')

#MIN_VERSION=0.19.4
MIN_VERSION=0.20.8

# the parser project directory
PARSER_PROJ_DIR=$(realpath "$SCRIPT_DIR/..")

GRAMMAR_PATH=${PARSER_PROJ_DIR}/grammar.js

OLD_TREE_SITTER_DIR=${TREE_SITTER_DIR}
TREE_SITTER_DIR=${PARSER_PROJ_DIR}/.tree-sitter

# XXX: the env var TREE_SITTER_LIBDIR only affects the tree-sitter cli
#      for versions beyond 0.20.7 -- we use it here for convenient
#      expression but just put its value in SO_INSTALL_DIR and use
#      that instead
OLD_TREE_SITTER_LIBDIR=${TREE_SITTER_LIBDIR}
TREE_SITTER_LIBDIR=${TREE_SITTER_DIR}/lib

# where the shared object is looked for by tree-sitter cli
SO_INSTALL_DIR=${TREE_SITTER_LIBDIR}

UNAME_S=$(uname -s)

case ${UNAME_S} in
    Linux)
        SYS_TYPE=Linux
        ;;
    Darwin)
        SYS_TYPE=Darwin
        ;;
    MINGW64*)
        SYS_TYPE=MINGW64
        ;;
    *)
        # XXX: warn?
        SYS_TYPE=UNKNOWN
        ;;
esac

case ${SYS_TYPE} in
    Linux)
        SO_EXT=so
        ;;
    Darwin)
        SO_EXT=dylib
        ;;
    MINGW64)
        SO_EXT=dll
        ;;
    *)
        # XXX: warn?
        SO_EXT=so
        ;;
esac

SO_NAME=${TS_LANGUAGE}.${SO_EXT}

# build directory for shared object
#
# may be BUILD_DIR_NAME is not a good choice if exposing to outside?
# NOTE: making this the same as src will make some values in this program
#       incorrect so don't do that
BUILD_DIR_NAME=${BUILD_DIR_NAME:-build}
BUILD_DIR_PATH=${PARSER_PROJ_DIR}/${BUILD_DIR_NAME}

PARSER_WASM=tree-sitter-${TS_LANGUAGE}.wasm
PARSER_WASM_PATH=${PARSER_PROJ_DIR}/${PARSER_WASM}

BUILT_SO_PATH=${BUILD_DIR_PATH}/${SO_NAME}
INSTALLED_SO_PATH=${SO_INSTALL_DIR}/${SO_NAME}

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
HACK_LINK=$(ls -d "${LINK_NAME}" 2> /dev/null || printf "None")
HACK_LINK_DEREF=$(readlink "${LINK_NAME}" 2> /dev/null || printf "None")

####################
# emsdk experiment #
####################

# XXX: not sure how to integrate emsdk_env.sh...
#
#      might not be possble because one needs to . or source it?
#
#        https://lists.gnu.org/archive/html/help-make/2006-04/msg00142.html
#
#      the output of sourcing displays which env vars are set and what
#      they are set to.  a hack would be to capture and parse that output?
#      some attempts at this failed -- "source" doesn't work via
#      $(shell ,,,) and "." didn't work out for different reasons
#
#      running EMSDK_QUIET=1 python ~/src/emsdk/emsdk.py construct_env
#      produces output of the form:
#
#        export PATH="...";
#        export EMSDK="...";
#        export EMSDK_NODE="...";
#        unset EMSDK_QUIET;
#
#      possibly that could be parsed...but seems like a lot of work

# XXX: doing the following as an experiment.  may be brittle though if
#      emscripten changes certain things
EMSDK=$(realpath "${PARSER_PROJ_DIR}/../emsdk")
EMSCRIPTEN="${EMSDK}/upstream/emscripten"
# XXX: is there a guarantee that this will yield a single value?
NODE_VERSION=$(ls "${EMSDK}/node")
NODE_BIN_DIR_PATH="${EMSDK}/node/${NODE_VERSION}/bin"
EMSDK_NODE="${NODE_BIN_DIR_PATH}/node"
