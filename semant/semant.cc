
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <unordered_set>
#include "semant.h"
#include "utilities.h"

extern int semant_debug;
extern char *curr_filename;
extern int node_lineno;

//////////////////////////////////////////////////////////////////////
//
// Symbols
//
// For convenience, a large number of symbols are predefined here.
// These symbols include the primitive type and method names, as well
// as fixed names used by the runtime system.
//
//////////////////////////////////////////////////////////////////////
static Symbol
    arg,
    arg2,
    Bool,
    concat,
    cool_abort,
    copy,
    Int,
    in_int,
    in_string,
    IO,
    isProto,
    length,
    Main,
    main_meth,
    No_class,
    No_type,
    _BOTTOM_,
    Object,
    out_int,
    out_string,
    prim_slot,
    self,
    SELF_TYPE,
    Str,
    str_field,
    substr,
    type_name,
    val;
//
// Initializing the predefined symbols.
//
static void initialize_constants(void)
{
  arg = idtable.add_string("arg");
  arg2 = idtable.add_string("arg2");
  Bool = idtable.add_string("Bool");
  concat = idtable.add_string("concat");
  cool_abort = idtable.add_string("abort");
  ::copy = idtable.add_string("copy");
  Int = idtable.add_string("Int");
  in_int = idtable.add_string("in_int");
  in_string = idtable.add_string("in_string");
  IO = idtable.add_string("IO");
  isProto = idtable.add_string("isProto");
  length = idtable.add_string("length");
  Main = idtable.add_string("Main");
  main_meth = idtable.add_string("main");
  //   _no_class is a symbol that can't be the name of any
  //   user-defined class.
  No_class = idtable.add_string("_no_class");
  No_type = idtable.add_string("_no_type");
  // _BOTTOM_ is the symbol for the bottom of the lattice of types
  _BOTTOM_ = idtable.add_string("_bottom");
  Object = idtable.add_string("Object");
  out_int = idtable.add_string("out_int");
  out_string = idtable.add_string("out_string");
  prim_slot = idtable.add_string("_prim_slot");
  self = idtable.add_string("self");
  SELF_TYPE = idtable.add_string("SELF_TYPE");
  Str = idtable.add_string("String");
  str_field = idtable.add_string("_str_field");
  substr = idtable.add_string("substr");
  type_name = idtable.add_string("type_name");
  val = idtable.add_string("_val");
}

static const std::unordered_set<std::string> basic_classes = {"Object", "IO", "Int", "Bool", "String", "SELF_TYPE"};
static const std::unordered_set<std::string> uninheritable = {"Int", "Bool", "String", "SELF_TYPE"};
static const std::unordered_set<std::string> eq_type_set = {"Int", "Bool", "String"};

Symbol assign_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_prime = this->expr->type_check(cur_class, class_table, env);
  Symbol id = this->name;

  if (id == self)
    class_table->semant_error(cur_class->get_filename(), this) << "Cannot assign to 'self'." << endl;

  Symbol t = env->_objects->lookup(id);
  if (t || id == self)
  {
    if (!(class_table->leq(t, t_prime, cur_class->get_name())))
      class_table->semant_error(cur_class->get_filename(), this) << "Type " << t_prime << " of assigned expression does not conform to declared type " << t << " of identifier " << id << "." << endl;
  }
  else
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Assignment to undeclared variable " << id << "." << endl;
  }

  this->set_type(t_prime);
  return t_prime;
}

Symbol static_dispatch_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_zero = this->expr->type_check(cur_class, class_table, env);
  Symbol t = this->type_name, f = this->name;
  Expressions actual_ls = this->actual;

  TypeList actual_types;
  for (int i = actual_ls->first(); actual_ls->more(i); i = actual_ls->next(i))
    actual_types.emplace_back(actual_ls->nth(i)->type_check(cur_class, class_table, env));

  if (t == SELF_TYPE)
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Static dispatch to SELF_TYPE." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }

  if (!class_table->lookup(t))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Static dispatch to undefined class " << t << "." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }

  if (!class_table->leq(t, t_zero, cur_class->get_name()))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Expression type " << t_zero << " does not conform to declared static dispatch type " << t << "." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }

  TypeListP formal_types = class_table->lookup(t)->_env->_methods->lookup(f);
  if (!formal_types)
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Static dispatch to undefined method " << f << "." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }

  if (formal_types->size() - 1 != static_cast<size_t>(actual_ls->len()))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Method " << f << " invoked with wrong number of arguments." << endl;
  }
  else
  {
    for (size_t i = 0; i < actual_types.size(); i++)
    {
      if (!(class_table->leq(formal_types->at(i), actual_types[i], cur_class->get_name())))
        class_table->semant_error(cur_class->get_filename(), this) << "In call of method " << f << ", type " << actual_types[i] << " does not conform to declared type " << formal_types->at(i) << "." << endl;
    }
  }

  Symbol t_n_plus_one_prime = formal_types->at(formal_types->size() - 1);
  Symbol t_n_plus_one = (t_n_plus_one_prime == SELF_TYPE) ? t_zero : t_n_plus_one_prime;

  this->set_type(t_n_plus_one);
  return t_n_plus_one;
}

