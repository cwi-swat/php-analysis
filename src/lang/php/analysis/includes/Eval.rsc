module lang::php::analysis::includes::Eval

import lang::php::ast::AbstractSyntax;

alias Layer = tuple[str className, map[str,Val] fieldValues];
alias Layers = list[Layer];

data Val
	= strVal(str sv)
	| objVal(str className, Layers layers)
	| nothing()
	| anything()
	;

data Config = config(map[str,Val] varMap, map[str,Val] constMap, map[str,Layers] classConstMap, map[str,Layers] classStaticMap);

data ComputationItem
	= nil()
	| expr(Expr e)
	| stmt(Stmt s)
	| expr(list[Expr] el)
	| stmt(list[Stmt] sl)
	| val(Val v)
	| val(list[Val] vl)
	;

alias Computation = list[ComputationItem];

//public data Stmt 
//	= \break(OptionExpr breakExpr)
//	| classDef(ClassDef classDef)
//	| const(list[Const] consts)
//	| \continue(OptionExpr continueExpr)
//	| declare(list[Declaration] decls, list[Stmt] body)
//	| do(Expr cond, list[Stmt] body)
//	| echo(list[Expr] exprs)
//	| exprstmt(Expr expr)
//	| \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)
//	| foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body)
//	| function(str name, bool byRef, list[Param] params, list[Stmt] body)
//	| global(list[Expr] exprs)
//	| goto(str label)
//	| haltCompiler(str remainingText)
//	| \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause)
//	| inlineHTML(str htmlText)
//	| interfaceDef(InterfaceDef interfaceDef)
//	| traitDef(TraitDef traitDef)
//	| label(str labelName)
//	| namespace(OptionName nsName, list[Stmt] body)
//	| \return(OptionExpr returnExpr)
//	| static(list[StaticVar] vars)
//	| \switch(Expr cond, list[Case] cases)
//	| \throw(Expr expr)
//	| tryCatch(list[Stmt] body, list[Catch] catches)
//	| unset(list[Expr] unsetVars)
//	| use(list[Use] uses)
//	| \while(Expr cond, list[Stmt] body)	
//	;

public Config red(Config c) {
	switch(c.k) {
		case [ stmt(\break(noExpr())), K*] : {
			;
		}
	}	
}
//
// VARIATION POINTS
// Array formation
// Array dim, tied to formation (how fine-grained a representation we have)
//

alias Res = tuple[Config c, Val v];

//
// These reduction functions just propagate the call, but do nothing to directly change
// the configuration.
//
public Res red(Config c, Expr e:array(list[ArrayElement] items)) = < ( c | red(it,i).c | i <- items ), top() >;
public Res red(Config c, Expr e:fetchArrayDim(Expr var, OptionExpr dim)) = < red(red(c,var).c,dim).c, top() >;
public Red red(Config c, Expr e:unaryOperation(Expr operand, Op operation)) = < red(c,operand).c, top() >;
public Res red(Config c, Expr e:clone(Expr expr)) = < red(c,expr).c, top() >;
public Red red(Config c, Expr e:isSet(list[Expr] exprs)) = < ( c | red(c,i).c | i <- exprs ), top() >;
public Red red(Config c, Expr e:print(Expr expr)) = < red(c,expr).c, top() >;
public Red red(Config c, Expr e:shellExec(list[Expr] parts)) = < ( c | red(it,p).c | p <- parts ), top() >;
public Red red(Config c, Expr e:empty(Expr expr)) = < red(c,expr).c, top() >;
public Red red(Config c, Expr e:suppress(Expr expr)) = red(c,expr);
public Red red(Config c, Expr e:eval(Expr expr)) = < red(c,expr).c, top() >;
public Red red(Config c, Expr e:exit(OptionExpr exitExpr)) = < red(c,exitExpr).c, top() >;
public Red red(Config c, Expr e:cast(CastType castType, Expr expr)) = < red(c,expr).c, top() >;
public Res red(Config c, Expr e:instanceOf(Expr expr, NameOrExpr toCompare)) = < red(red(c,expr).c,toCompare).c, top() >;

public Res red(Config c, Expr e:closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)) {
	throw "Closures are not yet implemented";
}



