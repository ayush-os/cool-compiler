#include "cgen.h"
#include "cgen_supp.h"
#include "handle_flags.h"
#include <unordered_set>
#include <map>

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
  length = idtable.add_string("length");
  Main = idtable.add_string("Main");
  main_meth = idtable.add_string("main");
  //   _no_class is a symbol that can't be the name of any
  //   user-defined class.
  No_class = idtable.add_string("_no_class");
  No_type = idtable.add_string("_no_type");
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

static const char *gc_init_names[] =
    {"_NoGC_Init", "_GenGC_Init", "_ScnGC_Init"};
static const char *gc_collect_names[] =
    {"_NoGC_Collect", "_GenGC_Collect", "_ScnGC_Collect"};

BoolConst falsebool(FALSE);
BoolConst truebool(TRUE);
int labelCounter = 0;

void program_class::cgen(ostream &os)
{
  initialize_constants();
  CgenClassTable *codegen_classtable = new CgenClassTable(classes, os);
}

static std::string get_label_ref(int l)
{
  std::stringstream ss;
  ss << l;
  std::string lbl = "label" + ss.str();
  return lbl;
}

static void emit_load(const char *dest_reg, int offset, const char *source_reg, ostream &s)
{
  s << LW << dest_reg << " " << offset * WORD_SIZE << "(" << source_reg << ")"
    << std::endl;
}

static void emit_store(const char *source_reg, int offset, const char *dest_reg, ostream &s)
{
  s << SW << source_reg << " " << offset * WORD_SIZE << "(" << dest_reg << ")"
    << std::endl;
}

static void emit_load_imm(const char *dest_reg, int val, ostream &s)
{
  s << LI << dest_reg << " " << val << std::endl;
}

static void emit_load_address(const char *dest_reg, const char *address, ostream &s)
{
  s << LA << dest_reg << " " << address << std::endl;
}

static void emit_partial_load_address(const char *dest_reg, ostream &s)
{
  s << LA << dest_reg << " ";
}

static void emit_load_bool(const char *dest, const BoolConst &b, ostream &s)
{
  emit_partial_load_address(dest, s);
  b.code_ref(s);
  s << std::endl;
}

static void emit_load_string(const char *dest, StringEntry *str, ostream &s)
{
  emit_partial_load_address(dest, s);
  str->code_ref(s);
  s << std::endl;
}

static void emit_load_int(const char *dest, IntEntry *i, ostream &s)
{
  emit_partial_load_address(dest, s);
  i->code_ref(s);
  s << std::endl;
}

static void emit_move(const char *dest_reg, const char *source_reg, ostream &s)
{
  s << MOVE << dest_reg << " " << source_reg << std::endl;
}

static void emit_neg(const char *dest, const char *src1, ostream &s)
{
  s << NEG << dest << " " << src1 << std::endl;
}

static void emit_add(const char *dest, const char *src1, const char *src2, ostream &s)
{
  s << ADD << dest << " " << src1 << " " << src2 << std::endl;
}

static void emit_addu(const char *dest, const char *src1, const char *src2, ostream &s)
{
  s << ADDU << dest << " " << src1 << " " << src2 << std::endl;
}

static void emit_addiu(const char *dest, const char *src1, int imm, ostream &s)
{
  s << ADDIU << dest << " " << src1 << " " << imm << std::endl;
}

static void emit_div(const char *dest, const char *src1, const char *src2, ostream &s)
{
  s << DIV << dest << " " << src1 << " " << src2 << std::endl;
}

static void emit_mul(const char *dest, const char *src1, const char *src2, ostream &s)
{
  s << MUL << dest << " " << src1 << " " << src2 << std::endl;
}

static void emit_sub(const char *dest, const char *src1, const char *src2, ostream &s)
{
  s << SUB << dest << " " << src1 << " " << src2 << std::endl;
}

static void emit_sll(const char *dest, const char *src1, int num, ostream &s)
{
  s << SLL << dest << " " << src1 << " " << num << std::endl;
}

static void emit_jalr(const char *dest, ostream &s)
{
  s << JALR << "\t" << dest << std::endl;
}

static void emit_jal(char *address, ostream &s)
{
  s << JAL << address << endl;
}

static void emit_return(ostream &s)
{
  s << RET << std::endl;
}

static void emit_gc_assign(ostream &s)
{
  s << JAL << "_GenGC_Assign" << std::endl;
}

static void emit_gc_assign_call(ostream &s, Register reg, int offset)
{
  if (cgen_Memmgr == GC_GENGC)
  {
    emit_addiu(A1, reg, offset * WORD_SIZE, s);
    emit_gc_assign(s);
  }
}

static void emit_disptable_ref(Symbol sym, ostream &s)
{
  s << sym << DISPTAB_SUFFIX;
}

static void emit_init_ref(Symbol sym, ostream &s)
{
  s << sym << CLASSINIT_SUFFIX;
}

static void emit_label_ref(int l, ostream &s)
{
  s << get_label_ref(l);
}

