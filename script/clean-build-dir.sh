#! /bin/sh

#set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

CUR_DIR=$(pwd)

cd "${PARSER_PROJ_DIR}" || exit 1

if [ $# -eq 0 ]; then
  printf "Cleaning build directory\n"
fi

rm -rf "${BUILD_DIR_PATH}"

cd "${CUR_DIR}" || exit 1

if [ $# -eq 0 ]; then
  printf "Done\n"
fi

