@license{
  Copyright (c) 2009-2013 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::pp::PrettyPrinter

import lang::php::ast::AbstractSyntax;
import List;
import String;
import Set;
import IO;

//public data OptionExpr = someExpr(Expr expr) | noExpr();
public str pp(someExpr(Expr expr)) = pp(expr);
public str pp(noExpr()) = "";

//public data OptionName = someName(Name name) | noName();
public str pp(someName(Name name)) = pp(name);
public str pp(noName()) = "";

//public data OptionElse = someElse(Else e) | noElse();
public str pp(someElse(Else e)) = pp(e);
public str pp(noElse()) = "";

//public data ActualParameter = actualParameter(Expr expr, bool byRef, bool isPacked);
public str pp(actualParameter(Expr e, true, false)) = "&<pp(e)>";
public str pp(actualParameter(Expr e, false, false)) = pp(e);
public str pp(actualParameter(Expr e, true, true)) = "...&<pp(e)>";
public str pp(actualParameter(Expr e, false, true)) = "...<pp(e)>";

//public data Const = const(str name, Expr constValue);
public str pp(Const::const(str name, Expr constValue)) = "<name> = <pp(constValue)>";

//public data ArrayElement = arrayElement(OptionExpr key, Expr val, bool byRef);
public str pp(arrayElement(someExpr(Expr expr), Expr val, true)) = "<pp(expr)> =\> &<pp(val)>";
public str pp(arrayElement(someExpr(Expr expr), Expr val, false)) = "<pp(expr)> =\> <pp(val)>";
public str pp(arrayElement(noExpr(), Expr val, true)) = "&<pp(val)>";
public str pp(arrayElement(noExpr(), Expr val, false)) = pp(val);

//public data Name = name(str name);
public str pp(Name::name(str n)) = replaceAll(n, "/", "\\");

//public data NameOrExpr = name(Name name) | expr(Expr expr);
// TODO ${'a'} is printed as $'a'
public str pp(NameOrExpr::name(Name n)) = pp(n);
public str pp(NameOrExpr::expr(Expr e)) = pp(e);

//public data CastType = \int() | \bool() | float() | string() | array() | object() | unset();
public str pp(\int()) = "int";
public str pp(\bool()) = "bool";
public str pp(CastType::float()) = "float";
public str pp(CastType::string()) = "string";
public str pp(CastType::array()) = "array";
public str pp(object()) = "object";
public str pp(CastType::unset()) = "unset";

//public data ClosureUse = closureUse(Expr varName, bool byRef); 
public str pp(closureUse(Expr expr, true)) = "&<pp(expr)>";
public str pp(closureUse(Expr expr, false)) = "<pp(expr)>";

//public data IncludeType = include() | includeOnce() | require() | requireOnce();
public str pp(IncludeType::include()) = "include";
public str pp(includeOnce()) = "include_once";
public str pp(require()) = "require";
public str pp(requireOnce()) = "require_once";

// public data ClassName = explicitClassName(Name name) | computedClassName(Expr expr) | anonymousClass(Stmt stmt);
public str pp(explicitClassName(Name name)) = pp(name);
public str pp(computedClassName(Expr expr)) = pp(expr);
public str pp(anonymousClass(Stmt stmt)) = pp(stmt);

//public data Expr 
//	= array(list[ArrayElement] items, bool usesBracketNotation)
public str pp(Expr::array(list[ArrayElement] items, false)) = "array(<intercalate(",",[pp(i)|i<-items])>)";
public str pp(Expr::array(list[ArrayElement] items, true)) = "[ <intercalate(",",[pp(i)|i<-items])> ]";

//	| fetchArrayDim(Expr var, OptionExpr dim)
public str pp(fetchArrayDim(Expr var, someExpr(Expr dim))) = "<pp(var)>[<pp(dim)>]";
public str pp(fetchArrayDim(Expr var, noExpr())) = "<pp(var)>[]";

//	| fetchClassConst(NameOrExpr className, str constName)
public str pp(fetchClassConst(NameOrExpr className, str constName)) = "<pp(className)>::<pp(constName)>";

//	| assign(Expr assignTo, Expr assignExpr)
public str pp(assign(Expr assignTo, Expr assignExpr)) = "<pp(assignTo)> = <pp(assignExpr)>";

//	| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
public str pp(assignWOp(Expr assignTo, Expr assignExpr, Op operation)) = "<pp(assignTo)> <pp(operation)>= <pp(assignExpr)>";

//	| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
public str pp(listAssign(list[OptionExpr] assignsTo, Expr assignExpr)) = "list(<intercalate(",",[pp(a)|a<-assignsTo])>) = <pp(assignExpr)>";

//	| refAssign(Expr assignTo, Expr assignExpr)
public str pp(refAssign(Expr assignTo, Expr assignExpr)) = "<pp(assignTo)> =& <pp(assignExpr)>";

//	| binaryOperation(Expr left, Expr right, Op operation)
public str pp(binaryOperation(Expr left, Expr right, Op operation)) = "(<pp(left)> <pp(operation)> <pp(right)>)";

//	| unaryOperation(Expr operand, Op operation)
public str pp(unaryOperation(Expr operand, Op operation)) = "<pp(operation)><pp(operand)>" when ppOnLeft(operation);
public str pp(unaryOperation(Expr operand, Op operation)) = "<pp(operand)><pp(operation)>" when ppOnRight(operation);

//	| new(ClassName newClassName, list[ActualParameter] parameters)
public str pp(new(ClassName newClassName, list[ActualParameter] parameters)) = 
	"(new <pp(newClassName)>(<intercalate(",",[pp(p)|p<-parameters])>))";
	
//	| cast(CastType castType, Expr expr)
public str pp(cast(CastType castType, Expr expr)) = "(<pp(castType)>) <pp(expr)>";

//	| clone(Expr expr)
public str pp(clone(Expr expr)) = "clone <pp(expr)>";

//	| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static, PHPType returnType)
// TODO: Add remaining closure cases...
public str pp(closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, false, false, PHPType returnType)) = 
	"function (<intercalate(",",[pp(p)|p<-params])>) use (<intercalate(",",[pp(cu)|cu<-closureUses])>)
	'{
	'	<for(s<-statements) {><pp(s)><}>
	'}"
	when !isEmpty(closureUses);

