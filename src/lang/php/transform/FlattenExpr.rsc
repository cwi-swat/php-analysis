@license{
  Copyright (c) 2009-2013 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::transform::FlattenExpr

import lang::php::ast::AbstractSyntax;
import String;

alias FlattenResult = tuple[Name varName, Stmt resultStmt];

public str padTo(str toPad, str padChar, int len) {
	if (size(toPad) >= len) return toPad;
	return padTo(padChar + toPad, padChar, len - size(padChar));
}

public anno Name node@flatName;

public FlattenResult flattenExpr(Expr exp, int counterStart = 1, str counterPrefix = "tmp") {
	list[Stmt] flattened = [ ];
	int counter = counterStart;
	
	Name makeFreshName() {
		Name n = name("<counterPrefix><padTo("<counter>","0",2)>");
		counter += 1;
		return n;
	}
	
	Expr bv(Name vn) = var(name(vn));
	Expr asgn(Name vn, Expr e, bool makeRef) = makeRef ? refAssign(bv(vn),e) : assign(bv(vn),e);
	
	bool toFlatten(scalar(Scalar s)) = false when not (s is encapsed);
	bool toFlatten(var(name(name(str s)))) = false;
	
	Expr buildra(Expr e) {
		fn = makeFreshName();
		newExpr = refAssign(bv(fn), e)[@flatName=fn];
		flattened += exprstmt(newExpr);
		return bv(fn)[@flatName=fn]; 
	}
	
	exp = bottom-up visit(exp) {
		case array(AEs) => buildra(array([ arrayElement(( someExpr(kexp) := key && ((key@flatName)?)) ? someExpr(bv(key@flatName)) : key, ((val@flatName)?) ? bv(val@flatName) : val, byRef) | arrayElement(key, val, byRef) <- AEs ]))
		
		case fetchArrayDim(v,someExpr(d)) => buildra(fetchArrayDim(bv(v@flatName),someExpr(bv(d@flatName)))) when (v@flatName)? && (d@flatName)?
		case fetchArrayDim(v,someExpr(d)) => buildra(fetchArrayDim(bv(v@flatName),someExpr(d))) when (v@flatName)? && (!(d@flatName)?)
		case fetchArrayDim(v,someExpr(d)) => buildra(fetchArrayDim(v,someExpr(bv(d@flatName)))) when (!(v@flatName)?) && (d@flatName)?
		case fetchArrayDim(v,someExpr(d)) => buildra(fetchArrayDim(v,someExpr(d))) when (!(v@flatName)?) && (!(d@flatName)?)
		case fetchArrayDim(v, noExpr()) => buildra(fetchArrayDim(bv(v@flatName),noExpr())) when (v@flatName)?
		case fetchArrayDim(v, noExpr()) => buildra(fetchArrayDim(v,noExpr())) when !((v@flatName)?)
		
		case fetchClassConst(expr(cn), cnst) => buildra(fetchClassConst(name(cn@flatName), cnst)) when (cn@flatName)?
		case fetchClassConst(expr(cn), cnst) => buildra(fetchClassConst(expr(cn), cnst)) when !(cn@flatName)?
		case fetchClassConst(name(cn), cnst) => buildra(fetchClassConst(name(cn), cnst))

		case assign(to, from) => buildra(assign(bv(to@flatName), bv(from@flatName))) when (to@flatName)? && (from@flatName)?
		case assign(to, from) => buildra(assign(bv(to@flatName), from)) when (to@flatName)? && (!(from@flatName)?)
		case assign(to, from) => buildra(assign(to, bv(from@flatName))) when (!(to@flatName)?) && (from@flatName)?
		case assign(to, from) => buildra(assign(to, from)) when (!(to@flatName)?) && (!(from@flatName)?)
		 
		case assignWOp(to, from, aop) => buildra(assignWOp(bv(to@flatName), bv(from@flatName), aop)) when (to@flatName)? && (from@flatName)?
		case assignWOp(to, from, aop) => buildra(assignWOp(bv(to@flatName), from, aop)) when (to@flatName)? && (!(from@flatName)?)
		case assignWOp(to, from, aop) => buildra(assignWOp(to, bv(from@flatName), aop)) when (!(to@flatName)?) && (from@flatName)?
		case assignWOp(to, from, aop) => buildra(assignWOp(to, from, aop)) when (!(to@flatName)?) && (!(from@flatName)?)

	//| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)

	//| refAssign(Expr assignTo, Expr assignExpr)

		case binaryOperation(e1, e2, bop) => buildra(binaryOperation(bv(e1@flatName),bv(e2@flatName),bop)) when (e1@flatName)? && (e2@flatName)?
		case binaryOperation(e1, e2, bop) => buildra(binaryOperation(e1,bv(e2@flatName),bop)) when !(e1@flatName)? && (e2@flatName)?
		case binaryOperation(e1, e2, bop) => buildra(binaryOperation(bv(e1@flatName),e2,bop)) when (e1@flatName)? && !(e2@flatName)?
		case binaryOperation(e1, e2, bop) => buildra(binaryOperation(e1,e2,bop)) when !(e1@flatName)? && !(e2@flatName)?
		
		case unaryOperation(e1, uop) => buildra(unaryOperation(bv(e1@flatName), uop)) when (e1@flatName)?
		case unaryOperation(e1, uop) => buildra(unaryOperation(e1, uop)) when !(e1@flatName)?
		
	//| new(NameOrExpr className, list[ActualParameter] parameters)

		case cast(ct, e1) => buildra(cast(ct,bv(e1@flatName))) when (e1@flatName)?
		case cast(ct, e1) => buildra(cast(ct,e1)) when !((e1@flatName)?)
		
		case clone(e1) => buildra(clone(bv(e1@flatName))) when (e1@flatName)?
		case clone(e1) => buildra(clone(e1)) when !(e1@flatName)?
		 
	//| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)

	//| fetchConst(Name name)

		case empty(e1) => buildra(empty(bv(e1@flatName))) when (e1@flatName)?
		case empty(e1) => buildra(empty(e1)) when !(e1@flatName)?

		case suppress(e1) => buildra(suppress(bv(e1@flatName))) when (e1@flatName)?
		case suppress(e1) => buildra(suppress(e1)) when !(e1@flatName)?
		
		case eval(e1) => buildra(eval(bv(e1@flatName))) when (e1@flatName)?
		case eval(e1) => buildra(eval(e1)) when !(e1@flatName)?

		case exit(someExpr(e1)) => buildra(exit(someExpr(bv(e1@flatName)))) when (e1@flatName)?
		case exit(someExpr(e1)) => buildra(exit(someExpr(e1))) when !(e1@flatName)?
		case exit(noExpr()) => buildra(exit(noExpr()))
		
		case call(expr(fne), params) => buildra(call(name(fne@flatName), [ actualParameter(((e1@flatName)?) ? bv(e1@flatName) : e1, br) | actualParameter(e1,br) <- params ])) when (fne@flatName)?
		case call(expr(fne), params) => buildra(call(expr(fne), [ actualParameter(((e1@flatName)?) ? bv(e1@flatName) : e1, br) | actualParameter(e1,br) <- params ])) when !(fne@flatName)?
		case call(name(N), params) => buildra(call(name(N), [ actualParameter(((e1@flatName)?) ? bv(e1@flatName) : e1, br) | actualParameter(e1,br) <- params ]))
		
	//| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)

	//| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)

		case include(e1, itype) => buildra(include(bv(e1@flatName),itype)) when (e1@flatName)?
		case include(e1, itype) => buildra(include(e1,itype)) when !((e1@flatName)?)

	//| instanceOf(Expr expr, NameOrExpr toCompare)

	//| isSet(list[Expr] exprs)

		case Expr::print(e1) => buildra(Expr::print(bv(e1@flatName))) when (e1@flatName)?
		case Expr::print(e1) => buildra(Expr::print(e1)) when !(e1@flatName)?
		
	//| propertyFetch(Expr target, NameOrExpr propertyName)

	//| shellExec(list[Expr] parts)
		
	//| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)

	//| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)

		case scalar(encapsed(EL)) => buildra(scalar(encapsed([ ((e1@flatName)?) ? bv(e1@flatName) : e1 | e1 <- EL ])))

	//| var(NameOrExpr varName)	

	//| yield(OptionExpr keyExpr, OptionExpr valueExpr)

	//| listExpr(list[OptionExpr] listExprs)

		
	}
		
	if (var(name(N)) := exp) {
		return < exp.varName.name, block(flattened) >;
	} else {
		exp = buildra(exp);
		return < exp.varName.name, block(flattened) >;
	}
	
	//return < name(""), block(flattened + exprstmt(exp)) >;
}

	//| assign(Expr assignTo, Expr assignExpr)
	//| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
	//| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
	//| refAssign(Expr assignTo, Expr assignExpr)
	//| new(NameOrExpr className, list[ActualParameter] parameters)
	//| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)
	//| call(NameOrExpr funName, list[ActualParameter] parameters)
	//| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)
	//| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)
	//| instanceOf(Expr expr, NameOrExpr toCompare)
	//| isSet(list[Expr] exprs)
	//| propertyFetch(Expr target, NameOrExpr propertyName)
	//| shellExec(list[Expr] parts)
	//| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)
	//| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)
	//| var(NameOrExpr varName)	
	//| yield(OptionExpr keyExpr, OptionExpr valueExpr)
	//| listExpr(list[OptionExpr] listExprs)
