module lang::php::m3::TypeConstraints

import lang::php::ast::AbstractSyntax;
import lang::php::m3::TypeSymbol;

// what information is needed:
// constructor of a class
// parameters of a function/method/constructor	

data TypeOf 
	= typeOf(loc ident) 
	//| typeOf(Stmt s) 
	//| typeOf(Param p) 
	//| typeOf(ClassItem ci) 
	//| typeOf(Const c)
	//| typeOf(ArrayElement ae)
	//// more?
	;

data Constraint 
	= eq(TypeOf a, TypeOf b)
    | subtype(TypeOf a, TypeOf b)
    | subtype(TypeOf a, set[TypeOf] alts)
    ;

data TypeSet
	= Universe()
	| EmptySet()
	| Root()
	| Single(TypeSymbol T)
	| Set(set[TypeSymbol] Ts)
	| Subtypes(TypeSet subs)
	| Union(set[TypeSet] args)
	| Intersection(set[TypeSet] args)
	;