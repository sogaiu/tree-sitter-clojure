#! /bin/sh

#set -o pipefail

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

mkdir -p "${BUILD_DIR_PATH}"

printf "* Compiling parser\n"
cc -fPIC -c -Isrc src/parser.c -o "${BUILD_DIR_PATH}/parser.o"

if [ -f src/scanner.c ]; then
  printf "* Compiling scanner\n"
  cc -fPIC -c -Isrc src/scanner.c -o "${BUILD_DIR_PATH}/scanner.o"
fi

if [ -f src/scanner.cc ]; then
  printf "* Compiling scanner\n"
  c++ -fPIC -Isrc -c src/scanner.cc -o "${BUILD_DIR_PATH}/scanner.o"
fi

printf "* Linking\n"
if [ -f src/scanner.cc ]; then
  c++ -fPIC -shared "${BUILD_DIR_PATH}"/*.o \
      -o "${BUILD_DIR_PATH}/${SO_NAME}"
else
  cc -fPIC -shared "${BUILD_DIR_PATH}"/*.o \
      -o "${BUILD_DIR_PATH}/${SO_NAME}"
fi

cd "${CUR_DIR}" || exit 1

printf "Done\n"
