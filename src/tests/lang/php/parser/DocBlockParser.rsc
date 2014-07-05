module tests::lang::php::parser::DocBlockParser
extend lang::php::parser::DocBlockParser;

// run main to run all the tests
// errors will be printed in the console.
public void main()
{
    print("Testing php types ...");     if (testPhpTypes())     println("Done.");
    print("Testing class types ...");   if (testClassTypes())   println("Done.");
    print("Testing variables...");      if (testVariables())    println("Done.");
    print("Testing annotations...");    if (testAnnotations())  println("Done.");
    print("Testing descriptions...");   if (testDescriptions()) println("Done.");
    
    int numberOfTests = 50;	
    print("Testing <numberOfTests> random multiple types ..."); if (testMultipleTypes(numberOfTests)) println("Done.");

    print("Testing docblocks...");      if (testDocBlocks())    println("Done.");
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

// helper methods to create nodes
private node expectedTypeNode(str nodeName) 
    = makeNode("types", [ [ makeNode(nodeName) ] ]);	
    
private node expectedArrayTypeNode(str nodeName) 
    = makeNode("types", [ [ makeNode("arrayOf", makeNode(nodeName)) ] ]);

public test bool testPhpTypes() 
{
    lrel[str input, node expectedResult] inputs
        = [ <"array",   expectedTypeNode("array")> ] 
        + [ <"array()", expectedTypeNode("array")> ] 
    	
        + [ <"mixed",   expectedTypeNode("mixed")> ] 
        + [ <"mixed()", expectedTypeNode("mixed")> ] 
    	
        + [ <"bool",   expectedTypeNode("bool")> ] 
        + [ <"bool()", expectedTypeNode("bool")> ] 
        + [ <"bool[]", expectedArrayTypeNode("bool")> ] 
        + [ <"boolean",   expectedTypeNode("bool")> ] 
        + [ <"boolean()", expectedTypeNode("bool")> ] 
        + [ <"boolean[]", expectedArrayTypeNode("bool")> ] 
    	
        + [ <"int",   expectedTypeNode("int")> ] 
        + [ <"int()", expectedTypeNode("int")> ] 
        + [ <"int[]", expectedArrayTypeNode("int")> ] 
        
        + [ <"float",   expectedTypeNode("float")> ] 
        + [ <"float()", expectedTypeNode("float")> ] 
        + [ <"float[]", expectedArrayTypeNode("float")> ] 
        
        + [ <"string",   expectedTypeNode("string")> ] 
        + [ <"string()", expectedTypeNode("string")> ] 
        + [ <"string[]", expectedArrayTypeNode("string")> ] 
        
        + [ <"resource",   expectedTypeNode("resource")> ] 
        + [ <"resource()", expectedTypeNode("resource")> ] 
        + [ <"resource[]", expectedArrayTypeNode("resource")> ] 
        
        + [ <"unset",   expectedTypeNode("unset")> ] 
        + [ <"unset()", expectedTypeNode("unset")> ] 
        + [ <"unset[]", expectedArrayTypeNode("unset")> ] 
        ;

    return testParser(#Types, inputs);	
}

public test bool testClassTypes() 
{
    list[str] input 
        = [ "C", "ClassName", "Object" ]
        + [ "OldStyleClasses", "Old_Style_Classes"] 
    //    + ["class_lowercased" ] // does not work because of case sensitivity
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

@doc { Test multiple types, devided by |; example: int|mixed }

public test bool testMultipleTypes(int numberOfTests)
{
    // list of php types
    list[str] keywords = [ "array", "bool", "float", "int", "mixed", "resource", "null", "string", "unset" ];
        
    // list of mixed types (from the array above)
    list[list[str]] lists = [ dup(getMixedKeywordsList(keywords)) | n <- [0 .. numberOfTests] ];	
    
    // create x random inputs	
    lrel[str input, node expectedResult] inputs = [ <listToString(l), listToExpectedOutput(l)> | l <- lists ];
    inputs += [ <"ClassName|null", makeNode("types", [[ makeNode("class", "ClassName"), makeNode("null") ]])> ];

    return testParser(#Types, inputs);
}

// Helper methods for testMultipleTypes
private str listToString(list[str] keywords) = intercalate(getOneFrom(["|", "|", "|", "|", "|", "|", " |", "| ", " | "]), keywords);
private node listToExpectedOutput(list[str] keywords) = makeNode("types", [[ makeNode(k) | k <- keywords ]]);
private list[str] getMixedKeywordsList(list[str] keywords) { return for (i <- [0..getOneFrom([2..5])]) append getOneFrom(keywords); }

public test bool testAnnotations() 
{
    lrel[str input, node expectedResult] inputs
        = [ <"@param int $var",     makeNode("annotation", makeNode("param", makeNode("types", [ [ makeNode("int") ] ]), makeNode("variable", "$var"), [] ))> ]
        + [ <"@param $var int",     makeNode("annotation", makeNode("param", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("int") ] ]), [] ))> ]
        + [ <"@param int $var some text",     makeNode("annotation", makeNode("param", makeNode("types", [ [ makeNode("int") ] ]), makeNode("variable", "$var"), [makeNode("description", "some text")] ))> ]
        + [ <"@param $var int some text",     makeNode("annotation", makeNode("param", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("int") ] ]), [makeNode("description", "some text")] ))> ]
    	
        + [ <"@var mixed $var",     makeNode("annotation", makeNode("var", makeNode("types", [ [ makeNode("mixed") ] ]), makeNode("variable", "$var"), [] ))> ]
        + [ <"@var $var mixed",     makeNode("annotation", makeNode("var", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("mixed") ] ]), [] ))> ]
        + [ <"@var mixed $var some text",     makeNode("annotation", makeNode("var", makeNode("types", [ [ makeNode("mixed") ] ]), makeNode("variable", "$var"), [makeNode("description", "some text")] ))> ]
        + [ <"@var $var mixed some text",     makeNode("annotation", makeNode("var", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("mixed") ] ]), [makeNode("description", "some text")] ))> ]
    	
        + [ <"@var RandomClass $var some text",     makeNode("annotation", makeNode("var", makeNode("types", [ [ makeNode("class", "RandomClass") ] ]), makeNode("variable", "$var"), [makeNode("description", "some text")] ))> ]
        + [ <"@var $var RandomClass some text",     makeNode("annotation", makeNode("var", makeNode("variable", "$var"), makeNode("types", [ [ makeNode("class", "RandomClass") ] ]), [makeNode("description", "some text")] ))> ]
        ;


    return testParser(#Annotation, inputs);	
}
    
