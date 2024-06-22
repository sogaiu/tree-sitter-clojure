# Run Real-World Code Tests

## clojars

The `clojars` tests typically take longer than a minute if the full
set of samples has been fetched.

It is expected for there to be a certain number of errors.  Currently,
115 out of somewhat over 150,000 files parse with errors.

Assuming the same set of samples are being tested over, if the number
of errors reported differs from 115, it may be evidence of one of the
following:

* the grammar has changed and is behaving in unexpected ways
* tree-sitter behavior has changed

Examining the specifics (e.g. more errors, less errors, exactly which
files might be yielding different parse results, etc.) may help in
investigating what the cause(s) might be and determining what if any
action should be taken (e.g. modifying the grammar, communicating with
tree-sitter developers about tree-sitter behavior, etc.).

To aid in such spelunking, detailed information about expected errors
has been kept in the
[classify-parse-errors.tsv](../data/classify-parse-errors.tsv) file.

### classify-parse-errors.tsv

`classify-parse-errors.tsv` is a TSV file that stores information
about expected errors.  It has four fields:

* checksum - MD5 of the source file content
* description - brief description of error
* path - relative path to source file
* location - describes location of error

As detailed elsewhere, an effort is made to keep the source samples
deduplicated.  Because deduplication can lead to different "survivors"
/ "originals" remaining depending on the method chosen, the path of a
file is problematic as something that can be used to compare between
tests being run under different conditions (e.g. if two different
users perform deduplication differently or on somewhat different sets
of samples).  The checksum field is an attempt to address this issue.

The location indicates where in the file to look for evidence of the
error.  It can be one of:

* single line number
* comma-separated line numbers
* range of lines (e.g. X-Y)

All line numbers are 1-based.

Note that `classify-parse-errors.tsv` is not automatically updated.\,
but there is Emacs Lisp code that can aid in working with the file
(e.g. adding to it, viewing the location of a particular error, etc.).

### Expected Error Frequencies

To see a frequency table of the expected errors:

```
bb show-expected-errors
```

This should produce output like:

```
1    Bare colon
2    Caret used to mean wrap in meta call
1    Colon instead of semi colon
3    Commenting hid closing paren(s)
4    Dispatch macro hackery
1    Dispatch macro hackery via $, clarity
2    Dispatch macro hackery via chiara
3    Dispatch macro hackery via clarity
2    Extra closing curly brace(s)
10   Extra closing paren(s)
1    Extra closing square bracket(s)
9    Incomplete code
1    Keyword with @
1    Metadata with no metadatee
1    Mismatched number of discards
1    Missing closing delimiter for string
17   Missing closing paren(s)
3    Missing closing square bracket(s)
1    Partially converted file
1    Premature end of string by double quote
2    Stray characters
45   Template
1    Unescaped backslashes in string
2    Zero byte
---------------------------------------
115  Total
```

## clojuredart

The `clojuredart` tests don't take very long because there are not
many samples to test against.  ATM, no errors are expected.
