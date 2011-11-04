@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::semantics::concrete::PHP

import lang::php::ast::AbstractSyntax;
import lang::php::semantics::shared::Value;

//public data Expr 
//	= AssignmentExpr(Var assignTo, bool isRef, Expr assignExpr)
//	| CastExpr(Id cast, Expr castExpr)
//	| UnaryOpExpr(Op op, Expr expr)
//	| BinOpExpr(Expr left, Op op, Expr right)
//	| ConstantExpr(Option[Id] constantNameExprOrId, Id constantName)
//	| InstanceofExpr(Expr instanceExpr, NameExprOrId instanceNameExprOrId)
//	| VariableExpr(Var var)
//	| PreOpExpr(Op op, Var var)
//	| MethodInvocationExpr(Option[NameExprOrId] target, NameExprOrId methodName, list[ActualParameter] parameters)
//	| NewExpr(NameExprOrId className, list[ActualParameter] parameters)
//	| LiteralExpr(Lit literal)
//	| OpAssignmentExpr(Var var, Op op, Expr expr)
//	| ListAssignmentExpr(Option[list[ListElement]] listElements, Expr expr)
//	| PostOpExpr(Var var, Op op)
//	| ArrayExpr(list[ArrayElement] arrayElements)
//	| ConditionalExpr(Expr cond, Expr ifTrue, Expr ifFalse)
//	| IgnoreErrorsExpr(Expr expr)
//	;

public Value eval(Expr e) {

}