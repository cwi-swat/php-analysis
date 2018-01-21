module lang::php::analysis::usedef::UseDef

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::cfg::Util;

import Relation;
import IO;
import Set;
import List;

data Name 
	= varName(str varName) 
	| computedName(Expr computedName)
	| propertyName(Expr targetObject, str propertyName)
	| computedPropertyName(Expr targetObject, Expr computedPropertyName)
	| staticPropertyName(str className, str propertyName)
	| computedStaticPropertyName(Expr computedClassName, str propertyName)
	| computedStaticPropertyName(str className, Expr computedPropertyName)
	| computedStaticPropertyName(Expr computedClassName, Expr computedPropertyName)
	;

public str printName(varName(str vname)) = "$<vname>";
public str printName(computedName(Expr cname)) = "{<pp(cname)>}";
public str printName(propertyName(Expr targetObject, str pname)) = "{<pp(targetObject)>}.<pname>";
public str printName(computedPropertyName(Expr targetObject, Expr pname)) = "{<pp(targetObject)>}.{<pp(pname)>}";
public str printName(staticPropertyName(str className, str pname)) = "<className>::<pname>";
public str printName(computedStaticPropertyName(Expr computedClassName, str pname)) = "{<pp(computedClassName)>}::<pname>";
public str printName(computedStaticPropertyName(str className, Expr pname)) = "<className>::{<pp(pname)>}";
public str printName(computedStaticPropertyName(Expr computedClassName, Expr pname)) = "{<pp(computedClassName)>}::{<pp(pname)>}";

data DefExpr = defExpr(Expr e) | defExprWOp(Name usedName, Expr e, Op usedOp) | inputParamDef(Name paramName) | globalDef(Name globalName);

alias Defs = rel[Lab current, Name name, DefExpr definedAs, Lab definedAt];

alias Uses = rel[Lab current, Name name, Lab definedAt];

public bool isDefNode(exprNode(assign(_,_),_)) = true;
public bool isDefNode(exprNode(assignWOp(_,_,_),_)) = true;
public bool isDefNode(exprNode(refAssign(_,_),_)) = true;
public bool isDefNode(headerNode(global(_),_,_)) = true;
public default bool isDefNode(CFGNode n) = false;

public list[Name] getNames(Expr n) {
	// TODO: Add support for list_expr
	switch(n) {
		case var(name(name(vn))) :
			return [ varName(vn) ];
		
		case fetchArrayDim(var(name(name(vn))),_) :
			return [ varName(vn) ];
			
		case var(expr(Expr e)) :
			return [ computedName(e) ];
		
		case fetchArrayDim(var(expr(Expr e)),_) :
			return [ computedName(e) ];
		
		case propertyFetch(target, name(name(vn))) :
			return [ propertyName(target, vn) ];
			
		case propertyFetch(target, expr(Expr e)) :
			return [ computedPropertyName(target, e) ];
		
		case staticPropertyFetch(name(name(target)), name(name(vn))) :
			return [ staticPropertyName(target, vn) ];
			
		case staticPropertyFetch(name(name(target)), expr(Expr e)) :
			return [ computedStaticPropertyName(target, e) ];
		
		case staticPropertyFetch(expr(Expr target), name(name(vn))) :
			return [ computedStaticPropertyName(target, vn) ];
			
		case staticPropertyFetch(expr(Expr target), expr(Expr e)) :
			return [ computedStaticPropertyName(target, e) ];
			
		default :
			return [ computedName(n) ];
	}
}