static void emit_protobj_ref(Symbol sym, ostream &s)
{
  s << sym << PROTOBJ_SUFFIX;
}

static void emit_method_ref(Symbol classname, Symbol methodname, ostream &s)
{
  s << classname << METHOD_SEP << methodname;
}

static void emit_label_def(int l, ostream &s)
{
  emit_label_ref(l, s);
  s << ":" << std::endl;
}

static void emit_beqz(const char *source, int label, ostream &s)
{
  s << BEQZ << source << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_beq(const char *src1, const char *src2, int label, ostream &s)
{
  s << BEQ << src1 << " " << src2 << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_bne(const char *src1, const char *src2, int label, ostream &s)
{
  s << BNE << src1 << " " << src2 << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_bleq(const char *src1, const char *src2, int label, ostream &s)
{
  s << BLEQ << src1 << " " << src2 << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_blt(const char *src1, const char *src2, int label, ostream &s)
{
  s << BLT << src1 << " " << src2 << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_blti(const char *src1, int imm, int label, ostream &s)
{
  s << BLT << src1 << " " << imm << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_bgti(const char *src1, int imm, int label, ostream &s)
{
  s << BGT << src1 << " " << imm << " ";
  emit_label_ref(label, s);
  s << std::endl;
}

static void emit_branch(int l, ostream &s)
{
  s << BRANCH;
  emit_label_ref(l, s);
  s << std::endl;
}

//
// Push a register on the stack. The stack grows towards smaller addresses.
//
static void emit_push(const char *reg, ostream &str)
{
  emit_store(reg, 0, SP, str);
  emit_addiu(SP, SP, -4, str);
}

//
// Fetch the integer value in an Int object. Emits code to fetch the integer
// value of the Integer object pointed to by register source into the register dest
//
static void emit_fetch_int(const char *dest, const char *source, ostream &s)
{
  emit_load(dest, DEFAULT_OBJFIELDS, source, s);
}

//
// Emits code to store the integer value contained in register source
// into the Integer object pointed to by dest.
//
static void emit_store_int(const char *source, const char *dest, ostream &s)
{
  emit_store(source, DEFAULT_OBJFIELDS, dest, s);
}

static void emit_test_collector(ostream &s)
{
  emit_push(ACC, s);
  emit_move(ACC, SP, s);  // stack end
  emit_move(A1, ZERO, s); // allocate nothing
  s << JAL << gc_collect_names[cgen_Memmgr] << endl;
  emit_addiu(SP, SP, 4, s);
  emit_load(ACC, 0, SP, s);
}

static void emit_gc_check(const char *source, ostream &s)
{
  if (strcmp(source, A1))
    emit_move(A1, source, s);
  s << JAL << "_gc_check" << std::endl;
}

static void emit_prologue(ostream &s)
{
  emit_addiu(SP, SP, -(WORD_SIZE * 3), s);
  emit_store(FP, 3, SP, s);
  emit_store(SELF, 2, SP, s);
  emit_store(RA, 1, SP, s);
  emit_addiu(FP, SP, WORD_SIZE * 4, s);
  emit_move(SELF, ACC, s);
}

static void emit_epilogue(ostream &s, int sp_offset = 0)
{
  emit_load(FP, 3, SP, s);
  emit_load(SELF, 2, SP, s);
  emit_load(RA, 1, SP, s);
  emit_addiu(SP, SP, 12 + (WORD_SIZE * sp_offset), s);
  emit_return(s);
}

//
// Strings
//
void StringEntry::code_ref(ostream &s)
{
  s << STRCONST_PREFIX << index;
}

//
// Emit code for a constant String.
//
void StringEntry::code_def(ostream &s, int stringclasstag)
{
  IntEntryP lensym = inttable.add_int(len);

  s << WORD << "-1" << std::endl;

  code_ref(s);
  s << LABEL                                                                   // label
    << WORD << stringclasstag << std::endl                                     // tag
    << WORD << (DEFAULT_OBJFIELDS + STRING_SLOTS + (len + 4) / 4) << std::endl // size
    << WORD;
  s << Str << DISPTAB_SUFFIX << std::endl;
  s << WORD;
  lensym->code_ref(s);
  s << std::endl;               // string length
  emit_string_constant(s, str); // ascii string
  s << ALIGN;                   // align to word
}

//
// StrTable::code_string
// Generate a string object definition for every string constant in the
// stringtable.
//
void StrTable::code_string_table(ostream &s, int stringclasstag)
{
  for (auto entry : tbl)
  {
    entry.code_def(s, stringclasstag);
  }
}

//
// Ints
//
void IntEntry::code_ref(ostream &s)
{
  s << INTCONST_PREFIX << index;
}

//
// Emit code for a constant Integer.
//
void IntEntry::code_def(ostream &s, int intclasstag)
{
  s << WORD << "-1" << std::endl;

  code_ref(s);
  s << LABEL                                                // label
    << WORD << intclasstag << std::endl                     // class tag
    << WORD << (DEFAULT_OBJFIELDS + INT_SLOTS) << std::endl // object size
    << WORD;
  s << Int << DISPTAB_SUFFIX << std::endl;
  s << WORD << str << std::endl; // integer value
}

//
// IntTable::code_string_table
// Generate an Int object definition for every Int constant in the
// inttable.
//
void IntTable::code_string_table(ostream &s, int intclasstag)
{
  for (auto entry : tbl)
  {
    entry.code_def(s, intclasstag);
  }
}

//
// Bools
//
BoolConst::BoolConst(int i) : val(i) { assert(i == 0 || i == 1); }

void BoolConst::code_ref(ostream &s) const
{
  s << BOOLCONST_PREFIX << val;
}

//
// Emit code for a constant Bool.
//
void BoolConst::code_def(ostream &s, int boolclasstag)
{
  s << WORD << "-1" << std::endl;

  code_ref(s);
  s << LABEL                                                 // label
    << WORD << boolclasstag << std::endl                     // class tag
    << WORD << (DEFAULT_OBJFIELDS + BOOL_SLOTS) << std::endl // object size
    << WORD;
  s << Bool << DISPTAB_SUFFIX << std::endl; // dispatch table
  s << WORD << val << std::endl;            // value (0 or 1)
}

//////////////////////////////////////////////////////////////////////////////
//
//  CgenClassTable methods
//
//////////////////////////////////////////////////////////////////////////////

//
// Define global names for some of basic classes and their tags.
//
void CgenClassTable::code_global_data()
{
  Symbol main = idtable.lookup_string(MAINNAME);
  Symbol string = idtable.lookup_string(STRINGNAME);
  Symbol integer = idtable.lookup_string(INTNAME);
  Symbol boolc = idtable.lookup_string(BOOLNAME);

  str << "\t.data\n"
      << ALIGN;
  //
  // The following global names must be defined first.
  //
  str << GLOBAL << CLASSNAMETAB << std::endl;
  str << GLOBAL;
  emit_protobj_ref(main, str);
  str << std::endl;
  str << GLOBAL;
  emit_protobj_ref(integer, str);
  str << std::endl;
  str << GLOBAL;
  emit_protobj_ref(string, str);
  str << std::endl;
  str << GLOBAL;
  falsebool.code_ref(str);
  str << std::endl;
  str << GLOBAL;
  truebool.code_ref(str);
  str << std::endl;
  str << GLOBAL << INTTAG << std::endl;
  str << GLOBAL << BOOLTAG << std::endl;
  str << GLOBAL << STRINGTAG << std::endl;

  //
  // We also need to know the tag of the Int, String, and Bool classes
  // during code generation.
  //

  int stringclasstag = *class_to_tag_table.lookup(string);
  int intclasstag = *class_to_tag_table.lookup(integer);
  int boolclasstag = *class_to_tag_table.lookup(boolc);

  str << INTTAG << LABEL
      << WORD << intclasstag << std::endl;
  str << BOOLTAG << LABEL
      << WORD << boolclasstag << std::endl;
  str << STRINGTAG << LABEL
      << WORD << stringclasstag
      << std::endl;
}

//***************************************************
//
//  Emit code to start the .text segment and to
//  declare the global names.
//
//***************************************************

void CgenClassTable::code_global_text()
{
  str << GLOBAL << HEAP_START << std::endl
      << HEAP_START << LABEL
      << WORD << 0 << std::endl
      << "\t.text" << std::endl
      << GLOBAL;
  emit_init_ref(idtable.add_string("Main"), str);
  str << std::endl
      << GLOBAL;
  emit_init_ref(idtable.add_string("Int"), str);
  str << std::endl
      << GLOBAL;
  emit_init_ref(idtable.add_string("String"), str);
  str << std::endl
      << GLOBAL;
  emit_init_ref(idtable.add_string("Bool"), str);
  str << std::endl
      << GLOBAL;
  emit_method_ref(idtable.add_string("Main"), idtable.add_string("main"), str);
  str << std::endl;
}

void CgenClassTable::code_bools()
{
  int boolclasstag = *class_to_tag_table.lookup(idtable.add_string(BOOLNAME));
  falsebool.code_def(str, boolclasstag);
  truebool.code_def(str, boolclasstag);
}

//
// Generate GC choice constants (pointers to GC functions)
//
void CgenClassTable::code_select_gc()
{
  str << GLOBAL << "_MemMgr_INITIALIZER" << std::endl;
  str << "_MemMgr_INITIALIZER:" << std::endl;
  str << WORD << gc_init_names[cgen_Memmgr] << std::endl;
  str << GLOBAL << "_MemMgr_COLLECTOR" << std::endl;
  str << "_MemMgr_COLLECTOR:" << std::endl;
  str << WORD << gc_collect_names[cgen_Memmgr] << std::endl;
  str << GLOBAL << "_MemMgr_TEST" << std::endl;
  str << "_MemMgr_TEST:" << std::endl;
  str << WORD << (cgen_Memmgr_Test == GC_TEST) << std::endl;
}

//********************************************************
// Emit code to reserve space for and initialize all of
// the constants.  Class names should have been added to
// the string table (in the supplied code, is is done
// during the construction of the inheritance graph), and
// code for emitting string constants as a side effect adds
// the string's length to the integer table.  The constants
// are emmitted by running through the stringtable and inttable
// and producing code for each entry.
//********************************************************
void CgenClassTable::code_constants()
{
  //
  // Add constants that are required by the code generator.
  //
  stringtable.add_string("");
  inttable.add_string("0");

  int stringclasstag = *class_to_tag_table.lookup(idtable.lookup_string(STRINGNAME));
  int intclasstag = *class_to_tag_table.lookup(idtable.lookup_string(INTNAME));

  stringtable.code_string_table(str, stringclasstag);
  inttable.code_string_table(str, intclasstag);
  code_bools();
}

CgenClassTable::CgenClassTable(Classes classes, ostream &s) : str(s), next_tag(0)
{
  class_to_tag_table.enterscope();
  enterscope();

  if (cgen_debug)
    std::cerr << "Building CgenClassTable" << std::endl;
  install_basic_classes();
  install_classes(classes);
  build_inheritance_tree();
  install_tags(root());

  code();
  exitscope();
}

void CgenClassTable::install_basic_classes()
{
  Symbol filename = stringtable.add_string("<basic class>");

  //
  // A few special class names are installed in the lookup table but not
  // the class list.  Thus, these classes exist, but are not part of the
  // inheritance hierarchy.
  // No_class serves as the parent of Object and the other special classes.
  // SELF_TYPE is the self class; it cannot be redefined or inherited.
  // prim_slot is a class known to the code generator.
  //
  addid(No_class,
        new CgenNode(class_(No_class, No_class, nil_Features(), filename),
                     Basic, this));
  addid(SELF_TYPE,
        new CgenNode(class_(SELF_TYPE, No_class, nil_Features(), filename),
                     Basic, this));
  addid(prim_slot,
        new CgenNode(class_(prim_slot, No_class, nil_Features(), filename),
                     Basic, this));

  //
  // The Object class has no parent class. Its methods are
  //        cool_abort() : Object    aborts the program
  //        type_name() : Str        returns a string representation of class name
  //        copy() : SELF_TYPE       returns a copy of the object
  //
  // There is no need for method bodies in the basic classes---these
  // are already built in to the runtime system.
  //
  install_class(
      new CgenNode(
          class_(Object,
                 No_class,
                 append_Features(
                     append_Features(
                         single_Features(method(cool_abort, nil_Formals(), Object, no_expr())),
                         single_Features(method(type_name, nil_Formals(), Str, no_expr()))),
                     single_Features(method(::copy, nil_Formals(), SELF_TYPE, no_expr()))),
                 filename),
          Basic, this));

  //
  // The IO class inherits from Object. Its methods are
  //        out_string(Str) : SELF_TYPE          writes a string to the output
  //        out_int(Int) : SELF_TYPE               "    an int    "  "     "
  //        in_string() : Str                    reads a string from the input
  //        in_int() : Int                         "   an int     "  "     "
  //
  install_class(
      new CgenNode(
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
                 filename),
          Basic, this));

  //
  // The Int class has no methods and only a single attribute, the
  // "val" for the integer.
  //
  install_class(
      new CgenNode(
          class_(Int,
                 Object,
                 single_Features(attr(val, prim_slot, no_expr())),
                 filename),
          Basic, this));

  //
  // Bool also has only the "val" slot.
  //
  install_class(
      new CgenNode(
          class_(Bool, Object, single_Features(attr(val, prim_slot, no_expr())), filename),
          Basic, this));

  //
  // The class Str has a number of slots and operations:
  //       val                                  the string's length
  //       str_field                            the string itself
  //       length() : Int                       length of the string
  //       concat(arg: Str) : Str               string concatenation
  //       substr(arg: Int, arg2: Int): Str     substring
  //
  install_class(
      new CgenNode(
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
                 filename),
          Basic, this));
}

// CgenClassTable::install_class
// CgenClassTable::install_classes
//
// install_classes enters a list of classes in the symbol table.
// The following possible errors are checked:
//       - a class called SELF_TYPE
//       - redefinition of a basic class
//       - redefinition of another previously defined class
//
void CgenClassTable::install_class(CgenNodeP nd)
{
  Symbol name = nd->get_name();

  if (probe(name))
    return;

  // The class name is legal, so add it to the list of classes
  // and the symbol table.
  nds.push_front(nd);
  addid(name, nd);
}

void CgenClassTable::install_classes(Classes cs)
{
  for (int i = cs->first(); cs->more(i); i = cs->next(i))
    install_class(new CgenNode(cs->nth(i), NotBasic, this));
}

//
// CgenClassTable::build_inheritance_tree
//
void CgenClassTable::build_inheritance_tree()
{
  for (auto nd : nds)
    set_relations(nd);
}

void CgenClassTable::install_tags(CgenNodeP nd)
{
  class_to_tag_table.addid(nd->get_name(), new int(next_tag++));

  for (auto &child : nd->get_children())
    install_tags(child);
}

//
// CgenClassTable::set_relations
//
// Takes a CgenNode and locates its, and its parent's, inheritance nodes
// via the class table.  Parent and child pointers are added as appropriate.
//
void CgenClassTable::set_relations(CgenNodeP nd)
{
  CgenNode *parent_node = probe(nd->get_parent());
  nd->set_parentnd(parent_node);
  parent_node->add_child(nd);
}

void CgenNode::add_child(CgenNodeP n)
{
  children.push_front(n);
}

void CgenNode::set_parentnd(CgenNodeP p)
{
  assert(parentnd == NULL);
  assert(p != NULL);
  parentnd = p;
}

CgenNodeP CgenNode::get_parentnd()
{
  return parentnd;
}

void CgenClassTable::code()
{
  code_global_data();
  code_select_gc();
  code_constants();

  str << CLASSNAMETAB << LABEL;
  code_class_nameTab(root());

  str << CLASSOBJTAB << LABEL;
  code_class_objTab(root());

  code_tree(root());

  code_global_text();

  code_init(root());
  code_methods(root());
}

void CgenClassTable::code_class_nameTab(CgenNodeP nd)
{
  str << WORD;
  stringtable.lookup_string(nd->get_name()->get_string())->code_ref(str);
  str << std::endl;

  for (const auto &child : nd->get_children())
    code_class_nameTab(child);
}

void CgenClassTable::code_class_objTab(CgenNodeP nd)
{
  str << WORD << nd->get_name() << PROTOBJ_SUFFIX << std::endl;
  str << WORD << nd->get_name() << CLASSINIT_SUFFIX << std::endl;

  for (const auto &child : nd->get_children())
    code_class_objTab(child);
}

void CgenClassTable::code_tree(CgenNodeP nd)
{
  nd->code(str, *class_to_tag_table.lookup(nd->get_name()));

  for (const auto &child : nd->get_children())
    code_tree(child);
}

void CgenClassTable::code_init(CgenNodeP nd)
{
  nd->code_init(str, this);

  for (auto &child : nd->get_children())
    code_init(child);
}

void CgenClassTable::code_methods(CgenNodeP nd)
{
  if (!basic_classes.count(nd->get_name()->get_string()))
    nd->code_methods(str, this);

  for (auto &child : nd->get_children())
    code_methods(child);
}

CgenNodeP CgenClassTable::root()
{
  return probe(Object);
}

///////////////////////////////////////////////////////////////////////
//
// CgenNode methods
//
///////////////////////////////////////////////////////////////////////

CgenNode::CgenNode(Class_ nd, Basicness bstatus, CgenClassTableP ct) : class__class((const class__class &)*nd),
                                                                       parentnd(NULL),
                                                                       basic_status(bstatus)
{
  stringtable.add_string(name->get_string());
  variables.enterscope();
}

void CgenNode::code_method(ostream &s, Feature &f, CgenClassTableP class_table)
{
  variables.enterscope();

  Formals cur_formals = f->get_formals();

  int counter = cur_formals->len() - 1;
  for (int i = cur_formals->first(); cur_formals->more(i); i = cur_formals->next(i))
    variables.addid(cur_formals->nth(i)->get_name(), new Variable{counter--, FP});

  s << get_name() << METHOD_SEP << f->get_name() << LABEL;
  emit_prologue(s);
  f->get_expr()->code(s, this, class_table, 4);
  emit_epilogue(s, cur_formals->len());

  variables.exitscope();
}

void CgenNode::code_methods(ostream &s, CgenClassTableP class_table)
{
  Symbol name = get_name();
  for (auto &method : methods)
  {
    if (method.class_name == name)
      code_method(s, method.nd, class_table);
  }
}

void CgenNode::code_init(ostream &s, CgenClassTableP class_table)
{
  variables.enterscope();
  s << get_name() << CLASSINIT_SUFFIX << LABEL;
  emit_prologue(s);

  if (get_parent() != No_class)
    s << JAL << get_parent() << CLASSINIT_SUFFIX << endl;

  int offset = parentnd->variables.gettable().front().size();
  Features f = get_features();

  for (int i = f->first(); f->more(i); i = f->next(i))
  {
    Feature cur = f->nth(i);
    if (cur->is_attr())
    {
      if (!cur->get_expr()->is_no_expr())
      {
        int loc = DEFAULT_OBJFIELDS + offset;
        cur->get_expr()->code(s, this, class_table, 4);
        emit_store(ACC, loc, SELF, s);

        emit_gc_assign_call(s, SELF, loc);
      }
      offset++;
    }
  }

  emit_move(ACC, SELF, s);
  emit_epilogue(s);

  variables.exitscope();
}

void CgenNode::code(ostream &s, const int &classtag)
{
  variables = parentnd->variables;
  methods = parentnd->methods;

  int method_offset = methods.size();
  int attr_offset = variables.gettable().front().size() + DEFAULT_OBJFIELDS;

  Features f = get_features();

  for (int i = f->first(); f->more(i); i = f->next(i))
  {
    Feature cur = f->nth(i);
    if (cur->is_attr())
    {
      variables.addid(cur->get_name(), new Variable(cur, attr_offset++, SELF));
    }
    else
    {
      insert_method(cur, method_offset);
    }
  }

  code_prot_obj(s, classtag);
  code_disp_tab(s);
}

void CgenNode::insert_method(const Feature &cur, int &offset)
{
  for (auto &method : methods)
  {
    if (method.nd->get_name() == cur->get_name())
    {
      method.class_name = get_name();
      method.nd = cur;
      return;
    }
  }

  methods.emplace_back(Method{get_name(), cur, offset++});
}

void CgenNode::code_disp_tab(ostream &s)
{
  Symbol name = get_name();
  emit_disptable_ref(name, s);
  s << LABEL;

  for (const auto &method : methods)
    s << WORD << method.class_name << METHOD_SEP << method.nd->get_name() << std::endl;
}

void CgenNode::code_prot_obj(ostream &s, const int &classtag)
{
  const auto &attrs = variables.gettable().front();

  s << WORD << "-1" << std::endl;
  s << get_name() << PROTOBJ_SUFFIX << LABEL
    << WORD << classtag << std::endl
    << WORD << (DEFAULT_OBJFIELDS + attrs.size()) << std::endl
    << WORD << get_name() << DISPTAB_SUFFIX << std::endl;

  for (auto it = attrs.rbegin(); it != attrs.rend(); ++it)
  {
    auto attr = *it;
    s << WORD;

    Symbol type = attr.get_info()->nd->get_type_decl();

    if (type == Int)
    {
      inttable.add_int(0)->code_ref(s);
    }
    else if (type == Bool)
    {
      s << BOOLCONST_PREFIX << 0;
    }
    else if (type == Str)
    {
      stringtable.add_string("")->code_ref(s);
    }
    else
    {
      s << 0;
    }
    s << std::endl;
  }
}

void assign_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  expr->code(s, nd, class_tab, frame_height);

  Variable *cur = nd->variables.lookup(name);
  emit_store(ACC, cur->offset, cur->reg, s);

  if (cur->reg == SELF)
    emit_gc_assign_call(s, cur->reg, cur->offset);
}

namespace dispatch_helpers
{
  void emit_arguments(const Expressions &actual, ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int &frame_height)
  {
    for (int i = actual->first(); actual->more(i); i = actual->next(i)) {
      actual->nth(i)->code(s, nd, class_tab, frame_height);
      emit_push(ACC, s);
      frame_height++;
    }
  }

  void emit_dynamic_call(int &offset, ostream &s)
  {
    emit_load(T1, DISPTABLE_OFFSET, ACC, s);
    emit_load(T1, offset, T1, s);
    emit_jalr(T1, s);
  }

  void emit_static_call(int &offset, ostream &s, Symbol type)
  {
    s << LA << T1 << " " << type << DISPTAB_SUFFIX << std::endl;
    emit_load(T1, offset, T1, s);
    emit_jalr(T1, s);
  }

  void find_method(Method &cur, Symbol type, CgenClassTableP class_tab, Symbol method_name)
  {
    for (const auto &method : class_tab->lookup(type)->methods)
    {
      if (method.nd->get_name() == method_name)
      {
        cur = method;
        return;
      }
    }
  }

  void emit_void_checker(int line_num, ostream &s)
  {
    emit_bne(ACC, ZERO, labelCounter, s);
    emit_load_string(ACC, stringtable.lookup(0), s);
    emit_load_imm(T1, line_num, s);
    emit_jal(DISP_ABORT, s);
    emit_label_def(labelCounter++, s);
  }
}

void static_dispatch_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  dispatch_helpers::emit_arguments(actual, s, nd, class_tab, frame_height);
  expr->code(s, nd, class_tab, frame_height);

  dispatch_helpers::emit_void_checker(line_number, s);

  Method cur;
  dispatch_helpers::find_method(cur, type_name, class_tab, name);
  dispatch_helpers::emit_static_call(cur.offset, s, type_name);
}

void dispatch_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  dispatch_helpers::emit_arguments(actual, s, nd, class_tab, frame_height);
  expr->code(s, nd, class_tab, frame_height);

  dispatch_helpers::emit_void_checker(line_number, s);

  Method cur;
  dispatch_helpers::find_method(cur, (expr->get_type() == SELF_TYPE) ? nd->get_name() : expr->get_type(), class_tab, name);
  dispatch_helpers::emit_dynamic_call(cur.offset, s);
}

void cond_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  pred->code(s, nd, class_tab, frame_height);

  emit_load(T1, DEFAULT_OBJFIELDS, ACC, s);

  int elseBranch = labelCounter++;
  emit_beqz(T1, elseBranch, s);

  then_exp->code(s, nd, class_tab, frame_height);

  int epilogueBranch = labelCounter++;
  emit_branch(epilogueBranch, s);

  emit_label_def(elseBranch, s);
  else_exp->code(s, nd, class_tab, frame_height);

  emit_label_def(epilogueBranch, s);
}

