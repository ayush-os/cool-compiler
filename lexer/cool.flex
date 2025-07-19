/*
 * The scanner definition for COOL.
 */
%option noyywrap
/*
 * Stuff enclosed in %{ %} in the first section is copied verbatim to the
 * output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include "cool-parse.h"

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
char *max_str = string_buf + MAX_STR_CONST;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

%}

DARROW =>
ASSIGN <-

DIGIT [0-9]
INTEGER {DIGIT}+

NEWLINE \n
WHITESPACE [ \f\r\t\v]+

CLASS (?i:class)
INHERITS (?i:inherits)
IF (?i:if)
THEN (?i:then)
ELSE (?i:else)
FI (?i:fi)
WHILE (?i:while)
LOOP (?i:loop)
POOL (?i:pool)
LET (?i:let)
IN (?i:in)
CASE (?i:case)
OF (?i:of)
ESAC (?i:esac)
NEW (?i:new)
ISVOID (?i:isvoid)
NOT (?i:not)

TRUE t(?i:rue)
FALSE f(?i:alse)

ID [A-Za-z0-9_]*
TYPEID [A-Z]{ID}
OBJECTID  [a-z]{ID}

%x comment
COMM1START "(*"
COMM1END   "*)"

%x comment2
COMM2START "--"

%x string
QUOTE \"
BACKSLASH \\
BACKSPACE \\b
TAB \\t
FORMFEED \\f
ESCD     \\.
ESCDNL   \\\n
SLASHNL  \\n
ANY [^\"\0\n\\]+
NULLTERM \0

%x stringerrored

%%

    int nests = 0;
    int err(char *msg, bool strerr);
    int buf_append(char c);

{CLASS}           { return (CLASS); }
{INHERITS}        { return (INHERITS); }
{IF}              { return (IF); }
{THEN}            { return (THEN); }
{ELSE}            { return (ELSE); }
{FI}              { return (FI); }
{WHILE}           { return (WHILE); }
{LOOP}            { return (LOOP); }
{POOL}            { return (POOL); }
{LET}             { return (LET); }
{IN}              { return (IN); }
{CASE}            { return (CASE); }
{OF}              { return (OF); }
{ESAC}            { return (ESAC); }
{NEW}             { return (NEW); }
{ISVOID}          { return (ISVOID); }
{NOT}             { return (NOT); }

{TRUE}            {
                    cool_yylval.boolean = true;
                    return (BOOL_CONST);
                  }
{FALSE}           {
                    cool_yylval.boolean = false;
                    return (BOOL_CONST);
                  }

{TYPEID}          {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return (TYPEID);
                  }
{OBJECTID}        {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return (OBJECTID);
                  }

{INTEGER}         {
                    cool_yylval.symbol = inttable.add_string(yytext);
                    return (INT_CONST);
                  }

{WHITESPACE}    /* discard */
{NEWLINE}       curr_lineno++;

{COMM1END}      return err("Unmatched *)", false);

{DARROW}        { return (DARROW); }
"@"             { return '@'; }
"."             { return '.'; }
";"             { return ';'; }
"{"             { return '{'; }
"}"             { return '}'; }
","             { return ','; }
"("             { return '('; }
")"             { return ')'; }
":"             { return ':'; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
"~"             { return '~'; }
"<"             { return '<'; }
"<="            { return LE; }
"="             { return '='; }
{ASSIGN}        { return (ASSIGN); }

{QUOTE}         { string_buf_ptr = string_buf; BEGIN(string); }
<string>{
    {QUOTE} {
                BEGIN(INITIAL);
                *string_buf_ptr = '\0';
                cool_yylval.symbol = stringtable.add_string(string_buf);
                return (STR_CONST);
            }
    <<EOF>> { return err("EOF in string constant", false); }
    {NULLTERM}       { return err("String contains null character.", true); }
    {BACKSPACE}      { int ret = buf_append(8); if (ret) return ret; }
    {TAB}            { int ret = buf_append(9); if (ret) return ret; }
    {FORMFEED}       { int ret = buf_append(12); if (ret) return ret; }
    {SLASHNL}        { int ret = buf_append(10); if (ret) return ret; }
    {ESCDNL}         {
                        curr_lineno++;
                        int ret = buf_append(10);
                        if (ret) return ret;
                     }
    {ESCD}           { int ret = buf_append(yytext[1]); if (ret) return ret; }
    {BACKSLASH}      { int ret = buf_append(yytext[1]); if (ret) return ret; }
    {NEWLINE}        {
                        curr_lineno++;
                        return err("Unterminated string constant", false);
                     }
    {ANY}            {
                        int len = strlen(yytext);
                        if (string_buf_ptr + len < max_str) { 
                           memcpy(string_buf_ptr, yytext, len);
                           string_buf_ptr += len;
                        } else {
                          return err("String constant too long", true);
                        }
                     }
}

<stringerrored>{
    {NEWLINE}   { curr_lineno++; BEGIN(INITIAL); }
    {QUOTE}     BEGIN(INITIAL);
    [^\"\n]     /* discard */;
}
         
{COMM1START}    { BEGIN(comment); }
<comment>{
    {COMM1START}    { nests++; }
    {COMM1END} {
                if (nests <= 0) {
                   BEGIN(INITIAL);
                   nests = 0;
                } else {
                  nests--;
                }
               }
    {NEWLINE}  { curr_lineno++; }
    .          /* discard */
    <<EOF>>    { return err("EOF in comment", false); }
}

{COMM2START}    { BEGIN(comment2); }
<comment2>{
    {NEWLINE} { curr_lineno++; BEGIN(INITIAL); }
    .         /* discard */
}

.   return err(yytext, false);

%%

int err(char *msg, bool strerror) {
    cool_yylval.error_msg = msg;
    BEGIN(strerror ? stringerrored : INITIAL);
    return (ERROR);
}

int buf_append(char c) {
    if (string_buf_ptr + 1 < max_str) {
       *string_buf_ptr = c;
       string_buf_ptr++;
       return 0;
    } else {
      return err("String constant too long", true);
    }
}