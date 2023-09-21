@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::usedef::UseDef

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::cfg::Util;

import Relation;
import Set;
import List;

data Name 
	= varName(str varName)
	| elementName(str varName, str indexName) 
	| computedName(Expr computedName)
	| propertyName(Expr targetObject, str propertyName)
	| computedPropertyName(Expr targetObject, Expr computedPropertyName)
	| staticPropertyName(str className, str propertyName)
	| computedStaticPropertyName(Expr computedClassName, str propertyName)
	| computedStaticPropertyName(str className, Expr computedPropertyName)
	| computedStaticPropertyName(Expr computedClassName, Expr computedPropertyName)
	;

public str printName(varName(str vname)) = "$<vname>";
public str printName(elementName(str vname, str indexName)) = "$<vname>[\'<indexName>\']";
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
public bool isDefNode(foreachAssignValue(_,_,_)) = true;
public bool isDefNode(foreachAssignKey(_,_,_)) = true;
public default bool isDefNode(CFGNode n) = false;

private set[str] superGlobalNames = { "GLOBALS", "_SERVER", "_REQUEST", "_POST", "_GET", "_FILES", "_ENV", "_COOKIE", "_SESSION" };

public list[Name] getNames(Expr n) {
	// TODO: Add support for list_expr
	switch(n) {
		case var(name(name(vn))) :
			return [ varName(vn) ];
		
		case var(expr(Expr e)) :
			return [ computedName(e) ];
		
		case fetchArrayDim(var(name(name(vn))), noExpr()) :
			return [ varName(vn) ];
			
		case fetchArrayDim(var(name(name(vn))),someExpr(idx)) : {
			// If we have an array and a scalar string index, we treat this specially
			// so the analysis can differentiate different array elements.
			// NOTE: At this point, we only do this for superglobals
			// TODO: It would be good to enable this for all arrays, but we need enough type
			// information to know which names reference arrays and/or array elements.
			if (scalar(string(idxname)) := idx && vn in superGlobalNames) {
				return [ elementName(vn,idxname) ];
			} else {
				return [ varName(vn) ];
			}
		}
			
		case fetchArrayDim(var(expr(Expr e)),_) :
			return [ computedName(e) ];
		
		case propertyFetch(target, name(name(vn)), bool _) :
			return [ propertyName(target, vn) ];
			
		case propertyFetch(target, expr(Expr e), bool _) :
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
			res = res + < varName(vn), ni.at >;
		
		case ni:fetchArrayDim(var(name(name(vn))),noExpr()) :
			res = res + < varName(vn), ni.at >;
			
		case ni:fetchArrayDim(var(name(name(vn))),someExpr(idx)) :
			if (scalar(string(idxname)) := idx && vn in superGlobalNames) {
				res = res + < elementName(vn,idxname), ni.at >;
			} else {
				res = res + < varName(vn), ni.at >;
			}

		case ni:var(expr(Expr e)) :
			res = res + < computedName(e), ni.at >;
		
		case ni:fetchArrayDim(var(expr(Expr e)),_) :
			res = res + < computedName(e), ni.at >;
		
		case ni:propertyFetch(target, name(name(vn)), bool _) :
			res = res + < propertyName(target, vn), ni.at >;
			
		case ni:propertyFetch(target, expr(Expr e), bool _) :
			res = res + < computedPropertyName(target, e), ni.at >;
		
		case ni:staticPropertyFetch(name(name(target)), name(name(vn))) :
			res = res + < staticPropertyName(target, vn), ni.at >;
			
		case ni:staticPropertyFetch(name(name(target)), expr(Expr e)) :
			res = res + < computedStaticPropertyName(target, e), ni.at >;
		
		case ni:staticPropertyFetch(expr(Expr target), name(name(vn))) :
			res = res + < computedStaticPropertyName(target, vn), ni.at >;
			
		case ni:staticPropertyFetch(expr(Expr target), expr(Expr e)) :
			res = res + < computedStaticPropertyName(target, e), ni.at >;
	}
	
	int beforeFilteringSize = size(res);
	res = { < rn, rl > | < rn, rl > <- res, rl notin locsToFilter };
	int afterFilteringSize = size(res);
	//if (beforeFilteringSize != afterFilteringSize) {
	//	println("<n.lab>:Before/after filtering: <beforeFilteringSize>/<afterFilteringSize> elements");
	//}
		
	return res<0>;
}

