# Scope and Limits of tree-sitter-clojure

## TLDR

Only "primitives"
(e.g. [symbols](https://github.com/sogaiu/tree-sitter-clojure/blob/c00293fb0cd5ce3a7005c0601e9b546c1ea73094/grammar.js#L280-L282),
[lists](https://github.com/sogaiu/tree-sitter-clojure/blob/c00293fb0cd5ce3a7005c0601e9b546c1ea73094/grammar.js#L307-L309),
etc.) are supported, i.e. no higher level constructs like `defn`.

## The Details

### Why

For some background, Clojure (and other Lisps) have runtime extensible
"syntax" via macros, but AFAIU tree-sitter's current design assumes a
fixed syntax.

Keeping the above in mind, below are some of the factors that
influenced the current stance on scope:

* Clojure has no language specification.  This means it's unclear what
  to try to support in the grammar.  For example, `defn` is defined in
  the `clojure.core` namespace, but then so are a lot of other things.

* Each additional item added to the grammar increases the chance of a
  conflict which in turn may adversely impact correct parsing, but
  also makes the grammar harder to extend and maintain.  In some cases
  this may lead to degraded performance (though it may be premature to
  be concerned about this point).

### Alternatives

It is possible to [use tree-sitter-clojure as a
base](https://github.com/tree-sitter/tree-sitter/issues/645) to add
additional constructs to a "derived" grammar.  For example, such a
grammar might be specialized to look for "definitions".  At least in
[emacs-tree-sitter](https://github.com/ubolonton/emacs-tree-sitter),
[it is technically possibly to have multiple grammars be used on
single
buffer](https://github.com/ubolonton/emacs-tree-sitter/discussions/129#discussioncomment-502836):

> If you want 2 parse trees in the same buffer instead, you would need
> to define an advice for tree-sitter--do-parse, as well as additional
> buffer-local variables for the secondary grammar.

Apparently it became possible in September of 2020 for [queries to
match on any of a node's
supertypes](https://github.com/tree-sitter/tree-sitter/pull/738).  It
may be possible to make a list supertype that is "composed of" `defn`
and things that are not `defn`.
[tree-sitter-clojure-def](https://github.com/sogaiu/tree-sitter-clojure-def)
is an attempt at realizing this apoproach.

However, depending on one's goals, it might make more sense to
consider leveraging [clj-kondo's analysis
capabilities](https://github.com/clj-kondo/clj-kondo/tree/master/analysis)
as clj-kondo already understands Clojure pretty well. IIUC,
[clojure-lsp does
this](https://github.com/clojure-lsp/clojure-lsp/blob/14724457f0d553795dfe16317d3ee6c5fc97d4ba/deps.edn#L21).

## Other Limits

* Earlier attempts at adding `def` and friends resulted in
  unacceptably high error rates [1].  The tests were conducted against
  code from [Clojars](https://clojars.org/) (uncontrived code).  FWIW,
  two of the previous tree-sitter-clojure attempts (by
  [oakmac](https://github.com/oakmac/tree-sitter-clojure) and
  [Tavistock](https://github.com/Tavistock/tree-sitter-clojure)) also
  had unacceptably high error rates [2] and they both attempted to
  support higher level constructs.

* For use cases like structural editing, it seems important to be able
  to distinguish between the following sorts of cases:
    * `defn` used for defining a function, and
    *  [Using the symbol `defn` within a macro to construct code to define a function](https://github.com/Raynes/conch/blob/685f2c73138f376f2aa0623053dfdaba350a04f4/src/me/raynes/conch.clj#L251-L252)

    AFAICT, the approach taken in tree-sitter-clojure-def does not
    make telling these sorts of things apart possible.

* It doesn't seem possible to support all "defining" macros like `
  defsomething`
  (e.g. https://github.com/redplanetlabs/specter/blob/efaf35558a2c0068f5b6a8ef1dbbd0912702bdbd/src/clj/com/rpl/specter.cljc#L57-L60)
  since a user's Clojure code can define these.

* Tree-sitter has some limitations that may not get addressed.  One
  example is that it won't handle files that contain [null
  characters](https://en.wikipedia.org/wiki/Null_character).  [Clojure
  code can legally contain null
  characters](https://github.com/santifa/clj-dbase/blob/a1d6de1bfba3fd0a90efed837a6483e93f22524e/src/clj_dbase/core.clj#L121),
  but since [tree-sitter doesn't handle such
  information](https://github.com/tree-sitter/tree-sitter/issues/1167),
  neither does tree-sitter-clojure.  The use of null characters in
  Clojure source does not appear to be that common though :)

* Files that contain `{{` and `}}`for templating are often not strictly
  Clojure source, though once processed they may be.  Due to there
  being enough difficulties in getting ordinary correct Clojure code
  to be processed well, not much effort has been put toward handling
  these sorts of template files.  This is not likely to change.

* Due to [issues
  elsewhere](https://github.com/sogaiu/tree-sitter-clojure/pull/26),
  tree-sitter-clojure is currently using tree-sitter 0.19.3, not the
  latest 0.20.x series.  One way this could change is if [this
  issue](https://github.com/tree-sitter/tree-sitter/issues/1336) is
  addressed, or if it becomes clear that the [upcoming tree-sitter
  support in Emacs
  29](https://github.com/emacs-mirror/emacs/blob/d90d7d15f2f78c37b9a5c775e617ab6f5cd5fb01/etc/NEWS#L34-L69)
  makes support of
  [elisp-tree-sitter](https://github.com/emacs-tree-sitter/elisp-tree-sitter/)
  less of an issue.

## Footnotes

* [1] Author's opinion :)
* [2] Author's opinion again :)

## References

* https://www.reddit.com/r/Clojure/comments/fkc6uv/is_anyone_working_on_a_treesitter_parser_for/fksmf67/
* https://github.com/sogaiu/tree-sitter-clojure/issues/15#issuecomment-880729889
