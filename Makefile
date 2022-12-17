.PHONY: run
run: bug
	./bug

bug: bug.c tree-sitter/libtree-sitter.a src/parser.c
	cc bug.c -o bug -I tree-sitter/lib/include src/parser.c tree-sitter/libtree-sitter.a

src/parser.c: grammar.js
	tree-sitter generate

tree-sitter/libtree-sitter.a: tree-sitter
	$(MAKE) -C tree-sitter

tree-sitter:
	git clone https://github.com/tree-sitter/tree-sitter.git
