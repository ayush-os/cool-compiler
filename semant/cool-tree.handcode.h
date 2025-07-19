#ifndef COOL_TREE_HANDCODE_H
#define COOL_TREE_HANDCODE_H

#include <iostream>
#include "tree.h"
#include "stringtab.h"
#define yylineno curr_lineno
extern int yylineno;

typedef bool Boolean;
class Environment;
typedef Environment *EnvironmentP;
class ClassTable;
typedef ClassTable *ClassTableP;

inline Boolean copy_Boolean(Boolean b) { return b; }
inline void assert_Boolean(Boolean) {}
inline void dump_Boolean(ostream &stream, int padding, Boolean b)
{
  stream << pad(padding) << (int)b << "\n";
}

void dump_Symbol(ostream &stream, int padding, Symbol b);
void assert_Symbol(Symbol b);
Symbol copy_Symbol(Symbol b);

class Program_class;
typedef Program_class *Program;
class Class__class;
typedef Class__class *Class_;
class Feature_class;
typedef Feature_class *Feature;
class Formal_class;
typedef Formal_class *Formal;
class Expression_class;
typedef Expression_class *Expression;
class Case_class;
typedef Case_class *Case;

typedef list_node<Class_> Classes_class;
typedef Classes_class *Classes;
typedef list_node<Feature> Features_class;
typedef Features_class *Features;
typedef list_node<Formal> Formals_class;
typedef Formals_class *Formals;
typedef list_node<Expression> Expressions_class;
typedef Expressions_class *Expressions;
typedef list_node<Case> Cases_class;
typedef Cases_class *Cases;

#define Program_EXTRAS       \
  virtual void semant() = 0; \
  virtual void dump_with_types(ostream &, int) = 0;

#define program_EXTRAS \
  void semant();       \
  void dump_with_types(ostream &, int);

#define Class__EXTRAS                  \
  virtual Symbol get_name() = 0;       \
  virtual Symbol get_parent() = 0;     \
  virtual Features get_features() = 0; \
  virtual Symbol get_filename() = 0;   \
  virtual void dump_with_types(ostream &, int) = 0;

#define class__EXTRAS                          \
  Symbol get_name() { return name; }           \
  Symbol get_parent() { return parent; }       \
  Features get_features() { return features; } \
  Symbol get_filename() { return filename; }   \
  void dump_with_types(ostream &, int);

#define Feature_EXTRAS                                                                      \
  virtual Boolean is_attr() = 0;                                                            \
  virtual Symbol get_name() = 0;                                                            \
  virtual Symbol get_ret() = 0;                                                             \
  virtual Symbol get_type_dec() = 0;                                                        \
  virtual Formals get_formals() = 0;                                                        \
  virtual Expression get_expr() = 0;                                                        \
  virtual void type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env) = 0; \
  virtual void dump_with_types(ostream &, int) = 0;

#define attr_EXTRAS                                                             \
  Formals get_formals() { return NULL; }                                        \
  Symbol get_ret() { return NULL; }                                             \
  Symbol get_type_dec() { return type_decl; }                                   \
  Expression get_expr() { return init; }                                        \
  void type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env); \
  Boolean is_attr() { return true; };

#define method_EXTRAS                                                           \
  Formals get_formals() { return formals; }                                     \
  Symbol get_ret() { return return_type; }                                      \
  Symbol get_type_dec() { return NULL; }                                        \
  Expression get_expr() { return expr; }                                        \
  void type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env); \
  Boolean is_attr() { return false; };

#define Feature_SHARED_EXTRAS        \
  Symbol get_name() { return name; } \
  void dump_with_types(ostream &, int);

#define Formal_EXTRAS                \
  virtual Symbol get_type_dec() = 0; \
  virtual Symbol get_name() = 0;     \
  virtual void dump_with_types(ostream &, int) = 0;

#define formal_EXTRAS                         \
  Symbol get_type_dec() { return type_decl; } \
  Symbol get_name() { return name; }          \
  void dump_with_types(ostream &, int);

#define Case_EXTRAS                         \
  virtual Symbol get_branch_name() = 0;     \
  virtual Symbol get_branch_type() = 0;     \
  virtual Expression get_branch_expr() = 0; \
  virtual void dump_with_types(ostream &, int) = 0;

#define branch_EXTRAS                             \
  Symbol get_branch_name() { return name; };      \
  Symbol get_branch_type() { return type_decl; }; \
  Expression get_branch_expr() { return expr; };  \
  void dump_with_types(ostream &, int);

#define Expression_EXTRAS                                                                     \
  Symbol type;                                                                                \
  Symbol get_type() { return type; }                                                          \
  Expression set_type(Symbol s)                                                               \
  {                                                                                           \
    type = s;                                                                                 \
    return this;                                                                              \
  }                                                                                           \
  virtual void dump_with_types(ostream &, int) = 0;                                           \
  inline virtual Boolean is_no_expr() { return false; }                                       \
  virtual Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env) = 0; \
  void dump_type(ostream &, int);                                                             \
  Expression_class() { type = (Symbol)NULL; }

#define Expression_SHARED_EXTRAS \
  void dump_with_types(ostream &, int);

#define assign_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define static_dispatch_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define dispatch_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define cond_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define loop_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define typcase_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define block_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define let_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define plus_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define sub_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define mul_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define divide_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define neg_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define lt_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define eq_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define leq_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define comp_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define int_const_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define bool_const_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define string_const_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define new__EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define isvoid_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define no_expr_EXTRAS                         \
  inline Boolean is_no_expr() { return true; } \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#define object_EXTRAS \
  Symbol type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env);

#endif // COOL_TREE_HANDCODE_H
