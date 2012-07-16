module lang::php::stats::Queries1

import Prelude;
import lang::csv::IO;
import lang::php::util::Utils;
import Exprs = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/exprs.csv?funname=csvExprs|;
import Stmts = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/stmts.csv?funname=csvStmts|;
//import Simlarities = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/similarities.csv?funname=csvSimilarities|;

import ValueIO;
import analysis::formalconcepts::FCA;
import vis::Figure;
import vis::Render;

/* Brief log of observations and questions:
 - CVS resource did not work with field names that are Rascal reserved keywords (fixed).
 - tuple concatenation does not preserve field names [This happens when there are duplicate fieldnames, but which?]
 - How to conveniently handle tuples and their type? I would like to have (for instance)
    list[str] fieldsOf(tuple t);
   but we cannot type this since we have to explicitly specify the element types of the tuple :-(
   Of course, this function can get a value argument but that is not so nice.
   Here we do all this manually.
*/

/*
  WARNING: Mark has removed some fields, so this declaration should be updated.
*/

list[str] featureNames = ["product", "version", "array", "fetcharraydim", "fetchclassconst", "assign", "assignwithoperationbitwiseand", "assignwithoperationbitwiseor", "assignwithoperationbitwisexor", "assignwithoperationconcat", "assignwithoperationdiv", "assignwithoperationminus", "assignwithoperationmod", "assignwithoperationmul", "assignwithoperationplus", "assignwithoperationrightshift", "assignwithoperationleftshift", "assignwithoperationbooleanand", "assignwithoperationbooleanor", "assignwithoperationlogicaland", "assignwithoperationlogicalor", "assignwithoperationlogicalxor", "listassign", "refassign", "binaryoperationbitwiseand", "binaryoperationbitwiseor", "binaryoperationbitwisexor", "binaryoperationconcat", "binaryoperationdiv", "binaryoperationminus", "binaryoperationmod", "binaryoperationmul", "binaryoperationplus", "binaryoperationrightshift", "binaryoperationleftshift", "binaryoperationbooleanand", "binaryoperationbooleanor", "binaryoperationgt", "binaryoperationgeq", "binaryoperationlogicaland", "binaryoperationlogicalor", "binaryoperationlogicalxor", "binaryoperationnotequal", "binaryoperationnotidentical", "binaryoperationlt", "binaryoperationleq", "binaryoperationequal", "binaryoperationidentical", "unaryoperationbooleannot", "unaryoperationbitwisenot", "unaryoperationpostdec", "unaryoperationpredec", "unaryoperationpostinc", "unaryoperationpreinc", "unaryoperationunaryplus", "unaryoperationunaryminus", "new", "classconst", "casttoint", "casttobool", "casttofloat", "casttostring", "casttoarray", "casttoobject", "casttounset", "clone", "closure", "fetchconst", "empty", "suppress", "eval", "exit", "call", "methodcall", "staticcall", "include", "instanceOf", "isSet", "print", "propertyfetch", "shellexec", "exit", "fetchstaticproperty", "scalar", "var",
 "break", "classdef", "const", "continue", "declare", "do", "echo", "expressionstatementchainrule", "for", "foreach", "functiondef", "global", "goto", "haltcompiler", "if", "inlineHTML", "interfacedef", "traitdef", "label", "namespace", "return", "static", "switch", "throw", "trycatch", "unset", "use", "whiledef"];