Symbol dispatch_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_zero = this->expr->type_check(cur_class, class_table, env);
  Symbol method_name = this->name;
  Expressions actual_ls = this->actual;

  TypeList actual_types;
  for (int i = actual_ls->first(); actual_ls->more(i); i = actual_ls->next(i))
    actual_types.emplace_back(actual_ls->nth(i)->type_check(cur_class, class_table, env));

  Symbol t_zero_prime = t_zero;
  if (t_zero == SELF_TYPE)
    t_zero_prime = cur_class->get_name();

  if (t_zero_prime == _BOTTOM_)
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Dispatch on type _bottom not allowed.  The type _bottom is the type of throw expressions." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }
  if (!(class_table->lookup(t_zero_prime)))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Dispatch on undefined class " << t_zero_prime << "." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }

  TypeListP formal_types = class_table->lookup(t_zero_prime)->_env->_methods->lookup(method_name);
  if (!formal_types)
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Dispatch to undefined method " << method_name << "." << endl;
    this->type = _BOTTOM_;
    return _BOTTOM_;
  }
  else if (formal_types->size() - 1 != static_cast<size_t>(actual_ls->len()))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Method " << method_name << " called with wrong number of arguments." << endl;
  }
  else
  {
    for (size_t i = 0; i < actual_types.size(); i++)
    {
      if (!(class_table->leq(formal_types->at(i), actual_types[i], cur_class->get_name())))
        class_table->semant_error(cur_class->get_filename(), this) << "In call of method " << method_name << ", type " << actual_types[i] << " does not conform to declared type " << formal_types->at(i) << "." << endl;
    }
  }

  Symbol t_n_plus_one_prime = formal_types->at(formal_types->size() - 1);
  Symbol t_n_plus_one = (t_n_plus_one_prime == SELF_TYPE) ? t_zero : t_n_plus_one_prime;

  this->set_type(t_n_plus_one);
  return t_n_plus_one;
}

Symbol cond_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->pred->type_check(cur_class, class_table, env);
  if (t_one != Bool)
    class_table->semant_error(cur_class->get_filename(), this) << "Predicate of 'if' does not have type Bool." << endl;

  Symbol t_two = this->then_exp->type_check(cur_class, class_table, env);
  Symbol t_three = this->else_exp->type_check(cur_class, class_table, env);

  Symbol lub = class_table->lub(t_two, t_three, cur_class->get_name());
  this->set_type(lub);
  return lub;
}

Symbol loop_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  if (this->pred->type_check(cur_class, class_table, env) != Bool)
    class_table->semant_error(cur_class->get_filename(), this) << "Loop condition does not have type Bool." << endl;

  this->body->type_check(cur_class, class_table, env);

  this->set_type(Object);
  return Object;
}

