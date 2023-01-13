## What's In Here

Apart from this file and the file named "settings", everything else
should be a script of some sort.  Each script expresses a task one
might carry out in the course of working with this repository such as:

* Generating parser source from `grammar.js`
* Cleaning up files and directories
* Starting the web playground

The scripts can be executed on their own but they are also used as
part of recipes associated with the targets of the `Makefile` in the
repository root.

### settings

The `settings` file is meant to contain just lines that look like:

```
TS_LANGUAGE=clojure
```

Note that the `Makefile` in the repository root parses this file for
lines that look like the above.

### Why No File Extensions?

The names do not have extensions deliberately:

* An alternative language might be used to implement a task
* Might lead to a nicer arrangement on Windows

## Linting Shell Scripts

To lint, run `shellcheck -x <name>` on the shell files in this
directory.  At the moment, that's all files except `README` and
`settings`.

Invoke `shellcheck` from inside this directory.  I'm not sure its
checking will function correctly for "source"d files otherwise.


