@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::il::GenerateIL

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::il::IL;

data GenState = genState(int fresh, list[Instruction] pgm);

public tuple[GenState gs, Var v] freshVar(GenState gs) {
	gs.fresh += 1;
	return < gs, temp(gs.fresh) >;
}

data GenResult = res(GenState newState, Var storedIn);

//public data Expr 
//	= array(list[ArrayElement] items)
public GenResult generateIL(GenState gs, array(list[ArrayElement] items)) {
	list[tuple[Var key, Var val, bool byRef]] entries = [ ];
	
	for (arrayElement(OptionExpr key, Expr val, bool byRef) <- items) {
		if (someExpr(kv) := key) {
			gr = generateIL(gs, kv);
			gr2 = generateIL(gr.newState, val);
			gs = gr2.newState;
			entries += < gr.storedIn, gr2.storedIn, byRef >;
		} else {
			gr = generateIL(gs, val);
			gs = gr.newState;
			entries +=  < placeholder(), gr.storedIn, byRef >;
		}
		
	}		
}

//	| fetchArrayDim(Expr var, OptionExpr dim)
public GenResult generateIL(GenState gs, fetchArrayDim(Expr var, OptionExpr dim)) {

}
//	| fetchClassConst(NameOrExpr className, Name constName)
public GenResult generateIL(GenState gs, fetchClassConst(NameOrExpr className, name(str constName))) {

}
//	| assign(Expr assignTo, Expr assignExpr)
public GenResult generateIL(GenState gs, assign(Expr assignTo, Expr assignExpr)) {

}
//	| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
public GenResult generateIL(GenState gs, assignWOp(Expr assignTo, Expr assignExpr, Op operation)) {

}
//	| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
public GenResult generateIL(GenState gs, listAssign(list[OptionExpr] assignsTo, Expr assignExpr)) {

}
//	| refAssign(Expr assignTo, Expr assignExpr)
public GenResult generateIL(GenState gs, refAssign(Expr assignTo, Expr assignExpr)) {

}
//	| binaryOperation(Expr left, Expr right, Op operation)
public GenResult generateIL(GenState gs, binaryOperation(Expr left, Expr right, Op operation)) {

}
//	| unaryOperation(Expr operand, Op operation)
public GenResult generateIL(GenState gs, unaryOperation(Expr operand, Op operation)) {

}
//	| new(NameOrExpr className, list[ActualParameter] parameters)
public GenResult generateIL(GenState gs, new(NameOrExpr className, list[ActualParameter] parameters)) {

}
//	| cast(CastType castType, Expr expr)
public GenResult generateIL(GenState gs, cast(CastType castType, Expr expr)) {

}
//	| clone(Expr expr)
public GenResult generateIL(GenState gs, clone(Expr expr)) {

}
//	| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)
public GenResult generateIL(GenState gs, closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)) {

}
//	| fetchConst(Name name)
public GenResult generateIL(GenState gs, fetchConst(Name name)) {

}
//	| empty(Expr expr)
public GenResult generateIL(GenState gs, empty(Expr expr)) {

}
//	| suppress(Expr expr)
public GenResult generateIL(GenState gs, suppress(Expr expr)) {

}
//	| eval(Expr expr)
public GenResult generateIL(GenState gs, eval(Expr expr)) {

}
//	| exit(OptionExpr exitExpr)
public GenResult generateIL(GenState gs, exit(OptionExpr exitExpr)) {

}
//	| call(NameOrExpr funName, list[ActualParameter] parameters)
public GenResult generateIL(GenState gs, call(NameOrExpr funName, list[ActualParameter] parameters)) {

}
//	| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)
public GenResult generateIL(GenState gs, methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)) {

}
//	| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)
public GenResult generateIL(GenState gs, staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)) {

}
//	| include(Expr expr, IncludeType includeType)
public GenResult generateIL(GenState gs, include(Expr expr, IncludeType includeType)) {

}
//	| instanceOf(Expr expr, NameOrExpr toCompare)
public GenResult generateIL(GenState gs, instanceOf(Expr expr, NameOrExpr toCompare)) {

}
//	| isSet(list[Expr] exprs)
public GenResult generateIL(GenState gs, isSet(list[Expr] exprs)) {

}
//	| print(Expr expr)
public GenResult generateIL(GenState gs, print(Expr expr)) {

}
//	| propertyFetch(Expr target, NameOrExpr propertyName)
public GenResult generateIL(GenState gs, propertyFetch(Expr target, NameOrExpr propertyName)) {

}
//	| shellExec(list[Expr] parts)
public GenResult generateIL(GenState gs, shellExec(list[Expr] parts)) {

}
//	| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)
public GenResult generateIL(GenState gs, ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)) {

}
//	| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)
public GenResult generateIL(GenState gs, staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)) {

}
//	| scalar(Scalar scalarVal)
public GenResult generateIL(GenState gs, scalar(Scalar scalarVal)) {

}
//	| var(NameOrExpr varName)	
public GenResult generateIL(GenState gs, var(NameOrExpr varName)) {

}
