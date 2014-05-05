module lang::php::m3::Aliases

import lang::php::m3::Core;
import lang::php::ast::AbstractSyntax;
import lang::php::\syntax::Names;

import Prelude;


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
				m3 = addUseToAliases(m3, u, currentNamespace);
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
		
		// TODO global variable declarations (alias from local name to global name)
	}
	
	return m3;
}


public M3 addUseToAliases(M3 m3, Use u, loc currentNamespace)
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
