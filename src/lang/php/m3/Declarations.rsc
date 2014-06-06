module lang::php::m3::Declarations
extend lang::php::m3::Core;

import lang::php::ast::Scopes;

public loc standardLibraryLoc = |php://stdlib|;

@doc {
	fill @declarations and @names
	
	@declarations are provided by the PHP-Parser [@decl]
	@names are the last part of the declaration 
}
public M3 fillDeclarations(M3 m3, Script script) {
	visit (script) {
		case node n: {
			if ( (n@at)? && (n@decl)? ) {
				m3@declarations += {<n@decl, n@at>};
				m3@names += {<n@decl.file, n@decl>};
			}
		}
   	}
   	return m3;
}


@doc {
When a class is inside a namespace, the only option for the constructor is "__construct"
When a class is defined outside a namespace, "__construct" will be the constructor. If this one
is not available, a method with the class name will be the constructor (and will also be a method)
}
public Script propagateDeclToScope(Script script) {
   	set[str] scopingTypes = {"namespace", "class", "interface", "trait", "function", "method"};
	return annotateWithDeclScopes(script, globalNamespace, scopingTypes);
}

public M3 addPredefinedDeclarations(M3 m3)
{
	// alternative: call get_declared_classes()
	predefinedClasses = {"stdClass", "Directory", "__PHP_Incomplete_Class", "Exception", "ErrorException", "php_user_filter", "Closure", "Generator"};
	predefinedInterfaces = {"Traversable", "Iterator", "IteratorAggregate", "ArrayAccess", "Serializable"};
	
	predefinedTypes = {"class"} * predefinedClasses + {"interface"} * predefinedInterfaces;

	m3@declarations += { <|php+<\type>:///<normalizeName(name, \type)>|, standardLibraryLoc> | <\type, name> <- predefinedTypes };
	
	return m3;
}



