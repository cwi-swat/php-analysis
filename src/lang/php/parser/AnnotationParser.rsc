@note{Please make sure to run tests::lang::php::parser::DocBlockParser when you modify this grammar file}
module lang::php::parser::AnnotationParser

import Node;
import IO;
import Ambiguity;

lexical Number = n: [0-9];
syntax Numbers = ns: Number+;

syntax Id = i: [0-9A-Z]+;
syntax Ida = ia: [0-9A-Z]+; 
syntax Idb = ib: [0-9A-Z]+;
syntax Idc = ic: [0-9A-Z]+; 
syntax Idd = id: [0-9A-Z]+;

//syntax NumberOrIda = Numbers | Id \ [0-9]+;   
syntax NumberOrIdb = nn: Numbers ![0-7]+ | ii: Id;
syntax NumberOrIdc = nn: Numbers | ii: Id \ Number+;  
syntax NumberOrIdd = nn: Numbers | ii: Id \ Numbers;  

public void main() {
	canParse(#NumberOrIda, "34"); // amb
	canParse(#NumberOrIdb, "34"); // apl
	canParse(#NumberOrIdc, "34"); // amb
	canParse(#NumberOrIdd, "34"); // amb
	
	println(getName(parse(#NumberOrIda, "34"))); // amb
	println(getName(parse(#NumberOrIdb, "34"))); // apl
	println(getName(parse(#NumberOrIdc, "34"))); // amb
	println(getName(parse(#NumberOrIdd, "34"))); // amb
}
 
public bool canParse(type[&T<:Tree] t, str input)
{
    try {
        println(input); 
        node res = implode(#node, parse(t, input));
        iprintln(res);
        
    } catch ParseError(loc l): {
        println("Stopped. Failed to parse:");
        println(input);
        println(parse(t, input)); 
        //exit();
        return false;
    } catch: {
    	println("Unknown error... ambigious grammar??");
        println(input);
        iprintln(diagnose(parse(t, input)));
        //println(implode(#node, parse(t, input)));
    	//exit;
    	return false;
    }
   
    return true;
} 
