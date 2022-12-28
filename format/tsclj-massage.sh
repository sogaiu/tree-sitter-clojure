#! /bin/sh

# pass grammar.js as first argument to script

# n.b. order of arguments seems to matter below
emacs --batch \
      --load=tsclj-massage.el \
      $1 \
      --funcall=tsclj-massage-and-save

