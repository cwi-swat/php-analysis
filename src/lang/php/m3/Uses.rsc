module lang::php::m3::Uses

import lang::php::m3::Core;
import lang::php::ast::AbstractSyntax;
import lang::php::\syntax::Names;

import Prelude;


public M3 calculateUsesFlowInsensitive(M3 m3, node ast)
{
	visit (ast)
	{
		// classes, interfaces and traits use

		case c:class(_, _, extends, implements, _):
		{
			currentNamespace = getNamespace(c@scope);
		
			if (someName(className) := extends)
			{
				m3 = addUse(m3, className, "class", currentNamespace);
			}
		
			for (interfaceName <- implements)
			{
				m3 = addUse(m3, interfaceName, "interface", currentNamespace);
			}				
		}
		
		case i:interface(_, extends, _):
		{
			for (interfaceName <- extends)
			{
				m3 = addUse(m3, interfaceName, "interface", getNamespace(i@scope));
			}		
		}
		
		case traitUse(names, _):
		{
			for (name <- names)
			{
				m3 = addUse(m3, name, "trait", getNamespace(name@scope));
			}
		}
		
		case new(name(nameNode), _):
		{
			m3 = addUse(m3, nameNode, "class", getNamespace(nameNode@scope));			
		}

		// parameter type hints
		
		case param(_, _, someName(nameNode), _):
		{
			if (nameNode notin ["array", "callable"])
			{
				for (\type <- ["class", "interface"])
				{
					m3 = addUse(m3, nameNode, \type, getNamespace(nameNode@scope));
				}
			}
		}

		// static references
		
		case fetchClassConst(name(nameNode), _):
		{
			m3 = addUseStaticRef(m3, nameNode, getNamespace(nameNode@scope));
		}
		
		case staticCall(name(nameNode), _, _):
		{
			m3 = addUseStaticRef(m3, nameNode, getNamespace(nameNode@scope));			
		}
		
		case staticPropertyFetch(name(nameNode), _):
		{
			m3 = addUseStaticRef(m3, nameNode, getNamespace(nameNode@scope));
		}
		
		// type operators
		
		case i:instanceOf(_, n:name(name(phpName))):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, n@at, phpName, \type, getNamespace(i@scope));
			}
		}
		
		case c:call(name(name("is_a")), [_, actualParameter(s:scalar(string(typeName)), _), _*]):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, s@at, typeName, \type, getNamespace(c@scope));
			}
		}
		
		case c:call(name(name("is_subclass_of")), [_, actualParameter(s:scalar(string(typeName)), _), _*]):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, s@at, typeName, \type, getNamespace(c@scope));
			}
		}
		
		// method or property access
		
		case methodCall(_, n:name(name(methodName)), parameters):
		{
			m3@uses += {<n@at, |php+unresolved+method:///<methodName>|>};
		}
		
		case propertyFetch(_, n:name(name(propertyName))):
		{
			m3@uses += {<n@at, |php+unresolved+field:///<propertyName>|>};
		}
		
		// function call and variable / const access
		
		case c:call(name(nameNode), _):
		{
			m3 = addUse(m3, nameNode, "function", getNamespace(c@scope));
		}
		
		case v:var(name(nameNode)):
		{
			if (!v@decl?) // don't add uses on declarations
			{
				m3 = addVarUse(m3, nameNode, v@at, nameNode@scope);
			}
		}
		
		case fetchConst(nameNode): // always global constant
		{
			m3 = addUse(m3, nameNode, "constant", getNamespace(nameNode@scope));
		}
		
		case f:fetchArrayDim(var(name(name("GLOBALS"))), someExpr(scalar(string(str name)))):
		{
			m3@uses += {<f@at, nameToLoc(name, "globalVar")>};
		}
		
		// closure captures
		
		case c:closure(_, _, closureUses, _, _):
		{
			for (closureUse(nameNode, _) <- closureUses)
			{
				m3 = addVarUse(m3, nameNode, closureUse@at, c@scope);
			}
		}
	}

	return m3;
}


public M3 addUse(M3 m3, Name name, str \type, loc currentNamespace)
{
	return addUse(m3, name@at, name.name, \type, currentNamespace);
}


public M3 addUseFullyQualified(M3 m3, loc at, str name, str \type, loc currentNamespace)
{
	if (fullyQualified() !:= getNameQualification(name))
	{
		name = "/" + name;
	}
	
	return addUse(m3, at, name, \type, currentNamespace);
}


