module lang::php::types::TypeConstraints

import lang::php::ast::AbstractSyntax;
import lang::php::types::TypeSymbol;

alias TypeFacts = rel[loc decl, Fact fact];

// these facts can be extracted from the M3.
//data Fact
//	= className(str name) // = FQN (= fully qualified name) 
//	| classMethod(str name)
//	| classProperty(str name)
//	| classConstant(str name)
//	| classConstructorParameters(PhpParams params)
//	| methodName(str name)
//	| methodParameters(PhpParams params)
//	| functionName(str name) 
//	| functionParameters(PhpParams params)
//	;

data TypeEnvironment
	= var()
	| method()
	;
	
data TypeOf 
	= typeOf(loc ident)
	| typeOf(TypeSymbol ts)
	| arrayType(set[TypeOf] expressions)
	;

data Constraint 
	= eq(TypeOf a, TypeOf t)
	| eq(TypeOf a, TypeSymbol ts)
    | subtyp(TypeOf a, TypeOf t)
    | subtyp(TypeOf a, TypeSymbol ts)
    | supertyp(TypeOf a, TypeOf t)
    | supertyp(TypeOf a, TypeSymbol ts)
  
  	| lub(set[TypeOf] elms) 
  	
   	// query the m3 to solve these 
    | isAFunction(TypeOf a)
    | isAMethod(TypeOf a)
    | hasName(TypeOf a, str name)
    
    | isItemOfClass(TypeOf a, TypeOf t)
    | hasMethod(TypeOf a, str name)
    | hasMethod(TypeOf a, str name, set[ModifierConstraint] modifiers)
    //| parentHasMethod(TypeOf a, str name)
    //| parentHasMethod(TypeOf a, str name, set[ModifierConstraint] modifiers)
    
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

//
// do not use typesets (can be added later to boost performance of solving constraints)
//
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
	
TypeSet Set({\any()})        = Root();
TypeSet Set({})              = EmptySet();
TypeSet Single(TypeSymbol T) = Set({T});

TypeSet Subtypes(Root())              = Universe();
TypeSet Subtypes(EmptySet())          = EmptySet();
TypeSet Subtypes(Universe())          = Universe();
TypeSet Subtypes(Subtypes(TypeSet x)) = Subtypes(x);

TypeSet Intersection ({x}) = x;
TypeSet Intersection ({Subtypes(TypeSet x), x, set[TypeSet] rest}) 
	= Intersection (Subtypes(x), rest);
TypeSet Intersection ({EmptySet(), set[TypeSet] _}) = EmptySet();
TypeSet Intersection ({Universe(), set[TypeSet] x}) = Intersection({x});
TypeSet Intersection ({set[TypeSet] _, EmptySet()}) = EmptySet();
TypeSet Intersection ({set[TypeSet] x, Universe()}) = Intersection({x});
//TypeSet Intersection ({EmptySet(), Set(set[TypeSet] _)}) = EmptySet();
//TypeSet Intersection ({Universe(), Set(set[TypeSet] x)}) = Intersection({x});
TypeSet Intersection ({Set(_), EmptySet()}) = EmptySet();
TypeSet Intersection ({x:Set(_), Universe()}) = Intersection({x});
TypeSet Intersection ({Set (set[TypeSymbol] t1), Set (set[TypeSymbol] t2), set[TypeSet] rest}) 
	= Intersection ({Set (t1 & t2), rest});

TypeSet Union({Universe(), set[TypeSet] _}) = Universe();
TypeSet Union({EmptySet(), set[TypeSet] x}) = Union({x});
TypeSet Union({set[TypeSet] _, Universe()}) = Universe();
TypeSet Union({set[TypeSet] x, EmptySet()}) = Union({x});
TypeSet Union({Set(set[TypeSymbol] t1), Set (set[TypeSymbol] t2), set[TypeSet] rest}) 
	= Union({Set(t1 + t2), rest});	