Symbol typcase_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  this->expr->type_check(cur_class, class_table, env);
  Cases cases = this->cases;
  std::vector<Symbol> types_ls;
  std::unordered_set<Symbol> unique_types;

  for (int i = cases->first(); cases->more(i); i = cases->next(i))
  {
    Case c = cases->nth(i);
    Symbol c_name = c->get_branch_name();
    Symbol c_type = c->get_branch_type();

    if (c_name == self)
      class_table->semant_error(cur_class->get_filename(), c) << "'self' bound in 'case'." << endl;
    if (c_type == SELF_TYPE)
      class_table->semant_error(cur_class->get_filename(), c) << "Identifier " << c_name << " declared with type SELF_TYPE in case branch." << endl;

    if (unique_types.count(c_type))
      class_table->semant_error(cur_class->get_filename(), c) << "Duplicate branch " << c_type << " in case statement." << endl;
    if (c_type != SELF_TYPE && !class_table->lookup(c_type))
      class_table->semant_error(cur_class->get_filename(), c) << "Class " << c_type << " of case branch is undefined." << endl;

    unique_types.insert(c_type);

    env->_objects->enterscope();
    env->_objects->addid(c_name, c_type);
    Symbol c_expr_type = c->get_branch_expr()->type_check(cur_class, class_table, env);
    env->_objects->exitscope();

    types_ls.emplace_back(c_expr_type);
  }

  while (types_ls.size() > 1)
  {
    Symbol type_one = types_ls.back();
    types_ls.pop_back();
    Symbol type_two = types_ls.back();
    types_ls.pop_back();

    types_ls.emplace_back(class_table->lub(type_one, type_two, cur_class->get_name()));
  }

  this->type = types_ls[0];
  return types_ls[0];
}

Symbol block_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Expressions expr_ls = this->body;
  Symbol ret = Object;

  for (int i = expr_ls->first(); expr_ls->more(i); i = expr_ls->next(i))
    ret = expr_ls->nth(i)->type_check(cur_class, class_table, env);

  this->set_type(ret);
  return ret;
}

Symbol let_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol id = this->identifier;
  Symbol t_zero = this->type_decl;

  if (id == self)
    class_table->semant_error(cur_class->get_filename(), this) << "'self' cannot be bound in a 'let' expression." << endl;

  Boolean type_exists = (class_table->lookup(t_zero)) || t_zero == SELF_TYPE;

  if (!type_exists)
    class_table->semant_error(cur_class->get_filename(), this) << "Class " << t_zero << " of let-bound identifier " << id << " is undefined." << endl;

  if (!(this->init->is_no_expr()))
  {
    Symbol t_one = this->init->type_check(cur_class, class_table, env);
    if (type_exists && !class_table->leq(t_zero, t_one, cur_class->get_name()))
      class_table->semant_error(cur_class->get_filename(), this) << "Inferred type " << t_one
                                                                 << " of initialization of " << id
                                                                 << " does not conform to identifier's declared type " << t_zero << "." << endl;
  }

  env->_objects->enterscope();
  env->_objects->addid(id, t_zero);
  Symbol t_two = this->body->type_check(cur_class, class_table, env);
  env->_objects->exitscope();

  this->set_type(t_two);
  return t_two;
}

Symbol plus_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);
  if (t_one != Int || t_two != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "non-Int arguments: " << t_one << " + " << t_two << endl;

  this->set_type(Int);
  return Int;
}

Symbol sub_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);
  if (t_one != Int || t_two != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "non-Int arguments: " << t_one << " - " << t_two << endl;

  this->set_type(Int);
  return Int;
}

Symbol mul_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);
  if (t_one != Int || t_two != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "non-Int arguments: " << t_one << " * " << t_two << endl;

  this->set_type(Int);
  return Int;
}

Symbol divide_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);
  if (t_one != Int || t_two != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "non-Int arguments: " << t_one << " / " << t_two << endl;

  this->set_type(Int);
  return Int;
}

Symbol neg_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  if (t_one != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "Argument of '~' has type " << t_one << " instead of Int." << endl;

  this->set_type(Int);
  return Int;
}

Symbol lt_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);
  if (t_one != Int || t_two != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "non-Int arguments: " << t_one << " < " << t_two << endl;

  this->set_type(Bool);
  return Bool;
}

Symbol eq_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);
  if (eq_type_set.count(t_one->get_string()) || eq_type_set.count(t_two->get_string()))
  {
    if (t_one != t_two)
      class_table->semant_error(cur_class->get_filename(), this) << "Illegal comparison with a basic type." << endl;
  }
  this->set_type(Bool);
  return Bool;
}

Symbol leq_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);
  Symbol t_two = this->e2->type_check(cur_class, class_table, env);

  if (t_one != Int || t_two != Int)
    class_table->semant_error(cur_class->get_filename(), this) << "non-Int arguments: " << t_one << " <= " << t_two << endl;

  this->set_type(Bool);
  return Bool;
}