public test bool testDocBlocks()
{
    lrel[str input, node expectedResult] inputs
        = [ <"/***/",     makeNode("docBlock", [ [],[] ] )> ]
        + [ <"/   /",     makeNode("docBlock", [ [],[] ] )> ] // this matches because all stars (*) are ignored
        + [ <"/** \n * * */",     makeNode("docBlock", [ [],[] ] )> ] 
    	
        + [ <"/** this is some description */",     makeNode("docBlock", [ [ makeNode("description", "this is some description ") ] , [] ])> ]
        + [ <"/** \n * @var int $number \n */",     makeNode("docBlock", [], [ makeNode("annotation", makeNode("var", makeNode("types", [ [makeNode("int")] ]), makeNode("variable", "$number"), [] )) ] )> ]
    	
        // todo: add more complex tests
        //+ [ <"/** @param int */",     "docBlock"> ]
        //+ [ <"/** @param class */",     "docBlock"> ]
        //+ [ <"/** @param $var */",     "docBlock"> ]
        //+ [ <"/** @param $var type */",     "docBlock"> ]
        //
        //+ [ <"/** @param object|class|null */",     "docBlock"> ]
        //+ [ <"/** @param object|class|null $variable */",     "docBlock"> ]
        //+ [ <"/** @param object|class|null $variable extra comment */",     "docBlock"> ]
        //
        //+ [ <"/* random text */",     "docBlock"> ]
        ;

    return testParser(#DocBlock, inputs);	
}