# Background

As Clojure lacks an official specification (like the sort of thing you
can find for Scheme or Common Lisp or other languages like C, Python,
etc.), creating a tree-sitter grammar for it was time-consuming and not
straight-forward in certain ways.

Expressing associated corpus tests was affected in a similar fashion
because vague and open-ended descriptions are sometimes not helpful in
these sorts of endeavors.

As an additional layer of testing, we tried running `tree-sitter
parse` over a gradually increasing amount of real-world code [1].  As
we carried this process out, we turned up constructs and usages of the
language that we were unaware of.  This helped in shaping the grammar
as well as expressing our corpus tests.

However, there is no guarantee that we captured all relevant patterns
that are expressed in the real world code we test against.  Thus we
recommend continuing to test against this large set of samples.

In Clojure's case, there is a significant amount of syntactically
correct code available within "latest release" jars on Clojars and we
retrieve about as much of it as it seems to be sensible to do
(currently somewhat over 20,000 jars).

---

[1] Other approaches were also tried, but these are not covered here.
