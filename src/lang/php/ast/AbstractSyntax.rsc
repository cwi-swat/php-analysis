@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::ast::AbstractSyntax

import IO;

public data OptionExpr = someExpr(Expr expr) | noExpr();

public data OptionName = someName(Name name) | noName();

public data OptionElse = someElse(Else e) | noElse();

public data ActualParameter = actualParameter(Expr expr, bool byRef);
	
public data Const = const(str name, Expr constValue);

public data ArrayElement = arrayElement(OptionExpr key, Expr val, bool byRef);
	 
public data Name = name(str name);

public data NameOrExpr = name(Name name) | expr(Expr expr);

public data CastType = \int() | \bool() | float() | string() | array() | object() | unset();
	
public data ClosureUse = closureUse(str name, bool byRef);

public data IncludeType = include() | includeOnce() | require() | requireOnce();

// NOTE: In PHP, yield is a statement, but it can also be used as an expression.
// To handle this, we just treat it as an expression. The parser does this as well.
// TODO: listAssign is deprecated and will be removed in the future, this is now
// given as an assignment into a listExpr
public data Expr 
	= array(list[ArrayElement] items)
	| fetchArrayDim(Expr var, OptionExpr dim)
	| fetchClassConst(NameOrExpr className, str constName)
	| assign(Expr assignTo, Expr assignExpr)
	| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
	| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
	| refAssign(Expr assignTo, Expr assignExpr)
	| binaryOperation(Expr left, Expr right, Op operation)
	| unaryOperation(Expr operand, Op operation)
	| new(NameOrExpr className, list[ActualParameter] parameters)
	| cast(CastType castType, Expr expr)
	| clone(Expr expr)
	| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)
	| fetchConst(Name name)
	| empty(Expr expr)
	| suppress(Expr expr)
	| eval(Expr expr)
	| exit(OptionExpr exitExpr)
	| call(NameOrExpr funName, list[ActualParameter] parameters)
	| methodCall(Expr target, NameOrExpr methodName, list[ActualParameter] parameters)
	| staticCall(NameOrExpr staticTarget, NameOrExpr methodName, list[ActualParameter] parameters)
	| include(Expr expr, IncludeType includeType)
	| instanceOf(Expr expr, NameOrExpr toCompare)
	| isSet(list[Expr] exprs)
	| print(Expr expr)
	| propertyFetch(Expr target, NameOrExpr propertyName)
	| shellExec(list[Expr] parts)
	| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)
	| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)
	| scalar(Scalar scalarVal)
	| var(NameOrExpr varName)	
	| yield(OptionExpr keyExpr, OptionExpr valueExpr)
	| listExpr(list[OptionExpr] listExprs)
	;

public data Op = bitwiseAnd() | bitwiseOr() | bitwiseXor() | concat() | div() 
			   | minus() | \mod() | mul() | plus() | rightShift() | leftShift()
			   | booleanAnd() | booleanOr() | booleanNot() | bitwiseNot()
			   | gt() | geq() | logicalAnd() | logicalOr() | logicalXor()
			   | notEqual() | notIdentical() | postDec() | preDec() | postInc()
			   | preInc() | lt() | leq() | unaryPlus() | unaryMinus() 
			   | equal() | identical() ;

public data Param = param(str paramName, 
						  OptionExpr paramDefault, 
						  OptionName paramType,
						  bool byRef);
						  
public data Scalar
	= classConstant()
	| dirConstant()
	| fileConstant()
	| funcConstant()
	| lineConstant()
	| methodConstant()
	| namespaceConstant()
	| traitConstant()
	| float(real realVal)
	| integer(int intVal)
	| string(str strVal)
	| encapsed(list[Expr] parts)
	;

public data Stmt 
	= \break(OptionExpr breakExpr)
	| classDef(ClassDef classDef)
	| const(list[Const] consts)
	| \continue(OptionExpr continueExpr)
	| declare(list[Declaration] decls, list[Stmt] body)
	| do(Expr cond, list[Stmt] body)
	| echo(list[Expr] exprs)
	| exprstmt(Expr expr)
	| \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)
	| foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body)
	| function(str name, bool byRef, list[Param] params, list[Stmt] body)
	| global(list[Expr] exprs)
	| goto(str label)
	| haltCompiler(str remainingText)
	| \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause)
	| inlineHTML(str htmlText)
	| interfaceDef(InterfaceDef interfaceDef)
	| traitDef(TraitDef traitDef)
	| label(str labelName)
	| namespace(OptionName nsName, list[Stmt] body)
	| namespaceHeader(Name namespaceName)
	| \return(OptionExpr returnExpr)
	| static(list[StaticVar] vars)
	| \switch(Expr cond, list[Case] cases)
	| \throw(Expr expr)
	| tryCatch(list[Stmt] body, list[Catch] catches)
	| tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody)

	| unset(list[Expr] unsetVars)
	| use(list[Use] uses)
	| \while(Expr cond, list[Stmt] body)
	| emptyStmt()
	| block(list[Stmt] body)
	;

public data Declaration = declaration(str key, Expr val);

public data Catch = \catch(Name xtype, str xname, list[Stmt] body);
	
public data Case = \case(OptionExpr cond, list[Stmt] body);

