@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::il::IL

data Instruction 
	= createArray(list[tuple[Var key, Var val, bool byRef]]);

data Var
	= temp(int n)
	| placeholder()
	;
	
	//= array(list[ArrayElement] items)
	//| fetchArrayDim(Expr var, OptionExpr dim)
	//| fetchClassConst(NameOrExpr className, str constName)
	//| assign(Expr assignTo, Expr assignExpr)
	//| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
	//| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
	//| refAssign(Expr assignTo, Expr assignExpr)
	//| binaryOperation(Expr left, Expr right, Op operation)
	//| unaryOperation(Expr operand, Op operation)
	//| new(NameOrExpr className, list[ActualParameter] parameters)
	//| cast(CastType castType, Expr expr)
	//| clone(Expr expr)
	//| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)
	//| fetchConst(Name name)
	//| empty(Expr expr)
	//| suppress(Expr expr)
	//| eval(Expr expr)
	//| exit(OptionExpr exitExpr)
	//| call(NameOrExpr funName, list[ActualParameter] parameters)
	//| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)
	//| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)
	//| include(Expr expr, IncludeType includeType)
	//| instanceOf(Expr expr, NameOrExpr toCompare)
	//| isSet(list[Expr] exprs)
	//| print(Expr expr)
	//| propertyFetch(Expr target, NameOrExpr propertyName)
	//| shellExec(list[Expr] parts)
	//| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)
	//| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)
	//| scalar(Scalar scalarVal)
	//| var(NameOrExpr varName)	
	