public set[Name] getNestedNames(CFGNode n, set[loc] locsToFilter) {
	// TODO: Add support for list_expr
	rel[Name,loc] res = { };
	
	bottom-up visit(n) {
		case ni:var(name(name(vn))) :
			res = res + < varName(vn), ni@at >;
		
		case ni:fetchArrayDim(var(name(name(vn))),_) :
			res = res + < varName(vn), ni@at >;
			
		case ni:var(expr(Expr e)) :
			res = res + < computedName(e), ni@at >;
		
		case ni:fetchArrayDim(var(expr(Expr e)),_) :
			res = res + < computedName(e), ni@at >;
		
		case ni:propertyFetch(target, name(name(vn))) :
			res = res + < propertyName(target, vn), ni@at >;
			
		case ni:propertyFetch(target, expr(Expr e)) :
			res = res + < computedPropertyName(target, e), ni@at >;
		
		case ni:staticPropertyFetch(name(name(target)), name(name(vn))) :
			res = res + < staticPropertyName(target, vn), ni@at >;
			
		case ni:staticPropertyFetch(name(name(target)), expr(Expr e)) :
			res = res + < computedStaticPropertyName(target, e), ni@at >;
		
		case ni:staticPropertyFetch(expr(Expr target), name(name(vn))) :
			res = res + < computedStaticPropertyName(target, vn), ni@at >;
			
		case ni:staticPropertyFetch(expr(Expr target), expr(Expr e)) :
			res = res + < computedStaticPropertyName(target, e), ni@at >;
	}
	
	int beforeFilteringSize = size(res);
	res = { < rn, rl > | < rn, rl > <- res, rl notin locsToFilter };
	int afterFilteringSize = size(res);
	//if (beforeFilteringSize != afterFilteringSize) {
	//	println("<n.l>:Before/after filtering: <beforeFilteringSize>/<afterFilteringSize> elements");
	//}
		
	return res<0>;
}

public rel[Name name, DefExpr definedAs, Lab definedAt] getDefInfo(CFGNode n) {
	rel[Name name, DefExpr definedAs, Lab definedAt] res = { };
	switch (n) {
		case exprNode(assign(Expr e1, Expr e2),_) : {
			names = getNames(e1);
			res = res + { < ni, defExpr(e2), n.l > | ni <- names };
		}

		case exprNode(assignWOp(Expr e1, Expr e2, op),_) : {
			names = getNames(e1);
			res = res + { < ni, defExprWOp(ni, e2, op), n.l > | ni <- names };
		}

		case exprNode(refAssign(Expr e1, Expr e2),_) : {
			names = getNames(e1);
			res = res + { < ni, defExpr(e2), n.l > | ni <- names };
		}
		
		case headerNode(global(el),_,_) : {
			res = res + { < ni, globalDef(ni), n.l > | ei <- el, ni <- getNames(ei) };
		}
	}
	return res;
}

private set[str] superGlobalNames = { "GLOBALS", "_SERVER", "_REQUEST", "_POST", "_GET", "_FILES", "_ENV", "_COOKIE", "_SESSION" };

