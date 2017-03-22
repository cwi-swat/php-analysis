module lang::php::analysis::usedef::UseDef

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;

import Relation;

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
