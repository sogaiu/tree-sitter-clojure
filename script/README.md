## What's In Here

* `README.md` - this README file
* `settings` - contains settings specific to this grammar
* All other files - task scripts
* `util` - directory of utility scripts

### `settings`

The `settings` file is meant to contain just lines that look like:

```
TS_LANGUAGE=clojure
```

The information in `settings` is meant to abstract out differences
between grammars.  At the moment, that's just the name of the grammar.

### Task Scripts

Each task script in this directory expresses a task one might carry
out in the course of working with this repository such as:

* Generating parser source from `grammar.js`
* Cleaning up files and directories
* Starting the web playground

The scripts can be executed on their own but they are also used as
recipes for targets of the `Makefile` in the repository root.

### `util`

The `util` directory contains some scripts that allow reuse of
functionality invoked from the `Makefile` as well as from the task
scripts.  The hope here was to reduce duplication.

## Why No File Extensions?

The scripts' names do not have file extensions deliberately:

* An alternative language might be used to implement a task script
* Might lead to a nicer arrangement on Windows

## Linting Shell Scripts

To lint, run `shellcheck -x <name>` on the shell files in this
directory.  At the moment, that's all files except `README` and
`settings`.

Invoke `shellcheck` from inside this directory.  I'm not sure its
checking will function correctly for "source"d files otherwise.