public str pp(closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, false, false, PHPType returnType)) = 
	"function (<intercalate(",",[pp(p)|p<-params])>)
	'{
	'	<for(s<-statements) {><pp(s)><}>
	'}"
	when isEmpty(closureUses);

public str pp(closure(_,_,_,_,_,_)) = 
	"/* this closure not supported yet by pretty printer */";
	
//	| fetchConst(Name name)
public str pp(fetchConst(Name name)) = "<pp(name)>";

//	| empty(Expr expr)
public str pp(empty(Expr expr)) = "empty(<pp(expr)>)";

//	| suppress(Expr expr)
public str pp(suppress(Expr expr)) = "@<pp(expr)>";

//	| eval(Expr expr)
public str pp(eval(Expr expr)) = "eval(<pp(expr)>)";

//	| exit(OptionExpr exitExpr, bool isExit)
public str pp(exit(OptionExpr exitExpr, bool isExit)) = "exit(<pp(exitExpr)>)";

//	| call(NameOrExpr funName, list[ActualParameter] parameters)
public str pp(call(NameOrExpr funName, list[ActualParameter] parameters)) = 
	"<pp(funName)>(<intercalate(",",[pp(p)|p<-parameters])>)";

//	| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)
public str pp(methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)) =
	"<pp(target)>-\><pp(methodName)>(<intercalate(",",[pp(p)|p<-parameters])>)";

//	| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)
public str pp(staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)) =
	"<pp(staticTarget)>::<pp(methodName)>(<intercalate(",",[pp(p)|p<-parameters])>)";

//	| include(Expr expr, IncludeType includeType)
public str pp(Expr::include(Expr expr, IncludeType includeType)) = "<pp(includeType)> <pp(expr)>";

//	| instanceOf(Expr expr, NameOrExpr toCompare)
public str pp(instanceOf(Expr expr, NameOrExpr toCompare)) = "<pp(expr)> instanceof <pp(toCompare)>";

