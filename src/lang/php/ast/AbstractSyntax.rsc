@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::ast::AbstractSyntax

import IO;
import lang::php::util::Option;

// This mirrors the abstract syntax created using the phc php compiler, with some
// simplifications to make the AST more sensible. It is not based directly on the 
// PHP concrete syntax. Productions shown below are those used to define the phc 
// abstract syntax.

// Class_def ::=
//    Class_mod CLASS_NAME extends:CLASS_NAME?
//    implements:INTERFACE_NAME* Member* ; 
// Class_mod ::= "abstract"? "final"? ;
public data ClassDef = ClassDef(bool isAbstract, bool isFinal, Id className, Option[Id] extends, list[Id] implements, list[Member] members);

// Interface_def ::= INTERFACE_NAME extends:INTERFACE_NAME* Member* ;
public data InterfaceDef = InterfaceDef(Id interfaceName, list[Id] extends, list[Member] members);

// Member ::= Method | Attribute ;
public data Member 
	= MethodMember(Method method)
	| AttributeMember(Attribute attribute)
	;
	
// Method ::= Signature Statement*? ;
// Signature ::= Method_mod is_ref:"&"? METHOD_NAME Formal_parameter* ;
// Method_mod ::= "public"? "protected"? "private"? "static"? "abstract"? "final"? ;
public data Method = Method(bool isPublic, bool isProtected, bool isPrivate, bool isStatic, bool isAbstract, 
							bool isFinal, bool isRef, Id methodName, list[FormalParameter] parameters, 
							Option[list[Stmt]] methodBody);
	
// Formal_parameter ::= Type is_ref:"&"?
//    var:Name_with_default ;
// Type ::= CLASS_NAME? ;
public data FormalParameter = FormalParameter(Option[Id] paramType, bool isRef, NameWithDefault param);
	
// Name_with_default ::= VARIABLE_NAME Expr? ;
public data NameWithDefault = NameWithDefault(Id variableName, Option[Expr] expr);
	 	
// Attribute ::= Attr_mod vars:Name_with_default* ;
// Attr_mod ::= "public"? "protected"? "private"? "static"? "const"?  ;
public data Attribute = Attribute(bool isPublic, bool isProtected, bool isPrivate, bool isStatic, bool isConst, 
								  list[NameWithDefault] vars);

// Return ::= Expr? ;
// Static_declaration ::= vars:Name_with_default* ;
// Global ::= Variable_name* ;
// Try ::= Statement* catches:Catch* ;
// Throw ::= Expr ;
// Eval_expr ::= Expr ;
// If ::= Expr iftrue:Statement* iffalse:Statement* ;
// While ::= Expr Statement* ;
// Do ::= Statement* Expr ;
// For ::= init:Expr? cond:Expr? incr:Expr? Statement* ;
// Foreach ::= Expr key:Variable? is_ref:"&"? val:Variable Statement* ;
// Switch ::= Expr Switch_case* ;
// Break ::= Expr? ;
// Continue ::= Expr? ;
// Declare ::= Directive+ Statement* ;
// Nop ::= ;
public data Stmt 
	= ClassDefStmt(ClassDef classDef)
	| InterfaceDefStmt(InterfaceDef interfaceDef)
	| MethodStmt(Method method)
	| ReturnStmt(Option[Expr] returnExpr)
	| StaticDeclarationStmt(list[NameWithDefault] vars)
	| GlobalStmt(list[NameExprOrId] varNames)
	| TryStmt(list[Stmt] tryBlock, list[Catch] catches)
	| ThrowStmt(Expr throwExpr)
	| EvalExprStmt(Expr evalExpr)
	| IfStmt(Expr ifCond, list[Stmt] trueBody, list[Stmt] falseBody)
	| WhileStmt(Expr whileCond, list[Stmt] whileBody)
	| DoStmt(list[Stmt] doBody, Expr doCond)
	| ForStmt(Option[Expr] initExpr, Option[Expr] condExpr, Option[Expr] incrExpr, list[Stmt] forBody)
	| ForEachStmt(Expr expr, Option[Var] key, bool isRef, Var val, list[Stmt] forEachBody)
	| SwitchStmt(Expr switchExpr, list[SwitchCase] cases)
	| BreakStmt(Option[Expr] breakExpr)
	| ContinueStmt(Option[Expr] continueExpr)
	| DeclareStmt(list[Directive] directives, list[Stmt] declareBody)
	| NopStmt()
	;

// Directive ::= DIRECTIVE_NAME Expr ;
public data Directive = Directive(Id directiveName, Expr expr);
		
// Switch_case ::= Expr? Statement* ;	
public data SwitchCase = SwitchCase(Option[Expr] expr, list[Stmt] caseBody);

// Catch ::= CLASS_NAME VARIABLE_NAME Statement* ;
public data Catch = Catch(Id className, Id varName, list[Stmt] catchBlock);
		
