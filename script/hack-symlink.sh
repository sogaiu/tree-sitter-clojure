#! /bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

CUR_DIR=$(pwd)

cd "${PARSER_PROJ_DIR}" || exit 1

if [ ! -f "${LINK_NAME}" ]; then
  printf "Work-around symlink not found so creating it.\n"
else
  printf "Found work-around symlink exists, so exiting.\n"
  exit 1;
fi

printf "* Invoking ln\n"

if [ "${SYS_TYPE}" = "MINGW64" ]; then
  MSYS=winsymlinks:nativestrict ln -sf . "${LINK_NAME}"
else
  ln -sf . "${LINK_NAME}"
fi

cd "${CUR_DIR}" || exit 1

printf "Done\n"