void loop_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  int loop_start = labelCounter++;
  emit_label_def(loop_start, s);

  pred->code(s, nd, class_tab, frame_height);
  emit_load(T1, DEFAULT_OBJFIELDS, ACC, s);

  int loop_end = labelCounter++;
  emit_beq(T1, ZERO, loop_end, s);

  body->code(s, nd, class_tab, frame_height);
  emit_branch(loop_start, s);

  emit_label_def(loop_end, s);

  emit_move(ACC, ZERO, s);
}

void branch_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  nd->variables.enterscope();
  nd->variables.addid(get_name(), new Variable(-frame_height, FP));
  emit_push(ACC, s);

  expr->code(s, nd, class_tab, frame_height + 1);

  emit_addiu(SP, SP, 4, s);
  nd->variables.exitscope();
}

namespace case_helpers
{
  struct CaseBranch
  {
    Case nd;
    int label;
    CaseBranch() = default;
    CaseBranch(const Case nd) : nd(nd) {}
  };

  int last_descendent(CgenNodeP nd, CgenClassTableP class_tab)
  {
    int last = *(class_tab->class_to_tag_table.lookup(nd->get_name()));

    for (auto &child : nd->get_children())
      last = std::max(last, last_descendent(child, class_tab));

    return last;
  }

  void emit_case_on_void(ostream &s, int line_no)
  {
    emit_bne(ACC, ZERO, labelCounter, s);
    emit_load_string(ACC, stringtable.lookup(0), s);
    emit_load_imm(T1, line_no, s);
    emit_jal(CASE_ABORT_TWO, s);
  }

