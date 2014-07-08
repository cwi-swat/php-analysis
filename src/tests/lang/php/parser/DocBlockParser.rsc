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

    print("Testing docblocks...");      if (testDocBlocks())     println("Done.");
    print("Testing real docblocks..."); testFullDocBlocks();
}

// test the parser with some inputs
public bool testParser(type[&T<:Tree] t, lrel[str input, node expectedResult] inputs)
{
    for (i <- inputs) {
        try { 
            // try to parse
            node n = implode(#node, parse(t, i.input));
        	
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
        = [ <"array",   makeTypeNode("array")> ] 
        + [ <"array()", makeTypeNode("array")> ] 
    	
        + [ <"mixed",   makeTypeNode("mixed")> ] 
        + [ <"mixed()", makeTypeNode("mixed")> ] 
    	
        + [ <"bool",   makeTypeNode("bool")> ] 
        + [ <"bool()", makeTypeNode("bool")> ] 
        + [ <"bool[]", makeArrayTypeNode("bool")> ] 
        + [ <"boolean",   makeTypeNode("bool")> ] 
        + [ <"boolean()", makeTypeNode("bool")> ] 
        + [ <"boolean[]", makeArrayTypeNode("bool")> ] 
    	
        + [ <"int",   makeTypeNode("int")> ] 
        + [ <"int()", makeTypeNode("int")> ] 
        + [ <"int[]", makeArrayTypeNode("int")> ] 
        
        + [ <"float",   makeTypeNode("float")> ] 
        + [ <"float()", makeTypeNode("float")> ] 
        + [ <"float[]", makeArrayTypeNode("float")> ] 
        
        + [ <"string",   makeTypeNode("string")> ] 
        + [ <"string()", makeTypeNode("string")> ] 
        + [ <"string[]", makeArrayTypeNode("string")> ] 
        
        + [ <"resource",   makeTypeNode("resource")> ] 
        + [ <"resource()", makeTypeNode("resource")> ] 
        + [ <"resource[]", makeArrayTypeNode("resource")> ] 
        
        + [ <"unset",   makeTypeNode("unset")> ] 
        + [ <"unset()", makeTypeNode("unset")> ] 
        + [ <"unset[]", makeArrayTypeNode("unset")> ] 
        ;

    return testParser(#Types, inputs);	
}

// helper methods to create nodes
private node makeTypeNode(str nodeName) = makeNode("types", [ [ makeNode(nodeName) ] ]);	
private node makeTypesNode(list[str] keywords) = makeNode("types", [[ makeNode(k) | k <- keywords ]]);
private node makeArrayTypeNode(str nodeName) = makeNode("types", [ [ makeNode("arrayOf", makeNode(nodeName)) ] ]);
private list[node] makeDescriptionNode(list[str] descriptions) = [ makeNode("description", desc) | desc <- descriptions ];

public test bool testClassTypes() 
{
    list[str] input 
        = [ "C", "ClassName", "Object" ]
        + [ "OldStyleClasses", "Old_Style_Classes"] 
        + [ "class_lowercased" ] 
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
    lrel[str input, node expectedResult] inputs = [ <listToString(l), makeTypesNode(l)> | l <- lists ];
    inputs += [ <"ClassName|null", makeNode("types", [[ makeNode("class", "ClassName"), makeNode("null") ]])> ];

    return testParser(#Types, inputs);
}

// Helper methods for testMultipleTypes
private str listToString(list[str] keywords) = intercalate(getOneFrom(["|", "|", "|", "|", "|", "|", " |", "| ", " | "]), keywords);
private list[str] getMixedKeywordsList(list[str] keywords) { return for (i <- [0..getOneFrom([2..5])]) append getOneFrom(keywords); }

public test bool testAnnotations() 
{
    lrel[str input, node expectedResult] inputs
        = [ <"@param int $var",    makeAnnotationNode("param", [makeNode("int")], "$var", [])> ]
        //+ [ <"@param $var int",    makeAnnotationNode("param", "$var", [makeNode("int")], [])> ]
        + [ <"@param int $var some text",    makeAnnotationNode("param", [makeNode("int")], "$var", ["some text"])> ]
        //+ [ <"@param $var int some text",    makeAnnotationNode("param", "$var", [makeNode("int")], ["some text"])> ]

        + [ <"@var mixed $var",    makeAnnotationNode("var", [makeNode("mixed")], "$var", [])> ]
        //+ [ <"@var $var mixed",    makeAnnotationNode("var", "$var", [makeNode("mixed")], [])> ]
        + [ <"@var mixed $var some text",    makeAnnotationNode("var", [makeNode("mixed")], "$var", ["some text"])> ]
        //+ [ <"@var $var mixed some text",    makeAnnotationNode("var", "$var", [makeNode("mixed")], ["some text"])> ]
        
        + [ <"@var RandomClass $var some text",    makeAnnotationNode("var", [makeNode("class", "RandomClass")], "$var", ["some text"])> ]
        //+ [ <"@var $var RandomClass some text",    makeAnnotationNode("var", "$var", [makeNode("class", "RandomClass")], ["some text"])> ]
        ;
	
    return testParser(#Annotation, inputs);	
}

// helper methods for testAnnotations
private node makeAnnotationNode(str annoType, list[node] varTypes, str var, list[str] descriptions) {
	typesNodes = isEmpty(varTypes) ? [] : makeNode("types", [[ vt | vt <- varTypes ]]);	
	node varNode = makeNode("variable", var);
	descNodes = isEmpty(descriptions) ? [] : makeDescriptionNode(descriptions);	
	
	return makeNode("annotation", makeNode(annoType, <typesNodes, varNode, descNodes> ));
}
 
private node makeAnnotationNode(str annoType, str var, list[node] varTypes, list[str] descriptions) {
	typesNodes = isEmpty(varTypes) ? [] : makeNode("types", [[ vt | vt <- varTypes ]]);	
	node varNode = makeNode("variable", var);
	descNodes = isEmpty(descriptions) ? [] : makeDescriptionNode(descriptions);	
	
	return makeNode("annotation", makeNode(annoType, <varNode, typesNodes, descNodes> ));
}

public test bool testDocBlocks()
{
    lrel[str input, node expectedResult] inputs
        = [ <"/***/",     makeNode("docBlock", [ [],[] ] )> ]
        + [ <"/   /",     makeNode("docBlock", [ [],[] ] )> ] // this matches because all stars (*) are ignored
        + [ <"/** \n * * */",     makeNode("docBlock", [ [],[] ] )> ] 
    	
        + [ <"/** this is some description */",     makeNode("docBlock", [ [ makeNode("description", "this is some description ") ] , [] ])> ]
        + [ <"/** \n * this is some description */",     makeNode("docBlock", [ [ makeNode("description", "this is some description ") ] , [] ])> ]
        + [ <"/** \n * @var int $number \n */",     makeNode("docBlock", [], [ makeAnnotationNode("var", [makeNode("int")], "$number", [] ) ] )> ]
    	
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

public void testFullDocBlocks()
{
    loc baseDir = |project://PHPAnalysis/src/tests/resources/parser|;
   
    for (l <- baseDir.ls, l.extension == "txt") {
        int success = 0, total = 0;
    
        list[str] phpdocs = readTextValueFile(#list[str],l);
            
        for(phpdoc <- phpdocs)
        {
            total += 1;
            if (canParse(#DocBlock, phpdoc)) 
                success += 1;
        }

        // parse results
        println("<100*success/total>% :: (<success>/<total>) :: <l>");  
    }
}

public bool canParse(type[&T<:Tree] t, str input)
{
    try {
        //println(input); 
        node res = implode(#node, parse(t, input));
        //println(res);
        
    } catch ParseError(loc l): {
        //println("Stopped. Failed to parse:");
        //println(input);
        //println(parse(t, input)); 
        //exit();
        return false;
    } catch: {
    	//println("Unknown error... ambigious grammar??");
     //   println(input);
     //   println(implode(#node, parse(t, input)));
    	//exit;
    	return false;
    }
   
    return true;
} 