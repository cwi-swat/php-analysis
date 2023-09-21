@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::semantics::concrete::PHP

// import lang::php::ast::AbstractSyntax;
// import lang::php::semantics::shared::Value;

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

// public Value eval(Expr e) {

// }