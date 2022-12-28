REM pass grammar.js as first argument to script
set grammarfile=%1

REM n.b. order of arguments seems to matter below
emacs --batch^
      --load=tsclj-jmassage.el^
      %grammarfile%^
      --funcall=tsclj-massage-and-save