//Expr ::=
//     Assignment
//   | Cast | Unary_op | Bin_op
//   | Constant | Instanceof
//   | Variable | Pre_op
//   | Method_invocation | New
//   | Literal
//   | Op_assignment | List_assignment
//   | Post_op | Array | Conditional_expr | Ignore_errors
//   ;
//
// Using these productions:	
//   Assignment ::= Variable is_ref:"&"? Expr ;
//   Cast ::= CAST Expr ;
//   Unary_op ::= OP Expr ;
//   Bin_op ::= left:Expr OP right:Expr ;	
//   Constant ::= CLASS_NAME? CONSTANT_NAME ;
//   Instanceof ::= Expr Class_name ;
//   Pre_op ::= OP Variable ;
//   Method_invocation ::= Target? Method_name Actual_parameter* ;
//   Method_invocation ::= Target? Method_name Actual_parameter* ;
//   New ::= Class_name Actual_parameter* ;
//   Op_assignment ::= Variable OP Expr ;
//   List_assignment ::= List_element?* Expr ;
//   Post_op ::= Variable OP ;
//   Array ::= Array_elem* ;
//   Conditional_expr ::= cond:Expr iftrue:Expr iffalse:Expr ;
//   Ignore_errors ::= Expr ;
//
// Expanded below:
//   Lit (for Literal ::=)
//   Var (for Variable ::=)
// 
public data Expr 
	= AssignmentExpr(Var assignTo, bool isRef, Expr assignExpr)
	| CastExpr(Id cast, Expr castExpr)
	| UnaryOpExpr(Op op, Expr expr)
	| BinOpExpr(Expr left, Op op, Expr right)
	| ConstantExpr(Option[Id] constantNameExprOrId, Id constantName)
	| InstanceofExpr(Expr instanceExpr, NameExprOrId instanceNameExprOrId)
	| VariableExpr(Var var)
	| PreOpExpr(Op op, Var var)
	| MethodInvocationExpr(Option[NameExprOrId] target, NameExprOrId methodName, list[ActualParameter] parameters)
	| NewExpr(NameExprOrId className, list[ActualParameter] parameters)
	| LiteralExpr(Lit literal)
	| OpAssignmentExpr(Var var, Op op, Expr expr)
	| ListAssignmentExpr(Option[list[ListElement]] listElements, Expr expr)
	| PostOpExpr(Var var, Op op)
	| ArrayExpr(list[ArrayElement] arrayElements)
	| ConditionalExpr(Expr cond, Expr ifTrue, Expr ifFalse)
	| IgnoreErrorsExpr(Expr expr)
	;
	
// List_element ::= Variable | Nested_list_elements ;
// Nested_list_elements ::= List_element?* ;
public data ListElement 
	= VarListElement(Var var)
	| NestedListElements(Option[list[ListElement]] elements)
	;
	
// Array_elem ::= key:Expr? is_ref:"&"? val:Expr ;
public data ArrayElement = ArrayElement(Option[Expr] key, bool isRef, Expr val);
	 
// Literal ::= INT<long> | REAL<double> | STRING<String*> | BOOL<bool> | NIL<> ;	
public data Lit 
	= IntLit(int intVal)
	| RealLit(real realVal)
	| StringLit(str strVal)
	| BoolLit(bool boolVal)
	| NilLit()
	;
	
// Variable ::= Target? Variable_name array_indices:Expr?* ;
public data Var = Var(Option[NameExprOrId] target, NameExprOrId varName, Option[list[Expr]] arrayIndices);

// Variable_name ::= VARIABLE_NAME | Reflection ;
// Reflection ::= Expr ;
// Class_name ::= CLASS_NAME | Reflection ;
// Reflection ::= Expr ;
// Method_name ::= METHOD_NAME | Reflection ;
// Reflection ::= Expr ;
public data NameExprOrId
	= NameExpr(Expr nameExpr)
	| NameId(Id nameId)
	;
	
// Actual_parameter ::= is_ref:"&"? Expr ;
public data ActualParameter = ActualParameter(bool isRef, Expr expr);
	
// Identifier ::=
//     INTERFACE_NAME | CLASS_NAME | METHOD_NAME | VARIABLE_NAME
//     | CAST | OP | CONSTANT_NAME
//     | DIRECTIVE_NAME
//   ;
public data Id = Id(str idValue);

public alias Op = Id;

public alias Script = list[Stmt];

public anno list[str] Member@comments;
public anno list[str] Stmt@comments;
public anno list[str] InterfaceDef@comments;
public anno list[str] ClassDef@comments;
public anno list[str] SwitchCase@comments;
public anno list[str] Catch@comments;

public anno loc ClassDef@at;
public anno loc InterfaceDef@at;
public anno loc Member@at;
public anno loc Method@at;
public anno loc FormalParameter@at;
public anno loc NameWithDefault@at;
public anno loc Attribute@at;
public anno loc Stmt@at;
public anno loc Directive@at;
public anno loc SwitchCase@at;
public anno loc Catch@at;
public anno loc Expr@at;
public anno loc ListElement@at;
public anno loc ArrayElement@at;
public anno loc Lit@at;
public anno loc Var@at;
public anno loc NameExprOrId@at;
public anno loc ActualParameter@at;
public anno loc Id@at;