public data ElseIf = elseIf(Expr cond, list[Stmt] body);

public data Else = \else(list[Stmt] body);

public data Use = use(Name importName, OptionName asName);

public data ClassItem 
	= property(set[Modifier] modifiers, list[Property] prop)
	| constCI(list[Const] consts)
	| method(str name, set[Modifier] modifiers, bool byRef, list[Param] params, list[Stmt] body)
	| traitUse(list[Name] traits, list[Adaptation] adaptations)
	;

public data Adaptation
	= traitAlias(OptionName traitName, str methodName, set[Modifier] newModifiers, OptionName newName)
	| traitPrecedence(OptionName traitName, str methodName, set[Name] insteadOf)
	;
	
public data Property = property(str propertyName, OptionExpr defaultValue);

public data Modifier = \public() | \private() | protected() | static() | abstract() | final();
 
public data ClassDef = class(str className,
							 set[Modifier] modifiers, 
							 OptionName extends, 
							 list[Name] implements, 
							 list[ClassItem] members);

public data InterfaceDef = interface(str interfaceName, 
									list[Name] extends, 
									list[ClassItem] members);
									
public data TraitDef = trait(str traitName, list[ClassItem] members);

public data StaticVar = staticVar(str name, OptionExpr defaultValue);

public data Script = script(list[Stmt] body) | errscript(str err);

@doc{Stores the location of the node in the original source file.}
public anno loc ActualParameter@at;
public anno loc Const@at;
public anno loc ArrayElement@at;
public anno loc Name@at;
public anno loc NameOrExpr@at;
public anno loc CastType@at;
public anno loc ClosureUse@at;
public anno loc IncludeType@at;
public anno loc Expr@at;
public anno loc Op@at;
public anno loc Param@at;
public anno loc Scalar@at;
public anno loc Stmt@at;
public anno loc Declaration@at;
public anno loc Catch@at;
public anno loc Case@at;
public anno loc ElseIf@at;
public anno loc Else@at;
public anno loc Use@at;
public anno loc ClassItem@at;
public anno loc Property@at;
public anno loc Modifier@at;
public anno loc ClassDef@at;
public anno loc InterfaceDef@at;
public anno loc StaticVar@at;
public anno loc Script@at;

@decl{Contains Namespace/Class/Method/Function information.}
public anno loc ActualParameter@decl;
public anno loc Const@decl;
public anno loc ArrayElement@decl;
public anno loc Name@decl;
public anno loc NameOrExpr@decl;
public anno loc CastType@decl;
public anno loc ClosureUse@decl;
public anno loc IncludeType@decl;
public anno loc Expr@decl;
public anno loc Op@decl;
public anno loc Param@decl;
public anno loc Scalar@decl;
public anno loc Stmt@decl;
public anno loc Declaration@decl;
public anno loc Catch@decl;
public anno loc Case@decl;
public anno loc ElseIf@decl;
public anno loc Else@decl;
public anno loc Use@decl;
public anno loc ClassItem@decl;
public anno loc Property@decl;
public anno loc Modifier@decl;
public anno loc ClassDef@decl;
public anno loc InterfaceDef@decl;
public anno loc StaticVar@decl;
public anno loc Script@decl;

@doc{Stores unique IDs for the AST nodes.}
public anno str ActualParameter@id;
public anno str Const@id;
public anno str ArrayElement@id;
public anno str Name@id;
public anno str NameOrExpr@id;
public anno str CastType@id;
public anno str ClosureUse@id;
public anno str IncludeType@id;
public anno str Expr@id;
public anno str Op@id;
public anno str Param@id;
public anno str Scalar@id;
public anno str Stmt@id;
public anno str Declaration@id;
public anno str Catch@id;
public anno str Case@id;
public anno str ElseIf@id;
public anno str Else@id;
public anno str Use@id;
public anno str ClassItem@id;
public anno str Property@id;
public anno str Modifier@id;
public anno str ClassDef@id;
public anno str InterfaceDef@id;
public anno str StaticVar@id;
public anno str Script@id;

@doc{Stores PHPDoc for the AST nodes.}
public anno str ActualParameter@phpdoc;
public anno str Const@phpdoc;
public anno str ArrayElement@phpdoc;
public anno str Name@phpdoc;
public anno str NameOrExpr@phpdoc;
public anno str CastType@phpdoc;
public anno str ClosureUse@phpdoc;
public anno str IncludeType@phpdoc;
public anno str Expr@phpdoc;
public anno str Op@phpdoc;
public anno str Param@phpdoc;
public anno str Scalar@phpdoc;
public anno str Stmt@phpdoc;
public anno str Declaration@phpdoc;
public anno str Catch@phpdoc;
public anno str Case@phpdoc;
public anno str ElseIf@phpdoc;
public anno str Else@phpdoc;
public anno str Use@phpdoc;
public anno str ClassItem@phpdoc;
public anno str Property@phpdoc;
public anno str Modifier@phpdoc;
public anno str ClassDef@phpdoc;
public anno str InterfaceDef@phpdoc;
public anno str StaticVar@phpdoc;
public anno str Script@phpdoc;

@doc{Used to associate the actual compile-time value with magic constants.}
public anno str Scalar@actualValue;
