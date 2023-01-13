#! /bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

CUR_DIR=$(pwd)

cd "${PARSER_PROJ_DIR}" || exit 1

if [ -f grammar.js ]; then
  printf "Found grammar.js, generating src/parser.c and friends.\n"
else
  printf "Failed to find grammar.js...exiting\n"
  exit 1;
fi

printf "* Invoking tree-sitter generate subcommand\n"
${TS_PATH} generate --abi 13 --no-bindings

cd "${CUR_DIR}" || exit 1

printf "Done\n"
