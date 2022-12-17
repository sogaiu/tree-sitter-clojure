#include <string.h>
#include <stdio.h>
#include <tree_sitter/api.h>


TSLanguage *tree_sitter_clojure();

void print_src(char *source) {
  printf("\n---------\n");
  char form1[11] = { 0 };
  strncpy(form1, source, 10);
  
  printf("%s", form1);

  char form2[12] = { 0 };
  strncpy(form2, source+10, 11);
  printf("%s", form2);

  char form3[13] = { 0 };
  strncpy(form3, source+21, 12);
  printf("%s", form3);
  printf("---------\n\n");
  return;
}

int main() {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_clojure());

  char *source =
    "(def x a)\n"  // 0-9
    "\n"           // 10
    "{def y 2}\n"  // 11-20
    "\n"           // 21
    "[def z 3]\n"; // 22-31

  print_src(source);
  
  TSTree *tree = ts_parser_parse_string(parser, NULL, source, strlen(source));

  TSNode root = ts_tree_root_node(tree);
  TSNode child;

  for (int i = 0; i < (int)strlen(source); ++i) {
    child = ts_node_first_child_for_byte(root, i);
    if (!ts_node_is_null(child)) {
      printf("Child at %i is %s %s\n", i, ts_node_type(child), ts_node_string(child));
    } else {
      printf("Child at %i is null\n", i);
    }
  }
  
  printf("\nParse tree:\n%s\n", ts_node_string(root));
  return 0;
}