alias ProductFeatures = tuple[str \product, str \version, int \array, int \fetcharraydim, int \fetchclassconst, int \assign, int \assignwithoperationbitwiseand, int \assignwithoperationbitwiseor, int \assignwithoperationbitwisexor, int \assignwithoperationconcat, int \assignwithoperationdiv, int \assignwithoperationminus, int \assignwithoperationmod, int \assignwithoperationmul, int \assignwithoperationplus, int \assignwithoperationrightshift, int \assignwithoperationleftshift, int \assignwithoperationbooleanand, int \assignwithoperationbooleanor, int \assignwithoperationlogicaland, int \assignwithoperationlogicalor, int \assignwithoperationlogicalxor, int \listassign, int \refassign, int \binaryoperationbitwiseand, int \binaryoperationbitwiseor, int \binaryoperationbitwisexor, int \binaryoperationconcat, int \binaryoperationdiv, int \binaryoperationminus, int \binaryoperationmod, int \binaryoperationmul, int \binaryoperationplus, int \binaryoperationrightshift, int \binaryoperationleftshift, int \binaryoperationbooleanand, int \binaryoperationbooleanor, int \binaryoperationgt, int \binaryoperationgeq, int \binaryoperationlogicaland, int \binaryoperationlogicalor, int \binaryoperationlogicalxor, int \binaryoperationnotequal, int \binaryoperationnotidentical, int \binaryoperationlt, int \binaryoperationleq, int \binaryoperationequal, int \binaryoperationidentical, int \unaryoperationbooleannot, int \unaryoperationbitwisenot, int \unaryoperationpostdec, int \unaryoperationpredec, int \unaryoperationpostinc, int \unaryoperationpreinc, int \unaryoperationunaryplus, int \unaryoperationunaryminus, int \new, int \classconst, int \casttoint, int \casttobool, int \casttofloat, int \casttostring, int \casttoarray, int \casttoobject, int \casttounset, int \clone, int \closure, int \fetchconst, int \empty, int \suppress, int \eval, int \exit, int \call, int \methodcall, int \staticcall, int \include, int \instanceOf, int \isSet, int \print, int \propertyfetch, int \shellexec, int \exit, int \fetchstaticproperty, int \scalar, int \var,
 int \break, int \classdef, int \const, int \continue, int \declare, int \do, int \echo, int \expressionstatementchainrule, int \for, int \foreach, int \functiondef, int \global, int \goto, int \haltcompiler, int \if, int \inlineHTML, int \interfacedef, int \traitdef, int \label, int \namespace, int \return, int \static, int \switch, int \throw, int \trycatch, int \unset, int \use, int \whiledef];

alias ProductFeaturesRel = set[ProductFeatures];

int firstFeature = indexOf(featureNames, "array");
int lastFeature = indexOf(featureNames, "whiledef");

void header(str h) = println("\n**** <h> ****\n");

/* Products ordered according to the total number of different features they use
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
	int getUsedFeatures(ProductFeatures tp){
  		n = 0;
  		for(i <- [firstFeature .. lastFeature])
  	 	   if(tp[i] > 0)
   	   		   n += 1;
 	 	return n;
	}
   used = [<f.product, f.version, getUsedFeatures(f)> | ProductFeatures f <- features];
   
   used = sort(used, bool (&T a, &T b) { return a[2] > b[2]; });
   header("Number of different features used per product");
   for( u <- used)
     println(u);
}

/* Frequency of features:
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
{"casttounset","classconst","assignwithoperationlogicalor","assignwithoperationbooleanor","traitdef","label","assignwithoperationlogicalxor","const","goto","assignwithoperationbooleanand","assignwithoperationlogicaland","haltcompiler"}: 0

*/

void frequencyOfFeatures(ProductFeaturesRel features){
    freq = ();
    for(ProductFeatures f <- features){
        for(int i <- [firstFeature .. lastFeature]){
           name = featureNames[i];
           freq[name] ? 0 += f[i];
        }   
    }          
    sortedFreq = reverse(sort(toList(range(freq))));
    ifreq = invert(toRel(freq));
    header("Frequency of usage of features across all products");
    for(n <- sortedFreq){
       println("<ifreq[n]>: <n>");
    }
}

void numberOfProductsUsingFeature(ProductFeaturesRel features){
    freq = ();
    for(ProductFeatures f <- features){
        for(int i <- [firstFeature .. lastFeature]){
           name = featureNames[i];
           freq[name] ? 0 += f[i] > 0 ? 1 : 0;
        }   
    }          
    sortedFreq = reverse(sort(toList(range(freq))));
    ifreq = invert(toRel(freq));
    header("Number of products that use a feature");
    for(n <- sortedFreq){
       println("<ifreq[n]>: <n>");
    }
}