Symbol comp_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t_one = this->e1->type_check(cur_class, class_table, env);

  if (t_one != Bool)
    class_table->semant_error(cur_class->get_filename(), this) << "Argument of 'not' has type " << t_one << " instead of Bool." << endl;

  this->set_type(Bool);
  return Bool;
}

Symbol int_const_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  this->set_type(Int);
  return Int;
}

Symbol bool_const_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  this->set_type(Bool);
  return Bool;
}

Symbol string_const_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  this->set_type(Str);
  return Str;
}

Symbol new__class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol t = this->type_name;

  if (t != SELF_TYPE && !class_table->lookup(t))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "'new' used with undefined class " << t << "." << endl;
    t = _BOTTOM_;
  }

  this->set_type(t);
  return t;
}

Symbol isvoid_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  this->e1->type_check(cur_class, class_table, env);
  this->set_type(Bool);
  return Bool;
}

Symbol no_expr_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  this->set_type(No_type);
  return No_type;
}

Symbol object_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Symbol id = this->name;
  Symbol t = env->_objects->lookup(id);

  if (!t)
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Undeclared identifier " << id << "." << endl;
    t = _BOTTOM_;
  }

  this->set_type(t);
  return t;
}

void method_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  env->_objects->enterscope();
  Formals formals = this->formals;

  for (int i = formals->first(); formals->more(i); i = formals->next(i))
  {
    Formal cur = formals->nth(i);
    Symbol t = cur->get_type_dec();
    Symbol name = cur->get_name();

    if (t != SELF_TYPE && !class_table->lookup(t))
      class_table->semant_error(cur_class->get_filename(), this) << "Class " << t << " of formal parameter " << name << " is undefined." << endl;

    env->_objects->addid(name, t);
  }
  env->_objects->addid(self, SELF_TYPE);

  Symbol t_zero_prime = this->expr->type_check(cur_class, class_table, env);
  Symbol t_zero = this->return_type;

  if (t_zero != SELF_TYPE && !class_table->lookup(t_zero))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Undefined return type " << t_zero << " in method " << this->get_name() << "." << endl;
  }
  else if (!(class_table->leq(t_zero, t_zero_prime, cur_class->get_name())))
  {
    class_table->semant_error(cur_class->get_filename(), this) << "Inferred return type " << t_zero_prime << " of method " << this->get_name() << " does not conform to declared return type " << t_zero << "." << endl;
  }

  env->_objects->exitscope();
}

void attr_class::type_check(Class_ cur_class, ClassTableP class_table, EnvironmentP env)
{
  Expression e_one = this->get_expr();
  Symbol t_zero = this->get_type_dec();
  Boolean type_exists = (class_table->lookup(t_zero)) || t_zero == SELF_TYPE;

  if (!type_exists)
    class_table->semant_error(cur_class->get_filename(), this) << "Class " << t_zero << " of attribute " << this->get_name() << " is undefined." << endl;

  if (!(e_one->is_no_expr()))
  {
    env->_objects->enterscope();
    env->_objects->addid(self, SELF_TYPE);
    Symbol t_one = e_one->type_check(cur_class, class_table, env);

    if (type_exists && !(class_table->leq(t_zero, t_one, cur_class->get_name())))
      class_table->semant_error(cur_class->get_filename(), this) << "Inferred type " << t_one
                                                                 << " of initialization of attribute " << this->get_name()
                                                                 << " does not conform to declared type " << t_zero << "." << endl;

    env->_objects->exitscope();
  }
}

void type_check(ClassTableP c)
{
  for (const auto &cur : c->gettable().front())
  {
    if (basic_classes.count(cur.get_id()->get_string()))
      continue;

    InheritanceNodeP c_node = cur.get_info();
    Features c_features = c_node->_ref->get_features();

    for (int i = c_features->first(); c_features->more(i); i = c_features->next(i))
      c_features->nth(i)->type_check(c_node->_ref, c, c_node->_env);
  }
}

Symbol ClassTable::lub(Symbol type_one, Symbol type_two, Symbol C)
{
  if (type_one == No_type || type_one == _BOTTOM_)
    return type_two;
  if (type_two == No_type || type_two == _BOTTOM_)
    return type_one;
  if (type_one == SELF_TYPE && type_two == SELF_TYPE)
    return SELF_TYPE;
  if (type_one == SELF_TYPE)
    type_one = C;
  if (type_two == SELF_TYPE)
    type_two = C;

  InheritanceNodeP node_one = this->lookup(type_one);
  InheritanceNodeP node_two = this->lookup(type_two);

  if (node_one && node_two)
  {
    while (node_one->_ref->get_name() != Object && node_two->_ref->get_name() != Object)
    {
      if (node_one->is_ancestor(node_two))
        return node_one->_ref->get_name();
      if (node_two->is_ancestor(node_one))
        return node_two->_ref->get_name();

      node_one = node_one->_parent;
      node_two = node_two->_parent;
    }
  }

  return Object;
}

