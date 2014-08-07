module lang::php::experiments::mscse2014::Constraints

import lang::php::ast::AbstractSyntax;

import lang::php::m3::Core;
import lang::php::ast::System;

import lang::php::types::TypeSymbol;
import lang::php::types::TypeConstraints;

import IO; // for debuggin

private set[Constraint] constraints = {};

// only callable method (from another file)
public set[Constraint] getConstraints(System system, M3 m3) 
{
	// reset the constraints of previous runs
	constraints = {};
	
	for(s <- system) {
		addConstraints(system[s], m3);
	}	
	
	return constraints;
}

private void addConstraints(Script script, M3 m3)
{ 
	for (stmt <- script.body) {
		addConstraints(stmt, m3);
	}
}

private void addConstraints(Stmt statement, M3 m3)
{
	//set[Constraint] constraints = {};

	//println("Statment :: <statement>");
	switch(statement) { 
		case \break(_): ;
		case classDef(ClassDef classDef): constraints += getConstraints(classDef, m3);
//	= \break(OptionExpr breakExpr)
//	| classDef(ClassDef classDef)
//	| const(list[Const] consts)
//	| \continue(OptionExpr continueExpr)
//	| declare(list[Declaration] decls, list[Stmt] body)
//	| do(Expr cond, list[Stmt] body)
//	| echo(list[Expr] exprs)
		case exprstmt(Expr expr): addConstraints(expr, m3);
//	| \for(list[Expr] inits, list[Expr] conds, list[Expr] exprs, list[Stmt] body)
//	| foreach(Expr arrayExpr, OptionExpr keyvar, bool byRef, Expr asVar, list[Stmt] body)
//	| function(str name, bool byRef, list[Param] params, list[Stmt] body)
//	| global(list[Expr] exprs)
//	| goto(Name gotoName)
//	| haltCompiler(str remainingText)
//	| \if(Expr cond, list[Stmt] body, list[ElseIf] elseIfs, OptionElse elseClause)
//	| inlineHTML(str htmlText)
//	| interfaceDef(InterfaceDef interfaceDef)
//	| traitDef(TraitDef traitDef)
//	| label(str labelName)
//	| namespace(OptionName nsName, list[Stmt] body)
//	| namespaceHeader(Name namespaceName)
//	| \return(OptionExpr returnExpr)
//	| static(list[StaticVar] vars)
//	| \switch(Expr cond, list[Case] cases)
//	| \throw(Expr expr)
//	| tryCatch(list[Stmt] body, list[Catch] catches)
//	| tryCatchFinally(list[Stmt] body, list[Catch] catches, list[Stmt] finallyBody)
//
//	| unset(list[Expr] unsetVars)
//	| use(list[Use] uses)
//	| \while(Expr cond, list[Stmt] body)
//	| emptyStmt()
//	| block(list[Stmt] body)
	}	
	
	//return constraints;
}

private set[Constraint] getConstraints(ClassDef classDef, M3 m3)
{
	set[Constraint] constraints = {};
	
	//	
	
	throw "implement ClassDef";
	return constraints;
}

