module lang::php::types::TypeConstraints

import lang::php::ast::AbstractSyntax;
import lang::php::types::TypeSymbol;

alias TypeFacts = rel[loc decl, Fact fact];

// these facts can be extracted from the M3.
data Fact
	= className(str name) // = FQN (= fully qualified name) 
	| classMethod(str name)
	| classProperty(str name)
	| classConstant(str name)
	| classConstructorParameters(PhpParams params)
	| methodName(str name)
	| methodParameters(PhpParams params)
	| functionName(str name) 
	| functionParameters(PhpParams params)
	;
	
data TypeOf 
	= typeOf(loc ident)
	| arrayType(set[TypeOf] expressions)
	//| typeOf(TypeSymbol typeSymbol)
	;

data Constraint 
	= eq(TypeOf a, TypeOf t)
	| eq(TypeOf a, TypeSymbol ts)
	//| eq(TypeOf a, set[TypeOf] alts)
	//| eq(TypeOf a, set[TypeSymbol] altts)
    | subtyp(TypeOf a, TypeOf t)
    | subtyp(TypeOf a, TypeSymbol ts)
    //| subtyp(TypeOf a, set[TypeOf] alts)
    //| subtyp(TypeOf a, set[TypeSymbol] altts)
   
   	// query the m3 to solve these 
    | isMethodName(TypeOf a, str name)
    | hasMethod(TypeOf a, str name)
    | hasMethod(TypeOf a, str name, set[ModifierConstraint] modifiers)
    
    | conditional(Constraint preCondition, Constraint result)
    | disjunction(set[Constraint] constraints)
    | exclusiveDisjunction(set[Constraint] constraints)
    | conjunction(set[Constraint] constraints) 
    | negation(Constraint constraint) 
    ;
    
data ModifierConstraint
	= required(set[Modifier] modifiers)
	| notAllowed(set[Modifier] modifiers)
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