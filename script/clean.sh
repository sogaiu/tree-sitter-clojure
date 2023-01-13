#! /bin/sh

#set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

CUR_DIR=$(pwd)

cd "${PARSER_PROJ_DIR}" || exit 1

printf "Cleaning\n"

printf "* Generated source\n"
"${SCRIPT_DIR}"/clean-gen-src.sh 1

printf "* Build directory\n"
"${SCRIPT_DIR}"/clean-build-dir.sh 1

printf "* Wasm file\n"
"${SCRIPT_DIR}"/clean-wasm-file.sh 1

cd "${CUR_DIR}" || exit 1

printf "Done\n"
