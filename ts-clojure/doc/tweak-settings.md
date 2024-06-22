# Tweak settings

Below are some values that might be useful to change in
`conf/conf.clj`.

## abi

`abi` specifies the ABI number the `tree-sitter` cli `generate`
subcommand uses for generating `src/parser.c`.

What values can be specified may depend on the version of the
`tree-sitter` cli in use.

At the time of this writing (2024-05), it's likey that `14` is a good
choice as it has been the default for a few years (so across a fair
number of `tree-sitter` cli versions).

## grammar-dir

`grammar-dir` specifies a filesystem path to where tree-sitter-clojure
has been cloned to.

Note that making an appropriate symlink to where tree-sitter-clojure
lives may work too.

## repos

`repos` specifies the set of source samples to be tested against.

Note that this repository does not come with any samples.
Instructions on fetching samples is provided elsewhere.

## ts-bin-path

`ts-bin-path` specifies the command name or path to the `tree-sitter`
cli used to execute the cli's subcommands.

Adjusting this can be useful if one wants to use a different version
of the cli.