  void create_case_branches(Cases cases, CgenClassTableP class_tab, std::map<int, CaseBranch, std::greater<int>> &branches)
  {
    for (int i = cases->first(); cases->more(i); i = cases->next(i))
    {
      Case cur = cases->nth(i);
      int tag = *(class_tab->class_to_tag_table.lookup(cur->get_type_decl()));
      branches.emplace(tag, CaseBranch(cur));
    }
  }

  void emit_last_labels(ostream &s, int missingBranchLabel, int epilogueLabel)
  {
    emit_label_def(missingBranchLabel, s);
    emit_jal(CASE_ABORT_ONE, s);

    emit_label_def(epilogueLabel, s);
  }

  void generate_case_dispatch(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height,
                              std::map<int, CaseBranch, std::greater<int>> &branches, int epilogueLabel)
  {
    for (auto &branch : branches)
      branch.second.label = labelCounter++;

    int missingBranchLabel = labelCounter++;

    bool first = true;
    for (const auto &branch : branches)
    {
      emit_label_def(branch.second.label, s);

      if (first)
      {
        emit_load(T2, 0, ACC, s);
        first = false;
      }

      emit_blti(T2, branch.first, branch.second.label + 1, s);
      emit_bgti(T2, case_helpers::last_descendent(class_tab->lookup(branch.second.nd->get_type_decl()), class_tab), branch.second.label + 1, s);

      branch.second.nd->code(s, nd, class_tab, frame_height);

      emit_branch(epilogueLabel, s);
    }

    emit_last_labels(s, missingBranchLabel, epilogueLabel);
  }
}

