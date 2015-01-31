module lang::php::analysis::il::ILGenerator

lexical Comment
	= @category="Comment" "/*" (![*] | [*] !>> [/])* "*/" 
	| @category="Comment" "//" ![\n]* !>> [\ \t\r \u00A0 \u1680 \u2000-\u200A \u202F \u205F \u3000] $ // the restriction helps with parsing speed
	;
	
lexical LAYOUT
	= Comment 
	// all the white space chars defined in Unicode 6.0 
	| [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] 
	;

layout LAYOUTLIST
	= LAYOUT* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "//" !>> "/*";

lexical DecimalIntegerLiteral
	= "0" !>> [0-9 A-Z _ a-z] 
	| [1-9] [0-9]* !>> [0-9 A-Z _ a-z] 
	;

lexical HexIntegerLiteral
	= [0] [X x] [0-9 A-F a-f]+ !>> [0-9 A-Z _ a-z] 
	;

lexical OctalIntegerLiteral
	= [0] [0-7]+ !>> [0-9 A-Z _ a-z] 
	;

syntax IntegerLiteral
	= /*prefer()*/ decimalIntegerLiteral: DecimalIntegerLiteral decimal 
	| /*prefer()*/ hexIntegerLiteral: HexIntegerLiteral hex 
	| /*prefer()*/ octalIntegerLiteral: OctalIntegerLiteral octal 
	;

lexical BooleanLiteral
	= "true" 
	| "false" 
	;

lexical UnicodeEscape
	  = utf16: "\\" [u] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
    | utf32: "\\" [U] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] [0-9 A-F a-f] 
    | ascii: "\\" [a] [0-7] [0-9A-Fa-f]
    ;

lexical StringCharacter
	= "\\" [\" \' \< \> \\ b f n r t] 
	| UnicodeEscape 
	| ![\" \' \< \> \\]
	| [\n][\ \t \u00A0 \u1680 \u2000-\u200A \u202F \u205F \u3000]* [\'] // margin 
	;
	
lexical StringConstant
	= @category="Constant" "\"" StringCharacter* chars "\"" 
	;

syntax StringLiteral
	= nonInterpolated: StringConstant constant 
	;

lexical DatePart
	= [0-9] [0-9] [0-9] [0-9] "-" [0-1] [0-9] "-" [0-3] [0-9] 
	| [0-9] [0-9] [0-9] [0-9] [0-1] [0-9] [0-3] [0-9] 
	;

lexical JustDate
	= "$" DatePart 
	;

lexical TimePartNoTZ
	= [0-2] [0-9] [0-5] [0-9] [0-5] [0-9] ([, .] [0-9] ([0-9] [0-9]?)?)? 
	| [0-2] [0-9] ":" [0-5] [0-9] ":" [0-5] [0-9] ([, .] [0-9] ([0-9] [0-9]?)?)? 
	;

lexical TimeZonePart
	= [+ \-] [0-1] [0-9] ":" [0-5] [0-9] 
	| "Z" 
	| [+ \-] [0-1] [0-9] 
	| [+ \-] [0-1] [0-9] [0-5] [0-9] 
	;

lexical JustTime
	= "$T" TimePartNoTZ !>> [+\-] 
	| "$T" TimePartNoTZ TimeZonePart
	;

lexical DateAndTime
	= "$" DatePart "T" TimePartNoTZ !>> [+\-]
    | "$" DatePart "T" TimePartNoTZ TimeZonePart
    ;

syntax DateTimeLiteral
	= /*prefer()*/ dateLiteral: JustDate date 
	| /*prefer()*/ timeLiteral: JustTime time 
	| /*prefer()*/ dateAndTimeLiteral: DateAndTime dateAndTime 
	;

syntax Literal
	= integer: IntegerLiteral integerLiteral 
	| boolean: BooleanLiteral booleanLiteral 
	| string: StringLiteral stringLiteral 
	| dateTime: DateTimeLiteral dateTimeLiteral 
	;

lexical Name
    // Names are surrounded by non-alphabetical characters, i.e. we want longest match.
	=  ([a-z] !<< [a-z] [0-9 A-Z a-z]* !>> [0-9 A-Z a-z]) \ ILTKeywords 
	| [\\] [a-z] [0-9 A-Z a-z]* !>> [0-9 A-Z a-z] 
	;

lexical Var
    // Names are surrounded by non-alphabetical characters, i.e. we want longest match.
	=  ([A-Z] !<< [A-Z] [0-9 A-Z a-z]* !>> [0-9 A-Z _ a-z]) \ ILTKeywords 
	| [\\] [A-Z] [0-9 A-Z a-z]* !>> [0-9 A-Z a-z] 
	;

lexical TempVar
    // Names are surrounded by non-alphabetical characters, i.e. we want longest match.
	=  ([%] !<< [%] [a-z] [a-z 0-9 A-Z]* [.] [0-9]+ !>> [0-9 A-Z a-z .]) \ ILTKeywords 
	;

lexical LabelVar
    // Names are surrounded by non-alphabetical characters, i.e. we want longest match.
	=  ([@] !<< [@] [A-Z a-z] [a-z 0-9 A-Z]* !>> [0-9 A-Z a-z]) \ ILTKeywords 
	;

syntax Term
	= termVar: Var v
	| consTerm: Name n
	| termPart: Name n "(" { Term ","}+ ts ")"
	| tempVar: TempVar tv
	| literalTerm: Literal lit
	;

syntax Comparison
	= equality: Term lhs "==" Term rhs
	| inequality: Term lhs "=/=" Term rhs
	;
		
syntax Logical
	= left conjunction: Comparison lhs "and" Comparison rhs
	> left disjunction: Comparison lhs "or" Comparison rhs
	> right not: "not" Comparison
	| bracket "(" Logical body ")"
	;
	
syntax Rule
	= unconditionalRule: "rule" Term lhs ":" RuleStep+ steps ";;"
	;
	
syntax RuleStep
	= lower: LoweringStep lstep
	| emit: "emit" Term
	| emitWithVar: "emit" TempVar tv "=" Term
	| newLabel: "new" "label" LabelVar lv
	;
	
syntax Labels
	= oneLabel: "with" "label" LabelVar lv
	| entryAndExit: "with" "entry" LabelVar enlv "and" "exit" LabelVar exlv
	;
	
syntax LoweringStep
	= lowerDiscard: "lower" Term
	| lowerSave: TempVar tv "=" LoweringStep ls
	> labelSave: LoweringStep ls Labels lbls
	;

syntax ILGProgram = Rule* ilgRules;

keyword ILTKeywords
	= "rule"
	| "and"
	| "or"
	| "not"
	| "lower"
	| "with"
	| "label"
	| "entry"
	| "exit"
	| "true"
	| "false"
	;
