module lang::php::m3::Aliases

import lang::php::m3::Core;
import lang::php::ast::AbstractSyntax;
import lang::php::\syntax::Names;

import Prelude;


public M3 calculateAliasesFlowInsensitive(M3 m3, node ast)
{
	visit (ast)
	{
		case use(uses):
		{
			for (u <- uses)
			{
				m3 = addUseToAliases(m3, u, getNamespace(u@scope));
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
		
		case global(globals):
		{
			for (v:var(name(name(varName))) <- globals)
			{
				globalVar = nameToLoc(varName, "globalVar");
				loc scope = v@scope;				
			
				if (isNamespace(scope))
				{
					;// allowed but useless, ignore
				}
				else if (isFunction(scope))
				{
					m3@aliases += {<appendName(varName, "functionVar", scope), globalVar>};
				}
				elseif (isMethod(scope))
				{
					m3@aliases += {<appendName(varName, "methodVar", scope), globalVar>};
				}
				else
				{
					throw "Unknown variable scope type: <scope>";
				}				
			}
		}
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
	else if (use(name(n1), noName()) := u)
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
	m3@aliases += { <appendName(asName, \type, currentNamespace), nameToLoc(importedName, \type)> |
					\type <- ["class", "interface", "namespace"] };
	return m3;
}