void typcase_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  int epilogueLabel = labelCounter++;

  expr->code(s, nd, class_tab, frame_height);

  case_helpers::emit_case_on_void(s, line_number);

  std::map<int, case_helpers::CaseBranch, std::greater<int>> branches;
  case_helpers::create_case_branches(cases, class_tab, branches);

  case_helpers::generate_case_dispatch(s, nd, class_tab, frame_height, branches, epilogueLabel);
}

void block_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  Expressions expr_ls = body;

  for (int i = expr_ls->first(); expr_ls->more(i); i = expr_ls->next(i))
    expr_ls->nth(i)->code(s, nd, class_tab, frame_height);
}

void let_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  nd->variables.enterscope();

  if (init->is_no_expr())
  {
    if (type_decl == Int)
    {
      emit_load_int(ACC, inttable.add_int(0), s);
    }
    else if (type_decl == Bool)
    {
      emit_load_bool(ACC, falsebool, s);
    }
    else if (type_decl == Str)
    {
      emit_load_string(ACC, stringtable.add_string(""), s);
    }
    else
    {
      emit_move(ACC, ZERO, s);
    }
  }
  else
  {
    init->code(s, nd, class_tab, frame_height);
  }

  nd->variables.addid(identifier, new Variable(-frame_height, FP));

  emit_push(ACC, s);

  body->code(s, nd, class_tab, frame_height + 1);

  emit_addiu(SP, SP, WORD_SIZE, s);

  nd->variables.exitscope();
}

