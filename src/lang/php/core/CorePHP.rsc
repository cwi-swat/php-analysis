@license{ Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::core::CorePHP

public data OptionExpr = someExpr(Expr expr) | noExpr();

public data OptionName = someName(Name name) | noName();

public data OptionElse = someElse(Else e) | noElse();

public data ArrayElement = arrayElement(OptionExpr key, Expr val);
	 
public data CastType = \int() | \bool() | float() | string();

public data Expr
	= array(list[ArrayElement] items)
	| fetchArrayDim(Expr var, OptionExpr dim)
	| fetchClassConst(str className, str constName)
	| assign(Expr assignTo, Expr assignExpr)
	| binaryOperation(Expr left, Expr right, Op operation)
	| unaryOperation(Expr operand, Op operation)
	| new(str className, list[Expr] parameters)
	| castToInt(CastType castType, Expr expr)
	| fetchConst(str name)
	| empty(Expr expr)
	| call(str funName, list[Expr] parameters)
	| methodCall(Expr target, str methodName, list[Expr] parameters)
	| print(Expr expr)
	| propertyFetch(Expr target, str propertyName)
	| ternary(Expr cond, OptionExpr ifBranch, Expr elseBranch)
	| scalar(Scalar scalarVal)
	| var(str varName)	
	;

public data Op = concat() | div() | minus() | mul() | plus() 
			   | gt() | geq() | logicalAnd() | logicalOr() 
			   | logicalXor() | notEqual() | notIdentical() 
			   | lt() | leq() | equal() | identical() ;

public data Param = param(str paramName, OptionExpr paramDefault, OptionName paramType, bool byRef);
						  
public data Scalar
	= float(real realVal)
	| integer(int intVal)
	| string(str strVal)
	| encapsed(list[Expr] parts)
	;

public data Stmt 
	= const(str name, Expr constValue)
	| do(Expr cond, list[Stmt] body)
	| echo(list[Expr] exprs)
	| exprstmt(Expr expr)
	| \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)
	| foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body)
	| global(list[Expr] exprs)
	| \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause)
	| inlineHTML(str htmlText)
	| \return(OptionExpr returnExpr)
	| \switch(Expr cond, list[Case] cases)
	| \while(Expr cond, list[Stmt] body)
	;

public data Case = \case(OptionExpr cond, list[Stmt] body);

public data ElseIf = elseIf(Expr cond, list[Stmt] body);

public data Else = \else(list[Stmt] body);

public data ClassItem 
	= property(set[Modifier] modifiers, list[Property] prop)
	| constCI(list[Const] consts)
	| method(str name, set[Modifier] modifiers, bool byRef, list[Param] params, list[Stmt] body)
	;

public data Property = property(str propertyName, OptionExpr defaultValue);

public data Modifier = \public() | \private() | protected() | static() | abstract() | final();
 
public data ClassDef = class(str className,
							 set[Modifier] modifiers, 
							 OptionName extends, 
							 list[str] implements, 
							 list[ClassItem] members);

public data InterfaceDef = interface(str interfaceName, 
									list[str] extends, 
									list[ClassItem] members);
									
public data Script = script(list[Stmt] body) | errscript(str err);
			   