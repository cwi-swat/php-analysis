module lang::php::m3::ParserTest

import ParseTree;
import IO;
import List;
import Node;
import Set;
import ValueIO;

// added \u002A == * to the layout
layout Standard 
  = Whitespace* !>> [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "//";
  
//extend lang::std::Whitespace; // for spaces and such                                                      
lexical Whitespace 
  = [\u0009-\u000D \u0020 \u002A \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000]
  ;

lexical ClassName 
	= [a-zA-Z_\\]+ !>> [a-zA-Z_\\] \ Keywords
	;
	
lexical Var 
	= "$" !>> [a-zA-Z_]+ \ Keywords
	;
    
// keywords to match
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
	= docBlock: "/" Description* Annotation* Description* "/"
	;

//lexical Text
//	= variable: Variable 
//	> description: Description
//	;
//	
//lexical Description = [a-z A-Z 0-9 _ \ \t \n] \ Keywords;
//lexical Variable = "$" Id \ Keywords; 
//
syntax Annotation
	= annotation: AnnotationType 
	;

syntax AnnotationType
	= param: 	ParamAnnotation
	| \return: 	ReturnAnnotation
	| var: 		VarAnnotation	
	;

syntax ParamAnnotation
	= "@param" Types Variable	
	> "@param" Variable Types
	> "@param" Variable
	> "@param" Types 
	;
	
syntax ReturnAnnotation
	= "@return" Types 
	;
	
syntax VarAnnotation
	= "@var" Types Variable	
	> "@var" Variable Types
	> "@var" Variable
	> "@var" Types 
	;

// type can be a php type: int, string, bool
// type can be a class: Foo, \Foo, \Package\SubPackage\Foo
// type can be an array of types: int[], \Package\SubPackage\Foo

syntax Variable
	= Var
	//= empty:
	//| Var
	;
	
syntax Types 
	= types: {Type "|"}*
	//= empty:
	//| types: {Type "|"}*
	;
syntax Type
	= PhpType "()" // sometimes mixed is written as mixed()
	> PhpType 
	| class: ClassName
	;

syntax PhpType
	= arrayOf: LiteralName "[]"
	> LiteralName 
	;

syntax LiteralName
	= array: "array"
	| \bool: ("bool" | "boolean")
	| float: "float"
	| \int: ("int" | "integer")
	| mixed: "mixed"
	| resource: "resource"
	| \null: "null"
	| string: "string"
	| unset: "unset"
	;


public void main()
{
	println("Testing php types ..."); if (testPhpTypes()) println("Done. \n");
	println("Testing class types ..."); if (testClassTypes()) println("Done. \n");
	println("Testing variables..."); if (testVariables()) println("Done. \n");
	println("Testing annotations..."); if (testAnnotations()) println("Done. \n");
	
	int numberOfTests = 50;	
	println("Testing <numberOfTests> random multiple types ..."); if (testMultipleTypes(numberOfTests)) println("Done. \n");
}

// test the parser with some inputs
public bool testParser(type[&T<:Tree] t, lrel[str input, str expectedType] inputs)
{
	for (i <- inputs) {
		try { 
			// try to parse
			node n = implode(#node, parse(t, i.input));
			//println("<i.input> ::\> <n>");
			// check if the type is the expected type
			assert getName(n) == i.expectedType : "Type of <getName(n)> is not the expected: <i.expectedType>";
		} catch ParseError(loc l): {
			println("PARSE ERROR!! I found a parse error at type: <t> || input: <i>");
			println("This test stopped.");
			println("");
			return false;
		}
    }
    return true;
}

public bool testPhpTypes() 
{
	lrel[str input, str expectedType] inputs
		= [ <"array", 	"array"> ]
		+ [ <"array()", "array"> ]
		
		+ [ <"mixed", 	"mixed"> ]
		+ [ <"mixed()", "mixed"> ]
		
		+ [ <"bool", 	"bool"> ]
		+ [ <"bool()", 	"bool"> ]
		+ [ <"bool[]", 	"arrayOf"> ]
		+ [ <"boolean", 	"bool"> ]
		+ [ <"boolean()", 	"bool"> ]
		+ [ <"boolean[]", 	"arrayOf"> ]
		
		+ [ <"int", 	"int"> ]
		+ [ <"int()", 	"int"> ]
		+ [ <"int[]", 	"arrayOf"> ]
		
		+ [ <"string",		"string"> ]
		+ [ <"string()",	"string"> ]
		+ [ <"string[]",	"arrayOf"> ]
		
		+ [ <"resource",	"resource"> ]
		+ [ <"resource()",	"resource"> ]
		+ [ <"resource[]",	"arrayOf"> ]
		
		+ [ <"int",			"int"> ]
		+ [ <"int()",		"int"> ]
		+ [ <"int[]",		"arrayOf"> ]
		
		+ [ <"unset",		"unset"> ]
		+ [ <"unset()",		"unset"> ]
		+ [ <"unset[]",		"arrayOf"> ]
		;

	return testParser(#Type, inputs);	
}

public bool testClassTypes() 
{
	lrel[str input, str expectedType] inputs
		= [ <"OBJECT", 	"class"> ]
		+ [ <"Object", 	"class"> ]
		+ [ <"object", 	"class"> ]
		
		+ [ <"\\ClassName", 						"class"> ]
		+ [ <"\\Package\\ClassName", 				"class"> ]
		+ [ <"\\Package\\SubPackage\\ClassName", 	"class"> ]
		;

	return testParser(#Type, inputs);	
}

public bool testVariables() 
{
	lrel[str input, str expectedType] inputs
		= [ <"$var", 	"class"> ]
		+ [ <"$object", 	"class"> ]
		//+ [ <"$a_b_c", 	"class"> ]
		
		;

	return testParser(#Type, inputs);	
}

public bool testMultipleTypes(int numberOfTests)
{
	// magic to get some random collection
	private str getRandomCollection(list[str] keywords)
		= intercalate(getOneFrom(["|", " |", "| ", " | "]), getOneFrom(toList(permutations(slice(keywords, getOneFrom([0..(size(keywords)-4)]), getOneFrom([1..5]))))));
	
	// list of keywords 
	list[str] keywords = [ "array", "bool", "boolean", "float", "int", "mixed", "resource", "null", "string", "unset" ];
	// create x random inputs	
	lrel[str input, str expectedType] inputs = [ <getRandomCollection(keywords), "types"> | n <- [0 .. numberOfTests] ];
		
	return testParser(#Types, inputs);
}

public bool testAnnotations() 
{
	lrel[str input, str expectedType] inputs
		= [ <"@param", 	"annotation"> ]
		+ [ <"@var", 	"annotation"> ]
		+ [ <"@return", "annotation"> ]
		
		+ [ <"@param int", "annotation"> ]
		+ [ <"@param int $var", "annotation"> ]
		;

	return testParser(#Annotation, inputs);	
}
	
public void testClassName() 
{
	lrel[str input, str expectedType] inputs
		= [ <"c", 	"ClassName"> ]
		+ [ <"C", 	"ClassName"> ]
		
		+ [ <"ClassName", 	"ClassName"> ]
		+ [ <"\\ClassName",	"ClassName"> ]
		
		+ [ <"\\Package\\ClassName", 				"ClassName"> ]
		+ [ <"\\Package\\SubPackage\\ClassName",	"ClassName"> ]
		;

	testParser(#Id, inputs);	
}

public list[str] testFiles() 
	//= { "/** @param mixed $var  */" }
	//+ { "/**   @param */" }
	= [ "/***/" ]
	+ [ "/** */" ]
	+ [ "/** \n */" ]
	+ [ "/** *	*/" ]
	+ [ "/** * @return */" ]
	+ [ "/** * @var */" ]
	+ [ "/** * @param */" ]
	+ [ "/** @return mixed */" ]
	//+ [ "/** sadf sadf soidf sadf sd */" ]
	//+ [ "/** * sadf sadf soidf sadf sd */" ]
	//= { "/**   @param */" }
	//+ { "/**   @param @param @return mixed */" }
	//+ { "/**   \n * public class PopupMenu extends  Object /reference/java/lang/Object.html implements MenuBuilder.Callback MenuPresenter.Callback 	*/" }
	;
/*
  Class signatures for testing:
   public class PopupMenu extends  Object /reference/java/lang/Object.html implements MenuBuilder.Callback MenuPresenter.Callback
   public abstract class AbsListView extends  AdapterView /reference/android/widget/AdapterView.html <T extends  Adapter /reference/android/widget/Adapter.html > implements  TextWatcher /reference/android/text/TextWatcher.html   ViewTreeObserver.OnGlobalLayoutListener /reference/android/view/ViewTreeObserver.OnGlobalLayoutListener.html   ViewTreeObserver.OnTouchModeChangeListener /reference/android/view/ViewTreeObserver.OnTouchModeChangeListener.html   Filter.FilterListener /reference/android/widget/Filter.FilterListener.html
  
  Method signatures for testing:
   public static AtomicReferenceFieldUpdater /reference/java/util/concurrent/atomic/AtomicReferenceFieldUpdater.html <U, W> newUpdater (Class /reference/java/lang/Class.html <U> tclass, Class /reference/java/lang/Class.html <W> vclass, String /reference/java/lang/String.html  fieldName)
   public T execute (HttpUriRequest /reference/org/apache/http/client/methods/HttpUriRequest.html  request, ResponseHandler /reference/org/apache/http/client/ResponseHandler.html <? extends T> responseHandler, HttpContext /reference/org/apache/http/protocol/HttpContext.html  context)
   public Set /reference/java/util/Set.html <String /reference/java/lang/String.html > getExtendedKeyUsage ()
   public Collection /reference/java/util/Collection.html <List /reference/java/util/List.html <?>> getPathToNames ()
   public abstract int drainTo (Collection /reference/java/util/Collection.html <? super E> c)
   public void putAll (Map /reference/java/util/Map.html <? extends K, ? extends V> map)
   public static SortedMap /reference/java/util/SortedMap.html <K, V> unmodifiableSortedMap (SortedMap /reference/java/util/SortedMap.html <K, ? extends V> map)
   public Map /reference/java/util/Map.html <String /reference/java/lang/String.html , List /reference/java/util/List.html <String /reference/java/lang/String.html >> getHeaderFields ()
*/