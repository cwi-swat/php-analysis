@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::il::IL

data Instruction;
alias InstructionList = list[Instruction];

data Var
	= normal(str vname)
	| temp(int n)
	;
	
data Instruction
	= createArray(Var target)
	| addArrayElement(Var arrayTarget, Var index, Var element)
	| addReferenceArrayElement(Var arrayTarget, Var index, Var element)
	| addArrayElementAtEnd(Var arrayTarget, Var index, Var element)
	| computeNextIndex(Var target, Var arrayTarget)
	| getElement(Var target, Var index)
	| destroyArray(Var target)
	;

// Instructions to support memory reads/writes
data Instruction
	= readVar(Var target)
	| writeVar(Var target, Var source)
	;

//public InstructionList buildDIL(Script scr) {
//	InstructionList il = [ ];
//	int freshCounter = 0;
//		
//	Var newTemp() { freshCounter += 1; return temp(freshCounter); }
//	
//	//| fetchArrayDim(Expr var, OptionExpr dim), OptionExpr is someExpr
//	void xform(fetchArrayDim(Expr var, someExpr(Expr dim)), bool wantRef) {
//		xform(var, true);
//		avar = lastVar();
//		xform(dim, false);
//		dvar = lastVar();
//		
//		if (wantRef)
//			il += arrayRefLookup(newTemp(), avar, dvar);
//		else
//			il += arrayItemLookup(newTemp(), avar, dvar);
//	}
//
//	//| fetchArrayDim(Expr var, OptionExpr dim), OptionExpr is noExpr
//	void xform(fetchArrayDim(Expr var, noExpr()), bool wantRef) {
//		xform(var, true);
//		avar = lastVar();
//		
//		if (wantRef)
//			il += arrayRefLookup(newTemp(), avar, nextIndex());
//		else
//			il += arrayItemLookup(newTemp(), avar, nextIndex());
//	}
//
//	//| fetchClassConst(NameOrExpr className, str constName)
//	void xform(fetchClassConst(expr(Expr className), str constName), bool wantRef) {
//		xform(className, false);
//		cnvar = lastVar();
//		il += assignScalarString(newTemp(), constName);
//		il += classConstLookup(newTemp(), cnvar, lastVar()); 
//	}
//
//	void xform(fetchClassConst(name(name(str className)), str constName), bool wantRef) {
//		il += assignScalarString(newTemp(), className);
//		cnvar = lastVar();
//		il += assignScalarString(newTemp(), constName);
//		il += classConstLookup(newTemp(), cnvar, lastVar()); 
//	}
//}
//
//data Var
//	= temp(int n)
//	| placeholder()
//	| nextIndex()
//	| normalVar(str v)
//	;
//	
//alias VarList = list[Var];

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
	
public int myfun() {
	int x;
	int y = 3;
	z = y + 4;
	return z;
}

//public Var lowerExp(Expr e) = e;


data Var = var(str vname) | tmp(int vnum);

//public data Scalar
//	= classConstant()
//	| dirConstant()
//	| fileConstant()
//	| funcConstant()
//	| lineConstant()
//	| methodConstant()
//	| namespaceConstant()
//	| traitConstant()
//	| float(real realVal)
//	| integer(int intVal)
//	| string(str strVal)
//	| encapsed(list[Expr] parts)
//	;

public Var lower(scalar(classConstant())) {
	nt = newTemp();
	i = lookupClassName(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(dirConstant())) {
	nt = newTemp();
	i = lookupFileDir(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(fileConstant())) {
	nt = newTemp();
	i = lookupFile(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(funcConstant())) {
	nt = newTemp();
	i = lookupFuncName(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(lineConstant())) {
	nt = newTemp();
	i = lookupFileLine(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(methodConstant())) {
	nt = newTemp();
	i = lookupMethodName(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(namespaceConstant())) {
	nt = newTemp();
	i = lookupNamespaceName(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(traitConstant())) {
	nt = newTemp();
	i = lookupTraitName(nt);
	emit(i);
	return nt;
}

public Var lower(scalar(float)) {
	nt = newTemp();
	i = lookupClassName(nt);
	emit(i);
	return nt;
}

public Var lower(var(expr(Expr e))) {
	v = lower(e);
	nt = newTemp();
	i = indirectLookup(nt, v);
	emit(i);
	return nt;
}

public Var lower(var(name(name(str s)))) {
	nt = newTemp();
	i = directLookup(nt, var(s));
	emit(i);
	return nt;
}
