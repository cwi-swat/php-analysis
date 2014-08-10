module lang::php::experiments::mscse2014::Constraints

import lang::php::ast::AbstractSyntax;

import lang::php::m3::Core;
import lang::php::ast::System;

import lang::php::types::TypeSymbol;
import lang::php::types::TypeConstraints;
import lang::php::types::core::Constants;
import lang::php::types::core::Variables;

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
	case f:function(str name, bool byRef, list[Param] params, list[Stmt] body): {
		loc functionScope = f@scope[file=name][scheme="php+function"];
		
		for (stmt <- body) addConstraints(stmt, m3);
	
		bool isReturnStatementWithinScope(Stmt rs, loc scope) = (\return(_) := rs) && (scope == rs@scope);
		set[OptionExpr] returnStmts = { rs.returnExpr | rs <- body, isReturnStatementWithinScope(rs, functionScope) };
		
		if (!isEmpty(returnStmts)) {
			// if there are return statements, the disjunction of them is the return value of the function
			constraints += { 
				disjunction(
					{ eq(typeOf(f@at), typeOf(e@at)) | rs <- returnStmts, someExpr(e) := rs }
					+ { eq(typeOf(f@at), null()) | rs <- returnStmts, noExpr() := rs }
				)};
		} else {
			// no return methods means that the function will always return null (unless an expception is thrown)
			constraints += { eq(typeOf(f@at), null()) }; 
		}
	}
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
		case a:assignWOp(Expr assignTo, Expr assignExpr, Op operation): {
			switch(operation) {
				case bitwiseAnd():	constraints += { eq(typeOf(assignTo@at), integer()) }; 
				case bitwiseOr():	constraints += { eq(typeOf(assignTo@at), integer()) }; 
				case bitwiseXor():	constraints += { eq(typeOf(assignTo@at), integer()) }; 
				case leftShift():	constraints += { eq(typeOf(assignTo@at), integer()) }; 
				case rightShift():	constraints += { eq(typeOf(assignTo@at), integer()) }; 
				case \mod():		constraints += { eq(typeOf(assignTo@at), integer()) };
				
				case div(): 		constraints += { 
										eq(typeOf(assignTo@at), integer()), // LHS is int
										negation(subtyp(typeOf(assignExpr@at), array(\any()))) // RHS is not an array
									};
				
				case minus(): 		constraints += { 
										eq(typeOf(assignTo@at), integer()), // LHS is int
										negation(subtyp(typeOf(assignExpr@at), array(\any()))) // RHS is not an array
									};
				
				case concat():		constraints += { eq(typeOf(assignTo@at), string()) };
				
				case mul(): 		constraints += { subtyp(typeOf(assignTo@at), float()) };
				case plus(): 		constraints += { subtyp(typeOf(assignTo@at), float()) };
				
				
			//	default: 	constraints += { subtyp(typeOf(assignExpr@at), typeOf(assignTo@at)) }; 
			}
			addConstraints(assignTo, m3);
			addConstraints(assignExpr, m3);
		}
	//| listAssign(list[OptionExpr] assignsTo, Expr assignExpr)
	//| refAssign(Expr assignTo, Expr assignExpr)
		case op:binaryOperation(Expr left, Expr right, Op operation): {
			addConstraints(left, m3);	
			addConstraints(right, m3);	
			switch (operation) {
				case plus():
					constraints += {
						// if left AND right are array: results is array
						conditional(
							conjunction({
								subtyp(typeOf(left@at), array(\any())),
								subtyp(typeOf(right@at), array(\any()))
							}),
							subtyp(typeOf(op@at), array(\any()))
						),
						
						// if left or right is NOT array: result is subytpe of float 
						conditional(
							disjunction({
								negation(subtyp(typeOf(left@at), array(\any()))),
								negation(subtyp(typeOf(right@at), array(\any())))
							}),
							subtyp(typeOf(op@at), float())
						),
						// unconditional: result = array | double | int
						disjunction({
							subtyp(typeOf(op@at), array(\any())),
							subtyp(typeOf(op@at), float()) 
						})
						// todo ?
						// if (left XOR right = double) -> double
						// in all other cases: int
					};
				case minus():
					constraints += {
						negation(subtyp(typeOf(left@at),  array(\any()))), // LHS != array
						negation(subtyp(typeOf(right@at), array(\any()))), // RHS != array
						subtyp(typeOf(op@at), float()) // result is subtype of float
						// todo ?
						// if (left XOR right = double) -> double
						// in all other cases: int
					};
				case mul(): // refactor: same as minus()
					constraints += {
						negation(subtyp(typeOf(left@at),  array(\any()))), // LHS != array
						negation(subtyp(typeOf(right@at), array(\any()))), // RHS != array
						subtyp(typeOf(op@at), float()) // result is subtype of float
						// todo ?
						// if (left XOR right = double) -> double
						// in all other cases: int
					};
				case div(): // refactor: same as minus()
					constraints += {
						negation(subtyp(typeOf(left@at),  array(\any()))), // LHS != array
						negation(subtyp(typeOf(right@at), array(\any()))), // RHS != array
						subtyp(typeOf(op@at), float()) // result is subtype of float
						// todo ?
						// if (left XOR right = double) -> double
						// in all other cases: int
					};
				
				case \mod(): 		constraints += { eq(typeOf(op@at), integer()) }; // [E] = int
				case leftShift():	constraints += { eq(typeOf(op@at), integer()) }; // [E] = int
				case rightShift():	constraints += { eq(typeOf(op@at), integer()) }; // [E] = int
				
				case bitwiseAnd():
					constraints += {
						conditional( // if [L] and [R] are string, then [E] is string
							conjunction({
								eq(typeOf(left@at), string()),
								eq(typeOf(right@at), string())
							}),
							eq(typeOf(op@at), string())
						),
						conditional( // if [L] or [R] is not string, then [E] is int
							disjunction({
								negation(eq(typeOf(left@at), string())), 
								negation(eq(typeOf(right@at), string())) 
							}),
							eq(typeOf(op@at), integer())
						),
						disjunction({ // [E] = int|string 
							eq(typeOf(op@at), string()),
							eq(typeOf(op@at), integer())
						})
					
					};
				case bitwiseOr(): // refactor: duplicate of bitwise And
					constraints += {
						conditional( // if [L] and [R] are string, then [E] is string
							conjunction({
								eq(typeOf(left@at), string()),
								eq(typeOf(right@at), string())
							}),
							eq(typeOf(op@at), string())
						),
						conditional( // if [L] or [R] is not string, then [E] is int
							disjunction({
								negation(eq(typeOf(left@at), string())), 
								negation(eq(typeOf(right@at), string())) 
							}),
							eq(typeOf(op@at), integer())
						),
						disjunction({ // [E] = int|string 
							eq(typeOf(op@at), string()),
							eq(typeOf(op@at), integer())
						})
					
					};
				case bitwiseXor(): // refactor: duplicate of bitwise And
					constraints += {
						conditional( // if [L] and [R] are string, then [E] is string
							conjunction({
								eq(typeOf(left@at), string()),
								eq(typeOf(right@at), string())
							}),
							eq(typeOf(op@at), string())
						),
						conditional( // if [L] or [R] is not string, then [E] is int
							disjunction({
								negation(eq(typeOf(left@at), string())), 
								negation(eq(typeOf(right@at), string())) 
							}),
							eq(typeOf(op@at), integer())
						),
						disjunction({ // [E] = int|string 
							eq(typeOf(op@at), string()),
							eq(typeOf(op@at), integer())
						})
					
					};
				
				// comparison operators, all result in booleans
				case lt(): 			 constraints += { eq(typeOf(op@at), boolean()) };
				case leq():			 constraints += { eq(typeOf(op@at), boolean()) };
				case gt():			 constraints += { eq(typeOf(op@at), boolean()) };
				case geq():			 constraints += { eq(typeOf(op@at), boolean()) };
				case equal():		 constraints += { eq(typeOf(op@at), boolean()) };
				case identical():	 constraints += { eq(typeOf(op@at), boolean()) };
				case notEqual():	 constraints += { eq(typeOf(op@at), boolean()) };
				case notIdentical(): constraints += { eq(typeOf(op@at), boolean()) };
			}
		}
	
		case expr:unaryOperation(Expr operand, Op operation): {
			addConstraints(operand, m3);	
			switch (operation) {
				case unaryPlus():
					constraints += { 
						subtyp(typeOf(expr@at), float()), // type of whole expression is int or float
						negation(subtyp(typeOf(operand@at), array(\any()))) // type of the expression is not an array
						// todo
						// in: float -> out: float
						// in: str 	 -> out: int|float
						// in: _	 -> out: int
					};
										
				case unaryMinus():		
					constraints += { 
							subtyp(typeOf(expr@at), float()), // type of whole expression is int or float
							negation(subtyp(typeOf(operand@at), array(\any()))) // type of the expression is not an array
							// todo
							// in: float -> out: float
							// in: str 	 -> out: int|float
							// in: _	 -> out: int
						};
				
				case booleanNot():		constraints += { eq(typeOf(expr@at), boolean()) }; // type of whole expression is bool
				
				case bitwiseNot():		
					constraints += { 
						disjunction({ // the sub expression is int, float or string (rest results in fatal error)
							eq(typeOf(operand@at), integer()),  
							eq(typeOf(operand@at), float()),
							eq(typeOf(operand@at), string()) 
						}),
						disjunction({ // the whole expression is always a int or string
							eq(typeOf(expr@at), integer()),  
							eq(typeOf(expr@at), string()) 
						})
						// todo:
						// in: int 	  -> out: int
						// in: float  -> out: int
						// in: string -> out: string
					}; 
				
				case postInc():
					constraints += {
						conditional( //"if([E] = array(any())) then ([E++] = array(any()))",
							subtyp(typeOf(operand@at), array(\any())),
							subtyp(typeOf(expr@at), array(\any()))
						),
						conditional( //"if([E] = bool()) then ([E++] = bool())",
							eq(typeOf(operand@at), boolean()),
							eq(typeOf(expr@at), boolean())
						),
						conditional( //"if([E] = float()) then ([E++] = float())",
							eq(typeOf(operand@at), float()),
							eq(typeOf(expr@at), float())
						),
						conditional( //"if([E] = int()) then ([E++] = int())",
							eq(typeOf(operand@at), integer()),
							eq(typeOf(expr@at), integer())
						),
						conditional( //"if([E] = null()) then (or([E++] = null(), [E++] = int()))",
							eq(typeOf(operand@at), null()),
							disjunction({eq(typeOf(expr@at), null()), eq(typeOf(expr@at), integer())})
						),
						conditional( //"if([E] = object()) then ([E++] = object())",
							subtyp(typeOf(operand@at), \object()),
							subtyp(typeOf(expr@at), \object())
						),
						conditional( //"if([E] = resource()) then ([E++] = resource())",
							eq(typeOf(operand@at), resource()),
							eq(typeOf(expr@at), resource())
						),
						conditional( //"if([E] = string()) then (or([E++] = float(), [E++] = int(), [E++] = string())",
							eq(typeOf(operand@at), \string()),
							disjunction({eq(typeOf(expr@at), \float()), eq(typeOf(expr@at), integer()), eq(typeOf(expr@at), \string())})
						)
					};
										
				case postDec():
					constraints += {
						conditional( //"if([E] = array(any())) then ([E--] = array(any()))",
							subtyp(typeOf(operand@at), array(\any())),
							subtyp(typeOf(expr@at), array(\any()))
						),
						conditional( //"if([E] = bool()) then ([E--] = bool())",
							eq(typeOf(operand@at), boolean()),
							eq(typeOf(expr@at), boolean())
						),
						conditional( //"if([E] = float()) then ([E--] = float())",
							eq(typeOf(operand@at), float()),
							eq(typeOf(expr@at), float())
						),
						conditional( //"if([E] = int()) then ([E--] = int())",
							eq(typeOf(operand@at), integer()),
							eq(typeOf(expr@at), integer())
						),
						conditional( //"if([E] = null()) then (or([E--] = null(), [E++] = int()))",
							eq(typeOf(operand@at), null()),
							disjunction({eq(typeOf(expr@at), null()), eq(typeOf(expr@at), integer())})
						),
						conditional( //"if([E] = object()) then ([E--] = object())",
							subtyp(typeOf(operand@at), \object()),
							subtyp(typeOf(expr@at), \object())
						),
						conditional( //"if([E] = resource()) then ([E--] = resource())",
							eq(typeOf(operand@at), resource()),
							eq(typeOf(expr@at), resource())
						),
						conditional( //"if([E] = string()) then (or([E--] = float(), [E--] = int(), [E--] = string())",
							eq(typeOf(operand@at), \string()),
							disjunction({eq(typeOf(expr@at), \float()), eq(typeOf(expr@at), integer()), eq(typeOf(expr@at), \string())})
						)
					};
										
				case preInc():
					constraints += {
						conditional( //"if([E] = array(any())) then ([E++] = array(any()))",
							subtyp(typeOf(operand@at), array(\any())),
							subtyp(typeOf(expr@at), array(\any()))
						),
						conditional( //"if([E] = bool()) then ([E++] = bool())",
							eq(typeOf(operand@at), boolean()),
							eq(typeOf(expr@at), boolean())
						),
						conditional( //"if([E] = float()) then ([E++] = float())",
							eq(typeOf(operand@at), float()),
							eq(typeOf(expr@at), float())
						),
						conditional( //"if([E] = int()) then ([E++] = int())",
							eq(typeOf(operand@at), integer()),
							eq(typeOf(expr@at), integer())
						),
						conditional( //"if([E] = null()) then (or([E++] = null(), [E++] = int()))",
							eq(typeOf(operand@at), null()),
							eq(typeOf(expr@at), integer())
						),
						conditional( //"if([E] = object()) then ([E++] = object())",
							subtyp(typeOf(operand@at), \object()),
							subtyp(typeOf(expr@at), \object())
						),
						conditional( //"if([E] = resource()) then ([E++] = resource())",
							eq(typeOf(operand@at), resource()),
							eq(typeOf(expr@at), resource())
						),
						conditional( //"if([E] = string()) then (or([E++] = float(), [E++] = int(), [E++] = string())",
							eq(typeOf(operand@at), \string()),
							disjunction({eq(typeOf(expr@at), \float()), eq(typeOf(expr@at), integer()), eq(typeOf(expr@at), \string())})
						)
					};
										
				case preDec():
					constraints += {
						conditional( //"if([E] = array(any())) then ([E--] = array(any()))",
							subtyp(typeOf(operand@at), array(\any())),
							subtyp(typeOf(expr@at), array(\any()))
						),
						conditional( //"if([E] = bool()) then ([E--] = bool())",
							eq(typeOf(operand@at), boolean()),
							eq(typeOf(expr@at), boolean())
						),
						conditional( //"if([E] = float()) then ([E--] = float())",
							eq(typeOf(operand@at), float()),
							eq(typeOf(expr@at), float())
						),
						conditional( //"if([E] = int()) then ([E--] = int())",
							eq(typeOf(operand@at), integer()),
							eq(typeOf(expr@at), integer())
						),
						conditional( //"if([E] = null()) then (or([E--] = null(), [E++] = int()))",
							eq(typeOf(operand@at), null()),
							eq(typeOf(expr@at), integer())
						),
						conditional( //"if([E] = object()) then ([E--] = object())",
							subtyp(typeOf(operand@at), \object()),
							subtyp(typeOf(expr@at), \object())
						),
						conditional( //"if([E] = resource()) then ([E--] = resource())",
							eq(typeOf(operand@at), resource()),
							eq(typeOf(expr@at), resource())
						),
						conditional( //"if([E] = string()) then (or([E--] = float(), [E--] = int(), [E--] = string())",
							eq(typeOf(operand@at), \string()),
							disjunction({eq(typeOf(expr@at), \float()), eq(typeOf(expr@at), integer()), eq(typeOf(expr@at), \string())})
						)
					};
			}
		
		}
		
	//| new(NameOrExpr className, list[ActualParameter] parameters)
	//| cast(CastType castType, Expr expr)
		case c:cast(CastType castType, Expr expr): {
			addConstraints(expr, m3);	
			switch(castType) {
				case \int() :	constraints += { eq(typeOf(c@at), integer()) };
				case \bool() :	constraints += { eq(typeOf(c@at), boolean()) };
				case float() :	constraints += { eq(typeOf(c@at), float()) };
				case array() :	constraints += { subtyp(typeOf(c@at), array(\any())) };
				case object() :	constraints += { subtyp(typeOf(c@at), object()) };
				case unset():	constraints += { eq(typeOf(c@at), null()) };
				// special case for string, when [expr] <: object, the class of the object needs to have method "__toString"
				case string() :	
					constraints += { 
						eq(typeOf(c@at), string()),
						conditional(
							subtyp(typeOf(expr@at), object()),
							hasMethod(typeOf(expr@at), "__tostring")
						)
					};
			}
		}
	//| clone(Expr expr)
	//| closure(list[Stmt] statements, list[Param] params, list[ClosureUse] closureUses, bool byRef, bool static)
		case fc:fetchConst(name(name)): {
			if (/true/i := name || /false/i := name) {
				constraints += { eq(typeOf(fc@at), boolean()) };
			} else if (/null/i := name) {
				constraints += { eq(typeOf(fc@at), null()) };
			} else if (name in predefinedConstants) {
				constraints += { eq(typeOf(fc@at), predefinedConstants[name]) };
			} else {
				constraints += { subtyp(typeOf(fc@at), \any()) };
			}
		}
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
		// ternary: E1?E2:E3 == E => [E] = [E2] V [E3]
		case t:ternary(Expr cond, someExpr(Expr ifBranch), Expr elseBranch): {
			addConstraints(cond, m3);
			addConstraints(ifBranch, m3);
			addConstraints(elseBranch, m3);
			constraints += { 
				disjunction({
					subtyp(typeOf(t@at), typeOf(ifBranch@at)),
					subtyp(typeOf(t@at), typeOf(elseBranch@at))
				})
			};
		}
		// ternary: E1?:E3 == E => [E] = [E1] V [E3]
		case t:ternary(Expr cond, noExpr(), Expr elseBranch): {
			addConstraints(cond, m3);
			addConstraints(elseBranch, m3);
			constraints += { 
				disjunction({
					subtyp(typeOf(t@at), typeOf(cond@at)),
					subtyp(typeOf(t@at), typeOf(elseBranch@at))
				})
			};
		}
	//| staticPropertyFetch(NameOrExpr className, NameOrExpr propertyName)
	
		//scalar(Scalar scalarVal)
		case s:scalar(Scalar scalarVal): {
			switch(scalarVal) {
				case classConstant():		constraints += { eq(typeOf(s@at), string()) };
				case dirConstant():			constraints += { eq(typeOf(s@at), string()) };
				case fileConstant():		constraints += { eq(typeOf(s@at), string()) };
				case funcConstant():		constraints += { eq(typeOf(s@at), string()) };
				case lineConstant():		constraints += { eq(typeOf(s@at), integer()) };
				case methodConstant():		constraints += { eq(typeOf(s@at), string()) };
				case namespaceConstant():	constraints += { eq(typeOf(s@at), string()) };
				case traitConstant():		constraints += { eq(typeOf(s@at), string()) };
				
				case float(_):				constraints += { eq(typeOf(s@at), float()) };
				case integer(_):			constraints += { eq(typeOf(s@at), integer()) };
				case string(_):				constraints += { eq(typeOf(s@at), string()) };
				case encapsed(_):			constraints += { eq(typeOf(s@at), string()) };
			}
		}
		
		// normal variable and variable variable (can be combined)
		case v:var(name(name(name))): {
			if (name in predefinedVariables) {
				if (array(\any()) := predefinedVariables[name]) {
					constraints += { subtyp(typeOf(v@at), predefinedVariables[name]) };
				} else {
					constraints += { eq(typeOf(v@at), predefinedVariables[name]) };
				}
			} else {
				constraints += { subtyp(typeOf(v@at), \any()) };
			}
		}
		case v:var(expr(e)): constraints += { subtyp(typeOf(v@at), \any()) };	
		
	//| yield(OptionExpr keyExpr, OptionExpr valueExpr)
	//| listExpr(list[OptionExpr] listExprs
	}
	
}