//	| isSet(list[Expr] exprs)
public str pp(isSet(list[Expr] exprs)) = "isset(<intercalate(",",[pp(e)|e<-exprs])>)";

//	| print(Expr expr)
public str pp(Expr::print(Expr expr)) = "print(<pp(expr)>)";

//	| propertyFetch(Expr target, NameOrExpr propertyName)
public str pp(propertyFetch(Expr target, NameOrExpr propertyName)) = "<pp(target)>-\><pp(propertyName)>";

//	| shellExec(list[Expr] parts)
// TODO: literal text is handled as string and will add quotes, this is not correct.
public str pp(shellExec(list[Expr] parts)) = "`<intercalate(" ",[pp(p)|p<-parts])>`";

//	| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)
public str pp(ternary(Expr c, OptionExpr ib, Expr eb)) = "<pp(c)>?<pp(ib)>:<pp(eb)>";

//	| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)
public str pp(staticPropertyFetch(NameOrExpr cn, NameOrExpr pn)) = "<pp(cn)>::$<pp(pn)>";

//	| scalar(Scalar scalarVal)
public str pp(scalar(Scalar scalarVal)) = pp(scalarVal);

//	| var(NameOrExpr varName)	
public str pp(var(NameOrExpr varName)) = "$<pp(varName)>";
//public str pp(var(name(Name varName))) = "$<varName>";
//public str pp(var(expr(Expr expr))) = "${<pp(expr)>}";

//  | yield(OptionExpr keyExpr, OptionExpr valueExpr)
public str pp(yield(noExpr(), noExpr())) = "yield";
public str pp(yield(noExpr(), someExpr(Expr v))) = "yield <pp(v)>";
public str pp(yield(someExpr(Expr k), someExpr(Expr v))) = "yield <pp(k)> =\> <pp(v)>";
public str pp(yield(someExpr(Expr k), noExpr())) { throw "Yielding a key with no value makes no sense."; }

//  | yieldFrom(Expr fromExpr)	
public str pp(yieldFrom(Expr f)) = "yield from <pp(f)>";

//  | listExpr(list[ArrayElement] listExprs)
public str pp(listExpr(list[ArrayElement] listExprs)) = "list(<intercalate(", ", [ pp(ae) | ae <- listExprs ])>)";

public str pp(bitwiseAnd()) = "&";
public str pp(bitwiseOr()) = "|";
public str pp(bitwiseXor()) = "^";
public str pp(Op::concat()) = ".";
public str pp(div()) = "/";
public str pp(minus()) = "-";
public str pp(\mod()) = "%";
public str pp(mul()) = "*";
public str pp(plus()) = "+";
public str pp(rightShift()) = "\>\>";
public str pp(leftShift()) = "\<\<";
public str pp(booleanAnd()) = "&&";
public str pp(booleanOr()) = "||";
public str pp(booleanNot()) = "!";
public str pp(bitwiseNot()) = "~";
public str pp(gt()) = "\>";
public str pp(geq()) = "\>=";
public str pp(logicalAnd()) = "and";
public str pp(logicalOr()) = "or";
public str pp(logicalXor()) = "xor";
public str pp(notEqual()) = "!=";
public str pp(notIdentical()) = "!==";
public str pp(postDec()) = "--";
public str pp(preDec()) = "--";
public str pp(postInc()) = "++";
public str pp(preInc()) = "++";
public str pp(lt()) = "\<";
public str pp(leq()) = "\<=";
public str pp(unaryPlus()) = "+";
public str pp(unaryMinus()) = "-";
public str pp(equal()) = "==";
public str pp(identical()) = "===";
public str pp(pow()) = "**";
public str pp(coalesce()) = "??";
public str pp(spaceship()) = "\<==\>";

public bool isUnary(booleanNot()) = true;
public bool isUnary(bitwiseNot()) = true;
public bool isUnary(postDec()) = true;
public bool isUnary(preDec()) = true;
public bool isUnary(postInc()) = true;
public bool isUnary(preInc()) = true;
public bool isUnary(unaryPlus()) = true;
public bool isUnary(unaryMinus()) = true;
public default bool isUnary(Op x) = false;