/*
 Common features of products and versions: 38

{"break","unaryoperationunaryminus","suppress","binaryoperationbooleanand","whiledef","switch","binaryoperationgt","return",
 "assign","binaryoperationequal","scalar","assignwithoperationplus","binaryoperationminus","unset","fetchconst","include",
 "var","unaryoperationpostinc","assignwithoperationconcat","new","binaryoperationplus","call","if","binaryoperationconcat",
 "array","isSet","binaryoperationlt","empty","binaryoperationgeq","listassign","binaryoperationdiv","foreach","for",
 "fetcharraydim","binaryoperationnotequal","expressionstatementchainrule","propertyfetch","unaryoperationbooleannot"}
*/


void commonFeatures(ProductFeaturesRel features){
    common = {};
    for(int i <- [firstFeature .. lastFeature]){
        if(all(f <- features, f[i] > 0)){
           common += featureNames[i];
        }   
    }
    header("Common features: <size(common)>");
    println(common); 
}

/*
 Normalize by replacing all features with a non-zero count by 1.
*/

ProductFeatures normalize(ProductFeatures f){
    for(int i <- [firstFeature .. lastFeature]){
        if(f[i] > 0)
        	f[i] = 1;
    }
    return f;
}

/*
  How many different feature combinations are in use?
  Answer: 94
  
*/
void numberOfDifferentProductFeatures(ProductFeaturesRel features){
     normalizedFeatures = {normalize(f) | f <- features};
     header("Number of different ProductFeatures: <size(normalizedFeatures[_,_])>");
}

