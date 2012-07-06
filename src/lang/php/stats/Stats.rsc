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

public bool containsVV(Expr e) = size({ v | /v:var(expr(Expr ev)) := e }) > 0;
public bool containsVV(someExpr(Expr e)) = size({ v | /v:var(expr(Expr ev)) := e }) > 0;
public bool containsVV(noExpr()) = false;

public rel[loc fileloc, Expr call] gatherExprStats(map[loc fileloc, Script scr] scripts, list[Expr](Script) f) {
	return { < l, e > | l <- scripts<0>, e <- f(scripts[l]) };
}

@doc{Gather information on uses of class constants where the class name is given using a variable-variable}
public list[Expr] fetchClassConstUses(Script scr) = [ f | /f:fetchClassConst(_,_) := scr ];
public list[Expr] fetchClassConstUsesVVTarget(Script scr) = [ f | f:fetchClassConst(expr(_),_) <- fetchClassConstUses(scr) ];
public rel[loc fileloc, Expr call] gatherVVClassConsts(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchClassConstUsesVVTarget);

@doc{Gather information on assignments where the assignment target contains a variable-variable}
public list[Expr] fetchAssignUses(Script scr) = [ a | /a:assign(_,_) := scr ];
public list[Expr] fetchAssignUsesVVTarget(Script scr) = [ a | a:assign(Expr t,_) <- fetchAssignUses(scr), containsVV(t) ];
public rel[loc fileloc, Expr call] gatherVVAssigns(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchAssignUsesVVTarget);

@doc{Gather information on assignment/op combos where the assignment target contains a variable-variable}
public list[Expr] fetchAssignWOpUses(Script scr) = [ a | /a:assignWOp(_,_,_) := scr ];
public list[Expr] fetchAssignWOpUsesVVTarget(Script scr) = [ a | a:assignWOp(Expr t,_,_) <- fetchAssignWOpUses(scr), containsVV(t) ];
public rel[loc fileloc, Expr call] gatherVVAssignWOps(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchAssignWOpUsesVVTarget);

@doc{Gather information on list assignments where the assignment target contains a variable-variable}
public list[Expr] fetchListAssignUses(Script scr) = [ a | /a:listAssign(_,_) := scr ];
public list[Expr] fetchListAssignUsesVVTarget(Script scr) = [ a | a:listAssign(ll,_) <- fetchListAssignUses(scr), true in { containsVV(t) | t <- ll } ];
public rel[loc fileloc, Expr call] gatherVVListAssigns(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchListAssignUsesVVTarget);

@doc{Gather information on reference assignments where the assignment target contains a variable-variable}
public list[Expr] fetchRefAssignUses(Script scr) = [ a | /a:refAssign(_,_) := scr ];
public list[Expr] fetchRefAssignUsesVVTarget(Script scr) = [ a | a:refAssign(Expr t,_) <- fetchRefAssignUses(scr), containsVV(t) ];
public rel[loc fileloc, Expr call] gatherVVRefAssigns(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchRefAssignUsesVVTarget);
 
@doc{Gather information on object creations with variable class names}
public list[Expr] fetchNewUses(Script scr) = [ f | /f:new(_,_) := scr ];
public list[Expr] fetchNewUsesVVClass(Script scr) = [ f | f:new(expr(_),_) <- fetchNewUses(scr) ];
public rel[loc fileloc, Expr call] gatherVVNews(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchNewUsesVVClass);

@doc{Gather information on calls where the function to call is given through a variable-variable}
public list[Expr] fetchCallUses(Script scr) = [ c | /c:call(_,_) := scr ];
public list[Expr] fetchCallUsesVVName(Script scr) = [ c | c:call(expr(_),_) <- fetchCallUses(scr) ];
public rel[loc fileloc, Expr call] gatherVVCalls(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchCallUsesVVName);

@doc{Gather information on method calls where the method to call is given through a variable-variable}
public list[Expr] fetchMethodCallUses(Script scr) = [ m | /m:methodCall(_,_,_) := scr ];
public list[Expr] fetchMethodCallUsesVVTarget(Script scr) = [ m | m:methodCall(_,expr(_),_) <- fetchMethodCallUses(scr) ];
public rel[loc fileloc, Expr call] gatherMethodVVCalls(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchMethodCallUsesVVTarget);

@doc{Gather information on static calls where the static class and/or the static method is given as a variable-variable}
public list[Expr] fetchStaticCallUses(Script scr) = [ m | /m:staticCall(_,_,_) := scr ];
public list[Expr] fetchStaticCallUsesVVMethod(Script scr) = [ m | m:staticCall(_,expr(_),_) <- fetchStaticCallUses(scr) ];
public list[Expr] fetchStaticCallUsesVVTarget(Script scr) = [ m | m:staticCall(expr(_),_,_) <- fetchStaticCallUses(scr) ];
public rel[loc fileloc, Expr call] gatherStaticVVCalls(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchStaticCallUsesVVMethod);
public rel[loc fileloc, Expr call] gatherStaticVVTargets(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchStaticCallUsesVVTarget);

