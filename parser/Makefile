ASSN = 2
CLASS= cs143
CLASSDIR= /afs/ir/class/cs143
LIB= -lfl 
AR= gar
ARCHIVE_NEW= -cr
RANLIB= gar -qs

SRC= cool.y cool-tree.handcode.h good.cl bad.cl README
CSRC= parser-phase.cc utilities.cc stringtab.cc dumptype.cc \
      tree.cc cool-tree.cc handle_flags.cc handle_files.cc
TSRC= myparser mycoolc cool-tree.aps
CGEN= cool-parse.cc
HGEN= cool.tab.h
LIBS= lexer semant cgen
CFIL= ${CSRC} ${CGEN}
HFIL= cool-tree.h cool-tree.handcode.h 
LSRC= Makefile
OBJS= ${CFIL:.cc=.o} tokens-lex.o
OUTPUT= good.output bad.output


CPPINCLUDE= -I. -I./include -I./src

BFLAGS = -d -v -y -b cool --debug -p cool_yy

CC=g++
CFLAGS=-g -Wall -Wno-unused -Wno-deprecated  -Wno-write-strings -DDEBUG ${CPPINCLUDE}
FLEX=flex ${FFLAGS}
BISON= bison ${BFLAGS}
DEPEND = ${CC} -MM ${CPPINCLUDE}

parser: ${OBJS}
	${CC} ${CFLAGS} ${OBJS} ${LIB} -o parser

${OUTPUT}:	parser good.cl bad.cl
	@rm -f ${OUTPUT}
	./myparser good.cl >good.output 2>&1 
	-./myparser bad.cl >bad.output 2>&1 

cool-parse.cc cool-parse.hh : cool.y
	bison ${BFLAGS} -o cool-parse.cc $<

dotest:	parser good.cl bad.cl
	@echo "\nRunning parser on good.cl\n"
	-./myparser good.cl 
	@echo "\nRunning parser on bad.cl\n"
	-./myparser bad.cl

tokens-lex.cc : src/tokens.flex
	${LEX} ${LEXFLAGS} -o$@ $<

submit: parser
	$(CLASSDIR)/bin/pa_submit PA2 .

clean:
	rm -f parser ${OBJS} cool-parse.cc cool-parse.hh tokens-lex.cc cool-parse.output

# build rules

%.o : %.cc
	${CC} ${CFLAGS} -c $< -o $@

%.o : src/%.cc
	${CC} ${CFLAGS} -c $< -o $@

# extra dependencies 
