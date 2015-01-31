module lang::php::m3::Types
extend lang::php::m3::Core;

import lang::php::types::TypeSymbol;
import lang::php::types::TypeConstraints;

public M3 resolveTypes(M3 m3, System system) 
{
	set[Constraint] constraints = getConstraints(m3, system);
	
	return m3;
}

public set[Constraint] getConstraints(M3 m3, System system)
{
	set[TypeSymbol] types = getTypesOfSystem(m3, system);
	
	set[Constraint] constraints =  {};
	//set[Constraint] constraints = getConstraintsForSystem(m3, system);
	
	for (f <- system)
		constraints += getConstraintsForScript(m3, system[f]);
		
	return constraints; 
}

	// some information can be extracted from the m3 and we wont need to visit all the scripts of a system
public set[TypeSymbol] getTypesOfSystem(M3 m3, System system)
{
	set[TypeSymbol] types
		= { \class(decl) | decl <- classes(m3) } 
		+ { \interface(decl) | decl <- interfaces(m3) }
		;
	
	return {}; // todo fix
}

// find the constructor and return the types
public list[TypeSymbol] getParamsForClass(ClassDef c)
{
	return [];
}

public set[Constraint] getConstraintsForScript(M3 m3, Script script)
{

	// <: = is same or sub type
	
	// Declarations:
	
	
	// Constraints are:
	
	// $a = $b; typeOf($b) <: typeOf($a);	

	// variable within a scope ( global | function | method )
	// type of a variable is the disjunction of the types of all occurances within the scope
	
	// type of a ( function | method ) is the disjunction of the types of the return types
	
	// type of an input parameter is mixed(), or a subtype of the type hint
	
	return {}; // todo fix
}