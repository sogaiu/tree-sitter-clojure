# Verify tree-sitter Setup

## Determine cli version

To determine your `tree-sitter` cli version:

```
tree-sitter --version
```

Make note of this for future reference.

If this is not the version you want to use, arrange for another one.
It's possible to configure things via `conf/conf.clj` so that this
repository's scripts make use of a different `tree-sitter` by
specifying a full path or changing a binary name.  See the top-level
document for info on changing settings.

## Determine where parser repositories are looked for

See if `tree-sitter` already knows about any parser repositories you
may have lying around:

```
tree-sitter dump-languages
```

If you don't see any output and you aren't familiar with where your
`tree-sitter` setup looks for parser repositories, you may want to
have a look at [this
document](https://github.com/sogaiu/ts-questions/blob/master/questions/what-paths-are-relevant/README.md).

If you do see some output, study any values associated with `parser`.
That should give you a clue regarding under which directories
`tree-sitter` will look for parser repositories.  You might still want
to see [the aforementioned
document](https://github.com/sogaiu/ts-questions/blob/master/questions/what-paths-are-relevant/README.md) to confirm your ideas :)

You want to know this information because you'll want to clone
tree-sitter-clojure to a location that `tree-sitter` can find.