@doc{Gather information on includes with paths based on expressions}
public list[Expr] fetchIncludeUses(Script scr) = [ i | /i:include(_,_) := scr ];
public list[Expr] fetchIncludeUsesVarPaths(Script scr) = [ i | i:include(Expr e,_) <- fetchIncludeUses(scr), scalar(_) !:= e ];
public rel[loc fileloc, Expr call] gatherIncludesWithVarPaths(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchIncludeUsesVarPaths);

@doc{Gather information on property fetch expressions with the property name given as a variable-variable}
public list[Expr] fetchPropertyFetchUses(Script scr) = [ f | /f:propertyFetch(_,_) := scr ];
public list[Expr] fetchPropertyFetchVVNames(Script scr) = [ f | f:propertyFetch(_,expr(_)) <- fetchPropertyFetchUses(scr) ];
public rel[loc fileloc, Expr call] gatherPropertyFetchesWithVarNames(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchPropertyFetchVVNames);

@doc{Gather information on static property fetches where the static class and/or the static property name is given as a variable-variable}
public list[Expr] staticPropertyFetchUses(Script scr) = [ m | /m:staticPropertyFetch(_,_) := scr ];
public list[Expr] staticPropertyFetchVVName(Script scr) = [ m | m:staticPropertyFetch(_,expr(_)) <- staticPropertyFetchUses(scr) ];
public list[Expr] staticPropertyFetchVVTarget(Script scr) = [ m | m:staticPropertyFetch(expr(_),_) <- staticPropertyFetchUses(scr) ];
public rel[loc fileloc, Expr call] gatherStaticPropertyVVNames(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, staticPropertyFetchVVName);
public rel[loc fileloc, Expr call] gatherStaticPropertyVVTargets(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, staticPropertyFetchVVTarget);

@doc{Gather variable-variable uses}
public list[Expr] fetchVarUses(Script scr) = [ v | /v:var(_) := scr ];
public list[Expr] fetchVarUsesVV(Script scr) = [ v | v:var(expr(_)) <- fetchVarUses(scr) ];
public rel[loc fileloc, Expr call] gatherVarVarUses(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchVarUsesVV);

@doc{Magic methods that implement overloads}
public list[ClassItem] fetchOverloadedSet(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:method("__set",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedGet(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:method("__get",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedIsSet(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:method("__isset",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedUnset(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:method("__unset",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedCall(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:method("__call",_,_,_,_) := scripts[l] ];
public list[ClassItem] fetchOverloadedCallStatic(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:method("__callStatic",_,_,_,_) := scripts[l] ];

@doc{Support for var-args functions}
public list[Expr] fetchVACalls(Script scr) = [ v | /v:call(name(name(fn)),_) := scr, fn in {"func_get_args","func_get_arg","func_num_args"} ];
public rel[loc fileloc, Expr call] getVACallUses(map[loc fileloc, Script scr] scripts) = gatherExprStats(scripts, fetchVACalls);

@doc{Break/continue with non-literal arguments}
public list[Stmt] fetchVarBreak(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:\break(someExpr(e)) := scripts[l], scalar(_) !:= e ];
public list[Stmt] fetchVarContinue(map[loc fileloc, Script scr] scripts) = [ x | l <- scripts<0>, /x:\continue(someExpr(e)) := scripts[l], scalar(_) !:= e ];

public map[str,int] featureCounts(map[loc fileloc, Script scr] scripts) {
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
public map[str,int] stmtCounts(map[loc fileloc, Script scr] scripts) {
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

@doc{Gather expression counts}
public map[str,int] exprCounts(map[loc fileloc, Script scr] scripts) {
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

public str getCastTypeKey(\int()) = "int";
public str getCastTypeKey(\bool()) = "bool";
public str getCastTypeKey(CastType::float()) = "float";
public str getCastTypeKey(CastType::string()) = "string";
public str getCastTypeKey(CastType::array()) = "array";
public str getCastTypeKey(object()) = "object";
public str getCastTypeKey(CastType::unset()) = "unset";

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
public str getStmtKey(\while(_,_)) = "while def";

public list[str] stmtKeyOrder() = [ "break", "class def", "const", "continue", "declare", "do",
								    "echo", "expression statement (chain rule)", "for", "foreach",
								    "function def", "global", "goto", "halt compiler", "if",
								    "inline HTML", "interface def", "trait def", "label",
								    "namespace", "return", "static", "switch", "throw",
								    "try/catch", "unset", "use", "while def" ];

public list[str] exprKeyOrder() {
	return [ "array", "fetch array dim", "fetch class const", "assign" ] +
		   [ "assign with operation: <op>" | op <- opKeyAssnOrder() ] +
		   [ "list assign", "ref assign" ] +
		   [ "binary operation: <op>" | op <- binOpOrder() ] +
		   [ "unary operation: <op>" | op <- uOpOrder() ] +
		   [ "new", "class const" ] +
		   [ "cast to <ct>" | ct <- castTypeOrder() ] +
		   [ "clone", "closure", "fetch const", "empty", "suppress", "eval", "exit",
		     "call", "method call", "static call", "include", "instanceOf", "isSet",
		     "print", "property fetch", "shell exec", "exit", "fetch static property",
		     "scalar", "var" ];
}
								  								  
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
									  "right shift", "left shift", "boolean and", 
									  "boolean or", "logical and", "logical or", "logical xor"];					

public list[str] castTypeOrder() = [ "int", "bool", "float", "string", "array", "object", "unset" ];

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

									