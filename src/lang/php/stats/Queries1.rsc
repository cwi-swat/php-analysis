module lang::php::stats::Queries1

import Prelude;
import lang::csv::IO;
import lang::php::util::Utils;
import Exprs = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv?funname=csvExprs|;
import Stmts = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/stmts.csv?funname=csvStmts|;

/* Brief log of observations and questions:
 - CVS resource did not work with field names that are Rascal reserved keywords (fixed).
 - tuple concatenation does not preserve field names.
 - How to conveniently handle tuples and their type? I would like to have (for instance)
    list[str] fieldsOf(tuple t);
   but we cannot type this since we have to explicitly specify the element types of the tuple :-(
   Of course, this function can get a value argument but that is not so nice.
   Here we do all this manually.
*/


list[str] featureNames = ["product", "version", "array", "fetcharraydim", "fetchclassconst", "assign", "assignwithoperationbitwiseand", "assignwithoperationbitwiseor", "assignwithoperationbitwisexor", "assignwithoperationconcat", "assignwithoperationdiv", "assignwithoperationminus", "assignwithoperationmod", "assignwithoperationmul", "assignwithoperationplus", "assignwithoperationrightshift", "assignwithoperationleftshift", "assignwithoperationbooleanand", "assignwithoperationbooleanor", "assignwithoperationlogicaland", "assignwithoperationlogicalor", "assignwithoperationlogicalxor", "listassign", "refassign", "binaryoperationbitwiseand", "binaryoperationbitwiseor", "binaryoperationbitwisexor", "binaryoperationconcat", "binaryoperationdiv", "binaryoperationminus", "binaryoperationmod", "binaryoperationmul", "binaryoperationplus", "binaryoperationrightshift", "binaryoperationleftshift", "binaryoperationbooleanand", "binaryoperationbooleanor", "binaryoperationgt", "binaryoperationgeq", "binaryoperationlogicaland", "binaryoperationlogicalor", "binaryoperationlogicalxor", "binaryoperationnotequal", "binaryoperationnotidentical", "binaryoperationlt", "binaryoperationleq", "binaryoperationequal", "binaryoperationidentical", "unaryoperationbooleannot", "unaryoperationbitwisenot", "unaryoperationpostdec", "unaryoperationpredec", "unaryoperationpostinc", "unaryoperationpreinc", "unaryoperationunaryplus", "unaryoperationunaryminus", "new", "classconst", "casttoint", "casttobool", "casttofloat", "casttostring", "casttoarray", "casttoobject", "casttounset", "clone", "closure", "fetchconst", "empty", "suppress", "eval", "exit", "call", "methodcall", "staticcall", "include", "instanceOf", "isSet", "print", "propertyfetch", "shellexec", "exit", "fetchstaticproperty", "scalar", "var",
 "break", "classdef", "const", "continue", "declare", "do", "echo", "expressionstatementchainrule", "for", "foreach", "functiondef", "global", "goto", "haltcompiler", "if", "inlineHTML", "interfacedef", "traitdef", "label", "namespace", "return", "static", "switch", "throw", "trycatch", "unset", "use", "whiledef"];