public rel[Name name, DefExpr definedAs, Lab definedAt] getDefInfo(CFGNode n) {
	rel[Name name, DefExpr definedAs, Lab definedAt] res = { };
	switch (n) {
		case exprNode(assign(Expr e1, Expr e2),_) : {
			names = getNames(e1);
			res = res + { < ni, defExpr(e2), n.lab > | ni <- names };
		}

		case exprNode(assignWOp(Expr e1, Expr e2, op),_) : {
			names = getNames(e1);
			res = res + { < ni, defExprWOp(ni, e2, op), n.lab > | ni <- names };
		}

		case exprNode(refAssign(Expr e1, Expr e2),_) : {
			names = getNames(e1);
			res = res + { < ni, defExpr(e2), n.lab > | ni <- names };
		}
		
		case headerNode(global(el),_,_) : {
			res = res + { < ni, globalDef(ni), n.lab > | ei <- el, ni <- getNames(ei) };
		}

		case foreachAssignValue(Expr expr, Expr valExpr, Lab _) : {
			res = res + { < ni, defExpr(expr), n.lab > | ni <- getNames(valExpr) };
		}
		
		case foreachAssignKey(Expr expr, Expr keyExpr, Lab _) : {
			res = res + { < ni, defExpr(expr), n.lab > | ni <- getNames(keyExpr) };
		}
	}
	return res;
}

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
	
	// Pull out both the bare superglobal names (e.g., $_REQUEST) and any literal index used with the
	// superglobal arrays (e.g., $_REQUEST['first_name']). We add these as defs in the entry node,
	// since they are provided globally and so are already defined.
	usedSuperGlobalNames = { sgn | sgn <- superGlobalNames, /var(name(name(sgn))) := inputCFG.nodes };
	usedIndexedNames = { < vn, idxname > | /fetchArrayDim(var(name(name(vn))),someExpr(scalar(string(idxname)))) := inputCFG.nodes, vn in usedSuperGlobalNames };
	resMap[entry.lab] = { < varName(sgn), globalDef(varName(sgn)), entry.lab >  | sgn <- usedSuperGlobalNames }
					+ { < elementName(sgn, idxname), globalDef(elementName(sgn, idxname)), entry.lab > | < sgn, idxname > <- usedIndexedNames };
	
	// Introduce the names for any parameters and add them as defs in the entry node, since they
	// are actually defined automatically by the function.
	if (entry is functionEntry || entry is methodEntry) {
		// Grab out all the parameter nodes
		actualProvidedNodes = { n | n <- inputCFG.nodes, n is actualProvided };
		actualNotProvidedNodes = { n | n <- inputCFG.nodes, n is actualNotProvided };
		
		// The actualProvided nodes represent formal parameters with no defaults, so the actual must
		// be provided to the program (and we don't know what that is)
		for (n <- actualProvidedNodes) {
			resMap[entry.lab] = resMap[entry.lab] + { < varName(n.paramName), inputParamDef(varName(n.paramName)), entry.lab > };
		}

		// The actualNotProvided nodes represent formal parameters with defaults, allowing cases
		// where an actual is not provided explicitly.
		for (n <- actualNotProvidedNodes) {
			resMap[entry.lab] = resMap[entry.lab] + { < varName(n.paramName), inputParamDef(varName(n.paramName)), entry.lab >, < varName(n.paramName), defExpr(n.expr), entry.lab > };
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
		resStart = resMap[n.lab] ? {};
		
		rel[Name name, DefExpr definedAs, Lab definedAt] inbound = { *(resMap[ni.lab]? {}) | ni <- gmapInverted[n]};
		rel[Name name, DefExpr definedAs, Lab definedAt] kills = { };
		
		if (isDefNode(n)) {
			kills = getDefInfo(n);
		}
		
		// We are trying to distinguish different named array indices for precision. If we have a kill
		// of the array name without an index, this kills all the inbound individual named indices,
		// so we take those out of inbound here: killedNames is all names we kill, killedIndexedNames
		// is all inbound array element names where the name, without index, is also killed, and
		// remainingInbound is all inbound names that are not killed in this way
		directKills = { ni.name | ni <- kills };
		indirectKills = { ni.name | ni <- inbound, elementName(vn,_) := ni.name, varName(vn) in directKills };
		
		tempRel = { < n.lab, ni.name, ni.definedAs, ni.definedAt > | ni <- inbound, ni.name notin (directKills + indirectKills) } 
			    + { < n.lab, ni.name, ni.definedAs, ni.definedAt > | ni <- kills };
			    
		for (l <- tempRel<0>) {
			resMap[l] = (resMap[l] ? {}) + tempRel[l];
		}
		
		resEnd = resMap[n.lab] ? {};
		
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
		case assign(ni:Expr _, _) : {
			locsToFilter = locsToFilter + ni.at;
		}

		case refAssign(ni:Expr _, _) : {
			locsToFilter = locsToFilter + ni.at;
		}
	}
	
	map[Lab, rel[Name name, DefExpr definedAs, Lab definedAt]] defsMap = ( n.lab : { } | n <- inputCFG.nodes );
	for ( < dl, dn, da, ddl > <- defs ) {
		defsMap[dl] += < dn, da, ddl >;
	}
	for (n <- inputCFG.nodes) {
		// Grab back the definitions that reach this node (this doesn't include any that are
		// created by this node)
		rel[Name name, DefExpr definedAs, Lab definedAt] inbound = { };
		for (ni <- gmapInverted[n]) {
			inbound = inbound + defsMap[ni.lab];
		}
		names = getNestedNames(n,locsToFilter);
		res = res + { < n.lab, name, definedAt > | Name name <- names, < name, _, definedAt > <- inbound };
	}
	
	return res;
}