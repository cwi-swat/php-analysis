module lang::php::parser::AnnotationParser

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


// test methods
public void main()
{

	println("Testing php types ..."); 	if (testPhpTypes()) 		println("Done. \n");
	println("Testing class types ..."); if (testClassTypes())	 	println("Done. \n");
	println("Testing variables..."); 	if (testVariables()) 		println("Done. \n");
	println("Testing annotations..."); 	if (testAnnotations()) 		println("Done. \n");
	println("Testing descriptions..."); if (testDescriptions()) 	println("Done. \n");
	
	int numberOfTests = 50;	
	println("Testing <numberOfTests> random multiple types ..."); if (testMultipleTypes(numberOfTests)) println("Done. \n");

	println("Testing docblocks..."); 	if (testDocBlocks()) 		println("Done. \n");
}

// test the parser with some inputs
public bool testParser(type[&T<:Tree] t, lrel[str input, node expectedResult] inputs)
{
	for (i <- inputs) {
		try { 
			// try to parse
			node n = implode(#node, parse(t, i.input));
			//println(n);
			// check if the result is the expected result
			assert n == i.expectedResult : println("Expected:\n<i.expectedResult>\nActual:\n<delAnnotationsRec(n)>");
		} catch ParseError(loc l): {
			println("PARSE ERROR!! I found a parse error at type: <t> || input: <i> \nThis test stopped.\n"); 
			return false;
		}
    }
    return true;
}

public bool testPhpTypes() 
{
	lrel[str input, node expectedResult] inputs
		= [ <"array", 	makeNode("types", [[makeNode("array")]])> ] 
		+ [ <"array()", makeNode("types", [[makeNode("array")]])> ]
		
		+ [ <"mixed", 	makeNode("types", [[makeNode("mixed")]])> ]
		+ [ <"mixed()", makeNode("types", [[makeNode("mixed")]])> ]
		
		+ [ <"bool", 	makeNode("types", [[makeNode("bool")]])> ]
		+ [ <"bool()", 	makeNode("types", [[makeNode("bool")]])> ]
		+ [ <"bool[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("bool"))]])> ]
		+ [ <"boolean", 	makeNode("types", [[makeNode("bool")]])> ]
		+ [ <"boolean()", 	makeNode("types", [[makeNode("bool")]])> ]
		+ [ <"boolean[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("bool"))]])> ]
		
		+ [ <"int", 	makeNode("types", [[makeNode("int")]])> ]
		+ [ <"int()", 	makeNode("types", [[makeNode("int")]])> ]
		+ [ <"int[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("int"))]])> ]
		
		+ [ <"float", 	makeNode("types", [[makeNode("float")]])> ]
		+ [ <"float()", 	makeNode("types", [[makeNode("float")]])> ]
		+ [ <"float[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("float"))]])> ]
		
		+ [ <"string", 		makeNode("types", [[makeNode("string")]])> ]
		+ [ <"string()", 	makeNode("types", [[makeNode("string")]])> ]
		+ [ <"string[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("string"))]])> ]
		
		+ [ <"resource", 	makeNode("types", [[makeNode("resource")]])> ]
		+ [ <"resource()", 	makeNode("types", [[makeNode("resource")]])> ]
		+ [ <"resource[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("resource"))]])> ]
		
		+ [ <"unset", 		makeNode("types", [[makeNode("unset")]])> ]
		+ [ <"unset()", 	makeNode("types", [[makeNode("unset")]])> ]
		+ [ <"unset[]", 	makeNode("types", [[makeNode("arrayOf", makeNode("unset"))]])> ]
		;

	return testParser(#Types, inputs);	
}

public bool testClassTypes() 
{
	list[str] input 
		= [ "C", "ClassName", "Object" ]
		+ [ "OldStyleClasses", "Old_Style_Classes"] 
	//	+ ["class_lowercased" ] // does not work because of case sensitivity
		+ [ "\\ClassName", "\\Package\\ClassName", "\\Package\\SubPackage\\ClassName" ];
		
	lrel[str input, node expectedResult] inputs = [ <i, makeNode("types", [[makeNode("class", i)]])> | i <- input ];

	return testParser(#Types, inputs);	
}

public bool testVariables() 
{
	list[str] input 
		= [ "$var", "$object", "$OBJ", "$_OBJ", "$_OBJ_o" ]
		+ [ "$_OBJ_ÿ", "$_{$O_ÿ}", "$a_b_c", "$randomName" ]
		;
	lrel[str input, node expectedResult] inputs = [ <i, makeNode("variable", i)> | i <- input ];

	return testParser(#Variable, inputs);	
}

public bool testDescriptions() 
{
	list[str] input 
		= [ "var", "object", "OBJ", "_OBJ", "_OBJ_o", "_OBJ_ÿ", "_{$OB_ÿ}",  "a_b_c" ] 
		+ [ "random text", " random text ", "This is some random comment", "  This is some random comment  " ]
		;
		
	lrel[str input, node expectedResult] inputs = [ <i, makeNode("description", i)> | i <- input ];

	return testParser(#Description, inputs);	
}

// this method contains 3 private methods, not the most pretty thing
public bool testMultipleTypes(int numberOfTests)
{
	// magic to get some random collection
	private str listToString(list[str] keywords)
		= intercalate(getOneFrom(["|", " |", "| ", " | "]), keywords);

	// list to expected output
	private node listToExpectedOutput(list[str] keywords)
		= makeNode("types", [[ makeNode(k) | k <- keywords ]]);
		
	private list[str] getMixedKeywordsList(list[str] keywords) 
		= getOneFrom(toList(permutations(slice(keywords, getOneFrom([0..(size(keywords)-4)]), getOneFrom([1..5])))));
	
	// list of php types
	list[str] keywords = [ "array", "bool", "float", "int", "mixed", "resource", "null", "string", "unset" ];
	// list of mixed types (from the array above)
	list[list[str]] lists = [ getMixedKeywordsList(keywords) | n <- [0 .. numberOfTests] ];	
	
	// create x random inputs	
	lrel[str input, node expectedResult] inputs = [ <listToString(l), listToExpectedOutput(l)> | l <- lists ];
		
	return testParser(#Types, inputs);
}

public bool testAnnotations() 
{
	lrel[str input, node expectedResult] inputs
		= [ <"@param int $var", 	makeNode("annotation", makeNode("param", makeNode("types", [ [ makeNode("int") ] ]), makeNode("variable", "$var"), [] ))> ]
		+ [ <"@param $var int", 	makeNode("annotation", makeNode("param", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("int") ] ]), [] ))> ]
		+ [ <"@param int $var some text", 	makeNode("annotation", makeNode("param", makeNode("types", [ [ makeNode("int") ] ]), makeNode("variable", "$var"), [makeNode("description", "some text")] ))> ]
		+ [ <"@param $var int some text", 	makeNode("annotation", makeNode("param", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("int") ] ]), [makeNode("description", "some text")] ))> ]
		
		+ [ <"@var mixed $var", 	makeNode("annotation", makeNode("var", makeNode("types", [ [ makeNode("mixed") ] ]), makeNode("variable", "$var"), [] ))> ]
		+ [ <"@var $var mixed", 	makeNode("annotation", makeNode("var", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("mixed") ] ]), [] ))> ]
		+ [ <"@var mixed $var some text", 	makeNode("annotation", makeNode("var", makeNode("types", [ [ makeNode("mixed") ] ]), makeNode("variable", "$var"), [makeNode("description", "some text")] ))> ]
		+ [ <"@var $var mixed some text", 	makeNode("annotation", makeNode("var", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("mixed") ] ]), [makeNode("description", "some text")] ))> ]
		
		+ [ <"@var RandomClass $var some text", 	makeNode("annotation", makeNode("var", makeNode("types", [ [ makeNode("class", "RandomClass") ] ]), makeNode("variable", "$var"), [makeNode("description", "some text")] ))> ]
		+ [ <"@var $var RandomClass some text", 	makeNode("annotation", makeNode("var", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("class", "RandomClass") ] ]), [makeNode("description", "some text")] ))> ]
		;


	return testParser(#Annotation, inputs);	
}
	