void plus_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  s << JAL << Object << METHOD_SEP << ::copy << endl;
  emit_load(T1, 1, SP, s);
  emit_fetch_int(T1, T1, s);
  emit_fetch_int(T2, ACC, s);
  emit_add(T1, T1, T2, s);
  emit_store_int(T1, ACC, s);
  emit_addiu(SP, SP, WORD_SIZE, s);
}

void sub_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  s << JAL << Object << METHOD_SEP << ::copy << endl;
  emit_load(T1, 1, SP, s);
  emit_fetch_int(T1, T1, s);
  emit_fetch_int(T2, ACC, s);
  emit_sub(T1, T1, T2, s);
  emit_store_int(T1, ACC, s);
  emit_addiu(SP, SP, WORD_SIZE, s);
}

void mul_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  s << JAL << Object << METHOD_SEP << ::copy << endl;
  emit_load(T1, 1, SP, s);
  emit_fetch_int(T1, T1, s);
  emit_fetch_int(T2, ACC, s);
  emit_mul(T1, T1, T2, s);
  emit_store_int(T1, ACC, s);
  emit_addiu(SP, SP, WORD_SIZE, s);
}

void divide_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  s << JAL << Object << METHOD_SEP << ::copy << endl;
  emit_load(T1, 1, SP, s);
  emit_fetch_int(T1, T1, s);
  emit_fetch_int(T2, ACC, s);
  emit_div(T1, T1, T2, s);
  emit_store_int(T1, ACC, s);
  emit_addiu(SP, SP, WORD_SIZE, s);
}