/*
   Feature usage decrease (of at least 10%) between consecutive versions of a product
   
ZendFramework: decreased usage between versions 1.0.0 and 1.0.1: [<"assignwithoperationmul",17,14>,<"binaryoperationbitwisexor",3,2>,<"binaryoperationrightshift",52,40>,<"casttofloat",25,19>,<"casttoobject",11,9>,<"exit",8,7>,<"print",19,6>,<"exit",8,7>,<"global",9,6>,<"inlineHTML",59,43>,<"static",15,12>]
ZendFramework: decreased usage between versions 1.9.7 and 1.9.8: [<"binaryoperationbitwiseand",306,269>,<"binaryoperationrightshift",105,92>,<"exit",34,30>,<"print",147,122>,<"exit",34,30>,<"functiondef",271,233>,<"global",36,23>]
CodeIgniter: decreased usage between versions 1.0b and 1.1b: [<"global",22,19>]
CodeIgniter: decreased usage between versions 2.0.3 and 2.1.2: [<"static",17,15>]
WordPress: decreased usage between versions 3.3.2 and 3.4: [<"exit",483,319>,<"exit",483,319>]
Joomla: decreased usage between versions 1.5.26 and 2.5.4: [<"fetcharraydim",13864,10642>,<"assignwithoperationbitwiseor",16,8>,<"assignwithoperationdiv",2,1>,<"assignwithoperationminus",29,22>,<"assignwithoperationmod",3,1>,<"assignwithoperationmul",17,6>,<"listassign",142,46>,<"refassign",2668,177>,<"binaryoperationbitwiseor",59,51>,<"binaryoperationdiv",186,100>,<"binaryoperationminus",670,411>,<"binaryoperationmul",321,145>,<"binaryoperationplus",825,478>,<"binaryoperationrightshift",69,48>,<"binaryoperationleftshift",59,53>,<"binaryoperationgeq",164,128>,<"binaryoperationlogicaland",173,102>,<"binaryoperationnotequal",1289,824>,<"binaryoperationnotidentical",445,395>,<"binaryoperationlt",849,523>,<"binaryoperationleq",120,80>,<"unaryoperationbitwisenot",1,0>,<"unaryoperationpostinc",709,340>,<"unaryoperationunaryminus",467,268>,<"suppress",883,553>,<"eval",18,7>,<"call",15426,13271>,<"include",537,354>,<"print",26,0>,<"break",1401,894>,<"for",550,274>,<"functiondef",456,111>,<"global",456,4>,<"static",135,121>,<"switch",345,223>,<"whiledef",222,142>]
Joomla: decreased usage between versions 1.5.26 and 2.5.4: [<"fetcharraydim",13864,10642>,<"assignwithoperationbitwiseor",16,8>,<"assignwithoperationdiv",2,1>,<"assignwithoperationminus",29,22>,<"assignwithoperationmod",3,1>,<"assignwithoperationmul",17,6>,<"listassign",142,46>,<"refassign",2668,177>,<"binaryoperationbitwiseor",59,51>,<"binaryoperationdiv",186,100>,<"binaryoperationminus",670,411>,<"binaryoperationmul",321,145>,<"binaryoperationplus",825,478>,<"binaryoperationrightshift",69,48>,<"binaryoperationleftshift",59,53>,<"binaryoperationgeq",164,128>,<"binaryoperationlogicaland",173,102>,<"binaryoperationnotequal",1289,824>,<"binaryoperationnotidentical",445,395>,<"binaryoperationlt",849,523>,<"binaryoperationleq",120,80>,<"unaryoperationbitwisenot",1,0>,<"unaryoperationpostinc",709,340>,<"unaryoperationunaryminus",467,268>,<"suppress",883,553>,<"eval",18,7>,<"call",15426,13271>,<"include",537,354>,<"print",26,0>,<"break",1401,894>,<"for",550,274>,<"functiondef",456,111>,<"global",456,4>,<"static",135,121>,<"switch",345,223>,<"whiledef",222,142>]
Drupal: decreased usage between versions 4.0.0 and 4.1.0: [<"suppress",3,2>,<"eval",6,5>]
Moodle: decreased usage between versions 2.2.3 and 2.3: [<"refassign",1183,737>,<"binaryoperationbitwiseand",511,435>,<"binaryoperationlt",2815,2358>]
Smarty: decreased usage between versions 2.6.26 and 3.0.9: [<"assignwithoperationbitwiseand",1,0>,<"assignwithoperationbitwiseor",1,0>,<"refassign",15,6>,<"binaryoperationbitwiseand",1,0>,<"binaryoperationgt",28,22>,<"binaryoperationlogicaland",2,1>,<"unaryoperationbitwisenot",1,0>,<"unaryoperationpredec",2,1>,<"casttofloat",3,1>,<"empty",101,90>,<"suppress",45,17>,<"include",73,24>,<"break",131,92>,<"for",36,29>,<"functiondef",76,49>]
phpMyAdmin: decreased usage between versions 2.11.11.3-english and 3.5.0-english: [<"binaryoperationbitwiseor",16,12>,<"binaryoperationrightshift",115,97>,<"binaryoperationleftshift",11,8>,<"binaryoperationgeq",204,78>,<"binaryoperationlogicaland",45,14>,<"binaryoperationlogicalor",36,9>,<"suppress",213,188>,<"do",3,2>]
phpMyAdmin: decreased usage between versions 2.11.11.3-english and 3.5.0-english: [<"binaryoperationbitwiseor",16,12>,<"binaryoperationrightshift",115,97>,<"binaryoperationleftshift",11,8>,<"binaryoperationgeq",204,78>,<"binaryoperationlogicaland",45,14>,<"binaryoperationlogicalor",36,9>,<"suppress",213,188>,<"do",3,2>]
PEAR: decreased usage between versions 0.9 and 1.0: [<"binaryoperationmod",3,2>]
CakePHP: decreased usage between versions 2.1.4-0 and 2.2.0-0: [<"binaryoperationgt",233,178>]

Conclusion: features never die, with one exception:
Joomla: unaryoperationbitwisenot disappeared from 1.5.26 to 2.5.4
*/

void decreasingUsagePerProduct(ProductFeaturesRel features){
    list[tuple[str, int, int]] decreased(ProductFeatures tp1, ProductFeatures tp2){
      return
        for(int i <- [firstFeature .. lastFeature]){
            n1 = tp1[i]; n2 = tp2[i];
            if(n1 > n2 && (n1 - n2) * 10 > n1)
               append <featureNames[i], n1, n2>;
        };
    }
    
   products = { f.product | f <- features };
   
   header("Decreasing usage of features across versions of same product");
   for(p <- products){
      versions = [f | f <- features, f.product == p];
      versions = sort(versions, bool(ProductFeatures a, ProductFeatures b){ return a.version < b.version; });
      
      if(size(versions) >= 2){
	      for(int i <- [0, size(versions)-2]){
	          d = decreased(versions[i], versions[i+1]);
	          if(!isEmpty(d)){
	             println("<p>: decreased usage between versions <versions[i].version> and <versions[i+1].version>: <d>");
	          }
	      }
      }
   }
}