public bool testDocBlocks()
{
	lrel[str input, node expectedResult] inputs
		= [ <"/***/", 	makeNode("docBlock", [ [],[] ] )> ]
		+ [ <"/   /", 	makeNode("docBlock", [ [],[] ] )> ] // this matches because all stars (*) are ignored
		+ [ <"/** \n * * */", 	makeNode("docBlock", [ [],[] ] )> ] 
		
		+ [ <"/** this is some description */", 	makeNode("docBlock", [ [ makeNode("description", "this is some description ") ] , [] ])> ]
		+ [ <"/** \n * @var int $number \n */", 	makeNode("docBlock", [], [ makeNode("annotation", makeNode("var", makeNode("types", [ [makeNode("int")] ]), makeNode("variable", "$number"), [] )) ] )> ]
		
		// todo: add more complex tests
		//+ [ <"/** @param int */", 	"docBlock"> ]
		//+ [ <"/** @param class */", 	"docBlock"> ]
		//+ [ <"/** @param $var */", 	"docBlock"> ]
		//+ [ <"/** @param $var type */", 	"docBlock"> ]
		//
		//+ [ <"/** @param object|class|null */", 	"docBlock"> ]
		//+ [ <"/** @param object|class|null $variable */", 	"docBlock"> ]
		//+ [ <"/** @param object|class|null $variable extra comment */", 	"docBlock"> ]
		//
		//+ [ <"/* random text */", 	"docBlock"> ]
		;

	return testParser(#DocBlock, inputs);	
}