alias ProductFeaturesType = tuple[str \product, str \version, int \array, int \fetcharraydim, int \fetchclassconst, int \assign, int \assignwithoperationbitwiseand, int \assignwithoperationbitwiseor, int \assignwithoperationbitwisexor, int \assignwithoperationconcat, int \assignwithoperationdiv, int \assignwithoperationminus, int \assignwithoperationmod, int \assignwithoperationmul, int \assignwithoperationplus, int \assignwithoperationrightshift, int \assignwithoperationleftshift, int \assignwithoperationbooleanand, int \assignwithoperationbooleanor, int \assignwithoperationlogicaland, int \assignwithoperationlogicalor, int \assignwithoperationlogicalxor, int \listassign, int \refassign, int \binaryoperationbitwiseand, int \binaryoperationbitwiseor, int \binaryoperationbitwisexor, int \binaryoperationconcat, int \binaryoperationdiv, int \binaryoperationminus, int \binaryoperationmod, int \binaryoperationmul, int \binaryoperationplus, int \binaryoperationrightshift, int \binaryoperationleftshift, int \binaryoperationbooleanand, int \binaryoperationbooleanor, int \binaryoperationgt, int \binaryoperationgeq, int \binaryoperationlogicaland, int \binaryoperationlogicalor, int \binaryoperationlogicalxor, int \binaryoperationnotequal, int \binaryoperationnotidentical, int \binaryoperationlt, int \binaryoperationleq, int \binaryoperationequal, int \binaryoperationidentical, int \unaryoperationbooleannot, int \unaryoperationbitwisenot, int \unaryoperationpostdec, int \unaryoperationpredec, int \unaryoperationpostinc, int \unaryoperationpreinc, int \unaryoperationunaryplus, int \unaryoperationunaryminus, int \new, int \classconst, int \casttoint, int \casttobool, int \casttofloat, int \casttostring, int \casttoarray, int \casttoobject, int \casttounset, int \clone, int \closure, int \fetchconst, int \empty, int \suppress, int \eval, int \exit, int \call, int \methodcall, int \staticcall, int \include, int \instanceOf, int \isSet, int \print, int \propertyfetch, int \shellexec, int \exit, int \fetchstaticproperty, int \scalar, int \var,
 int \break, int \classdef, int \const, int \continue, int \declare, int \do, int \echo, int \expressionstatementchainrule, int \for, int \foreach, int \functiondef, int \global, int \goto, int \haltcompiler, int \if, int \inlineHTML, int \interfacedef, int \traitdef, int \label, int \namespace, int \return, int \static, int \switch, int \throw, int \trycatch, int \unset, int \use, int \whiledef];

alias ProductFeaturesRel = set[ProductFeaturesType];

int firstFeature = indexOf(featureNames, "array");
int lastFeature = indexOf(featureNames, "whiledef");

/* Products ordered according to the total number of fdifferent eatures they use
   Result: 
<"Moodle","2.3",98>
<"Moodle","2.2.3",98>
...
<"PEAR","0.9",59>
<"Drupal","4.0.0",56>

Conclusion: no system uses all features
*/
void numberOfUsedFeatures(ProductFeaturesRel features){
	// Count the number of different features that is used by a product
	int getUsedFeatures(ProductFeaturesType tp){
  		n = 0;
  		for(i <- [firstFeature .. lastFeature])
  	 	   if(tp[i] > 0)
   	   		   n += 1;
 	 	return n;
	}
   used = [<f.product, f.version, getUsedFeatures(f)> | ProductFeaturesType f <- features];
   
   used = sort(used, bool (&T a, &T b) { return a[2] > b[2]; });
   println("numberOfUsedFeatures");
   for( u <- used)
     println(u);
}

/*  Determine features that are not used
unusedFeatures 12: {"assignwithoperationbooleanor","label","casttounset","classconst","goto","const","haltcompiler","traitdef",
                    "assignwithoperationlogicalor","assignwithoperationlogicalxor","assignwithoperationbooleanand","assignwithoperationlogicaland"}
*/

void unusedFeatures(ProductFeaturesRel features){
    used = {};
    for(ProductFeaturesType f <- features){
        for(int i <- [firstFeature .. lastFeature])
           if(f[i] > 0)
              used += featureNames[i];
    }          
    unused = toSet(featureNames) - used - {"product", "version"};
    println("unusedFeatures <size(unused)>: <unused>");
}

/* Most popular features:
{"scalar"}: 71728784
{"var"}: 37562609
{"expressionstatementchainrule"}: 16025660
{"assign"}: 8863169
{"methodcall"}: 8515441
{"propertyfetch"}: 6656378
{"call"}: 6183161
{"fetcharraydim"}: 4871331
{"array"}: 4180225
{"fetchconst"}: 3830907
{"if"}: 3309811
{"binaryoperationconcat"}: 3196996
...
*/

void mostPopularFeatures(ProductFeaturesRel features){
    freq = ();
    for(ProductFeaturesType f <- features){
        for(int i <- [firstFeature .. lastFeature]){
           name = featureNames[i];
           freq[name] ? 0 += f[i];
        }   
    }          
    sortedFreq = reverse(sort(toList(range(freq))));
    ifreq = invert(toRel(freq));
    println("mostPopularFeatures:");
    for(n <- sortedFreq){
       println("<ifreq[n]>: <n>");
    }
}

public void main(){
   exprs = csvExprs();
   stmts = csvStmts();
  
   // Combine exprs and stmts into a single relation
   ProductFeaturesRel features = {   e + s  | e <- exprs, {s} := stmts[e.product,e.version] };
   
   numberOfUsedFeatures(features);
   unusedFeatures(features);
   mostPopularFeatures(features);
}




