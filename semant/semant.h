#ifndef SEMANT_H_
#define SEMANT_H_

#include <assert.h>
#include <vector>
#include "cool-tree.h"
#include "stringtab.h"
#include "symtab.h"

#define TRUE 1
#define FALSE 0

class InheritanceNode;
typedef InheritanceNode *InheritanceNodeP;
class ClassTable;
typedef ClassTable *ClassTableP;
typedef std::vector<InheritanceNodeP> InheritanceNodeList;
typedef InheritanceNodeList *InheritanceNodeListP;
typedef std::vector<Symbol> TypeList;
typedef TypeList *TypeListP;
typedef SymbolTable<Symbol, TypeList> MethodTable;
typedef MethodTable *MethodTableP;
typedef SymbolTable<Symbol, Entry> ObjectTable;
typedef ObjectTable *ObjectTableP;
typedef Symbol ClassName;
class Environment;
typedef Environment *EnvironmentP;

class Environment
{
public:
  MethodTableP _methods;
  ObjectTableP _objects;
  ClassName _class_name;

  Environment(Symbol);
};

class InheritanceNode
{
public:
  InheritanceNode(Symbol, Class_);

  Class_ _ref;
  InheritanceNodeP _parent;
  InheritanceNodeListP _children;
  EnvironmentP _env;

  Boolean is_ancestor(InheritanceNodeP);
};

class ClassTable : public SymbolTable<Symbol, InheritanceNode>
{
private:
  int semant_errors;
  Classes _classes;

  Classes install_basic_classes();
  void install_classes();

  void build_inheritance();
  void cycle_check();

  MethodTableP clone_methods(MethodTableP);
  ObjectTableP clone_objects(ObjectTableP);
  void percolate_env(InheritanceNodeP);

  void process_attr(InheritanceNodeP, Symbol, Feature);
  void process_method(InheritanceNodeP, Symbol, Feature);
  void check_overriden_method(InheritanceNodeP, Symbol, TypeListP, TypeListP, Feature);
  TypeListP create_method_type_list(Class_, Symbol, Feature);
  void populate_env(InheritanceNodeP);

  void main_req_check();

  std::ostream &error_stream;

public:
  Boolean leq(Symbol, Symbol, Symbol);
  Symbol lub(Symbol, Symbol, Symbol);

  ClassTable(Classes);

  int errors() { return semant_errors; }
  void error_out();
  std::ostream &semant_error();
  std::ostream &semant_error(Class_ c);
  std::ostream &semant_error(Symbol filename, tree_node *t);
};

#endif