Boolean ClassTable::leq(Symbol ancestor, Symbol child, Symbol C)
{
  if (child == _BOTTOM_ || child == No_type)
    return true;
  if (ancestor == SELF_TYPE && child == SELF_TYPE)
    return true;
  if (ancestor == SELF_TYPE)
    return false;
  if (child == SELF_TYPE)
    child = C;

  InheritanceNodeP ancestor_node = this->lookup(ancestor);
  InheritanceNodeP child_node = this->lookup(child);

  if (ancestor_node && child_node)
    return ancestor_node->is_ancestor(child_node);

  return true;
}

void ClassTable::error_out()
{
  if (this->errors())
  {
    cerr << "Compilation halted due to static semantic errors." << endl;
    exit(1);
  }
}

void ClassTable::main_req_check()
{
  InheritanceNodeP main_node = this->lookup(Main);

  if (!main_node)
  {
    semant_error() << "Class Main is not defined." << endl;
    return;
  }

  Features m_features = main_node->_ref->get_features();

  for (int i = m_features->first(); m_features->more(i); i = m_features->next(i))
  {
    Feature cur = m_features->nth(i);

    if (!cur->is_attr() && (cur->get_name() == main_meth))
    {
      if (cur->get_formals()->len())
        semant_error(main_node->_ref) << "'main' method in class Main should have no arguments." << endl;
      return;
    }
  }

  semant_error(main_node->_ref) << "No 'main' method in class Main." << endl;
}

ObjectTableP ClassTable::clone_objects(ObjectTableP cur)
{
  ObjectTableP ret = new ObjectTable;
  ret->enterscope();

  for (const auto &obj : cur->gettable().front())
    ret->addid(obj.get_id(), obj.get_info());

  return ret;
}

MethodTableP ClassTable::clone_methods(MethodTableP cur)
{
  MethodTableP ret = new MethodTable;
  ret->enterscope();

  for (const auto &method : cur->gettable().front())
  {
    TypeListP new_val = new TypeList();

    for (const auto &type : *(method.get_info()))
      new_val->push_back(type);

    ret->addid(method.get_id(), new_val);
  }

  return ret;
}

void ClassTable::percolate_env(InheritanceNodeP cur)
{
  populate_env(cur);

  for (InheritanceNodeP child : *(cur->_children))
  {
    child->_env->_objects = clone_objects(cur->_env->_objects);
    child->_env->_methods = clone_methods(cur->_env->_methods);
    percolate_env(child);
  }
}

void ClassTable::populate_env(InheritanceNodeP c_node)
{
  Features features = c_node->_ref->get_features();

  for (int i = features->first(); features->more(i); i = features->next(i))
  {
    Feature cur = features->nth(i);

    if (cur->is_attr())
    {
      process_attr(c_node, cur->get_name(), cur);
    }
    else
    {
      process_method(c_node, cur->get_name(), cur);
    }
  }
}

void ClassTable::process_attr(InheritanceNodeP c_node, Symbol attr_name, Feature attr)
{
  if (attr_name == self)
  {
    semant_error(c_node->_ref->get_filename(), attr) << "'self' cannot be the name of an attribute." << endl;
    return;
  }

  if (c_node->_env->_objects->lookup(attr_name))
  {
    if (c_node->_parent && c_node->_parent->_env->_objects->lookup(attr_name))
    {
      semant_error(c_node->_ref->get_filename(), attr) << "Attribute " << attr_name << " is an attribute of an inherited class." << endl;
    }
    else
    {
      semant_error(c_node->_ref->get_filename(), attr) << "Attribute " << attr_name << " is multiply defined in class." << endl;
    }
  }
  c_node->_env->_objects->addid(attr_name, attr->get_type_dec());
}

