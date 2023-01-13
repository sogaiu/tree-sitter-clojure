#! /bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

########################################################################

if diff "${BUILT_SO_PATH}" "${INSTALLED_SO_PATH}" 2> /dev/null; then
    SOS_SAME="Yes"
else
    SOS_SAME="No"
fi

printf "OLD_PATH: %s\n" "${OLD_PATH}"
echo
printf "TS_LANGUAGE: %s\n" "${TS_LANGUAGE}"
printf "PARSER_PROJ_DIR: %s\n" "${PARSER_PROJ_DIR}"
echo
printf "TS_PATH: %s\n" "${TS_PATH}"
echo
printf "TS_VERSION: %s\n" "${TS_VERSION}"
printf "TS_COMMIT: %s\n" "${TS_COMMIT}"
printf "MIN_VERSION: %s\n" "${MIN_VERSION}"
echo
printf "OLD_TREE_SITTER_DIR: %s\n" "${OLD_TREE_SITTER_DIR}"
printf "TREE_SITTER_DIR: %s\n" "${TREE_SITTER_DIR}"
printf "OLD_TREE_SITTER_LIBDIR: %s\n" "${OLD_TREE_SITTER_LIBDIR}"
printf "TREE_SITTER_LIBDIR: %s\n" "${TREE_SITTER_LIBDIR}"
echo
printf "SO_INSTALL_DIR: %s\n" "${SO_INSTALL_DIR}"
printf "SO_EXT: %s\n" "${SO_EXT}"
echo
printf "BUILD_DIR_NAME: %s\n" "${BUILD_DIR_NAME}"
printf "BUILD_DIR_PATH: %s\n" "${BUILD_DIR_PATH}"
echo
printf "PARSER_WASM: %s\n" "${PARSER_WASM}"
printf "PARSER_WASM_PATH: %s\n" "${PARSER_WASM_PATH}"
echo
printf "BUILT_SO_PATH: %s\n" "${BUILT_SO_PATH}"
printf "INSTALLED_SO_PATH: %s\n" "${INSTALLED_SO_PATH}"
echo
printf "SOS_SAME: %s\n" "${SOS_SAME}"
echo
printf "LINK_NAME: %s\n" "${LINK_NAME}"
printf "HACK_LINK: %s\n" "${HACK_LINK}"
printf "HACK_LINK_DEREF: %s\n" "${HACK_LINK_DEREF}"
echo
printf "EMSDK: %s\n" "${EMSDK}"
printf "EMSCRIPTEN: %s\n" "${EMSCRIPTEN}"
printf "NODE_VERSION: %s\n" "${NODE_VERSION}"
printf "NODE_BIN_DIR_PATH: %s\n" "${NODE_BIN_DIR_PATH}"
printf "EMSDK_NODE: %s\n" "${EMSDK_NODE}"