public bool ppOnLeft(booleanNot()) = true;
public bool ppOnLeft(bitwiseNot()) = true;
public bool ppOnLeft(postDec()) = false;
public bool ppOnLeft(preDec()) = true;
public bool ppOnLeft(postInc()) = false;
public bool ppOnLeft(preInc()) = true;
public bool ppOnLeft(unaryPlus()) = true;
public bool ppOnLeft(unaryMinus()) = true;
public default bool ppOnLeft(Op x) = false;

public default bool ppOnRight(Op x) = isUnary(x) && !ppOnLeft(x);

//public data Param = param(str paramName, 
//						  OptionExpr paramDefault,
//						  bool byRef,
//						  bool isVariadic, 
//						  PHPType paramType);
public str pp(param(str pn, noExpr(), true, true, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>&$<pn>...";
public str pp(param(str pn, noExpr(), true, false, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>&$<pn>";
public str pp(param(str pn, noExpr(), false, true, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>$<pn>...";
public str pp(param(str pn, noExpr(), false, false, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>$<pn>";
public str pp(param(str pn, someExpr(Expr e), true, true, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>&$<pn>... = <pp(e)>";
public str pp(param(str pn, someExpr(Expr e), true, false, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>&$<pn> = <pp(e)>";
public str pp(param(str pn, someExpr(Expr e), false, true, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>$<pn>... = <pp(e)>";
public str pp(param(str pn, someExpr(Expr e), false, false, PHPType returnType)) = "<padIfNotEmpty(pp(returnType))>$<pn> = <pp(e)>";

public str padIfNotEmpty(str s) = "<s> " when size(s) != 0;
public str padIfNotEmpty(str s) = s when size(s) == 0;

// public data PHPType = nullableType(str typeName) | regularType(str typeName) | noType();
public str pp(nullableType(str typeName)) = "?<typeName>";
public str pp(regularType(str typeName)) = typeName;
public str pp(noType()) = "";

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
public str pp(classConstant()) = "__CLASS__";
public str pp(dirConstant()) = "__DIR__";
public str pp(fileConstant()) = "__FILE__";
public str pp(funcConstant()) = "__FUNCTION__";
public str pp(lineConstant()) = "__LINE__";
public str pp(methodConstant()) = "__METHOD__";
public str pp(namespaceConstant()) = "__NAMESPACE__";
public str pp(traitConstant()) = "__TRAIT__";
public str pp(Scalar::float(real r)) = "<r>";
public str pp(integer(int i)) = "<i>";
public str pp(Scalar::string(str s)) = "\'<s>\'";
public str pp(encapsed(list[Expr] parts)) = intercalate(".",[pp(p) | p <- parts]);

//public data Stmt 
//	= \break(OptionExpr breakExpr)
public str pp(\break(someExpr(Expr breakExpr))) = "break <pp(breakExpr)>;";
public str pp(\break(noExpr())) = "break;";

//	| classDef(ClassDef classDef)
public str pp(classDef(ClassDef classDef)) = pp(classDef);

//	| const(list[Const] consts)
public str pp(Stmt::const(list[Const] consts)) = "const <intercalate(",",[pp(c)|c<-consts])>;";

//	| \continue(OptionExpr continueExpr)
public str pp(\continue(someExpr(Expr continueExpr))) = "continue <pp(continueExpr)>;";
public str pp(\continue(noExpr())) = "continue;";

//	| declare(list[Declaration] decls, list[Stmt] body)
public str pp(declare(list[Declaration] decls, list[Stmt] body)) = 
	"declare(<intercalate(",",[pp(d)|d<-decls])>);" when isEmpty(body);
public str pp(declare(list[Declaration] decls, list[Stmt] body)) = 
	"declare(<intercalate(",",[pp(d)|d<-decls])>) {
	'	<for(b<-body) {><pp(b)><}>
	'}" when !isEmpty(body);

//	| do(Expr cond, list[Stmt] body)
public str pp(do(Expr cond, list[Stmt] body)) = 
	"do {
	'	<for (b<-body) {><pp(b)><}>
	'} while (<pp(cond)>);";

//	| echo(list[Expr] exprs)
public str pp(echo(list[Expr] exprs)) = "echo(<intercalate(".",[pp(e)|e<-exprs])>);";

//	| exprstmt(Expr expr)
public str pp(exprstmt(Expr expr)) = "<pp(expr)>;";

//	| \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)
public str pp(\for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)) = 
	"for(<intercalate(",",[pp(i)|i<-inits])> ; <intercalate(",",[pp(c)|c<-conds])> ; <intercalate(",",[pp(e)|e<-exprs])>) {
	'	<for (b <- body) {><pp(b)><}>
	'}";

//	| foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body)
public str pp(foreach(Expr arrayExpr, someExpr(Expr keyvar), false, Expr asVar, list[Stmt] body)) =
	"foreach(<pp(arrayExpr)> as <pp(keyvar)> =\> <pp(asVar)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}";
public str pp(foreach(Expr arrayExpr, someExpr(Expr keyvar), true, Expr asVar, list[Stmt] body)) =
	"foreach(<pp(arrayExpr)> as <pp(keyvar)> =\> &<pp(asVar)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}";
public str pp(foreach(Expr arrayExpr, noExpr(), false, Expr asVar, list[Stmt] body)) =
	"foreach(<pp(arrayExpr)> as <pp(asVar)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}";
public str pp(foreach(Expr arrayExpr, noExpr(), true, Expr asVar, list[Stmt] body)) =
	"foreach(<pp(arrayExpr)> as &<pp(asVar)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}";
	
//	| function(str name, bool byRef, list[Param] params, list[Stmt] body)
public str pp(function(str name, true, list[Param] params, list[Stmt] body, PHPType returnType)) = 
	"function &<name>(<intercalate(",",[pp(p)|p<-params])>) {
	'	<for (b <- body) {><pp(b)><}>
	'}";
public str pp(function(str name, false, list[Param] params, list[Stmt] body, PHPType returnType)) = 
	"function <name>(<intercalate(",",[pp(p)|p<-params])>) {
	'	<for (b <- body) {><pp(b)><}>
	'}";

//	| global(list[Expr] exprs)
public str pp(global(list[Expr] exprs)) = "global <intercalate(",",[pp(e)|e<-exprs])>;";

//	| goto(str label)
public str pp(goto(str label)) = "goto <label>;";

//	| haltCompiler(str remainingText)
public str pp(haltCompiler(str remainingText)) = "__halt_compiler(); <remainingText>";

//	| \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause)
public str pp(\if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, noElse())) = 
	"if(<pp(cond)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}" when isEmpty(elseIfs);
public str pp(\if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, someElse(Else elseClause))) = 
	"if(<pp(cond)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}
	'<pp(elseClause)>
	'" when isEmpty(elseIfs);
public str pp(\if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, noElse())) = 
	"if(<pp(cond)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}
	'<for (e <- elseIfs) {><pp(e)><}>
	'" when !isEmpty(elseIfs);
public str pp(\if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, someElse(Else elseClause))) = 
	"if(<pp(cond)>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}
	'<for (e <- elseIfs) {><pp(e)><}>
	'<pp(elseClause)>
	'" when !isEmpty(elseIfs);

//	| inlineHTML(str htmlText)
public str pp(inlineHTML(str htmlText)) = "?\><htmlText>\<?php";

//	| interfaceDef(InterfaceDef interfaceDef)
public str pp(interfaceDef(InterfaceDef interfaceDef)) = pp(interfaceDef);

//	| traitDef(TraitDef traitDef)
public str pp(traitDef(TraitDef traitDef)) = pp(traitDef);

//	| label(str labelName)
public str pp(label(str labelName)) = "<labelName>:";

//	| namespaceHeader(Name namespaceName)
public str pp(namespaceHeader(namespaceName)) =
	"namespace <pp(namespaceName)>;\n";
	
//	| namespace(OptionName nsName, list[Stmt] body)
public str pp(namespace(someName(Name nsName), list[Stmt] body)) =
	"namespace <pp(nsName)> {
	'	<for (b <- body) {><pp(b)><}>
	'}";
public str pp(namespace(noName(), list[Stmt] body)) =
	"namespace {
	'	<for (b <- body) {><pp(b)><}>
	'}";

//	| \return(OptionExpr returnExpr)
public str pp(\return(someExpr(Expr returnExpr))) = "return <pp(returnExpr)>;";
public str pp(\return(noExpr())) = "return;";

//	| static(list[StaticVar] vars)
public str pp(Stmt::static(list[StaticVar] vars)) = "static <intercalate(",",[pp(v)|v<-vars])>;";

//	| \switch(Expr cond, list[Case] cases)
public str pp(\switch(Expr cond, list[Case] cases)) = 
	"switch(<pp(cond)>) {
	'	<for (c <- cases) {><pp(c)><}>
	'}";

//	| \throw(Expr expr)
public str pp(\throw(Expr expr)) = "throw (<pp(expr)>);";

//	| tryCatch(list[Stmt] body, list[Catch] catches)
public str pp(tryCatch(list[Stmt] body, list[Catch] catches)) =
	"try {
	'	<for (b <- body) {><pp(b)><}>
	'} <for (c <- catches) {><pp(c)><}>
	'";
	
//	| tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody)
public str pp(tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody)) =
	"try {
	'	<for (b <- body) {><pp(b)><}>
	'} <for (c <- catches) {><pp(c)><}>
	'finally {
	'	<for (b <- finallyBody) {><pp(b)><}>
	'}";

//	| unset(list[Expr] unsetVars)
public str pp(Stmt::unset(list[Expr] unsetVars)) = "unset(<intercalate(",",[pp(u)|u<-unsetVars])>);";

//	| use(list[Use] uses, OptionName prefix, UseType useType)
public str pp(Stmt::use(list[Use] uses, OptionName prefix, UseType useType)) = "use <intercalate(",",[pp(u)|u<-uses])>;";

//	| \while(Expr cond, list[Stmt] body)
public str pp(\while(Expr cond, list[Stmt] body)) = 
	"while(<pp(cond)>) {
	'	<for (b <- body) {><pp(b)><}>
	'}";

//	| emptyStmt()
public str pp(emptyStmt()) = ";";

//	| block(list[Stmt] body)
public str pp(block(list[Stmt] body)) =
	"{
	'	<for (b <- body) {><pp(b)><}>
	'}";
	
//public data Declaration = declaration(str key, Expr val);
public str pp(declaration(str key, Expr val)) = "<key>=<pp(val)>";

//public data Catch = \catch(list[Name] xtypes, str varName, list[Stmt] body);
public str pp(\catch(list[Name] xtypes, str varName, list[Stmt] body)) =
	"catch (<intercalate(" | ", [ pp(xti) | xti <- xtypes ])> <varName>) {
	'	<for (b <- body) {><pp(b)><}> }";
	
//public data Case = \case(OptionExpr cond, list[Stmt] body);
public str pp(\case(noExpr(), list[Stmt] body)) =
	"default:
	'	<for (b <- body) {><pp(b)><}>"
	when !isEmpty(body);

public str pp(\case(noExpr(), list[Stmt] body)) =
	"default:"
	when isEmpty(body);
	
public str pp(\case(someExpr(Expr e), list[Stmt] body)) =
	"case <pp(e)>:
	'	<for (b <- body) {><pp(b)><}>"
	when !isEmpty(body);

public str pp(\case(someExpr(Expr e), list[Stmt] body)) =
	"case <pp(e)>:"
	when isEmpty(body);
	
//public data ElseIf = elseIf(Expr cond, list[Stmt] body);
public str pp(elseIf(Expr cond, list[Stmt] body)) =
	"elseif (<pp(cond)>) {
	'  <for (b <- body) {><pp(b)><}>
	'}"
	;
	
//public data Else = \else(list[Stmt] body);
public str pp(\else(list[Stmt] body)) =
	"else {
	'  <for (b <- body) {><pp(b)><}>
	'}"
	;

//public data Use = use(Name importName, OptionName asName, UseType useType);
public str pp(Use::use(Name importName, someName(Name asName), UseType useType)) = "<pp(importName)> as <pp(asName)>";
public str pp(Use::use(Name importName, noName(), UseType useType)) = "<pp(importName)>";

//public data ClassItem 
//	= property(set[Modifier] modifiers, list[Property] prop)
public str pp(ClassItem::property(set[Modifier] modifiers, list[Property] prop)) =
	"<for(p <- prop) {><intercalate(" ",[pp(m)|m<-modifiers])> <pp(p)>;
	'<}>";

//	| constCI(list[Const] consts)
public str pp(constCI(list[Const] consts, set[Modifier] modifiers)) = "const <intercalate(",",[pp(c)|c<-consts])>;";

//	| method(str name, set[Modifier] modifiers, bool byRef, list[Param] params, list[Stmt] body)
// TODO classes of interfaces have no body
public str pp(method(str name, set[Modifier] modifiers, true, list[Param] params, list[Stmt] body, PHPType returnType)) =
	"<intercalate(" ", [pp(m)|m<-modifiers])> function &<name>(<intercalate(",",[pp(p)|p<-params])>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}"
	when !(\abstract() in modifiers); 

public str pp(method(str name, set[Modifier] modifiers, true, list[Param] params, list[Stmt] body, PHPType returnType)) =
	"<intercalate(" ", [pp(m)|m<-modifiers])> function &<name>(<intercalate(",",[pp(p)|p<-params])>);";

public str pp(method(str name, set[Modifier] modifiers, false, list[Param] params, list[Stmt] body, PHPType returnType)) =
	"<intercalate(" ", [pp(m)|m<-modifiers])> function <name>(<intercalate(",",[pp(p)|p<-params])>) {<for (b <- body) {>
	'	<pp(b)><}>
	'}"
	when !(\abstract() in modifiers); 

public str pp(method(str name, set[Modifier] modifiers, false, list[Param] params, list[Stmt] body, PHPType returnType)) =
	"<intercalate(" ", [pp(m)|m<-modifiers])> function <name>(<intercalate(",",[pp(p)|p<-params])>);";

//	| traitUse(list[Name] traits, list[Adaptation] adaptations)
public str pp(traitUse(list[Name] traits, list[Adaptation] adaptations)) =
	"use <intercalate(",",[pp(t)|t<-traits])> {
	'	<for (a <- adaptations) {><pp(a)><}> 
	'}";
	
// Adaptation::traitAlias(OptionName traitName, Name methName, set[Modifier] newModifiers, OptionName newName)
public str pp(traitAlias(noName(), str methName, set[Modifier] newModifiers, noName())) =
	"<methName> as <intercalate(" ", [pp(m)|m<-newModifiers])>;";
public str pp(traitAlias(noName(), str methName, set[Modifier] newModifiers, someName(newName))) =
	"<methName> as <intercalate(" ", [pp(m)|m<-newModifiers])> <pp(newName)>;";
public str pp(traitAlias(someName(traitName), str methName, set[Modifier] newModifiers, noName())) =
	"<pp(traitName)>::<methName> as <intercalate(" ", [pp(m)|m<-newModifiers])>;";
public str pp(traitAlias(someName(traitName), str methName, set[Modifier] newModifiers, someName(newName))) =
	"<pp(traitName)>::<methName> as <intercalate(" ", [pp(m)|m<-newModifiers])> <pp(newName)>;";
	
// Apaptation::traitPrecedence(OptionName traitName, Name methName, set[Name] insteadOf)
public str pp(traitPrecedence(noName(), str methName, set[Name] insteadOf)) =
	"<methName> insteadof <intercalate(",", [pp(i)|i<-insteadOf])>;";
public str pp(traitPrecedence(someName(traitName), str methName, set[Name] insteadOf)) =
	"<pp(traitName)>::<methName> insteadof <intercalate(",", [pp(i)|i<-insteadOf])>;";

//public data Property = property(str propertyName, OptionExpr defaultValue);
public str pp(Property::property(str propertyName, someExpr(Expr defaultValue))) = "$<propertyName> = <pp(defaultValue)>";
public str pp(Property::property(str propertyName, noExpr())) = "$<propertyName>";

//public data Modifier = \public() | \private() | protected() | static() | abstract() | final();
public str pp(\public()) = "public";
public str pp(\private()) = "private";
public str pp(\protected()) = "protected";
public str pp(Modifier::\static()) = "static";
public str pp(\abstract()) = "abstract";
public str pp(\final()) = "final";

//public data ClassDef = class(str className,
//							 set[Modifier] modifiers, 
//							 OptionName extends, 
//							 list[Name] implements, 
//							 list[ClassItem] members);
//
public str pp(class(str className, set[Modifier] modifiers, someName(Name extends), list[Name] implements, list[ClassItem] members)) =
	"class <className> extends <pp(extends)> {
	'	<for (m <- members) {>
	'	<pp(m)><}>
	'}" when isEmpty(modifiers) && isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, noName(), list[Name] implements, list[ClassItem] members)) =
	"class <className> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when isEmpty(modifiers) && isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, someName(Name extends), list[Name] implements, list[ClassItem] members)) =
	"class <className> extends <pp(extends)> implements <intercalate(",",[pp(i)|i<-implements])> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when isEmpty(modifiers) && !isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, noName(), list[Name] implements, list[ClassItem] members)) =
	"class <className> implements <intercalate(",",[pp(i)|i<-implements])> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when isEmpty(modifiers) && !isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, someName(Name extends), list[Name] implements, list[ClassItem] members)) =
	"<intercalate(" ",[pp(m)|m<-modifiers])> class <className> extends <pp(extends)> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when !isEmpty(modifiers) && isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, noName(), list[Name] implements, list[ClassItem] members)) =
	"<intercalate(" ",[pp(m)|m<-modifiers])> class <className> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when !isEmpty(modifiers) && isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, someName(Name extends), list[Name] implements, list[ClassItem] members)) =
	"<intercalate(" ",[pp(m)|m<-modifiers])> class <className> extends <pp(extends)> implements <intercalate(",",[pp(i)|i<-implements])> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when !isEmpty(modifiers) && !isEmpty(implements);
public str pp(class(str className, set[Modifier] modifiers, noName(), list[Name] implements, list[ClassItem] members)) =
	"<intercalate(" ",[pp(m)|m<-modifiers])> class <className> implements <intercalate(",",[pp(i)|i<-implements])> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when !isEmpty(modifiers) && !isEmpty(implements);
	
//public data InterfaceDef = interface(str interfaceName, 
//									list[Name] extends, 
//									list[ClassItem] members);
//									
public str pp(interface(str interfaceName, list[Name] extends, list[ClassItem] members)) =
	"interface <interfaceName> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when isEmpty(extends);
public str pp(interface(str interfaceName, list[Name] extends, list[ClassItem] members)) =
	"interface <interfaceName> extends <intercalate(",",[pp(e)|e<-extends])> {
	'	<for (m <- members) {><pp(m)><}>
	'}" when !isEmpty(extends);

//public data TraitDef = trait(str traitName, list[ClassItem] members);
public str pp(trait(str traitName, list[ClassItem] members)) = 
	"trait <traitName> {
	'	<for (m <- members) {>
	'	<pp(m)><}>
	'}"; 

//public data StaticVar = staticVar(str name, OptionExpr defaultValue);
public str pp(staticVar(str vname, someExpr(Expr defaultValue))) = "$<vname> = <pp(defaultValue)>";
public str pp(staticVar(str vname, noExpr())) = "$<vname>";

//public data Script = script(list[Stmt] body) | errscript(str err);
public str pp(script(list[Stmt] body)) = "\<?php\n" + intercalate("\n",[pp(b) | b <- body]) + "\n";
public str pp(errscript(str err)) {
	println("Cannot print an error script as a normal PHP script: <err>");
	return "\n//<err>\n";
}

// will be used for annotations
public str pp(str text) = (size(text)>0?text+"\n":"");

public default str pp(node n) { throw "No pretty-printer found for node <n>"; }