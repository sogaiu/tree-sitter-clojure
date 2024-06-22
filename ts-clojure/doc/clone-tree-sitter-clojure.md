# Clone tree-sitter-clojure

Verification that `tree-sitter` knows about the cloned
tree-sitter-clojure directory can be performed by running `tree-sitter
dump-languages` and examining its output.

Sample output:

```
scope: source.clojure
parser: "./tree-sitter-clojure/"
highlights: None
file_types: ["bb", "clj", "cljc", "cljs"]
content_regex: None
injection_regex: None
```

The above output is somewhat atypical as far as the value of `parser`
is concerned because my `~/.config/tree-sitter/config.json` is:

```json
{
  "parser-directories": [
    "."
  ]
}
```

It's a long story that I won't go into here (^^;

The important thing is that the value associated with `parser` is
appropriate.

For example, in the above output, it is `"./tree-sitter-clojure"`,
which would match a setup where:

* `~/.config/tree-sitter/config.json` had the content mentioned above
* `tree-sitter dump-languages` was invoked from within this project's
  root directory
* tree-sitter-clojure was cloned to be a subdirectory of this project
  or it is a symlink in this project that resolves to a directory
  containing tree-sitter-clojure

I suspect most people don't set things up this way so YMMV.
