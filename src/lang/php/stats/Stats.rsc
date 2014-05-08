@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::stats::Stats

import Set;
import String;
import List;
import lang::php::util::Utils;
import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;
import lang::php::ast::System;
import lang::csv::IO;

public bool containsVV(Expr e) = size({ v | /v:var(expr(Expr ev)) := e }) > 0;
public bool containsVV(someExpr(Expr e)) = size({ v | /v:var(expr(Expr ev)) := e }) > 0;
public bool containsVV(noExpr()) = false;

public list[tuple[loc fileloc, Expr call]] gatherExprStats(System scripts, list[Expr](Script) f) {
	return [ < e@at, e > | l <- scripts<0>, e <- f(scripts[l]) ];
}

@doc{Gather information on uses of class constants where the class name is given using a variable-variable}
public list[Expr] fetchClassConstUses(Script scr) = [ f | /f:fetchClassConst(_,_) := scr ];
public list[Expr] fetchClassConstUsesVVTarget(Script scr) = [ f | f:fetchClassConst(expr(_),_) <- fetchClassConstUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherVVClassConsts(System scripts) = gatherExprStats(scripts, fetchClassConstUsesVVTarget);

@doc{Gather information on assignments where the assignment target contains a variable-variable}
public list[Expr] fetchAssignUses(Script scr) = [ a | /a:assign(_,_) := scr ];
public list[Expr] fetchAssignUsesVVTarget(Script scr) = [ a | a:assign(Expr t,_) <- fetchAssignUses(scr), containsVV(t) ];
public list[tuple[loc fileloc, Expr call]] gatherVVAssigns(System scripts) = gatherExprStats(scripts, fetchAssignUsesVVTarget);

@doc{Gather information on assignment/op combos where the assignment target contains a variable-variable}
public list[Expr] fetchAssignWOpUses(Script scr) = [ a | /a:assignWOp(_,_,_) := scr ];
public list[Expr] fetchAssignWOpUsesVVTarget(Script scr) = [ a | a:assignWOp(Expr t,_,_) <- fetchAssignWOpUses(scr), containsVV(t) ];
public list[tuple[loc fileloc, Expr call]] gatherVVAssignWOps(System scripts) = gatherExprStats(scripts, fetchAssignWOpUsesVVTarget);

@doc{Gather information on list assignments where the assignment target contains a variable-variable}
public list[Expr] fetchListAssignUses(Script scr) = [ a | /a:listAssign(_,_) := scr ];
public list[Expr] fetchListAssignUsesVVTarget(Script scr) = [ a | a:listAssign(ll,_) <- fetchListAssignUses(scr), true in { containsVV(t) | t <- ll } ];
public list[tuple[loc fileloc, Expr call]] gatherVVListAssigns(System scripts) = gatherExprStats(scripts, fetchListAssignUsesVVTarget);

@doc{Gather information on reference assignments where the assignment target contains a variable-variable}
public list[Expr] fetchRefAssignUses(Script scr) = [ a | /a:refAssign(_,_) := scr ];
public list[Expr] fetchRefAssignUsesVVTarget(Script scr) = [ a | a:refAssign(Expr t,_) <- fetchRefAssignUses(scr), containsVV(t) ];
public list[tuple[loc fileloc, Expr call]] gatherVVRefAssigns(System scripts) = gatherExprStats(scripts, fetchRefAssignUsesVVTarget);
 
@doc{Gather information on object creations with variable class names}
public list[Expr] fetchNewUses(Script scr) = [ f | /f:new(_,_) := scr ];
public list[Expr] fetchNewUsesVVClass(Script scr) = [ f | f:new(expr(_),_) <- fetchNewUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherVVNews(System scripts) = gatherExprStats(scripts, fetchNewUsesVVClass);

@doc{Gather information on calls where the function to call is given through a variable-variable}
public list[Expr] fetchCallUses(Script scr) = [ c | /c:call(_,_) := scr ];
public list[Expr] fetchCallUsesVVName(Script scr) = [ c | c:call(expr(_),_) <- fetchCallUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherVVCalls(System scripts) = gatherExprStats(scripts, fetchCallUsesVVName);

@doc{Gather information on method calls where the method to call is given through a variable-variable}
public list[Expr] fetchMethodCallUses(Script scr) = [ m | /m:methodCall(_,_,_) := scr ];
public list[Expr] fetchMethodCallUsesVVTarget(Script scr) = [ m | m:methodCall(_,expr(_),_) <- fetchMethodCallUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherMethodVVCalls(System scripts) = gatherExprStats(scripts, fetchMethodCallUsesVVTarget);

@doc{Gather information on static calls where the static class and/or the static method is given as a variable-variable}
public list[Expr] fetchStaticCallUses(Script scr) = [ m | /m:staticCall(_,_,_) := scr ];
public list[Expr] fetchStaticCallUsesVVMethod(Script scr) = [ m | m:staticCall(_,expr(_),_) <- fetchStaticCallUses(scr) ];
public list[Expr] fetchStaticCallUsesVVTarget(Script scr) = [ m | m:staticCall(expr(_),_,_) <- fetchStaticCallUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherStaticVVCalls(System scripts) = gatherExprStats(scripts, fetchStaticCallUsesVVMethod);
public list[tuple[loc fileloc, Expr call]] gatherStaticVVTargets(System scripts) = gatherExprStats(scripts, fetchStaticCallUsesVVTarget);

@doc{Gather information on includes with paths based on expressions}
public list[Expr] fetchIncludeUses(Script scr) = [ i | /i:include(_,_) := scr ];
public list[Expr] fetchIncludeUsesVarPaths(Script scr) = [ i | i:include(Expr e,_) <- fetchIncludeUses(scr), scalar(string(_)) !:= e ];
public list[tuple[loc fileloc, Expr call]] gatherIncludesWithVarPaths(System scripts) = gatherExprStats(scripts, fetchIncludeUsesVarPaths);

@doc{Gather information on property fetch expressions with the property name given as a variable-variable}
public list[Expr] fetchPropertyFetchUses(Script scr) = [ f | /f:propertyFetch(_,_) := scr ];
public list[Expr] fetchPropertyFetchVVNames(Script scr) = [ f | f:propertyFetch(_,expr(_)) <- fetchPropertyFetchUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherPropertyFetchesWithVarNames(System scripts) = gatherExprStats(scripts, fetchPropertyFetchVVNames);

@doc{Gather information on static property fetches where the static class and/or the static property name is given as a variable-variable}
public list[Expr] staticPropertyFetchUses(Script scr) = [ m | /m:staticPropertyFetch(_,_) := scr ];
public list[Expr] staticPropertyFetchVVName(Script scr) = [ m | m:staticPropertyFetch(_,expr(_)) <- staticPropertyFetchUses(scr) ];
public list[Expr] staticPropertyFetchVVTarget(Script scr) = [ m | m:staticPropertyFetch(expr(_),_) <- staticPropertyFetchUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherStaticPropertyVVNames(System scripts) = gatherExprStats(scripts, staticPropertyFetchVVName);
public list[tuple[loc fileloc, Expr call]] gatherStaticPropertyVVTargets(System scripts) = gatherExprStats(scripts, staticPropertyFetchVVTarget);

@doc{Gather variable-variable uses}
public list[Expr] fetchVarUses(Script scr) = [ v | /v:var(_) := scr ];
public list[Expr] fetchVarUsesVV(Script scr) = [ v | v:var(expr(_)) <- fetchVarUses(scr) ];
public list[tuple[loc fileloc, Expr call]] gatherVarVarUses(System scripts) = gatherExprStats(scripts, fetchVarUsesVV);

@doc{Magic methods that implement overloads}
public list[ClassItem] fetchOverloadedSet(System scripts) = [ x | l <- scripts<0>, /x:method("__set",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedGet(System scripts) = [ x | l <- scripts<0>, /x:method("__get",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedIsSet(System scripts) = [ x | l <- scripts<0>, /x:method("__isset",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedUnset(System scripts) = [ x | l <- scripts<0>, /x:method("__unset",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedCall(System scripts) = [ x | l <- scripts<0>, /x:method("__call",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedCallStatic(System scripts) = [ x | l <- scripts<0>, /x:method("__callStatic",_,_,_,_) := scripts[l] ];

@doc{Support for var-args functions}
public list[Expr] fetchVACalls(Script scr) = [ v | /v:call(name(name(fn)),_) := scr, fn in {"func_get_args","func_get_arg","func_num_args"} ];
public list[tuple[loc fileloc, Expr call]] getVACallUses(System scripts) = gatherExprStats(scripts, fetchVACalls);

@doc{Break/continue with non-literal arguments}
public list[Stmt] fetchVarBreak(System scripts) = [ x | l <- scripts<0>, /x:\break(someExpr(e)) := scripts[l], scalar(_) !:= e ];
public list[Stmt] fetchVarContinue(System scripts) = [ x | l <- scripts<0>, /x:\continue(someExpr(e)) := scripts[l], scalar(_) !:= e ];

@doc{Uses of eval}
public list[Expr] fetchEvalUses(Script scr) = [ e | /e:eval(_) := scr ];
public list[tuple[loc fileloc, Expr call]] gatherEvals(System scripts) = gatherExprStats(scripts, fetchEvalUses);

public map[str,int] featureCounts(System scripts) {
	map[str,int] counts = ( );
	
	counts["class consts with variable class name"] = size(gatherVVClassConsts(scripts));
	counts["assignments into variable-variables"] = size(gatherVVAssigns(scripts));
	counts["assignments w/ops into variable-variables"] = size(gatherVVAssignWOps(scripts));
	counts["list assignments into variable-variables"] = size(gatherVVListAssigns(scripts));
	counts["ref assignments into variable-variables"] = size(gatherVVRefAssigns(scripts));
	counts["object creation with variable class name"] = size(gatherVVNews(scripts));
	counts["calls of variable function names"] = size(gatherVVCalls(scripts));
	counts["calls of variable method names"] = size(gatherMethodVVCalls(scripts));
	counts["calls of static methods with variable names"] = size(gatherStaticVVCalls(scripts));
	counts["calls of static methods with variable targets"] = size(gatherStaticVVTargets(scripts));
	counts["includes with non-literal paths"] = size(gatherIncludesWithVarPaths(scripts));
	counts["fetches of properties with variable names"] = size(gatherPropertyFetchesWithVarNames(scripts));
	counts["fetches of static properties with variable names"] = size(gatherStaticPropertyVVNames(scripts));
	counts["fetches of static properties with variable targets"] = size(gatherStaticPropertyVVTargets(scripts));
	counts["uses of variable-variables (including the above)"] = size(gatherVarVarUses(scripts));
	counts["definitions of overloads: set"] = size(fetchOverloadedSet(scripts));
	counts["definitions of overloads: get"] = size(fetchOverloadedGet(scripts));
	counts["definitions of overloads: isset"] = size(fetchOverloadedIsSet(scripts));
	counts["definitions of overloads: unset"] = size(fetchOverloadedUnset(scripts));
	counts["definitions of overloads: call"] = size(fetchOverloadedCall(scripts));
	counts["definitions of overloads: callStatic"] = size(fetchOverloadedCallStatic(scripts));
	counts["var-args support functions"] = size(getVACallUses(scripts));
	counts["break with non-literal argument"] = size(fetchVarBreak(scripts));
	counts["continue with non-literal argument"] = size(fetchVarContinue(scripts));
			
	// to add: 2) ref array; 3) ref params; 5) functions with var-args parameters
	return counts;

}

@doc{Gather statement counts}
public map[str,int] stmtCounts(System scripts) {
	map[str,int] counts = ( );
	for (l <- scripts<0>, s <- scripts[l]) {
		visit(s) {
			case Stmt stmt : {
				stmtKey = getStmtKey(stmt);
				if (stmtKey in counts)
					counts[stmtKey] += 1;
				else
					counts[stmtKey] = 1;
			}
		}
	} 
	return counts;
}

public map[str file, map[str feature, int count] counts] stmtAndExprCountsByFile(System scripts) {
	map[str file, map[str feature, int count] counts] fileCounts = ( );
	for (l <- scripts<0>, s <- scripts[l]) {
		map[str feature, int count] counts = ( );
		visit(s) {
			case Stmt stmt : {
				stmtKey = getStmtKey(stmt);
				if (stmtKey in counts)
					counts[stmtKey] += 1;
				else
					counts[stmtKey] = 1;
			}
			case Expr expr : {
				exprKey = getExprKey(expr);
				if (exprKey in counts)
					counts[exprKey] += 1;
				else
					counts[exprKey] = 1;
			}
			case ClassItem citem : {
				ciKey = getClassItemKey(citem);
				if (ciKey in counts)
					counts[ciKey] += 1;
				else
					counts[ciKey] = 1;				
			}
		}
		fileCounts[l.path] = counts;
	} 
	return fileCounts;
}

@doc{Gather expression counts}
public map[str,int] exprCounts(System scripts) {
	map[str,int] counts = ( );
	for (l <- scripts<0>, s <- scripts[l]) {
		visit(s) {
			case Expr expr : {
				exprKey = getExprKey(expr);
				if (exprKey in counts)
					counts[exprKey] += 1;
				else
					counts[exprKey] = 1;
			}
		}
	} 
	return counts;
}

public str getExprKey(Expr::array(_)) = "array";
public str getExprKey(fetchArrayDim(_,_)) = "fetch array dim";
public str getExprKey(fetchClassConst(_,_)) = "fetch class const";
public str getExprKey(assign(_,_)) = "assign";
public str getExprKey(assignWOp(_,_,Op op)) = "assign with operation: <getOpKey(op)>";
public str getExprKey(listAssign(_,_)) = "list assign";
public str getExprKey(refAssign(_,_)) = "ref assign";
public str getExprKey(binaryOperation(_,_,Op op)) = "binary operation: <getOpKey(op)>";
public str getExprKey(unaryOperation(_,Op op)) = "unary operation: <getOpKey(op)>";
public str getExprKey(new(_,_)) = "new";
public str getExprKey(cast(CastType ct,_)) = "cast to <getCastTypeKey(ct)>";
public str getExprKey(clone(_)) = "clone";
public str getExprKey(closure(_,_,_,_,_)) = "closure";
public str getExprKey(fetchConst(_)) = "fetch const";
public str getExprKey(empty(_)) = "empty";
public str getExprKey(suppress(_)) = "suppress";
public str getExprKey(eval(_)) = "eval";
public str getExprKey(exit(_)) = "exit";
public str getExprKey(call(_,_)) = "call";
public str getExprKey(methodCall(_,_,_)) = "method call";
public str getExprKey(staticCall(_,_,_)) = "static call";
public str getExprKey(Expr::include(_,_)) = "include";
public str getExprKey(instanceOf(_,_)) = "instanceOf";
public str getExprKey(isSet(_)) = "isSet";
public str getExprKey(print(_)) = "print";
public str getExprKey(propertyFetch(_,_)) = "property fetch";
public str getExprKey(shellExec(_)) = "shell exec";
public str getExprKey(ternary(_,_,_)) = "ternary";
public str getExprKey(staticPropertyFetch(_,_)) = "fetch static property";
public str getExprKey(scalar(_)) = "scalar";
public str getExprKey(var(_)) = "var";
public str getExprKey(listExpr(_)) = "list";

public default str getExprKey(Expr e) { throw "No matching expression for <e>"; }

public list[str] exprKeyOrder() {
	return [ "array", "fetch array dim", "fetch class const", "assign" ] +
		   [ "assign with operation: <op>" | op <- opKeyAssnOrder() ] +
		   [ "list assign", "ref assign" ] +
		   [ "binary operation: <op>" | op <- binOpOrder() ] +
		   [ "unary operation: <op>" | op <- uOpOrder() ] +
		   [ "new" ] +
		   [ "cast to <ct>" | ct <- castTypeOrder() ] +
		   [ "clone", "closure", "fetch const", "empty", "suppress", "eval", "exit",
		     "call", "method call", "static call", "include", "instanceOf", "isSet",
		     "print", "property fetch", "shell exec", "ternary", "fetch static property",
		     "scalar", "var", "list" ];
}

public str getOpKey(bitwiseAnd()) = "bitwise and";
public str getOpKey(bitwiseOr()) = "bitwise or";
public str getOpKey(bitwiseXor()) = "bitwise xor";
public str getOpKey(concat()) = "concat";
public str getOpKey(div()) = "div";
public str getOpKey(minus()) = "minus";
public str getOpKey(\mod()) = "mod";
public str getOpKey(mul()) = "mul";
public str getOpKey(plus()) = "plus";
public str getOpKey(rightShift()) = "right shift";
public str getOpKey(leftShift()) = "left shift";
public str getOpKey(booleanAnd()) = "boolean and";
public str getOpKey(booleanOr()) = "boolean or";
public str getOpKey(booleanNot()) = "boolean not";
public str getOpKey(bitwiseNot()) = "bitwise not";
public str getOpKey(gt()) = "gt";
public str getOpKey(geq()) = "geq";
public str getOpKey(logicalAnd()) = "logical and";
public str getOpKey(logicalOr()) = "logical or";
public str getOpKey(logicalXor()) = "logical xor";
public str getOpKey(notEqual()) = "not equal";
public str getOpKey(notIdentical()) = "not identical";
public str getOpKey(postDec()) = "post dec";
public str getOpKey(preDec()) = "pre dec";
public str getOpKey(postInc()) = "post inc";
public str getOpKey(preInc()) = "pre inc";
public str getOpKey(lt()) = "lt";
public str getOpKey(leq()) = "leq";
public str getOpKey(unaryPlus()) = "unary plus";
public str getOpKey(unaryMinus()) = "unary minus";
public str getOpKey(equal()) = "equal";
public str getOpKey(identical()) = "identical";

public list[str] opKeyOrder() = [ "bitwise and", "bitwise or", "bitwise xor", "concat", "div",
								"minus", "mod", "mul", "plus", "right shift", "left shift",
								"boolean and", "boolean or", "boolean not", "bitwise not",
								"gt", "geq", "logical and", "logical or", "logical xor",
								"not equal", "not identical", "post dec", "pre dec",
								"post inc", "pre inc", "lt", "leq", "unary plus",
								"unary minus", "equal", "identical" ];
								
public list[str] binOpOrder() = [ "bitwise and", "bitwise or", "bitwise xor", "concat", "div",
							   	  "minus", "mod", "mul", "plus", "right shift", "left shift",
								  "boolean and", "boolean or", "gt", "geq", "logical and", 
								  "logical or", "logical xor", "not equal", "not identical", 
								  "lt", "leq", "equal", "identical" ];

public list[str] uOpOrder() = [ "boolean not", "bitwise not", "post dec", "pre dec",
								"post inc", "pre inc", "unary plus", "unary minus" ];

public list[str] opKeyAssnOrder() = [ "bitwise and", "bitwise or", "bitwise xor", 
									  "concat", "div", "minus", "mod", "mul", "plus", 
									  "right shift", "left shift" ];					

public str getCastTypeKey(\int()) = "int";
public str getCastTypeKey(\bool()) = "bool";
public str getCastTypeKey(CastType::float()) = "float";
public str getCastTypeKey(CastType::string()) = "string";
public str getCastTypeKey(CastType::array()) = "array";
public str getCastTypeKey(object()) = "object";
public str getCastTypeKey(CastType::unset()) = "unset";

public list[str] castTypeOrder() = [ "int", "bool", "float", "string", "array", "object", "unset" ];

public str getStmtKey(\break(_)) = "break";
public str getStmtKey(classDef(_)) = "class def";
public str getStmtKey(Stmt::const(_)) = "const";
public str getStmtKey(\continue(_)) = "continue";
public str getStmtKey(declare(_,_)) = "declare";
public str getStmtKey(do(_,_)) = "do";
public str getStmtKey(echo(_)) = "echo";
public str getStmtKey(exprstmt(_)) = "expression statement (chain rule)";
public str getStmtKey(\for(_,_,_,_)) = "for";
public str getStmtKey(foreach(_,_,_,_,_)) = "foreach";
public str getStmtKey(function(_,_,_,_)) = "function def";
public str getStmtKey(global(_)) = "global";
public str getStmtKey(goto(_)) = "goto";
public str getStmtKey(haltCompiler(_)) = "halt compiler";
public str getStmtKey(\if(_,_,_,_)) = "if";
public str getStmtKey(inlineHTML(_)) = "inline HTML";
public str getStmtKey(interfaceDef(_)) = "interface def";
public str getStmtKey(traitDef(_)) = "trait def";
public str getStmtKey(label(_)) = "label";
public str getStmtKey(namespace(_,_)) = "namespace";
public str getStmtKey(\return(_)) = "return";
public str getStmtKey(Stmt::static(_)) = "static";
public str getStmtKey(\switch(_,_)) = "switch";
public str getStmtKey(\throw(_)) = "throw";
public str getStmtKey(tryCatch(_,_)) = "try/catch";
public str getStmtKey(Stmt::unset(_)) = "unset";
public str getStmtKey(Stmt::use(_)) = "use";
public str getStmtKey(\while(_,_)) = "while";

public list[str] stmtKeyOrder() = [ "break", "class def", "const", "continue", "declare", "do",
								    "echo", "expression statement (chain rule)", "for", "foreach",
								    "function def", "global", "goto", "halt compiler", "if",
								    "inline HTML", "interface def", "trait def", "label",
								    "namespace", "return", "static", "switch", "throw",
								    "try/catch", "unset", "use", "while" ];
								    
public str getClassItemKey(ClassItem::property(set[Modifier] modifiers, list[Property] prop)) = "propertyDef";
public str getClassItemKey(ClassItem::constCI(list[Const] consts)) = "classConstDef";
public str getClassItemKey(ClassItem::method(str name, set[Modifier] modifiers, bool byRef, list[Param] params, list[Stmt] body)) = "methodDef";
public str getClassItemKey(ClassItem::traitUse(list[Name] traits, list[Adaptation] adaptations)) = "traitUse";
								    
public list[str] classItemKeyOrder() = ["propertyDef","classConstDef","methodDef","traitUse"];

public list[str] featureOrder() = [ "class consts with variable class name",
									"assignments into variable-variables",
									"assignments w/ops into variable-variables",
									"list assignments into variable-variables",
									"ref assignments into variable-variables",
									"object creation with variable class name",
									"calls of variable function names",
									"calls of variable method names",
									"calls of static methods with variable names",
									"calls of static methods with variable targets",
									"includes with non-literal paths",
									"fetches of properties with variable names",
									"fetches of static properties with variable names",
									"fetches of static properties with variable targets",
									"uses of variable-variables (including the above)",
									"definitions of overloads: set",
									"definitions of overloads: get",
									"definitions of overloads: isset",
									"definitions of overloads: unset",
									"definitions of overloads: call",
									"definitions of overloads: callStatic",
									"var-args support functions",
									"break with non-literal argument",
									"continue with non-literal argument"];

public str rascalFriendlyKey(str k) {
	while (/<pre:.*>[\(]<c:[a-zA-Z]><post:.*>/ := k) k = pre + toUpperCase(c) + post;
	while (/<pre:.*>[\)]<c:[a-zA-Z]><post:.*>/ := k) k = pre + toUpperCase(c) + post;
	while (/<pre:.*>[\)]<post:.*>/ := k) k = pre + post;
	while (/<pre:.*>[ ]<c:[a-zA-Z]><post:.*>/ := k) k = pre + toUpperCase(c) + post;
	while (/<pre:.*>[\/]<c:[a-zA-Z]><post:.*>/ := k) k = pre + toUpperCase(c) + post;
	while (/<pre:.*>[:]<c:[a-zA-Z]><post:.*>/ := k) k = pre + toUpperCase(c) + post;
	while (/<pre:.*>[-]<c:[a-zA-Z]><post:.*>/ := k) k = pre + toUpperCase(c) + post;
	return k;
}

public void gatherFeatureCountsFromBinary(str product, str version) {
	b = loadBinary(product, version);
	writeFeatureCounts(product, version, featureCounts(b));
}

public void buildFeatureCounts(str product, str version) {
	gatherFeatureCountsFromBinary(product, version);
}

public void buildFeatureCounts(str product) {
	for (version <- getVersions(product))
		buildFeatureCounts(product,version);
}

public void buildFeatureCounts() {
	for (product <- getProducts(), version <- getVersions(product))
		buildFeatureCounts(product,version);
}

public void gatherStatsFromBinary(str product, str version) {
	b = loadBinary(product, version);
	writeStats(product, version, featureCounts(b), stmtCounts(b), exprCounts(b));
}

public void buildStats(str product, str version) {
	gatherStatsFromBinary(product, version);
}

public void buildStats(str product) {
	for (version <- getVersions(product))
		buildStats(product,version);
}

public void buildStats() {
	for (product <- getProducts(), version <- getVersions(product))
		buildStats(product, version);
}

public void writeFeatureCounts(str product, str version, map[str,int] fc) {
	println("Writing counts for <product>-<version>");
	loc fcLoc = statsDir + "<product>-<version>.fc";
	writeBinaryValueFile(fcLoc, fc);
}

public void writeStats(str product, str version, map[str,int] fc, map[str,int] sc, map[str,int] ec) {
	loc fcLoc = statsDir + "<product>-<version>.fc";
	loc scLoc = statsDir +  "<product>-<version>.sc";
	loc ecLoc = statsDir +  "<product>-<version>.ec";
	writeBinaryValueFile(fcLoc, fc);
	writeBinaryValueFile(scLoc, sc);
	writeBinaryValueFile(ecLoc, ec);
}

public tuple[map[str,int] fc, map[str,int] sc, map[str,int] ec] getStats(str product, str version) {
	loc fcLoc = statsDir + "<product>-<version>.fc";
	loc scLoc = statsDir +  "<product>-<version>.sc";
	loc ecLoc = statsDir +  "<product>-<version>.ec";
	return < readBinaryValueFile(#map[str,int],fcLoc), readBinaryValueFile(#map[str,int],scLoc), readBinaryValueFile(#map[str,int],ecLoc) >;
}

public map[tuple[str,str],tuple[map[str,int] fc, map[str,int] sc, map[str,int] ec]] getStats(str product) {
	return ( < product, v > : getStats(product,v) | v <- getVersions(product) );
}

public map[tuple[str,str],tuple[map[str,int] fc, map[str,int] sc, map[str,int] ec]] getStats() {
	return ( < product, v > : getStats(product,v) | product <- getProducts(), v <- getVersions(product) );
}

public list[tuple[str p, str v, map[str,int] fc, map[str,int] sc, map[str,int] ec]] getSortedStats() {
	list[tuple[str p, str v, map[str,int] fc, map[str,int] sc, map[str,int] ec]] res = [ ];
	
	sm = getStats();
	pvset = sm<0>;

	for (p <- sort(toList(pvset<0>)), v <- sort(toList(pvset[p]),compareVersion))
		res += < p, v, sm[<p,v>].fc, sm[<p,v>].sc, sm[<p,v>].ec >;
	
	return res;
}

public tuple[int lineCount, int fileCount] loadCounts(str product, str version) {
	countItem = countsDir + "<toLowerCase(product)>-<version>";
	if (!exists(countItem))
		countItem = countsDir + "<toLowerCase(product)>_<version>";
	if (!exists(countItem))
		throw "Could not find counts file for <product>-<version>";
	lines = readFileLines(countItem);
	if(l <- lines, /PHP\s+<phpfiles:\d+>\s+\d+\s+\d+\s+<phploc:\d+>/ := l) return < toInt(phploc), toInt(phpfiles) >; 
	throw "Could not find PHP LOC counts for <product>-<version>";
}

public int loadCount(str product, str version) = loadCounts(product,version).lineCount;
public int loadFileCount(str product, str version) = loadCounts(product,version).fileCount;

public list[tuple[str p, str v, int count, int fileCount]] getSortedCounts() {
	return [ <p,v,lc,fc> | p <- sort(toList(getProducts())), v <- sort(toList(getVersions(p)),compareVersion), <lc,fc> := loadCounts(p,v) ];	
}

public void writeSortedCounts() {
	sc = getSortedCounts();
	scLines = [ "Product,Version,LoC,Files" ] + [ "<i.p>,<i.v>,<i.count>,<i.fileCount>" | i <- sc ];
	writeFile(|rascal://src/lang/php/extract/csvs/linesOfCode.csv|, intercalate("\n",scLines));
}

public rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments] loadVersionsCSV() {
	rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments] res = readCSV(#rel[str Product,str Version,str ReleaseDate,str RequiredPHPVersion,str Comments],|rascal://src/lang/php/extract/csvs/Versions.csv|);
	return res;
	//return { <r.Product,r.Version,parseDate(r.ReleaseDate,"yyyy-MM-dd"),r.RequiredPHPVersion,r.Comments> | r <-res };  
}

public rel[str Product,str Version,int Count,int FileCount] loadCountsCSV() {
	rel[str Product,str Version,int Count,int FileCount] res = readCSV(#rel[str Product,str Version,int Count,int fileCount],|rascal://src/lang/php/extract/csvs/linesOfCode.csv|);
	return res;
}

public map[str Product, str Version] getLatestVersionsByDate() {
	versions = loadVersionsCSV();
	return ( p : last(vl)[0] | p <- versions<0>, vl := sort([ <v,d> | <v,d,pv,_> <- versions[p] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }) );
}

public map[str Product, str Version] getLatestPHP4VersionsByDate() {
	versions = loadVersionsCSV();
	return ( p : last(v4l)[0] | p <- versions<0>, v4l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "4" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }), !isEmpty(v4l) );
}

public map[str Product, str Version] getLatestPHP5VersionsByDate() {
	versions = loadVersionsCSV();
	return ( p : last(v5l)[0] | p <- versions<0>, v5l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "5" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return t1[1] < t2[1]; }), !isEmpty(v5l) );
}

public map[str Product, str Version] getLatestVersionsByVersionNumber() {
	versions = loadVersionsCSV();
	return ( p : last(vl)[0] | p <- versions<0>, vl := sort([ <v,d> | <v,d,pv,_> <- versions[p] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }) );
}

public map[str Product, str Version] getLatestPHP4VersionsByVersionNumber() {
	versions = loadVersionsCSV();
	return ( p : last(v4l)[0] | p <- versions<0>, v4l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "4" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0], t2[0]); }), !isEmpty(v4l) );
}

public map[str Product, str Version] getLatestPHP5VersionsByVersionNumber() {
	versions = loadVersionsCSV();
	return ( p : last(v5l)[0] | p <- versions<0>, v5l := sort([ <v,d> | <v,d,pv,_> <- versions[p], "5" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }), !isEmpty(v5l) );
}

public map[str Product, str Version] getLatestVersions() = getLatestVersionsByVersionNumber();

public map[str Product, str Version] getLatestPHP4Versions() = getLatestPHP4VersionsByVersionNumber();

public map[str Product, str Version] getLatestPHP5Versions() = getLatestPHP5VersionsByVersionNumber();


public str getPHPVersion(str product, str version) {
	versions = loadVersionsCSV();
	return getOneFrom(versions[product,version,_]<0>);
}

public str getReleaseDate(str product, str version) {
	versions = loadVersionsCSV();
	return getOneFrom(versions[product,version]<0>);
}

public rel[str Product,str PlainText,str Description] loadProductInfoCSV() {
	rel[str Product,str PlainText,str Description] res = readCSV(#rel[str Product,str PlainText,str Description],|rascal://src/lang/php/extract/csvs/ProductInfo.csv|);
	return res;
}

									