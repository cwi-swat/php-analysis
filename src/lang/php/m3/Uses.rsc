module lang::php::m3::Uses

import lang::php::m3::Core;
import lang::php::ast::AbstractSyntax;
import lang::php::\syntax::Names;

import Prelude;


public M3 calculateUsesFlowInsensitive(M3 m3, Script script)
{
	m3 = calculateAliasesFlowInsensitive(m3, script);

	m3 = calculateUsesFlowInsensitive(m3, script, globalNamespace);
	
	return m3;
}


public M3 calculateUsesFlowInsensitive(M3 m3, node ast, loc currentNamespace)
{
	// for now, no methods/functions/variable names etc...

	top-down-break visit (ast)
	{
		case ns:namespace(name, body):
		{
			// TODO the same case statement appears in calculateAliases...., factor out into a visit with a parametric function?
			if (someName(name(phpName)) := name)
			{
				currentNamespace = ns@decl;
			}
			else
			{
				currentNamespace = globalNamespace;
			}
			
			m3 = calculateUsesFlowInsensitive(m3, script(body), currentNamespace); // hack, wrap body in a node
		}			

		case class(_, _, extends, implements, members):
		{
			if (someName(className) := extends)
			{
				m3 = addUse(m3, className, "class", currentNamespace);
			}
		
			for (interfaceName <- implements)
			{
				m3 = addUse(m3, interfaceName, "interface", currentNamespace);
			}		
		
			for (member <- members)
			{
				m3 = calculateUsesFlowInsensitive(m3, member, currentNamespace);
			}
		}
		
		case interface(_, extends, members):
		{
			for (interfaceName <- extends)
			{
				m3 = addUse(m3, interfaceName, "interface", currentNamespace);
			}		
		
			for (member <- members)
			{
				m3 = calculateUsesFlowInsensitive(m3, member, currentNamespace);
			}
		}
		
		case traitUse(names, _):
		{
			for (name <- names)
			{
				m3 = addUse(m3, name, "trait", currentNamespace);
			}
		}
		
		case new(name(nameNode), _):
		{
			m3 = addUse(m3, nameNode, "class", currentNamespace);
		}
		
		case param(_, _, someName(nameNode), _):
		{
			if (nameNode notin ["array", "callable"])
			{
				for (\type <- ["class", "interface"])
				{
					m3 = addUse(m3, nameNode, \type, currentNamespace);
				}
			}
		}
		
		case fetchClassConst(name(nameNode), _):
		{
			m3 = addUseStaticRef(m3, nameNode, currentNamespace);
		}
		
		case staticCall(name(nameNode), _, _):
		{
			m3 = addUseStaticRef(m3, nameNode, currentNamespace);
		}
		
		case staticPropertyFetch(name(nameNode), _):
		{
			m3 = addUseStaticRef(m3, nameNode, currentNamespace);
		}
		
		case instanceOf(_, n:name(name(phpName))):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, n@at, phpName, \type, currentNamespace);
			}
		}
		
		case call(name(name("is_a")), [_, actualParameter(s:scalar(string(typeName)), _), _*]):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, s@at, typeName, \type, currentNamespace);
			}
		}
		
		case call(name(name("is_subclass_of")), [_, actualParameter(s:scalar(string(typeName)), _), _*]):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, s@at, typeName, \type, currentNamespace);
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
			fullyQualifiedName = addNameToNamespace(name, \type, currentNamespace);
		}
		case unqualified():
		{
			fullyQualifiedName = addNameToNamespace(name, \type, currentNamespace);
			
			// TODO check if name is reference to internal PHP class or function
		}
	}
	
	return addUseSubstituteAliases(m3, at, fullyQualifiedName);
}

public M3 addUseSubstituteAliases(M3 m3, loc at, loc name)
{	
	set[loc] names;

	if (name in domain(m3@aliases))
	{
		// follow aliases to reach final type names
		// don't store intermediate names b/c they can't be aliases AND real type names at the same time
		names = (m3@aliases+)[name] & (range(m3@aliases) - domain(m3@aliases));
	}
	else
	{
		names = {name};
	}

	m3@uses += {<at, n> | n <-names };

	return m3;
}


public M3 calculateAliasesFlowInsensitive(M3 m3, Script script)
{
	return calculateAliasesFlowInsensitive(m3, script, globalNamespace);
}


public M3 calculateAliasesFlowInsensitive(M3 m3, node ast, loc currentNamespace)
{
	top-down-break visit (ast)
	{
		case ns:namespace(name, body):
		{
			if (someName(name(phpName)) := name)
			{
				currentNamespace = ns@decl;
			}
			else
			{
				currentNamespace = globalNamespace;
			}
			
			m3 = calculateAliasesFlowInsensitive(m3, script(body), currentNamespace); // hack, wrap body in a node
		}			
		
		case use(uses):
		{
			for (u <- uses)
			{
				m3 = addImportToAliases(m3, u, currentNamespace);
			}
		}	
		
		case call(name(name("class_alias")),
			[actualParameter(scalar(string(oldName)), _), actualParameter(scalar(string(newName)), _), _*]):
		{
			// both names are interpreted as fully qualified
			
			// also works for interfaces
			// TODO traits?
			m3@aliases += { <nameToLoc(newName, \type), nameToLoc(oldName, \type)> |
					\type <- ["class", "interface"] };
		}
	}
	
	return m3;
}


public M3 addImportToAliases(M3 m3, Use u, loc currentNamespace)
{
	str importedName, asName;
	
	if (use(name(n1), someName(name(n2))) := u)
	{
		importedName = n1;
		asName = n2;
	}
	else if (use(name(importedName), noName()) := u)
	{
		importedName = n1;
		asName = getLastNamePart(importedName);
	}
	else
	{
		throw "unknown use: <u>";
	}
	
	/* PHP namespaces support three kinds of aliasing or importing:
		- aliasing a class name,
		- aliasing an interface name,
		- and aliasing a namespace name
	*/
		
	// assume asName is a simple name
	// TODO: can asName be (fully) qualified?	
	m3@aliases += { <addNameToNamespace(asName, \type, currentNamespace), nameToLoc(importedName, \type)> |
					\type <- ["class", "interface", "namespace"] };
	return m3;
}


public M3 addUseAndAlias(M3 m3, loc oldName, loc oldNameLoc, loc newName)
{
	m3 = addUseSubstituteAliases(m3, oldNameLoc, oldName);

	m3@aliases += {newName, oldName};
	
	return m3;
} 
