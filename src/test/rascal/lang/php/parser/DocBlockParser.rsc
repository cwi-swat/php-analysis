@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module tests::lang::php::parser::DocBlockParser
extend lang::php::parser::DocBlockParser;

import ParseTree;
import IO;
import Node;
import List;
import ValueIO;

// hardcoded test inputs:
private list[str] phpTypes = ["array", "mixed", "bool", "boolean", "int", "integer", "float", "string", "resource", "unset"];
private list[str] variables = [ "$var", "$object", "$OBJ", "$_OBJ", "$_OBJ_o", "$_OBJ_ÿ", "$_{$O_ÿ}", "$a_b_c", "$randomName" ];
private list[str] classNames = [ "C", "ClassName", "Object" , "OldStyleClasses", "Old_Style_Classes", "class_lowercased", "\\ClassName", "\\Package\\ClassName", "\\Package\\SubPackage\\ClassName" ];
private list[str] descriptions = [ "var", "object", "OBJ", "_OBJ", "_OBJ_o", "_OBJ_ÿ", "_{$OB_ÿ}", "$var", "a_b_c", "random text", " random text ", "This is some random comment", "  This is some random comment  " ];

// run main to run all the tests
// output will be printed in the console.
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
    
    str filterFileNames = "";
    print("Testing real docblocks...\n"); testFullDocBlocks(filterFileNames);
}

// test the parser with some inputs
public bool testParser(type[&T<:Tree] t, lrel[str input, node expectedResult] inputs)
{
    for (i <- inputs) {
        try { 
            // try to parse
            node n = implode(#node, parse(t, i.input));
        	
            // check if the result is the expected result
            assert n == i.expectedResult : "Expected:\n<i.expectedResult>\nActual:\n<delAnnotationsRec(n)>";
        	
        } catch ParseError(loc l): {
            println("PARSE ERROR!! I found a parse error at type: <t> || input: <i> \nThis test stopped.\n"); 
            return false;
        }
    }
    return true;
}

public test bool testPhpTypes() 
{
    // for all phpTypes, create int, int[], int()[] and int()
    lrel[str input, node expectedResult] inputs
        = [ <phpType,       makeTypeNode(labelForType(phpType))>, 
            <phpType+"()",  makeTypeNode(labelForType(phpType))>, 
            <phpType+"()[]",makeArrayTypeNode(labelForType(phpType))>,
            <phpType+"[]",  makeArrayTypeNode(labelForType(phpType))> 
            | phpType <- phpTypes 
          ] 
        ;

    return testParser(#Types, inputs);	
}
// rename boolean to bool in the result
private str labelForType("boolean") = "bool";
private str labelForType("integer") = "int";
private str labelForType(str \type) = \type;

// helper methods to create nodes
private node makeTypeNode(str nodeName) = makeNode("types", [ [ makeNode(nodeName) ] ]);	
private node makeTypesNode(list[str] keywords) = makeNode("types", [[ makeNode(k) | k <- keywords ]]);
private node makeArrayTypeNode(str nodeName) = makeNode("types", [ [ makeNode("arrayOf", makeNode(nodeName)) ] ]);
private node makeClassTypesNode(str className) = makeNode("types", [[makeNode("class", className)]]);
private list[node] makeDescriptionNode(list[str] descriptions) = [ makeNode("description", desc) | desc <- descriptions ];

public test bool testClassTypes() 
{
    lrel[str input, node expectedResult] inputs = [ <i, makeClassTypesNode(i)> | i <- classNames ];

    return testParser(#Types, inputs);	
}

public test bool testVariables() 
{
    lrel[str input, node expectedResult] inputs = [ <i, makeNode("variable", i)> | i <- variables ];

    return testParser(#Var, inputs);	
}

public test bool testDescriptions() 
{	
    lrel[str input, node expectedResult] inputs = [ <i, makeNode("description", i)> | i <- descriptions ];

    return testParser(#Description, inputs);	
}

@doc { Test multiple types, devided by `|`; example: int|mixed, Object|void }
public test bool testMultipleTypes(int numberOfTests)
{
    // list of php types
    list[str] keywords = [ "array", "bool", "float", "int", "mixed", "resource", "null", "string", "unset" ];
        
    // list of mixed types (from the array above)
    list[list[str]] lists = [ dup(getMixedKeywordsList(keywords)) | n <- [0 .. numberOfTests] ];	
    
    // create x random inputs	
    lrel[str input, node expectedResult] inputs = [ <listToString(l), makeTypesNode(l)> | l <- lists ];
    // add one hardcoded mixed class
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
        + [ <"@var mixed $var",    makeAnnotationNode("var", [makeNode("mixed")], "$var", [])> ]
        + [ <"@param int $var some text",    makeAnnotationNode("param", [makeNode("int")], "$var", ["some text"])> ]
        + [ <"@var mixed $var some text",    makeAnnotationNode("var", [makeNode("mixed")], "$var", ["some text"])> ]
        + [ <"@var RandomClass $var some text",    makeAnnotationNode("var", [makeNode("class", "RandomClass")], "$var", ["some text"])> ]
        + [ <"@return RandomClass",    makeAnnotationNode("return", [makeNode("class", "RandomClass")], [])> ]
        + [ <"@throws Exception",    makeNode("annotation", [ makeNode("other", "@throws"), [ makeNode("description", "Exception") ] ] )> ]
        ;
	
    return testParser(#Annotation, inputs);	
}

// helper methods for testAnnotations
private node makeAnnotationNode(str annoType, list[node] varTypes, str var, list[str] descriptions) 
{
	typesNodes = isEmpty(varTypes) ? [] : makeNode("types", [[ vt | vt <- varTypes ]]);	
	node varNode = makeNode("variable", var);
	descNodes = isEmpty(descriptions) ? [] : makeDescriptionNode(descriptions);	

	return makeNode("annotation", makeNode(annoType, <typesNodes, varNode>), descNodes);
}
 
private node makeAnnotationNode(str annoType, list[node] varTypes, list[str] descriptions) 
{
	typesNodes = isEmpty(varTypes) ? [] : makeNode("types", [[ vt | vt <- varTypes ]]);	
	descNodes = isEmpty(descriptions) ? [] : makeDescriptionNode(descriptions);	

	return makeNode("annotation", makeNode(annoType, typesNodes), descNodes);
}
 
public test bool testDocBlocks()
{
    lrel[str input, node expectedResult] inputs
        = [ <"/***/",     makeNode("docBlock", [ [],[] ] )> ]
        + [ <"/   /",     makeNode("docBlock", [ [],[] ] )> ] // this matches because all stars (*) are ignored
        + [ <"/** \n * * */",     makeNode("docBlock", [ [],[] ] )> ] 
    	
        + [ <"/** this is some description */",     makeNode("docBlock", [ [ makeNode("description", "this is some description ") ] , [] ])> ]
        + [ <"/** \n * this is some description */",makeNode("docBlock", [ [ makeNode("description", "this is some description ") ] , [] ])> ]
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

public void testFullDocBlocks(str filtr)
{
	// helper method, apply filter when a filter is applied
	private bool filterFile(loc l) = filtr != "" ==> /<filtr>/ := l.file;
	
    loc baseDir = |project://PHPAnalysis/src/tests/resources/parser|;

  	set[loc] files = { f | f <- baseDir.ls, f.extension == "txt", filterFile(f) };
    for (l <- files) {
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
        //println(input);
        //iprintln(diagnose(parse(t, input)));
        //println(implode(#node, parse(t, input)));
    	//exit;
    	return false;
    }
   
    return true;
} 