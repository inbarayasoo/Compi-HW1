%{

/* Declarations section */
#include "output.hpp"
#include "tokens.hpp"
#include <iostream>
#include <ostream>
void printString();
bool checkHexEscape(const char* cur_char);
void printInvalidEscape();
%}

%option yylineno
%option noyywrap
digit   		    ([0-9])
letter  		    ([a-zA-Z])
digit_letter        ([a-zA-Z0-9])
hex_digit           ([0-9A-F])
whitespace		    ([\r\t\n ])

escape_sequence     ([\"nrt0\\])
valid_escape        (\\({escape_sequence}|x0[9aAdD]|x[2-6][0-9a-fA-F]|x7[0-9a-eA-E]))
string_char         ([^\\\"\n\r]|{valid_escape})

string              (\"({string_char})*\")
invalid_escape      (\"({string_char})*(\\[^\"nrt0x\\]|\\x[^\n\r\"]{0,2}))
unclosed_string     (\"({string_char})*)
%%

\\n         			                            {/*skip*/}
{whitespace}	                                    {/*skip*/}
void 	                                            {return VOID;}
int                                                 {return INT;}
byte                                                {return BYTE;}
bool                                                {return BOOL;}
and                                                 {return AND;}
or                                                  {return OR;}
not                                                 {return NOT;}
true                                                {return TRUE;}
false 	                                            {return FALSE;}
return                                              {return RETURN;}
if                                                  {return IF;}
else                                                {return ELSE;}
while                                               {return WHILE;}
break                                               {return BREAK;}
continue                                            {return CONTINUE;}
;                                                   {return SC;}
, 	                                                {return COMMA;}
\(                                                  {return LPAREN;}
\)                                                  {return RPAREN;}
\{                                                  {return LBRACE;}
\}                                                  {return RBRACE;}
\[                                                  {return LBRACK;}
\]                                                  {return RBRACK;}
=                                                   {return ASSIGN;}
==|!=|<|>|<=|>= 	                                {return RELOP;}
\+|\-|\*|\/                                         {return BINOP;}
\/\/[^\r\n]*                                        {return COMMENT;}
{letter}+{digit_letter}*                            {return ID;}
([1-9]+{digit}*)|0                                  {return NUM;}
(([1-9]+{digit}*)|0)b                               {return NUM_B;}

{string}                                            {printString(); return STRING;}
{unclosed_string}                                   {output::errorUnclosedString();}
{invalid_escape}                                    {printInvalidEscape();}

.		                                            {output::errorUnknownChar(*yytext);}
%%

void printString()
{
    const char* tmp = yytext+1;
    std::cout << yylineno << " " << "STRING" << " ";
    for (const char* cur_char = tmp; *(cur_char + 1) != '\0'; cur_char++) {
        if (*cur_char == '\\') {
            switch (*(cur_char + 1)) {
                case 'n':
                    std::cout << std::endl;
                    break;
                case 'r':
                    std::cout << '\r';
                    break;
                case 't':
                    std::cout << '\t';
                    break;
                case '"':
                    std::cout << '"';
                    break;
                case '\\':
                    std::cout << '\\';
                    break;
                case '0':
                    std::cout << std::endl;
                    return;
 
                case 'x': {
                    int x = 0, y = 0;
                    // get the hex value
                    for (int i = 0; i < 2; ++i) {
                        char hex_char = *(cur_char + 2 + i);
                        int val = 0;

                        if (hex_char >= '0' && hex_char <= '9')
                            val = hex_char - '0';
                        else if (hex_char >= 'a' && hex_char <= 'f')
                            val = hex_char - 'a' + 10;
                        else if (hex_char >= 'A' && hex_char <= 'F')
                            val = hex_char - 'A' + 10;

                        if (i == 0)
                            x = val;
                        else
                            y = val;
                    }

                    char c = char(16*x + y);
                    std::cout << c;
                    cur_char += 2; 
                    break;
                }
            }

            cur_char += 1;
            continue;
        }

        std::cout << *cur_char;
    }

    std::cout << std::endl;
}

bool checkHexEscape(const char* cur_char) {
    char x = *(cur_char + 2);
    char y = *(cur_char + 3);

    if (x >= '2' && x <= '6' && isxdigit(y)) {
        return true;
    }
    if (x == '7' && ((y >= '0' && y <= '9') || (y >= 'a' && y <= 'e') || (y >= 'A' && y <= 'E'))) {
        return true;
    }
    return false;
}

void printInvalidEscape() {
    for (const char* cur_char = yytext; *cur_char != '\0'; ++cur_char) {
        if (*cur_char == '\\') {
            char next_char = *(cur_char + 1);

            switch (next_char) {
                case 'n':
                case 'r':
                case 't':
                case '0':
                case '\\':
                case '"':
                    cur_char++; 
                    break;

                case 'x':
                    if (checkHexEscape(cur_char)) {
                        cur_char += 3; 
                    } else {
                        output::errorUndefinedEscape(cur_char + 1);
                        return;
                    }
                    break;

                default:
                    output::errorUndefinedEscape(cur_char + 1);
                    return;
            }
        }
    }
}

