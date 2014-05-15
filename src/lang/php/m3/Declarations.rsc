module lang::php::m3::Declarations

import lang::php::m3::Core;

// TODO add #decl annotations on define calls

public loc standardLibraryLoc = |php://stdlib|;

public M3 addPredefinedDeclarations(M3 m3)
{
	// alternative: call get_declared_classes()
	predefinedClasses = {"stdClass", "Directory", "__PHP_Incomplete_Class", "Exception", "ErrorException", "php_user_filter", "Closure", "Generator"};
	predefinedInterfaces = {"Traversable", "Iterator", "IteratorAggregate", "ArrayAccess", "Serializable"};

	predefinedTypes = {"class"} * predefinedClasses + {"interface"} * predefinedInterfaces;

	m3@declarations += { <|php+<\type>:///<normalizeName(name, \type)>|, standardLibraryLoc> | <\type, name> <- predefinedTypes };

	return m3;
}



