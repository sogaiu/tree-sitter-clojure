#! /bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

# this is here because it seems that to stop tree-sitter playground a
# user is likely to press control-c.  resuming after doesn't appear to
# happen otherwise.  that might lead to an incorrect current working
# directory.

trap cleanup INT

cleanup () {
  "Likely trapped Control-C"
}

########################################################################

CUR_DIR=$(pwd)

cd "${PARSER_PROJ_DIR}" || exit 1

if [ -f "${PARSER_WASM_PATH}" ]; then
  printf "Found %s, starting playground.\n" "${PARSER_WASM}"
else
  printf "Failed to find %s...exiting\n" "${PARSER_WASM}"
  exit 1;
fi

printf "* Invoking tree-sitter playground subcommand\n"

${TS_PATH} playground

cd "${CUR_DIR}" || exit 1

printf "Done\n"