// TODO: This does not properly handle computed names, such as variable variables.
// TODO: For properties, we should kill all properties of the same name when one is
// defined unless we can verify that the targets are disjoint. Currently properties
// with syntactically different targets are kept distinct.
public Defs definitions(CFG inputCFG) {
	g = cfgAsGraph(inputCFG);
	gInverted = invert(g);
	
	map[CFGNode, set[CFGNode]] gmap = ( n : { } | n <- inputCFG.nodes );
	map[CFGNode, set[CFGNode]] gmapInverted = ( n : { } | n <- inputCFG.nodes );
	for (< n1, n2 > <- g) {
		gmap[n1] = gmap[n1] + n2;
	}
	for ( < n1, n2 > <- gInverted) {
		gmapInverted[n1] = gmapInverted[n1] + n2;
	}
	
	map[Lab, rel[Name name, DefExpr definedAs, Lab definedAt]] resMap = ( );
		
	entry = getEntryNode(inputCFG);
	usedSuperGlobalNames = { sgn | sgn <- superGlobalNames, /var(name(name(sgn))) := inputCFG.nodes };
	resMap[entry.l] = { < varName(sgn), globalDef(varName(sgn)), entry.l >  | sgn <- usedSuperGlobalNames };
	
	// Introduce the names for the parameters
	if (entry is functionEntry || entry is methodEntry) {
		// Grab out all the parameter nodes
		actualProvidedNodes = { n | n <- inputCFG.nodes, n is actualProvided };
		actualNotProvidedNodes = { n | n <- inputCFG.nodes, n is actualNotProvided };
		
		// The actualProvided nodes represent formal parameters with no defaults, so the actual must
		// be provided to the program (and we don't know what that is)
		for (n <- actualProvidedNodes) {
			resMap[entry.l] = resMap[entry.l] + { < varName(n.paramName), inputParamDef(varName(n.paramName)), entry.l > };
		}

		// The actualNotProvided nodes represent formal parameters with defaults, allowing cases
		// where an actual is not provided explicitly.
		for (n <- actualNotProvidedNodes) {
			resMap[entry.l] = resMap[entry.l] + { < varName(n.paramName), inputParamDef(varName(n.paramName)), entry.l >, < varName(n.paramName), defExpr(n.expr), entry.l > };
		}
	}
	  
	// TODO: This is a slower algorithm but it won't miss cases, should look at ordering
	// the nodes to speed up the flow analysis
	list[CFGNode] worklist = buildForwardWorklist(inputCFG);
	workset = toSet(worklist);
	//println("Starting with worklist size <size(worklist)>");
	int i = 0;
	while (!isEmpty(worklist)) {
		i += 1;
		//if (i % 100 == 0) println("Remaining worklist size: <size(worklist)>");
		n = worklist[0];
		worklist = worklist[1..];
		workset = workset - n;
		resStart = resMap[n.l] ? {};
		
		rel[Name name, DefExpr definedAs, Lab definedAt] inbound = { *(resMap[ni.l]? {}) | ni <- gmapInverted[n]};
		rel[Name name, DefExpr definedAs, Lab definedAt] kills = { };
		
		if (isDefNode(n)) {
			kills = getDefInfo(n);
		}
		
		
		tempRel = { < n.l, ni.name, ni.definedAs, ni.definedAt > | ni <- inbound, ni.name notin kills.name } 
			    + { < n.l, ni.name, ni.definedAs, ni.definedAt > | ni <- kills };
			    
		for (l <- tempRel<0>) {
			resMap[l] = (resMap[l] ? {}) + tempRel[l];
		}
		
		resEnd = resMap[n.l] ? {};
		
		if (resStart != resEnd) {
			newElements = [ gi | gi <- gmap[n], gi notin workset ];
			worklist = newElements + worklist;
			workset = workset + toSet(newElements);
		}
	}
	
	return { < l, n, de, dl > | l <- resMap, < n, de, dl > <- resMap[l] };	
}

// TODO: This needs to better handle cases where the names are computed. These could, in theory,
// be any name, or maybe any name that matches a partial patterns (for cases where part of the
// name is given).
public Uses uses(CFG inputCFG, Defs defs) {
	gInverted = invert(cfgAsGraph(inputCFG));
	map[CFGNode, set[CFGNode]] gmapInverted = ( n : { } | n <- inputCFG.nodes );
	for ( < n1, n2 > <- gInverted) {
		gmapInverted[n1] = gmapInverted[n1] + n2;
	}

	Uses res = { };

	set[loc] locsToFilter = { };
	visit (inputCFG.nodes) {
		case assign(ni:Expr e1, _) : {
			locsToFilter = locsToFilter + ni@at;
		}

		case refAssign(ni:Expr e1, _) : {
			locsToFilter = locsToFilter + ni@at;
		}
	}
	
	// TODO: Remove defs, we don't want to use those as uses as well
	map[Lab, rel[Name name, DefExpr definedAs, Lab definedAt]] defsMap = ( n.l : { } | n <- inputCFG.nodes );
	for ( < dl, dn, da, ddl > <- defs ) {
		defsMap[dl] += < dn, da, ddl >;
	}
	for (n <- inputCFG.nodes) {
		// Grab back the definitions that reach this node (this doesn't include any that are
		// created by this node)
		rel[Name name, DefExpr definedAs, Lab definedAt] inbound = { };
		for (ni <- gmapInverted[n]) {
			inbound = inbound + defsMap[ni.l];
		}
		names = getNestedNames(n,locsToFilter);
		res = res + { < n.l, name, definedAt > | Name name <- names, < name, _, definedAt > <- inbound };
	}
	
	return res;
}