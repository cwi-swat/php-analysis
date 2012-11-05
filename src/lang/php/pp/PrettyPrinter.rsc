@license{
  Copyright (c) 2009-2012 CWI
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

//public data OptionExpr = someExpr(Expr expr) | noExpr();
public str pp(someExpr(Expr expr)) = pp(expr);
public str pp(noExpr()) = "";

//public data OptionName = someName(Name name) | noName();
public str pp(someName(Name name)) = pp(name);
public str pp(noName()) = "";

//public data OptionElse = someElse(Else e) | noElse();
public str pp(someElse(Else e)) = pp(e);
public str pp(noElse()) = "";

//public data ActualParameter = actualParameter(Expr expr, bool byRef);
public str pp(actualParameter(Expr e, true)) = "&<pp(e)>";
public str pp(actualParameter(Expr e, false)) = pp(e);

//public data Const = const(str name, Expr constValue);
public str pp(const(str name, Expr constValue)) = "const <name> = <pp(constValue)>;";

//public data ArrayElement = arrayElement(OptionExpr key, Expr val, bool byRef);
public str pp(arrayElement(someExpr(Expr expr), Expr val, true)) = "<pp(expr)> =\> &<pp(val)>";
public str pp(arrayElement(someExpr(Expr expr), Expr val, false)) = "<pp(expr)> =\> <pp(val)>";
public str pp(arrayElement(noExpr(), Expr val, true)) = "&<pp(val)>";
public str pp(arrayElement(noExpr(), Expr val, false)) = pp(val);

//public data Name = name(str name);
public str pp(name(str n)) = n;

//public data NameOrExpr = name(Name name) | expr(Expr expr);
public str pp(name(Name n)) = pp(n);
public str pp(expr(Expr e)) = pp(e);

//public data CastType = \int() | \bool() | float() | string() | array() | object() | unset();
public str pp(\int()) = "int";
public str pp(\bool()) = "bool";
public str pp(float()) = "float";
public str pp(string()) = "string";
public str pp(array()) = "array";
public str pp(object()) = "object";
public str pp(unset()) = "unset";

//public data ClosureUse = closureUse(str name, bool byRef);
public str pp(closureUse(str name, true)) = "&$<name>";
public str pp(closureUse(str name, false)) = "$<name>";

//public data IncludeType = include() | includeOnce() | require() | requireOnce();
//
//public data Expr 
//	= array(list[ArrayElement] items)
//	| fetchArrayDim(Expr var, OptionExpr dim)
//	| fetchClassConst(NameOrExpr className, str constName)
//	| assign(Expr assignTo, Expr assignExpr)
//	| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
//	| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
//	| refAssign(Expr assignTo, Expr assignExpr)
//	| binaryOperation(Expr left, Expr right, Op operation)
//	| unaryOperation(Expr operand, Op operation)
//	| new(NameOrExpr className, list[ActualParameter] parameters)
//	| cast(CastType castType, Expr expr)
//	| clone(Expr expr)
//	| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)
//	| fetchConst(Name name)
//	| empty(Expr expr)
//	| suppress(Expr expr)
//	| eval(Expr expr)
//	| exit(OptionExpr exitExpr)
//	| call(NameOrExpr funName, list[ActualParameter] parameters)
//	| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)
//	| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)
//	| include(Expr expr, IncludeType includeType)
//	| instanceOf(Expr expr, NameOrExpr toCompare)
//	| isSet(list[Expr] exprs)
//	| print(Expr expr)
//	| propertyFetch(Expr target, NameOrExpr propertyName)

public str pp(shellExec(list[Expr] parts)) = "`<intercalate(" ",[pp(p)|p<-parts])>`";
public str pp(ternary(Expr c, OptionExpr ib, Expr eb)) = "<pp(c)>?<pp(ib)>:<pp(eb)>";
public str pp(staticPropertyFetch(name(Name cn),name(Name pn))) = "<pp(cn)>::<pp(pn)>";
public str pp(staticPropertyFetch(name(Name cn),expr(Expr pn))) = "<pp(cn)>::$<pp(pn)>";
public str pp(staticPropertyFetch(expr(Expr cn),name(Name pn))) = "$<pp(cn)>::<pp(pn)>";
public str pp(staticPropertyFetch(expr(Expr cn),expr(Expr pn))) = "$<pp(cn)>::$<pp(pn)>";
public str pp(Scalar scalarVal) = pp(scalarVal);
public str pp(var(NameOrExpr varName)) = "$<pp(varName)>";

//public data Op = bitwiseAnd() | bitwiseOr() | bitwiseXor() | concat() | div() 
//			   | minus() | \mod() | mul() | plus() | rightShift() | leftShift()
//			   | booleanAnd() | booleanOr() | booleanNot() | bitwiseNot()
//			   | gt() | geq() | logicalAnd() | logicalOr() | logicalXor()
//			   | notEqual() | notIdentical() | postDec() | preDec() | postInc()
//			   | preInc() | lt() | leq() | unaryPlus() | unaryMinus() 
//			   | equal() | identical() ;
public str pp(bitwiseAnd()) = "&";
public str pp(bitwiseOr()) = "|";
public str pp(bitwiseXor()) = "^";
public str pp(concat()) = ".";
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
public str pp(lt()) = "\<=";
public str pp(leq()) = "\<";
public str pp(unaryPlus()) = "+";
public str pp(unaryMinus()) = "-";
public str pp(equal()) = "==";
public str pp(identical()) = "===";

public str isUnary(booleanNot()) = true;
public str isUnary(bitwiseNot()) = true;
public str isUnary(postDec()) = true;
public str isUnary(preDec()) = true;
public str isUnary(postInc()) = true;
public str isUnary(preInc()) = true;
public str isUnary(unaryPlus()) = true;
public str isUnary(unaryMinus()) = true;
public default str isUnary(Op x) = false;

public str ppOnLeft(booleanNot()) = true;
public str ppOnLeft(bitwiseNot()) = true;
public str ppOnLeft(postDec()) = false;
public str ppOnLeft(preDec()) = true;
public str ppOnLeft(postInc()) = false;
public str ppOnLeft(preInc()) = true;
public str ppOnLeft(unaryPlus()) = true;
public str ppOnLeft(unaryMinus()) = true;
public default str ppOnLeft(Op x) = false;

public default str ppOnRight(Op x) = isUnary(x) && !ppOnLeft(x);

//public data Param = param(str paramName, 
//						  OptionExpr paramDefault, 
//						  OptionName paramType,
//						  bool byRef);
public str pp(str pn, noExpr(), noName(), false) = "$<pn>";
public str pp(str pn, noExpr(), noName(), true) = "&$<pn>";
public str pp(str pn, noExpr(), someName(Name n), false) = "<pp(n)> $<pn>";
public str pp(str pn, noExpr(), someName(Name n), true) = "<pp(n)> &$<pn>";
public str pp(str pn, someExpr(Expr e), noName(), false) = "$<pn> = <pp(e)>";
public str pp(str pn, someExpr(Expr e), noName(), true) = "&$<pn> = <pp(e)>";
public str pp(str pn, someExpr(Expr e), someName(Name n), false) = "<pp(n)> $<pn> = <pp(e)>";
public str pp(str pn, someExpr(Expr e), someName(Name n), true) = "<pp(n)> &$<pn> = <pp(e)>";

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
public str pp(float(real r)) = "<r>";
public str pp(integer(int i)) = "<i>";
public str pp(string(str s)) = "<s>";
public str pp(encapsed(list[Expr] parts)) = intercalate(".",[pp(p) | p <- parts]);

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
//

//public data Declaration = declaration(str key, Expr val);
public str pp(declaration(str key, Expr val)) = "key=<pp(val)>";

//public data Catch = \catch(Name xtype, str xname, list[Stmt] body);
public str pp(\catch(Name xt, str xn, list[Stmt] body)) =
	"catch (<pp(xtype)> <xname>) {
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

//public data Else = \else(list[Stmt] body);

//public data Use = use(Name importName, OptionName asName);

//public data ClassItem 
//	= property(set[Modifier] modifiers, list[Property] prop)
//	| constCI(list[Const] consts)
//	| method(str name, set[Modifier] modifiers, bool byRef, list[Param] params, list[Stmt] body)
//	| traitUse(list[Name] traits, list[Adaptation] adaptations)
//	;
//
//public data Adaptation
//	= traitAlias(OptionName traitName, str methodName, set[Modifier] newModifiers, OptionName newName)
//	| traitPrecedence(OptionName traitName, str methodName, set[Name] insteadOf)
//	;
//	
//public data Property = property(str propertyName, OptionExpr defaultValue);
//
//public data Modifier = \public() | \private() | protected() | static() | abstract() | final();
// 
//public data ClassDef = class(str className,
//							 set[Modifier] modifiers, 
//							 OptionName extends, 
//							 list[Name] implements, 
//							 list[ClassItem] members);
//
//public data InterfaceDef = interface(str interfaceName, 
//									list[Name] extends, 
//									list[ClassItem] members);
//									
//public data TraitDef = trait(str traitName, list[ClassItem] members);
//
//public data StaticVar = staticVar(str name, OptionExpr defaultValue);
//
//public data Script = script(list[Stmt] body) | errscript(str err);
