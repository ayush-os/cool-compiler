
ASSN = 4
CLASS= cs143
CLASSDIR= /afs/ir/class/cs143
LIB= -L/usr/pubsw/lib -lfl 
# LIB= -L/usr/pubsw/lib -lfl -R/usr/pubsw/lib
AR= gar
ARCHIVE_NEW= -cr
RANLIB= gar -qs

SRC= cgen.cc cgen.h cgen_supp.cc cool-tree.h cool-tree.handcode.h emit.h example.cl README
CSRC= cgen-phase.cc utilities.cc stringtab.cc dumptype.cc tree.cc cool-tree.cc handle_flags.cc handle_files.cc
TSRC= mycoolc
CGEN=
HGEN= 
LIBS= lexer parser semant
CFIL= cgen.cc cgen_supp.cc ${CSRC} ${CGEN}
LSRC= Makefile
OBJS= ${CFIL:.cc=.o} ast-parse.o ast-lex.o
OUTPUT= good.output bad.output


CPPINCLUDE= -I. -I./include -I./src


FFLAGS = -d8 -ocool-lex.cc
BFLAGS = -d -v -y -b cool --debug -p cool_yy
ASTBFLAGS = -d -v -y -b ast --debug -p ast_yy

CC=g++
CFLAGS=-g -Wall -Wno-unused -Wno-write-strings -Wno-deprecated ${CPPINCLUDE} -DDEBUG
FLEX=flex ${FFLAGS}
BISON= bison ${BFLAGS}
SHELL = /bin/bash

DEPS := ${OBJS:.o=.d}

-include ${DEPS}

cgen : ${OBJS}
	${CC} ${CFLAGS} ${OBJS} ${LIB} -o $@

${OUTPUT}:	cgen
	@rm -f ${OUTPUT}
	./mycoolc  example.cl &> example.output 

ast-parse.cc ast-parse.hh : src/ast.y
	bison ${ASTBFLAGS} -o ast-parse.cc $<

ast-lex.cc : src/ast.flex
	${LEX} ${LEXFLAGS} -o$@ $<

dotest:	cgen example.cl
	@echo "\nRunning code generator on example.cl\n"
	-./mycoolc example.cl

submit: cgen
	$(CLASSDIR)/bin/pa_submit PA4 .

clean:
	rm -f cgen ${OBJS} ${DEPS} ast-lex.cc ast-parse.cc ast-parse.hh ast-parse.output

# build rules

%.o : %.cc
	${CC} ${CFLAGS} -MMD -c $< -o $@

%.o : src/%.cc
	${CC} ${CFLAGS} -MMD -c $< -o $@

.DEFAULT_GOAL := cgen

# extra dependencies 
