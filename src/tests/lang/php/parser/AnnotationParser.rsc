module tests::lang::php::parser::AnnotationParser
extend lang::php::parser::AnnotationParser;

// run main to run all the tests
// errors will be printed in the console.
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

public test bool testPhpTypes() 
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

public test bool testClassTypes() 
{
	list[str] input 
		= [ "C", "ClassName", "Object" ]
		+ [ "OldStyleClasses", "Old_Style_Classes"] 
	//	+ ["class_lowercased" ] // does not work because of case sensitivity
		+ [ "\\ClassName", "\\Package\\ClassName", "\\Package\\SubPackage\\ClassName" ];
		
	lrel[str input, node expectedResult] inputs = [ <i, makeNode("types", [[makeNode("class", i)]])> | i <- input ];

	return testParser(#Types, inputs);	
}

public test bool testVariables() 
{
	list[str] input 
		= [ "$var", "$object", "$OBJ", "$_OBJ", "$_OBJ_o" ]
		+ [ "$_OBJ_ÿ", "$_{$O_ÿ}", "$a_b_c", "$randomName" ]
		;
	lrel[str input, node expectedResult] inputs = [ <i, makeNode("variable", i)> | i <- input ];

	return testParser(#Variable, inputs);	
}

public test bool testDescriptions() 
{
	list[str] input 
		= [ "var", "object", "OBJ", "_OBJ", "_OBJ_o", "_OBJ_ÿ", "_{$OB_ÿ}",  "a_b_c" ] 
		+ [ "random text", " random text ", "This is some random comment", "  This is some random comment  " ]
		;
		
	lrel[str input, node expectedResult] inputs = [ <i, makeNode("description", i)> | i <- input ];

	return testParser(#Description, inputs);	
}

// this method contains 3 private methods, not the most pretty thing
public test bool testMultipleTypes(int numberOfTests)
{
//	// used these three `magic` methods to generate tests.
//	// magic to get some random collection
//	private str listToString(list[str] keywords)
//		= intercalate(getOneFrom(["|", " |", "| ", " | "]), keywords);
//
//	// list to expected output
//	private node listToExpectedOutput(list[str] keywords)
//		= makeNode("types", [[ makeNode(k) | k <- keywords ]]);
//		
//	private list[str] getMixedKeywordsList(list[str] keywords) 
//		= getOneFrom(toList(permutations(slice(keywords, getOneFrom([0..(size(keywords)-4)]), getOneFrom([1..5])))));
//	
//	// list of php types
//	list[str] keywords = [ "array", "bool", "float", "int", "mixed", "resource", "null", "string", "unset" ];
//	// list of mixed types (from the array above)
//	list[list[str]] lists = [ getMixedKeywordsList(keywords) | n <- [0 .. numberOfTests] ];	
//	
//	// create x random inputs	
//	lrel[str input, node expectedResult] inputs = [ <listToString(l), listToExpectedOutput(l)> | l <- lists ];
//
//	iprintln(inputs);
//	exit;

	lrel[str input, node expectedResult] inputs = [
  <"float","types"(["float"()])>,
  <"float|bool|array","types"([ "float"(), "bool"(), "array"() ])>,
  <"float | bool | array","types"([ "float"(), "bool"(), "array"() ])>,
  <"int |float","types"([ "int"(), "float"() ])>,
  <"bool| float| int| array","types"([ "bool"(), "float"(), "int"(), "array"() ])>,
  <"mixed |resource","types"([ "mixed"(), "resource"() ])>,
  <"bool","types"(["bool"()])>,
  <"int|mixed|float","types"([ "int"(), "mixed"(), "float"() ])>,
  <"bool |float |int |mixed","types"([ "bool"(), "float"(), "int"(), "mixed"() ])>,
  <"float|bool","types"([ "float"(), "bool"() ])>,
  <"mixed| resource","types"([ "mixed"(), "resource"() ])>,
  <"mixed|int","types"([ "mixed"(), "int"() ])>,
  <"mixed| resource","types"([ "mixed"(), "resource"() ])>,
  <"mixed| null| resource","types"([ "mixed"(), "null"(), "resource"() ])>,
  <"mixed| string| resource| null","types"([ "mixed"(), "string"(), "resource"(), "null"() ])>,
  <"bool|mixed|int|float","types"([ "bool"(), "mixed"(), "int"(), "float"() ])>,
  <"bool|array","types"([ "bool"(), "array"() ])>,
  <"float| mixed| int| resource","types"([ "float"(), "mixed"(), "int"(), "resource"() ])>,
  <"int | mixed | float | resource","types"([ "int"(), "mixed"(), "float"(), "resource"() ])>,
  <"int| resource| mixed","types"([ "int"(), "resource"(), "mixed"() ])>,
  <"float |int |mixed","types"([ "float"(), "int"(), "mixed"() ])>,
  <"float | int | mixed | bool","types"([ "float"(), "int"(), "mixed"(), "bool"() ])>,
  <"float|int|bool|array","types"([ "float"(), "int"(), "bool"(), "array"() ])>,
  <"float| array| int| bool","types"([ "float"(), "array"(), "int"(), "bool"() ])>,
  <"mixed","types"(["mixed"()])>,
  <"mixed|int","types"([ "mixed"(), "int"() ])>,
  <"bool","types"(["bool"()])>,
  <"mixed| resource","types"([ "mixed"(), "resource"() ])>,
  <"float | int | bool","types"([ "float"(), "int"(), "bool"() ])>,
  <"array | bool","types"([ "array"(), "bool"() ])>,
  <"bool | float | int","types"([ "bool"(), "float"(), "int"() ])>,
  <"bool|float|array","types"([ "bool"(), "float"(), "array"() ])>,
  <"mixed| resource| int","types"([ "mixed"(), "resource"(), "int"() ])>,
  <"mixed","types"(["mixed"()])>,
  <"array","types"(["array"()])>,
  <"int | mixed","types"([ "int"(), "mixed"() ])>,
  <"string| resource| null| mixed","types"([ "string"(), "resource"(), "null"(), "mixed"() ])>,
  <"float |int","types"([ "float"(), "int"() ])>,
  <"string| mixed| resource| null","types"([ "string"(), "mixed"(), "resource"(), "null"() ])>,
  <"int | float | bool","types"([ "int"(), "float"(), "bool"() ])>,
  <"float |int |resource |mixed","types"([ "float"(), "int"(), "resource"(), "mixed"() ])>,
  <"resource|int|mixed","types"([ "resource"(), "int"(), "mixed"() ])>,
  <"int","types"(["int"()])>,
  <"bool","types"(["bool"()])>,
  <"mixed","types"(["mixed"()])>,
  <"mixed| int| resource| null","types"([ "mixed"(), "int"(), "resource"(), "null"() ])>,
  <"int |bool |array |float","types"([ "int"(), "bool"(), "array"(), "float"() ])>,
  <"array","types"(["array"()])>,
  <"float","types"(["float"()])>,
  <"float |int","types"([ "float"(), "int"() ])>,
  <"mixed | float | resource | int","types"([ "mixed"(), "float"(), "resource"(), "int"() ])>,
  <"mixed | int | float","types"([ "mixed"(), "int"(), "float"() ])>,
  <"mixed|bool|int|float","types"([ "mixed"(), "bool"(), "int"(), "float"() ])>,
  <"mixed| null| resource| string","types"([ "mixed"(), "null"(), "resource"(), "string"() ])>,
  <"mixed","types"(["mixed"()])>,
  <"array","types"(["array"()])>,
  <"float| resource| int| mixed","types"([ "float"(), "resource"(), "int"(), "mixed"() ])>,
  <"int","types"(["int"()])>,
  <"resource | int | mixed | float","types"([ "resource"(), "int"(), "mixed"(), "float"() ])>,
  <"int | float","types"([ "int"(), "float"() ])>,
  <"bool| float","types"([ "bool"(), "float"() ])>,
  <"bool|array","types"([ "bool"(), "array"() ])>,
  <"bool","types"(["bool"()])>,
  <"bool |float |int |mixed","types"([ "bool"(), "float"(), "int"(), "mixed"() ])>,
  <"int | mixed","types"([ "int"(), "mixed"() ])>,
  <"bool|array","types"([ "bool"(), "array"() ])>,
  <"null|mixed|string|resource","types"([ "null"(), "mixed"(), "string"(), "resource"() ])>,
  <"mixed | int","types"([ "mixed"(), "int"() ])>,
  <"mixed| int| float| bool","types"([ "mixed"(), "int"(), "float"(), "bool"() ])>,
  <"resource |mixed","types"([ "resource"(), "mixed"() ])>,
  <"bool| float| int| mixed","types"([ "bool"(), "float"(), "int"(), "mixed"() ])>,
  <"resource|null|mixed|string","types"([ "resource"(), "null"(), "mixed"(), "string"() ])>,
  <"float","types"(["float"()])>,
  <"bool |array |float","types"([ "bool"(), "array"(), "float"() ])>,
  <"mixed |resource |null","types"([ "mixed"(), "resource"(), "null"() ])>,
  <"mixed |resource","types"([ "mixed"(), "resource"() ])>,
  <"array","types"(["array"()])>,
  <"array | float | bool","types"([ "array"(), "float"(), "bool"() ])>,
  <"mixed | resource","types"([ "mixed"(), "resource"() ])>,
  <"resource| null| string| mixed","types"([ "resource"(), "null"(), "string"(), "mixed"() ])>,
  <"int| mixed| float| resource","types"([ "int"(), "mixed"(), "float"(), "resource"() ])>,
  <"float| bool| array| int","types"([ "float"(), "bool"(), "array"(), "int"() ])>,
  <"int| bool| mixed| float","types"([ "int"(), "bool"(), "mixed"(), "float"() ])>,
  <"int","types"(["int"()])>,
  <"array","types"(["array"()])>,
  <"float","types"(["float"()])>,
  <"float | array | bool | int","types"([ "float"(), "array"(), "bool"(), "int"() ])>,
  <"int","types"(["int"()])>,
  <"int| mixed| bool| float","types"([ "int"(), "mixed"(), "bool"(), "float"() ])>,
  <"float| bool| mixed| int","types"([ "float"(), "bool"(), "mixed"(), "int"() ])>,
  <"array | bool","types"([ "array"(), "bool"() ])>,
  <"float","types"(["float"()])>,
  <"int|mixed|resource","types"([ "int"(), "mixed"(), "resource"() ])>,
  <"bool|float|int","types"([ "bool"(), "float"(), "int"() ])>,
  <"int |resource |float |mixed","types"([ "int"(), "resource"(), "float"(), "mixed"() ])>,
  <"float| bool| int","types"([ "float"(), "bool"(), "int"() ])>,
  <"int","types"(["int"()])>,
  <"float","types"(["float"()])>,
  <"resource| mixed| null","types"([ "resource"(), "mixed"(), "null"() ])>,
  <"array","types"(["array"()])>
];
	
		
		
	return testParser(#Types, inputs);
}

public test bool testAnnotations() 
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
	
public test bool testDocBlocks()
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