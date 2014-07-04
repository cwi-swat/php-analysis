module lang::php::parser::DocBlockParser

import ParseTree;
import IO;
import List;
import Node;
import Set;
import ValueIO;
import Ambiguity;

// added \u002A == * to the layout
layout Standard 
  = Whitespace* !>> [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "//";
  
//extend lang::std::Whitespace; // for spaces and such                                                      
lexical Whitespace 
  = [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000]
  ;

// Class names should start with a Capital letter or a backslash like \Object
lexical ClassName 
	//= [a-z] !<< [a-z]+ !>> [a-z]; // longest match
	= [a-z A-Z _ \\] !<< [A-Z \\] [a-z A-Z _ \\]* !>> [a-z A-Z _ \\]
		\ Keywords
	;

// borrowed from: lexical Id = [a-z A-Z 0-9 _] !<< [a-z A-Z][a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _];	
lexical Var 
	= [$] !<< "$" [$ { } a-z A-Z 0-9 _ \u007f-\u00ff]+ !>> [$ { } a-z A-Z 0-9 _ \u007f-\u00ff]
	//= "$" [$ { } a-z A-Z 0-9 _ \u007f-\u00ff]+ // $ and { } are needed for variable variables
	;
   
// keywords to match, use single quote for case insensitivity
keyword Keywords
	// annotations
	= "@param"
	| "@return"
	| "@var"
	// php types	
	| "array"
	| "bool"
	| "boolean"
	| "float"
	| "int"
	| "integer"
	| "mixed"
	| "resource"
	| "null"
	| "string"
	| "unset"
	;
	
syntax DocBlock 
	= docBlock: "/" Description? Annotation* "/"
	;

// Description is everything that is no Keyword.
// used !<< and !>> for longest match
lexical Description 
	= description: 
			[$ { } a-z A-Z 0-9 _ . \u007f-\u00ff] 
		!<<  
			![$ @] [$ { } a-z A-Z 0-9 _ . \  \u007f-\u00ff]+ 
		!>> 
			[$ { } a-z A-Z 0-9 _ . \  \u007f-\u00ff] 
		\ Keywords
		//\ ClassName
	;
	
syntax Annotation
	= annotation: AnnotationType
	;

syntax AnnotationType
	= param: "@param" Types Variable Description?
	| param: "@param" Variable Types Description?
	| \return: "@return" Types Description?
	| var: "@var" Variable Types Description?
	| var: "@var" Types Variable Description?
	| var: "@type" Variable Types Description?
	| var: "@type" Types Variable Description?
	;
	

syntax Variable
	= variable: Var
	;
	
// type can be a php type: int, string, bool
// type can be a class: Foo, \Foo, \Package\SubPackage\Foo
// type can be an array of types: int[], \Package\SubPackage\Foo
// types can be deived by |
syntax Types 
	= types: {Type "|"}+
	;
	
// This is some kind of wrapper; sometimes mixed is written as mixed() etc.
syntax Type
	= PhpTypeOrClass "()" 
	> PhpTypeOrClass
	;

syntax PhpTypeOrClass
	= arrayOf: PredefinedPhpType "[]"
	> PredefinedPhpType 
	> arrayOf: ClassName "[]" 
	> class: ClassName 
	;

syntax PredefinedPhpType 
	= array: "array"
	| \bool: "bool" 
	| \bool: "boolean"
	| float: "float"
	| \int: "int"
	| \int: "integer"
	| mixed: "mixed"
	| resource: "resource"
	| \null: "null"
	| string: "string"
	| unset: "unset"
	;