public M3 addUseStaticRef(M3 m3, Name name, loc currentNamespace)
{
	if (name.name notin ["static", "self", "parent"])
	{
		for (\type <- ["class", "interface"])
		{
			m3 = addUse(m3, name@at, name.name, \type, currentNamespace);
		}
	}

	return m3;
}


public M3 addUse(M3 m3, loc at, str name, str \type, loc currentNamespace)
{
	/* from https://github.com/php/php-src/blob/master/README.namespaces#L83-111 :
	
	Names inside namespace are resolved according to the following rules:

	1) all qualified names are translated during compilation according to
	current import rules. So if we have "use A\B\C" and then "C\D\e()"
	it is translated to "A\B\C\D\e()".
	2) unqualified class names translated during compilation according to
	current import rules. So if we have "use A\B\C" and then "new C()" it
	is translated to "new A\B\C()".
	3) inside namespace, calls to unqualified functions that are defined in 
	current namespace (and are known at the time the call is parsed) are 
	interpreted as calls to these namespace functions.
	4) inside namespace, calls to unqualified functions that are not defined 
	in current namespace are resolved at run-time. The call to function foo() 
	inside namespace (A\B) first tries to find and call function from current 
	namespace A\B\foo() and if it doesn't exist PHP tries to call internal
	function foo(). Note that using foo() inside namespace you can call only 
	internal PHP functions, however using \foo() you are able to call any
	function from the global namespace.
	5) unqualified class names are resolved at run-time. E.q. "new Exception()"
	first tries to use (and autoload) class from current namespace and in case 
	of failure uses internal PHP class. Note that using "new A" in namespace 
	you can only create class from this namespace or internal PHP class, however
	using "new \A" you are able to create any class from the global namespace.
	6) Calls to qualified functions are resolved at run-time. Call to
	A\B\foo() first tries to call function foo() from namespace A\B, then
	it tries to find class A\B (__autoload() it if necessary) and call its
	static method foo()
	7) qualified class names are interpreted as class from corresponding
	namespace. So "new A\B\C()" refers to class C from namespace A\B.
	
	*/
	
	loc fullyQualifiedName;
	
	switch(getNameQualification(name))
	{
		case fullyQualified():
		{
			fullyQualifiedName = nameToLoc(name, \type);
		}
		case qualified():
		{
			fullyQualifiedName = appendName(name, \type, currentNamespace);
		}
		case unqualified():
		{
			fullyQualifiedName = appendName(name, \type, currentNamespace);
			
			// name could also be reference to internal PHP class or function.
			
			/*if (\type in ["class", "interface"]) // TODO and name is an internal name
			{				
				m3@uses += {<at, nameToLoc(name, \type)>}; // name in global namespace			
			}
			else */ if (\type in ["function"])
			{
				// Contrary to what it says at point 4, function name resolution falls back
				// to the global namespace, not only to internal function names. 
				m3@uses += {<at, nameToLoc(name, \type)>}; // name in global namespace
			}			
		}
	}
	
	m3@uses += {<at, fullyQualifiedName> };

	return m3;
}


M3 addVarUse(M3 m3, Name name, loc pos, loc scope)
{
	list[str] types;
	
	if (isNamespace(scope))
	{
		types = ["globalVar"];
		scope = globalNamespace;
	}
	else if (isFunction(scope))
	{
		types = ["functionVar", "functionParam"];
	}
	elseif (isMethod(scope))
	{
		types = ["methodVar", "methodParam"]; 
	}
	else
	{
		throw "Unknown variable scope type: <scope>";
	}
	
	m3@uses += {<pos, |php+<\type>://<scope.path>/<name.name>|> | \type <- types};
	
	return m3;
}


@doc{
	Extend uses relation by following alias links.
}
M3 propagateAliasesInUses(M3 m3)
{
	m3@uses += m3@uses o (m3@aliases)+;
	return m3;
}


@doc{
	Resolve names in uses range to source code locations of potentially matching declarations.
	Result: <position, position> relation, relating use sites to declaration sites.
}
rel[loc, loc] resolveUsesToPossibleDeclarations(M3 m3)
{
	set[loc] allUseSites = domain(m3@uses);

	rel[loc, loc] result = m3@uses o m3@declarations;
	
	// add tuples for unresolved uses
	result += (allUseSites - domain(result)) * {unknownLocation};
	
	return result;
}
