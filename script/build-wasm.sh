#! /bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

CUR_DIR=$(pwd)

cd "${PARSER_PROJ_DIR}" || exit 1

if [ -f src/parser.c ]; then
  printf "Found src/parser.c, building shared object.\n"
else
  printf "Failed to find src/parser.c...exiting\n"
  exit 1;
fi

printf "* Invoking tree-sitter build-wasm subcommand\n"

# XXX: the following may be brittle as it depends on emscripten
#      internals.
#
#      observing the output of running emsdk_env.* should indicate
#      which environment variables are expected to have which
#      particular values so if the following breaks, the
#      aforementioned output could be one place to look for clues.
#
# shellcheck disable=SC2097,SC2098
EMSDK=${EMSDK} \
EMSDK_NODE=${EMSDK_NODE} \
PATH=${EMSDK}:${EMSCRIPTEN}:${NODE_BIN_DIR_PATH}:${OLD_PATH} \
     ${TS_PATH} build-wasm

cd "${CUR_DIR}" || exit 1

printf "Done\n"
