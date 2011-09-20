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