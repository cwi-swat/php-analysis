module lang::php::analysis::usedef::UseDef

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;

import Relation;
import IO;
import Set;

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
	
alias Defs = rel[Lab current, Name name, Expr definedAs, Lab definedAt];

alias Uses = rel[Lab current, Name name, Lab definedAt];

public bool isDefNode(exprNode(assign(_,_),_)) = true;
public bool isDefNode(exprNode(assignWOp(_,_,_),_)) = true;
public bool isDefNode(exprNode(refAssign(_,_),_)) = true;
public default bool isDefNode(_) = false;

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
			
		case propertyFetch(target, Expr e) :
			return [ computedPropertyName(target, e) ];
		
		case staticPropertyFetch(name(name(target)), name(name(vn))) :
			return [ staticPopertyName(target, vn) ];
			
		case staticPropertyFetch(name(name(target)), Expr e) :
			return [ computedStaticPopertyName(target, e) ];
		
		case staticPropertyFetch(expr(Expr target), name(name(vn))) :
			return [ computedStaticPopertyName(target, vn) ];
			
		case staticPropertyFetch(expr(Expr target), Expr e) :
			return [ computedStaticPopertyName(target, e) ];
			
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
			
		case ni:propertyFetch(target, Expr e) :
			res = res + < computedPropertyName(target, e), ni@at >;
		
		case ni:staticPropertyFetch(name(name(target)), name(name(vn))) :
			res = res + < staticPopertyName(target, vn), ni@at >;
			
		case ni:staticPropertyFetch(name(name(target)), Expr e) :
			res = res + < computedStaticPopertyName(target, e), ni@at >;
		
		case ni:staticPropertyFetch(expr(Expr target), name(name(vn))) :
			res = res + < computedStaticPopertyName(target, vn), ni@at >;
			
		case ni:staticPropertyFetch(expr(Expr target), Expr e) :
			res = res + < computedStaticPopertyName(target, e), ni@at >;
	}
	
	int beforeFilteringSize = size(res);
	res = { < rn, rl > | < rn, rl > <- res, rl notin locsToFilter };
	int afterFilteringSize = size(res);
	//if (beforeFilteringSize != afterFilteringSize) {
	//	println("<n.l>:Before/after filtering: <beforeFilteringSize>/<afterFilteringSize> elements");
	//}
		
	return res<0>;
}

public rel[Name name, Expr definedAs, Lab definedAt] getDefInfo(CFGNode n) {
	rel[Name name, Expr definedAs, Lab definedAt] res = { };
	switch (n) {
		case exprNode(assign(Expr e1, Expr e2),_) : {
			names = getNames(e1);
			res = res + { < ni, e2, n.l > | ni <- names };
		}

		case exprNode(assignWOp(Expr e1, Expr e2, _),_) : {
			names = getNames(e1);
			res = res + { < ni, e2, n.l > | ni <- names };
		}

		case exprNode(refAssign(Expr e1, Expr e2),_) : {
			names = getNames(e1);
			res = res + { < ni, e2, n.l > | ni <- names };
		}
	}
	return res;
}

// TODO: This does not properly handle computed names, such as variable variables.
// TODO: For properties, we should kill all properties of the same name when one is
// defined unless we can verify that the targets are disjoint. Currently properties
// with syntactically different targets are kept distinct.
public Defs definitions(CFG cfgFull) {
	g = cfgAsGraph(cfgFull);
	gInverted = invert(g);
	Defs res = { };
	
	set[CFGNode] seenBefore = { getEntryNode(cfgFull) };
	set[CFGNode] frontier = seenBefore;
	
	solve(res, frontier) {
		workingFrontier = frontier;
		for (n <- frontier) {
			rel[Name name, Expr definedAs, Lab definedAt] inbound = res[{ni.l | ni <- gInverted[n]}];
			rel[Name name, Expr definedAs, Lab definedAt] kills = { };
			if (isDefNode(n)) {
				kills = getDefInfo(n);
			}
			res = res + { < n.l, ni.name, ni.definedAs, ni.definedAt > | ni <- inbound, ni.name notin kills.name } 
				      + { < n.l, ni.name, ni.definedAs, ni.definedAt > | ni <- kills };
		}
		frontier = g[workingFrontier] - seenBefore;
		seenBefore += frontier;
	}
	
	return res;	
}

// TODO: This needs to better handle cases where the names are computed. These could, in theory,
// be any name, or maybe any name that matches a partial patterns (for cases where part of the
// name is given).
public Uses uses(CFG cfgFull, Defs defs) {
	g = cfgAsGraph(cfgFull);
	gInverted = invert(g);
	Uses res = { };

	set[loc] locsToFilter = { };
	visit (cfgFull.nodes) {
		case assign(ni:Expr e1, _) : {
			locsToFilter = locsToFilter + ni@at;
		}

		case assignWOp(ni:Expr e1, _, _) : {
			locsToFilter = locsToFilter + ni@at;
		}

		case refAssign(ni:Expr e1, _) : {
			locsToFilter = locsToFilter + ni@at;
		}
	}
	
	// TODO: Remove defs, we don't want to use those as uses as well
	for (n <- cfgFull.nodes) {
		// Grab back the definitions that reach this node (this doesn't include any that are
		// created by this node)
		rel[Name name, Expr definedAs, Lab definedAt] inbound = defs[{ni.l | ni <- gInverted[n]}];
		names = getNestedNames(n,locsToFilter);
		res = res + { < n.l, name, definedAt > | name <- names, < name, _, definedAt > <- inbound };
	}
	
	return res;
}