void ClassTable::process_method(InheritanceNodeP c_node, Symbol method_name, Feature method)
{
  TypeListP method_type_list = create_method_type_list(c_node->_ref, method_name, method);

  if (c_node->_env->_methods->lookup(method_name))
  {
    TypeListP parent_method = c_node->_parent->_env->_methods->lookup(method_name);
    if (!parent_method)
    {
      semant_error(c_node->_ref->get_filename(), method) << "Method " << method_name << " is multiply defined." << endl;
    }
    else
    {
      check_overriden_method(c_node, method_name, method_type_list, parent_method, method);
    }
  }
  c_node->_env->_methods->addid(method_name, method_type_list);
}

void ClassTable::check_overriden_method(InheritanceNodeP c_node, Symbol method_name, TypeListP method_ls, TypeListP parent_method_ls, Feature method)
{
  size_t method_types_sz = method_ls->size();
  size_t parent_types_sz = parent_method_ls->size();

  Symbol method_ret_type = method_ls->at(method_types_sz - 1);
  Symbol parent_ret_type = parent_method_ls->at(parent_types_sz - 1);

  if (method_ret_type != parent_ret_type)
  {
    semant_error(c_node->_ref->get_filename(), method) << "In redefined method " << method_name << ", return type " << method_ret_type << " is different from original return type " << parent_ret_type << "." << endl;
  }
  else if (method_types_sz != parent_types_sz)
  {
    semant_error(c_node->_ref->get_filename(), method) << "Incompatible number of formal parameters in redefined method " << method_name << "." << endl;
  }
  else
  {
    for (size_t i = 0; i < (method_types_sz - 1); i++)
    {
      Symbol type_m = method_ls->at(i);
      Symbol type_p = parent_method_ls->at(i);
      if (type_m != type_p)
        semant_error(c_node->_ref->get_filename(), method) << "In redefined method " << method_name << ", parameter type " << type_m << " is different from original type " << type_p << endl;
    }
  }
}

TypeListP ClassTable::create_method_type_list(Class_ c, Symbol method_name, Feature method)
{
  TypeListP type_list = new TypeList();
  std::unordered_set<Symbol> formal_ids;
  Formals formals = method->get_formals();

  for (int j = formals->first(); formals->more(j); j = formals->next(j))
  {
    Formal f = formals->nth(j);
    Symbol f_type = f->get_type_dec(), f_name = f->get_name();

    if (formal_ids.count(f_name))
      semant_error(c->get_filename(), method) << "Formal parameter " << f_name << " is multiply defined." << endl;
    if (f_name == self)
      semant_error(c->get_filename(), method) << "'self' cannot be the name of a formal parameter." << endl;
    if (f_type == SELF_TYPE)
      semant_error(c->get_filename(), method) << "Formal parameter " << f_name << " cannot have type SELF_TYPE." << endl;

    formal_ids.insert(f_name);
    type_list->push_back(f_type);
  }

  type_list->push_back(method->get_ret());
  return type_list;
}

Environment::Environment(Symbol class_name) : _methods(new MethodTable), _objects(new ObjectTable), _class_name(class_name)
{
  this->_methods->enterscope(), this->_objects->enterscope(), this->_objects->addid(self, SELF_TYPE);
}

InheritanceNode::InheritanceNode(Symbol class_name, Class_ ref) : _ref(ref), _parent(nullptr), _children(new InheritanceNodeList), _env(new Environment(class_name))
{
}

ClassTable::ClassTable(Classes classes) : semant_errors(0), error_stream(cerr)
{
  _classes = append_Classes(install_basic_classes(), classes);

  install_classes();
  build_inheritance();
  error_out();

  cycle_check();
  error_out();

  main_req_check();
  percolate_env(this->lookup(Object));
}

Boolean InheritanceNode::is_ancestor(InheritanceNodeP i_node)
{
  if (this == i_node)
  {
    return true;
  }
  else if (!(this->_children->size()))
  {
    return false;
  }
  else
  {
    bool res = false;
    for (InheritanceNodeP child : *(this->_children))
      res = res || child->is_ancestor(i_node);
    return res;
  }
}

void ClassTable::cycle_check()
{
  for (const auto &cur_class : this->gettable().front())
  {
    Symbol name = cur_class.get_id();
    InheritanceNodeP node = cur_class.get_info();

    for (InheritanceNodeP child : *(node->_children))
      if (child->is_ancestor(node))
        semant_error(node->_ref) << "Class " << name << ", or an ancestor of " << name << ", is involved in an inheritance cycle." << endl;
  }
}

