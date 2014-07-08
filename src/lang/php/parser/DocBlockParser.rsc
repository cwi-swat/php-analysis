@note{Please make sure to run tests::lang::php::parser::DocBlockParser when you modify this grammar file}
module lang::php::parser::DocBlockParser

import ParseTree;
import IO;
import List;
import Node;
import Set;
import ValueIO;
import Ambiguity;

// added \u002A == * to the layout, the rest is the same as lang::std::Whitespace;
layout Standard 
  = Whitespace* !>> [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "//";
  
lexical Whitespace 
  = [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000]
  ;

// Class names should start with a Capital letter or a backslash like \Object
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
	= description: 
			[$ a-z A-Z 0-9 { } ( ) \[ \] \< \> & @ # ^ + % = : ; ? ! ~ ` \' \" / \\ _ \- | . , \u007f-\u00ff] 
		!<<  
			(![@] [a-z A-Z 0-9 $ { } ( ) \[ \] \< \> & @ # ^ + % = : ; ? ! ~ ` \' \" / \\ _ \- | . , \  \u007f-\u00ff]*)
		!>> 
			[a-z A-Z 0-9 $ { } ( ) \[ \] \< \> & @ # ^ + % = : ; ? ! ~ ` \' \" / \\ _ \- | . , \  \u007f-\u00ff] 
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
	= docBlock: "/" Description* Annotation* "/"
	;
	
syntax Annotation
	= annotation: AnnotationType Description*
	;

syntax AnnotationType
	= param: ("@param" Types Var)
	| \return: ("@return" Types)
	| var: ("@var" Types Var)
	> other: OtherAnnotationTag
	;

lexical OtherAnnotationTag
	// a full list of Annoation tags found in the test applications
	// added them all to have more successful parsings
	// I would prefer to have `> "@" [a-z]+` but somehow this will result in ambiguity
    = "@Annotation"
    | "@Cache"
    | "@Entity"
    | "@Group"
    | "@Link"
    | "@MappedSuperclass"
    | "@Method"
    | "@ParamConverter"
    | "@RunAs"
    | "@Secure"
    | "@SecureParam"
    | "@SecureReturn"
    | "@TODO"
    | "@Template"
    | "@Todo"
    | "@abstract"
    | "@acces"
    | "@access"
    | "@addtogroup"
    | "@author"
    | "@autoComplete"
    | "@azure"
    | "@brief"
    | "@bug"
    | "@c"
    | "@callback"
    | "@category"
    | "@catehory"
    | "@class"
    | "@coauthor"
    | "@code"
    | "@codeCoverageIgnore"
    | "@comment"
    | "@contrib"
    | "@contributor"
    | "@copydoc"
    | "@copyright"
    | "@copyrigth"
    | "@count"
    | "@covers"
    | "@current,"
    | "@dataProvider"
    | "@default"
    | "@defgroup"
    | "@depends"
    | "@deprecated"
    | "@deprected"
    | "@desc"
    | "@descriptionTag"
    | "@echo"
    | "@elapsed."
    | "@embed"
    | "@error"
    | "@eturn"
    | "@example"
    | "@exception"
    | "@expectException"
    | "@expectedException"
    | "@expectedExceptionMessage"
    | "@expectedMessage"
    | "@factory"
    | "@file"
    | "@fixme"
    | "@global"
    | "@group"
    | "@hideinitializer"
    | "@ignore"
    | "@ignore"
    | "@import"
    | "@imports"
    | "@indent"
    | "@ingroup"
    | "@ingroups"
    | "@int"
    | "@internal"
    | "@lastmodified"
    | "@license"
    | "@link"
    | "@maintainers"
    | "@media"
    | "@method"
    | "@mod"
    | "@modifiedby"
    | "@name"
    | "@namespace"
    | "@note"
    | "@notice"
    | "@oaram"
    | "@outputBuffering"
    | "@override"
    | "@package"
    | "@par"
    //| "@param"
    | "@parambool"
    | "@parameter"
    | "@paramint"
    | "@params"
    | "@parma"
    | "@pat"
    | "@prarm"
    | "@prefix"
    | "@private"
    | "@private"
    | "@property"
    | "@protected"
    | "@public"
    | "@redmine"
    | "@ref"
    | "@rel"
    | "@retrun"
    | "@retun"
    | "@retur"
    //| "@return"
    | "@returnarray"
    | "@returnbool"
    | "@returnf"
    | "@returnint"
    | "@returnmixed"
    | "@returns"
    | "@returnstring"
    | "@returnstringcontent"
    | "@sa"
    | "@schema"
    | "@scope"
    | "@section"
    | "@see"
    | "@seeAlso"
    | "@since"
    | "@source"
    | "@static"
    | "@static"
    | "@staticvar"
    | "@stripprefix"
    | "@subpackage"
    | "@subplugin"
    | "@t"
    | "@throw"
    | "@throws"
    | "@ticket"
    | "@todo"
    | "@tutorial"
    | "@usage"
    | "@use"
    | "@usedby"
    | "@uses"
    | "@using"
    //| "@var"
    | "@version"
    | "@warning"
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
	> ClassName 
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
	| \void: "void"
	;