void neg_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  s << JAL << Object << METHOD_SEP << ::copy << endl;
  emit_fetch_int(T1, ACC, s);
  emit_neg(T1, T1, s);
  emit_store_int(T1, ACC, s);
}

void lt_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  emit_load(T1, 1, SP, s);
  emit_addiu(SP, SP, WORD_SIZE, s);

  emit_fetch_int(T1, T1, s);
  emit_fetch_int(T2, ACC, s);

  emit_load_bool(ACC, truebool, s);
  emit_blt(T1, T2, labelCounter, s);
  emit_load_bool(ACC, falsebool, s);

  emit_label_def(labelCounter++, s);
}

void eq_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  emit_move(T2, ACC, s);
  emit_load(T1, 1, SP, s);
  emit_addiu(SP, SP, WORD_SIZE, s);

  emit_load_bool(ACC, truebool, s);
  emit_beq(T1, T2, labelCounter, s);
  emit_load_bool(A1, falsebool, s);
  emit_jal(EQUALITY_TEST, s);

  emit_label_def(labelCounter++, s);
}

void leq_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);
  emit_push(ACC, s);
  e2->code(s, nd, class_tab, frame_height + 1);
  emit_load(T1, 1, SP, s);
  emit_addiu(SP, SP, WORD_SIZE, s);

  emit_fetch_int(T1, T1, s);
  emit_fetch_int(T2, ACC, s);

  emit_load_bool(ACC, truebool, s);
  emit_bleq(T1, T2, labelCounter, s);
  emit_load_bool(ACC, falsebool, s);

  emit_label_def(labelCounter++, s);
}

