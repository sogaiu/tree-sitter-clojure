# Prepare Source Samples

## General Info

A set of samples is defined in `conf/conf.clj` like:

```clojure
(def clojars
  {:name "clojars"
   :root (str proj-root "/clojars-samples/data/clojars-repos")
   :extensions #{"bb" "nbb"
                 "clj" "cljc" "cljd" "cljr" "cljs" "cljx"
                 "dtm" "edn"}
   :error-file-paths (str proj-root "/data/clojars-error-files.txt")})
```

That is, `clojars` refers to a map with information about:

* where on the local filesystem to look for files
* which files to parse based on file extension
* where to store the paths of files that yielded errors

You can define your own map along with an appropriate directory and
set of files / directories, and then point `repos` at it.

## Clojars

### On the subject of speed...

Retrieving jars from Clojars can be a slow process.  Durations ranging
from 4.5 to 11 hours have been observed for fetching somewhat over
20,000 jars.  It's likely this depends a bit on where one is located
though.

### Which Jars Exactly?

The jars are retrieved using Babashka's
[http-client](https://github.com/babashka/http-client/) library, based
on a list in `data/clojars-jar-list.txt`.  This list already lives in
this repository, but a new one (which may end up with different
content) can be generated via a Babashka task.

The Babashka task fetches `data/feed.clj` from Clojars and creates a
list of URLs of "latest release" jars and saves this in the
aforementioned `data/clojars-jar-list.txt`.

Using a new list is not recommended unless you're willing to comb
through new error output.  Still, it might be worth it at some point
because when the current list was generated, files with certain
extensions were quite under-represented.

To make a new list, first remove:

* `data/feed.clj`
* `data/clojars-jar-list.txt`

then execute:

```
bb make-jars-list
```

### Example Invocations

To fetch 1000 jars, execute:

```
bb fetch-jars 1000
```

To fetch the maximum number of jars that makes sense to [1], try:

```
bb fetch-jars -1
```

Note that after fetching jars, the content needs to be extracted.
This can be done manually, but it's likely more convenient to do:

```
bb extract-jars
```

### Misc Info

It turns out that there can be duplicate files across the content of
extracted jars.  You may be able to speed up the testing process (and
reduce local storage usage) by deduplicating.  There used to be code
to do this, but it has been removed for maintenance reasons.  Likely
some existing deduplication program will work fine.
[rdfind](https://github.com/pauldreik/rdfind) is one option.

---

[1] For a certain defintions of "makes sense to" :)
