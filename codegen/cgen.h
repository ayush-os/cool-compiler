#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <vector>
#include "cool-tree.h"
#include "emit.h"
#include "symtab.h"
#include <optional>

enum Basicness
{
  Basic,
  NotBasic
};
#define TRUE 1
#define FALSE 0

class CgenClassTable;
typedef CgenClassTable *CgenClassTableP;

class CgenNode;
typedef CgenNode *CgenNodeP;

struct Variable
{
  Feature nd;
  int offset;
  Register reg;
  Variable(const Feature &attr, const int offset, Register reg) : nd(attr), offset(offset), reg(reg) {}
  Variable(const int offset, Register reg) : nd(NULL), offset(offset), reg(reg) {}
};

struct Method
{
  Symbol class_name;
  Feature nd;
  int offset;
  
  Method() = default;
  Method(const Symbol &class_name, const Feature &nd, int offset)
      : class_name(class_name), nd(nd), offset(offset) {}
};

class CgenClassTable : public SymbolTable<Symbol, CgenNode>
{
private:
  std::list<CgenNodeP> nds;
  std::ostream &str;
  int next_tag;

  void code_global_data();
  void code_global_text();
  void code_bools();
  void code_select_gc();
  void code_constants();

  void code_tree(CgenNodeP);
  void code_class_nameTab(CgenNodeP);
  void code_class_objTab(CgenNodeP);

  void code_init(CgenNodeP);
  void code_methods(CgenNodeP);

  void install_basic_classes();
  void install_class(CgenNodeP nd);
  void install_classes(Classes cs);
  void build_inheritance_tree();
  void install_tags(CgenNodeP);
  void set_relations(CgenNodeP nd);

public:
  CgenClassTable(Classes, std::ostream &str);
  void code();
  CgenNodeP root();
  SymbolTable<Symbol, int> class_to_tag_table;
};

class CgenNode : public class__class
{
private:
  CgenNodeP parentnd;
  std::list<CgenNodeP> children;
  Basicness basic_status;

public:
  SymbolTable<Symbol, Variable> variables;
  std::vector<Method> methods;

  CgenNode(Class_ c,
           Basicness bstatus,
           CgenClassTableP class_table);

  void add_child(CgenNodeP child);
  std::list<CgenNodeP> &get_children() { return children; }
  void set_parentnd(CgenNodeP p);
  CgenNodeP get_parentnd();
  int basic() { return (basic_status == Basic); }

  void code(ostream &s, const int &);
  void insert_method(const Feature &, int &);

  void code_prot_obj(ostream &s, const int &);
  void code_disp_tab(ostream &s);

  void code_methods(ostream &s, CgenClassTableP);
  void code_method(ostream &s, Feature &f, CgenClassTableP);
  
  void code_init(ostream &s, CgenClassTableP);
};

class BoolConst
{
private:
  int val;

public:
  BoolConst(int);
  void code_def(std::ostream &, int boolclasstag);
  void code_ref(std::ostream &) const;
};
