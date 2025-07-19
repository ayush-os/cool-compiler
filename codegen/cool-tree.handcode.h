#ifndef COOL_TREE_HANDCODE_H
#define COOL_TREE_HANDCODE_H

#include <iostream>
#include "tree.h"
#include "stringtab.h"
#define yylineno curr_lineno
extern int yylineno;

typedef bool Boolean;

inline Boolean copy_Boolean(Boolean b) {return b; }
inline void assert_Boolean(Boolean) {}
inline void dump_Boolean(ostream& stream, int padding, Boolean b)
	{ stream << pad(padding) << (int) b << "\n"; }

void dump_Symbol(ostream& stream, int padding, Symbol b);
void assert_Symbol(Symbol b);
Symbol copy_Symbol(Symbol b);

typedef const char* Register;

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
class CgenNode;
typedef CgenNode *CgenNodeP;
class CgenClassTable;
typedef CgenClassTable *CgenClassTableP;

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

#define Program_EXTRAS					\
  virtual void cgen(ostream&) = 0;			\
  virtual void dump_with_types(ostream&, int) = 0;

#define program_EXTRAS                          \
  void cgen(ostream&);     			\
  void dump_with_types(ostream&, int);

#define Class__EXTRAS					\
  virtual Symbol get_name() = 0;			\
  virtual Symbol get_parent() = 0;			\
  virtual Symbol get_filename() = 0;			\
  virtual Features get_features() = 0;  \
  virtual void dump_with_types(ostream&,int) = 0;

#define class__EXTRAS                                  \
  Symbol get_name()   { return name; }		       \
  Symbol get_parent() { return parent; }     	       \
  Symbol get_filename() { return filename; }	       \
  Features get_features() { return features; } \
  void dump_with_types(ostream&,int);

#define Feature_EXTRAS                                                                      \
  virtual Boolean is_attr() = 0;                                                            \
  virtual Symbol get_name() = 0;                                                            \
  virtual Symbol get_ret() = 0;                                                             \
  virtual Symbol get_type_decl() = 0;                                                        \
  virtual Formals get_formals() = 0;                                                        \
  virtual Expression get_expr() = 0;                                                        \
  virtual void dump_with_types(ostream &, int) = 0;

#define Feature_SHARED_EXTRAS					\
  Symbol get_name() { return name; } \
  void dump_with_types(ostream&,int);

#define Formal_EXTRAS                \
  virtual Symbol get_type_dec() = 0; \
  virtual Symbol get_name() = 0;     \
  virtual void dump_with_types(ostream &, int) = 0;

#define formal_EXTRAS                         \
  Symbol get_type_dec() { return type_decl; } \
  Symbol get_name() { return name; }          \
  void dump_with_types(ostream &, int);

#define attr_EXTRAS                                                             \
  Formals get_formals() { return NULL; }                                        \
  Symbol get_ret() { return NULL; }                                             \
  Symbol get_type_decl() { return type_decl; }                                   \
  Expression get_expr() { return init; }                                        \
  Boolean is_attr() { return true; };

#define method_EXTRAS                                                           \
  Formals get_formals() { return formals; }                                     \
  Symbol get_ret() { return return_type; }                                      \
  Symbol get_type_decl() { return NULL; }                                        \
  Expression get_expr() { return expr; }                                        \
  Boolean is_attr() { return false; };

#define Case_EXTRAS							\
  virtual void code(ostream&, CgenNodeP, CgenClassTableP, int) = 0;					\
  virtual Symbol get_type_decl() = 0; \
  virtual Symbol get_name() = 0; \
  virtual void dump_with_types(ostream& ,int) = 0;

#define branch_EXTRAS						\
  Symbol get_type_decl() { return type_decl; } \
  Symbol get_name() { return name; } \
  void code(ostream&, CgenNodeP, CgenClassTableP, int);						\
  void dump_with_types(ostream& ,int);

#define Expression_EXTRAS					   \
  virtual void code(ostream&, CgenNodeP, CgenClassTableP, int) = 0;				   \
  Symbol type;							   \
  Symbol get_type() { return type; }				   \
  Expression set_type(Symbol s) { type = s; return this; }	   \
  virtual void dump_with_types(ostream&,int) = 0;		   \
  void dump_type(ostream&, int);				   \
  inline virtual Boolean is_no_expr() { return false; } \
  Expression_class() { type = (Symbol) NULL; }

#define Expression_SHARED_EXTRAS				\
  void code(ostream&, CgenNodeP, CgenClassTableP, int); \
  void dump_with_types(ostream&,int);

#define int_const_EXTRAS \
  Symbol get_val() { return token; }

#define string_const_EXTRAS \
  Symbol get_val() { return token; }

#define no_expr_EXTRAS                         \
  inline Boolean is_no_expr() { return true; }

#endif  // COOL_TREE_HANDCODE_H
