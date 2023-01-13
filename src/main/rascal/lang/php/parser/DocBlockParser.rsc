@note{Please make sure to run tests::lang::php::parser::DocBlockParser when you modify this grammar}
module lang::php::parser::DocBlockParser

// added \u002A == * to the layout, the rest is the same as lang::std::Whitespace;
layout Standard 
  = Whitespace* !>> [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000 \r \n] !>> "//";
  //= Whitespace !<< Whitespace* !>> Whitespace;
  
lexical Whitespace 
  = [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000 \r \n]
  ;

// Class names should start with a letter or a backslash like \Object
// used !<< and !>> for longest match
lexical ClassName 
	= class:
			[a-z A-Z _ \\] 
		!<< 
			([a-z A-Z _ \\] [a-z A-Z _ \\ 0-9]*) 
		!>> 
			[a-z A-Z _ \\]
		\ PhpTypes
	;

// Match variables (they start with a dollar sign `$`)
// used !<< and !>> for longest match
lexical Var 
	= variable:
			[$] 
		!<< 
			("$" [$ { } a-z A-Z 0-9 _ \u007f-\u00ff]+) 
		!>> 
			[$ { } a-z A-Z 0-9 _ \u007f-\u00ff]
	;

// Description is everything that does not start with @ (annotation).
// used !<< and !>> for longest match
lexical Description 
	//= description: ![@]+ 
	= description: 
			[a-z A-Z 0-9 $ { } ( ) \[ \] \< \> & @ # ^ + % = : ; ? ! ~ ` \' \" / \\ _ \- | . , \u007f-\u00ff] 
		!<<  
			(![@] [a-z A-Z 0-9 $ { } ( ) \[ \] \< \> & @ # ^ + % = : ; ? ! ~ ` \' \" / \\ _ \- | . , \  \u007f-\u00ff]*)
		!>> 
			[a-z A-Z 0-9 $ { } ( ) \[ \] \< \> & @ # ^ + % = : ; ? ! ~ ` \' \" / \\ _ \- | . , \  \u007f-\u00ff] 
	;
  
lexical AnnotationTag
	= ("@" [a-zA-Z]+)
	;
	
keyword SupportedAnnotationTags
	= "@param"
	| "@return"
	| "@var"
	;
	
// keywords to match
keyword PhpTypes 
	= "array"
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
	| "object"
	| "void"
	;
	
// known issue: a line cannot start with two slashes
// for instance: * // comment
// not found a solution for this yet.
syntax DocBlock 
	= docBlock: "/" Description? Annotation* "/"
	;
	
syntax Annotation
	= annotation: AnnotationType Description*
	;

syntax AnnotationType
	= param: ("@param" Types Var) 
	| \return: ("@return" Types) 
	| var: ("@var" Types Var)
	> other: AnnotationTag \ SupportedAnnotationTags
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
	= arrayOf: PhpTypeOrClass "[]"
	> PhpTypeOrClass 
	> arrayOf: ClassName "[]" 
	> ClassName 
	;

syntax PhpTypeOrClass
	= PredefinedPhpType "()" 
	> PredefinedPhpType
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
	| object: "object"
	| \null: "void"
	;