int featureDistance(ProductFeatures p1, ProductFeatures p2) =
    (0 | it + (((p1[i] == 0 && p2[i] == 0) || (p1[i] > 0 && p2[i] > 0)) ? 0 : 1) | int i <- [firstFeature .. lastFeature]);
    
void genUsageSimilarity(ProductFeaturesRel features){
    list[tuple[str product1, str version1, str product2, str version2, int distance]] res = [];
    featuresList = toList(features);
    for(int i <- [0 .. size(featuresList) -2]){
        f1 = featuresList[i];
        for(int j <- [i + 1 .. size(featuresList) -1]){
           //println("<i>,<j>");
           f2 = featuresList[j];
           res += <f1.product, f1.version, f2.product, f2.version, featureDistance(f1, f2)>;    
        }
    }
    res = sort(res, bool(tuple[str product1, str version1, str product2, str version2, int distance] a, 
                         tuple[str product1, str version1, str product2, str version2, int distance] b) { return a.distance < b.distance;});
    
    
    simLines = [ "product1,version1,product2,version2,distance" ] + [ "<r.product1>,<r.version1>,<r.product2>,<r.version2>,<r.distance>" | r <- res ];
	writeFile(|project://PHPAnalysis/src/lang/php/extract/csvs/similarity.csv|, intercalate("\n",simLines));
}

/*
  Make a concept lattice
*/

FormalContext[str,str] convert(ProductFeaturesRel features) =
	{ <"<f.product>-<f.version>", featureNames[i]> | f <- features, int i <- [firstFeature .. lastFeature], f[i] > 0 };

void makeConcepts(ProductFeaturesRel features){
  writeTextValueFile(|project://PHPAnalysis/src/lang/php/extract/csvs/fca-latest.txt|, fca(convert(features)));
}

public void analyzeConcepts(){
  lattice = readTextValueFile(#ConceptLattice[str,str], |project://PHPAnalysis/src/lang/php/extract/csvs/fca-latest.txt|);
  for(c <- top(lattice)){
     println(c[0]);
  }
  
   for(c <- bottom(lattice)){
     println(c[0]);
  }
}

Figure mkNode(Concept[str,str] c, str n){
  return box(text(intercalate("\n", toList(c[0]))), id(n));
}

public void drawConcepts(){
   lattice = readTextValueFile(#ConceptLattice[str,str], |project://PHPAnalysis/src/lang/php/extract/csvs/fca-latest.txt|);
   n = 0;
   objects = ();
   nodes = [];
   edges = [];
   for(<c1, c2> <- lattice){
       id1 = id2 = "0";
       if(objects[c1[0]]?)
          id1 = objects[c1[0]];
       else {
          id1 = "<n>";
          objects[c1[0]] = id1;
          n += 1;
       }
       
       if(objects[c2[0]]?)
          id2 = objects[c2[0]];
       else {
          id2 = "<n>";
          objects[c2[0]] = id2;
          n += 1;
       }
       nodes += [mkNode(c1, id1), mkNode(c2, id2)];
       edges += edge(id1, id2);
   }
   render(graph(nodes, edges, hint("spring"), size(1000), std(gap(50))));
}

public void main(){
   exprs = csvExprs();
   stmts = csvStmts();
  
   // Combine exprs and stmts into a single relation
   ProductFeaturesRel features = {   e + s  | e <- exprs, {s} := stmts[e.product,e.version] };
   
   // If desired, filter:
   
   latest = getLatestVersions();
   println(latest);
   
   ft = {};
   for(f <- features){
       if(latest[f.product] == f.version)
       	ft += f;
   }
   println(ft);
   features = ft;
   
   header("Number of products and versions: <size(features)>");
   numberOfUsedFeatures(features);
   numberOfProductsUsingFeature(features);
   frequencyOfFeatures(features);
   commonFeatures(features);
   numberOfDifferentProductFeatures(features);
   //decreasingUsagePerProduct(features);
   //genUsageSimilarity(features);
   makeConcepts(features);
}