private void addConstraints(Expr e, M3 m3)
{
	top-down-break visit (e) {
	//| array(list[ArrayElement] items)
	//| fetchArrayDim(Expr var, OptionExpr dim)
	//| fetchClassConst(NameOrExpr className, Name constantName)
	//| assign(Expr assignTo, Expr assignExpr)
		case a:assign(Expr assignTo, Expr assignExpr): {
			// add direct constraints
			constraints += { subtyp(typeOf(assignExpr@at), typeOf(assignTo@at)) }; 
			// add indirect constraints
			addConstraints(assignTo, m3);
			addConstraints(assignExpr, m3);
			//constraints += getConstraints(assignExpr, m3);
		}
	//| assignWOp(Expr assignTo, Expr assignExpr, Op operation)
		case a:assignWOp(Expr assignTo, Expr assignExpr, Op operation): {
			switch(operation) {
				case bitwiseAnd():	constraints += { eq(typeOf(assignTo@at), \int()) }; 
				case bitwiseOr():	constraints += { eq(typeOf(assignTo@at), \int()) }; 
				case bitwiseXor():	constraints += { eq(typeOf(assignTo@at), \int()) }; 
				case leftShift():	constraints += { eq(typeOf(assignTo@at), \int()) }; 
				case rightShift():	constraints += { eq(typeOf(assignTo@at), \int()) }; 
				case \mod():		constraints += { eq(typeOf(assignTo@at), \int()) };
				
				case div():	{		// LHS is int, RHS is not of type array
									constraints += { eq(typeOf(assignTo@at), \int()) };
									constraints += { negation(eq(typeOf(assignExpr@at), \array(\any()))) };
				}
				case minus():		constraints += { eq(typeOf(assignTo@at), \int()) };
				
				case concat():		constraints += { eq(typeOf(assignTo@at), string()) };
				
				
			//	default: 	constraints += { subtyp(typeOf(assignExpr@at), typeOf(assignTo@at)) }; 
			}
			addConstraints(assignTo, m3);
			addConstraints(assignExpr, m3);
		}
	//| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
	//| refAssign(Expr assignTo, Expr assignExpr)
	//| binaryOperation(Expr left, Expr right, Op operation)
	
		//unaryOperation(Expr operand, Op operation)
		// not final!!!!!!
		case u:unaryOperation(Expr operand, Op operation): {
			switch (operation) {
				case preInc(): {
					// if operand == string -> result = string/integer/float
					constraints += { conditional( 
										eq(typeOf(u@at), string()), 
										eq(typeOf(u@at), disjunction({ string(), integer(), float() }))
									 ) 
								   };
					// if operand isType(\null())
					//constraints += { conditional( 
										//isType(string()), 
										
										//eq(typeOf(u@at), getTypeOfExpr(operand, m3, constraints)) };
				
				}
				// I assume that the type of the expression does not change here!!!!!! please verify.
				case bitwiseNot():	addConstraints(operand, m3);	
				case unaryPlus():	addConstraints(operand, m3);	
				case unaryMinus():	addConstraints(operand, m3);	
			}
			// todo, commented the line below
			//constraints += { eq(typeOf(u@at), addConstraints(operand, m3, constraints)) };
			//constraints += getConstraints(operand, m3);
		}
		
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
	
		//scalar(Scalar scalarVal)
		case s:scalar(Scalar scalarVal): {
			switch(scalarVal) {
				case classConstant():		constraints += { eq(typeOf(s@at), string()) };
				case dirConstant():			constraints += { eq(typeOf(s@at), string()) };
				case fileConstant():		constraints += { eq(typeOf(s@at), string()) };
				case funcConstant():		constraints += { eq(typeOf(s@at), string()) };
				case lineConstant():		constraints += { eq(typeOf(s@at), string()) };
				case methodConstant():		constraints += { eq(typeOf(s@at), string()) };
				case namespaceConstant():	constraints += { eq(typeOf(s@at), string()) };
				case traitConstant():		constraints += { eq(typeOf(s@at), string()) };
				
				case float(_):				constraints += { eq(typeOf(s@at), float()) };
				case integer(_):			constraints += { eq(typeOf(s@at), \int()) };
				case string(_):				constraints += { eq(typeOf(s@at), string()) };
				case encapsed(_):			constraints += { eq(typeOf(s@at), string()) };
			}
		}
		
		//var(NameOrExpr varName)	
		case v:var(name(_)): { 
			constraints += { subtyp(typeOf(v@at), \any()) };
		}
		
		case v:var(expr(e)): { // variable variable
			constraints += { subtyp(typeOf(v@at), \any()) };	
		}
	//| yield(OptionExpr keyExpr, OptionExpr valueExpr)
	//| listExpr(list[OptionExpr] listExprs
		
		
		
	}
	
}

//private loc getLocForVar(Expr v, M3 m3)
//{
//	if (v@decl?) 
//		return v@decl;
//	
//	//set[loc] uses = { u | u <- m3@uses[v@at], isVariable(u) };
//	set[loc] uses = m3@uses[v@at];
//	assert size(uses) == 1 : "No uses found for: <v>";
//	
//	return getOneFrom(uses);
//}