//
// These reduction functions handle name lookups.
//
public Res red(Config c, Expr e:propertyFetch(Expr target, NameOrExpr propertyName)) {
	if (name(name(t)) := target && name(name(pn)) := propertyName) {
		return < c, lookupProperty(c,t,pn) >;
	}
	return < c, top() >;
}

public Res red(Config c, Expr e:staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)) {
	if (name(name(cn)) := className && name(name(pn)) := propertyName) {
		return < c, lookupStaticProperty(c,cn,pn) >;
	}
	return < c, top() >;
}

public Res red(Config c, Expr e:fetchConst(Name name)) {
	if (name(cn) := name)
		return < c, lookupConst(c,cn) >;
	return < c, top() >;
}

public Res red(Config c, Expr e:fetchClassConst(NameOrExpr className, str constName)) {
	if (name(name(cn)) := className) {
		return < c, lookupClassConst(c,cn,constName) >;
	}
	return < c, top() >;
}

public Res red(Config c, Expr e:var(NameOrExpr varName)) {
	if (name(name(vn)) := varName) {
		return < c, lookupVar(c,vn) >;
	}
	return < c, top() >;
}

//
// These reduction functions handle name assignments.
//
public Res red(Config c, Expr e:assign(Expr assignTo, Expr assignExpr)) {
	switch(assignTo) {
		case fetchClassConst(name(name(cn)), str constname) : {
			;
		}
		
		case fetchConst(name(cn)) : {
			;
		}

		case propertyFetch(var(name(name(tn))),name(name(pn))) : {
			;
		}
		
		case staticPropertyFetch(name(name(cn)),name(name(pn))) : {
			;
		}
		
		case var(name(name(vn))) : {
			;
		}
	}
	return < c, top() >;
}

public Res red(Config c, Expr e:assignWOp(Expr assignTo, Expr assignExpr, Op operation)) {
	switch(assignTo) {
		case fetchClassConst(name(name(cn)), str constname) : {
			;
		}
		
		case fetchConst(name(cn)) : {
			;
		}

		case propertyFetch(var(name(name(tn))),name(name(pn))) : {
			;
		}
		
		case staticPropertyFetch(name(name(cn)),name(name(pn))) : {
			;
		}
		
		case var(name(name(vn))) : {
			;
		}
	}
	return < c, top() >;
}

public Res red(Config c, Expr e:listAssign(list[OptionExpr] assignsTo, Expr assignExpr)) {
	return < c, top() >;
}

public Res red(Config c, Expr e:refAssign(Expr assignTo, Expr assignExpr)) {
	switch(assignTo) {
		case fetchClassConst(name(name(cn)), str constname) : {
			;
		}
		
		case fetchConst(name(cn)) : {
			;
		}

		case propertyFetch(var(name(name(tn))),name(name(pn))) : {
			;
		}
		
		case staticPropertyFetch(name(name(cn)),name(name(pn))) : {
			;
		}
		
		case var(name(name(vn))) : {
			;
		}
	}
	return < c, top() >;
}

//
// Simulate operations we care about. We don't simulate everything here, since most of
// it doesn't matter in this limited analysis
//
public Res red(Config c, Expr e:binaryOperation(Expr left, Expr right, Op operation)) {
	return < c, top() >;
}

public Res red(Config c, Expr e:new(NameOrExpr className, list[ActualParameter] parameters)) {
	return < c, top() >;
}

//
// Simulate calls. The main concern here is reference paramters and return results, since, in those
// cases, we need to discard the results in the targets.
//
public Res red(Config c, Expr e:call(NameOrExpr funName, list[ActualParameter] parameters)) {
	return < c, top() >;
}

public Res red(Config c, Expr e:methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)) {
	return < c, top() >;
}

public Res red(Config c, Expr e:staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)) {
	return < c, top() >;
}

//
// Include calls. We are trying to figure out the actual include here, using the results of the
// rest of the analysis.
//
public Res red(Config c, Expr e:include(Expr expr, IncludeType includeType)) {
	return < c, top() >;
}

//
// Scalars. We return these values, since they are used elsewhere.
//
public Res red(Config c, Expr e:scalar(Scalar scalarVal)) {
	return < c, top() >;
}