void ClassTable::build_inheritance()
{
  for (const auto &cur_class : this->gettable().front())
  {
    Symbol name = cur_class.get_id();
    InheritanceNodeP node = cur_class.get_info();
    Symbol parent = node->_ref->get_parent();

    if (parent == No_class)
      return;

    if (uninheritable.count(parent->get_string()))
    {
      semant_error(node->_ref) << "Class " << name << " cannot inherit class " << parent << "." << endl;
    }
    else if (InheritanceNodeP parent_node = this->probe(parent))
    {
      node->_parent = parent_node;
      parent_node->_children->emplace_back(node);
    }
    else
    {
      semant_error(node->_ref) << "Class " << name << " inherits from an undefined class " << parent << "." << endl;
    }
  }
}

void ClassTable::install_classes()
{
  this->enterscope();

  for (int i = _classes->first(); _classes->more(i); i = _classes->next(i))
  {
    Class_ cur = _classes->nth(i);
    Symbol cur_name = cur->get_name();

    if (this->probe(cur_name) || cur_name == SELF_TYPE)
    {
      if (basic_classes.count(cur_name->get_string()))
      {
        semant_error(cur) << "Redefinition of basic class " << cur_name << "." << endl;
      }
      else
      {
        semant_error(cur) << "Class " << cur_name << " was previously defined." << endl;
      }
    }

    InheritanceNodeP cur_node = new InheritanceNode(cur_name, cur);
    this->addid(cur_name, cur_node);
  }
}

Classes ClassTable::install_basic_classes()
{
  node_lineno = 0;
  Symbol filename = stringtable.add_string("<basic class>");

  Class_ Object_class =
      class_(Object,
             No_class,
             append_Features(
                 append_Features(
                     single_Features(method(cool_abort, nil_Formals(), Object, no_expr())),
                     single_Features(method(type_name, nil_Formals(), Str, no_expr()))),
                 single_Features(method(::copy, nil_Formals(), SELF_TYPE, no_expr()))),
             filename);

  Class_ IO_class =
      class_(IO,
             Object,
             append_Features(
                 append_Features(
                     append_Features(
                         single_Features(method(out_string, single_Formals(formal(arg, Str)),
                                                SELF_TYPE, no_expr())),
                         single_Features(method(out_int, single_Formals(formal(arg, Int)),
                                                SELF_TYPE, no_expr()))),
                     single_Features(method(in_string, nil_Formals(), Str, no_expr()))),
                 single_Features(method(in_int, nil_Formals(), Int, no_expr()))),
             filename);

  Class_ Int_class =
      class_(Int,
             Object,
             single_Features(attr(val, prim_slot, no_expr())),
             filename);

  Class_ Bool_class =
      class_(Bool, Object, single_Features(attr(val, prim_slot, no_expr())), filename);

  Class_ Str_class =
      class_(Str,
             Object,
             append_Features(
                 append_Features(
                     append_Features(
                         append_Features(
                             single_Features(attr(val, Int, no_expr())),
                             single_Features(attr(str_field, prim_slot, no_expr()))),
                         single_Features(method(length, nil_Formals(), Int, no_expr()))),
                     single_Features(method(concat,
                                            single_Formals(formal(arg, Str)),
                                            Str,
                                            no_expr()))),
                 single_Features(method(substr,
                                        append_Formals(single_Formals(formal(arg, Int)),
                                                       single_Formals(formal(arg2, Int))),
                                        Str,
                                        no_expr()))),
             filename);

  return append_Classes(
      append_Classes(
          append_Classes(
              append_Classes(
                  single_Classes(Object_class),
                  single_Classes(IO_class)),
              single_Classes(Int_class)),
          single_Classes(Bool_class)),
      single_Classes(Str_class));
}

ostream &ClassTable::semant_error(Class_ c)
{
  return semant_error(c->get_filename(), c);
}

ostream &ClassTable::semant_error(Symbol filename, tree_node *t)
{
  error_stream << filename << ":" << t->get_line_number() << ": ";
  return semant_error();
}

ostream &ClassTable::semant_error()
{
  semant_errors++;
  return error_stream;
}

void program_class::semant()
{
  initialize_constants();

  ClassTableP classtable = new ClassTable(classes);

  type_check(classtable);

  classtable->error_out();
}