void comp_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);

  emit_fetch_int(T1, ACC, s);
  emit_load_bool(ACC, truebool, s);
  emit_beqz(T1, labelCounter, s);
  emit_load_bool(ACC, falsebool, s);

  emit_label_def(labelCounter++, s);
}

void int_const_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  emit_load_int(ACC, inttable.lookup_string(token->get_string()), s);
}

void string_const_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  emit_load_string(ACC, stringtable.lookup_string(token->get_string()), s);
}

void bool_const_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  emit_load_bool(ACC, BoolConst(val), s);
}

void new__class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  Symbol t = get_type();
  if (t == SELF_TYPE)
  {
    s << LA << T1 << " " << CLASSOBJTAB << std::endl;
    emit_load(T2, 0, SELF, s);
    emit_sll(T2, T2, 3, s);
    emit_addu(T1, T1, T2, s);

    emit_push(T1, s);

    emit_load(ACC, 0, T1, s);
    s << JAL << Object << METHOD_SEP << ::copy << endl;

    emit_load(T1, 1, SP, s);
    emit_addiu(SP, SP, 4, s);

    emit_load(T1, 1, T1, s);
    emit_jalr(T1, s);
    return;
  }

  s << LA << ACC << " " << t << PROTOBJ_SUFFIX << std::endl;
  s << JAL << Object << METHOD_SEP << ::copy << endl;
  s << JAL << t << CLASSINIT_SUFFIX << endl;
}

void isvoid_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  e1->code(s, nd, class_tab, frame_height);

  emit_move(T1, ACC, s);

  emit_load_bool(ACC, truebool, s);
  emit_beqz(T1, labelCounter, s);
  emit_load_bool(ACC, falsebool, s);

  emit_label_def(labelCounter++, s);
}

void no_expr_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  /* no implementation necessary */
}

void object_class::code(ostream &s, CgenNodeP nd, CgenClassTableP class_tab, int frame_height)
{
  if (name == self)
  {
    emit_move(ACC, SELF, s);
  }
  else
  {
    Variable *cur = nd->variables.lookup(name);
    emit_load(ACC, cur->offset, cur->reg, s);
  }
}
