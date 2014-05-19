module lang::php::m3::Uses

import lang::php::m3::Core;
import lang::php::ast::AbstractSyntax;
import lang::php::pp::PrettyPrinter;
import lang::php::\syntax::Names;

import Prelude;
import Traversal;


public M3 calculateUsesFlowInsensitive(M3 m3, node ast)
{
	visit (ast)
	{
		// classes, interfaces and traits use
		case class(_, _, extends, implements, _):
		{
			if (someName(className) := extends)
			{
				m3 = addUse(m3, className, "class");
			}
		
			for (interfaceName <- implements)
			{
				m3 = addUse(m3, interfaceName, "interface");
			}				
		}
		
		case interface(_, extends, _):
		{
			for (interfaceName <- extends)
			{
				m3 = addUse(m3, interfaceName, "interface");
			}		
		}
		
		case traitUse(names, _):
		{
			for (name <- names)
			{
				m3 = addUse(m3, name, "trait");
			}
		}
		
		case new(nameOrExprNode, _):
		{
			m3 = addUse(m3, nameOrExprNode, "class");			
		}

		// parameter type hints
		
		case param(_, _, someName(nameNode), _):
		{
			if (nameNode.name notin ["array", "callable"])
			{
				for (\type <- ["class", "interface"])
				{
					m3 = addUse(m3, nameNode, \type);
				}
			}
		}

		// static references
		
		case fetchClassConst(nameNode, _):
		{
			m3 = addUseStaticRef(m3, nameNode);
		}
		
		case staticCall(nameNode, _, _):
		{
			m3 = addUseStaticRef(m3, nameNode);			
		}
		
		case staticPropertyFetch(nameNode, _):
		{
			m3 = addUseStaticRef(m3, nameNode);
		}
		
		// type operators
		
		case instanceOf(_, name(n:name(phpName))):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, n@at, phpName, \type, n@scope);
			}
		}
		
		case c:call(name(name("is_a")), [_, actualParameter(s:scalar(string(typeName)), _), _*]):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, s@at, typeName, \type, c@scope);
			}
		}
		
		case c:call(name(name("is_subclass_of")), [_, actualParameter(s:scalar(string(typeName)), _), _*]):
		{
			// name is interpreted as fully qualified
			for (\type <- ["class", "interface"])
			{
				m3 = addUseFullyQualified(m3, s@at, typeName, \type, c@scope);
			}
		}

		// TODO class_exists() ?
		
		// method or property access
		
		case methodCall(_, methodName, _): // todo, actually resolve this.
		{
			// todo, arrays fail in pretty print
			m3@uses += {<methodName@at, |php+unresolved+method:///<ppVar(methodName)>|>};
		}
		
		case p:propertyFetch(_, propertyName): // todo, actually resolve this.
		{
			m3@uses += {<propertyName@at, |php+unresolved+field:///<ppVar(propertyName)>|>};
		}
		
		// function call and variable / const access
		
		case call(name(nameNode), _):
		{
			m3 = addUse(m3, nameNode, "function");
		}
		 	
		case v:var(varNode):
		{
			if (v@decl?) // Special case for assign with Operation. They can be both declarations AND uses
			{	
				parentNode = getTraversalContextNodes()[1];
				/* if parent is $i++; or $i += 1; */
				if (unaryOperation(_,_) := parentNode || assignWOp(_,_,_) := parentNode) {
					m3 = addVarUse(m3, varNode, v@at, varNode@scope);
				}
			} else { // add all vars uses that have no declarations
				m3 = addVarUse(m3, varNode, v@at, varNode@scope);
			}
			
		}
		
		case fetchConst(nameNode): // always global constant
		{
			m3 = addUse(m3, nameNode, "constant");
		}
		
		//case f:fetchArrayDim(var(name(name("GLOBALS"))), someExpr(scalar(string(str name)))):
		//{
		//	m3@uses += {<f@at, nameToLoc(name, "globalVar")>};
		//}
		case f:fetchArrayDim(otherVars:var(varNode), _): // other than global
		{
			m3 = addVarUse(m3, ppVar(varNode), otherVars@at, varNode@scope);
		}
		
		// closure captures
		
		case c:closure(_, _, closureUses, _, _):
		{
			for (cu:closureUse(var(varNode), _) <- closureUses)
			{
				m3 = addVarUse(m3, ppVar(varNode), cu@at, c@scope);
			}
		}
		
		// exception names in catch
		
		case \catch(nameNode, _, _):
		{
			for (\type <- ["class", "interface"])
			{
				m3 = addUse(m3, nameNode, \type);
			}
		}		
	}

	return m3;
}


public M3 addUse(M3 m3, NameOrExpr nameOrExpr, str \type)
{
	if (name(name) := nameOrExpr) {
		return addUse(m3, name, \type, name@scope);
	} else {
		return addUse(m3, nameOrExpr@at, ppVar(nameOrExpr), "unresolved+"+\type, nameOrExpr@scope);
	}
}

public M3 addUse(M3 m3, Name name, str \type)
{
	return addUse(m3, name@at, name.name, \type, name@scope); 
}

public M3 addUse(M3 m3, Name name, str \type, loc scope)
{
	return addUse(m3, name@at, name.name, \type, scope);
}


public M3 addUseFullyQualified(M3 m3, loc at, str name, str \type, loc scope)
{
	if (fullyQualified() !:= getNameQualification(name))
	{
		name = "/" + name;
	}
	
	return addUse(m3, at, name, \type, scope);
}


public M3 addUseStaticRef(M3 m3, NameOrExpr nameOrExpr) {
	if (name(name) := nameOrExpr) {
		return addUseStaticRef(m3, name);
	} else {
		// todo, check what values come in here
		return m3; // check is this needs some work
		//return addVarUse(m3, ppVar(nameOrExpr), pos, scope);
	}
}

public M3 addUseStaticRef(M3 m3, Name name)
{
	for (\type <- ["class", "interface"])
	{
		m3 = addUse(m3, name, \type);
	}

	return m3;
}

//public M3 addUseStaticRef(M3 m3, NameOrExpr nameOrExpr, loc currentNamespace)
//{
//	if (name(name) := nameOrExpr) {
//		m3 = addUse(m3, nameOrExpr, name.name, currentNamespace);
//	} else {
//		m3 = addUse(m3, nameOrExpr, ppVar(nameOrExpr), currentNamespace);
//	}
//	return m3;
//}
//
//public M3 addUseStaticRef(M3 m3, loc at, str name, loc currentNamespace)
//{
//	if (name notin ["static", "self", "parent"])
//	{
//		for (\type <- ["class", "interface"])
//		{
//			m3 = addUse(m3, at, name, \type, currentNamespace);
//		}
//	}
//
//	return m3;
//}


public M3 addUse(M3 m3, loc at, str name, str \type, loc scope)
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

	if (name in ["static", "self", "parent"])
	{
		// don't resolve these for now
		return m3;
	}
	
	switch(getNameQualification(name))
	{
		case fullyQualified():
		{
			fullyQualifiedName = nameToLoc(name, \type);
		}
		case qualified():
		{
			fullyQualifiedName = appendName(name, \type, getNamespace(scope));
		}
		case unqualified():
		{
			fullyQualifiedName = appendName(name, \type, getNamespace(scope));
			
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


M3 addVarUse(M3 m3, NameOrExpr nameOrExpr, loc pos, loc scope) {

	if (name(name) := nameOrExpr) {
		return addVarUse(m3, name.name, pos, scope);
	} else {
		return addVarUse(m3, ppVar(nameOrExpr), pos, scope);
	}
}
	
M3 addVarUse(M3 m3, str name, loc pos, loc scope)
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
	
	m3@uses += {<pos, |php+<\type>://<scope.path>/<name>|> | \type <- types};
	
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

@doc{
	Return a histogram stating the number of times a use is matched with a number of declarations.
}
public map[int, int] calculateResolutionHistogram(rel[loc, loc] useDecl)
{
	map[int, int] counts = ();
	map[loc, int] countPerLoc = countNumPossibleDeclarations(useDecl);

	// calculation written for efficiency
	for (i <- [0..20])
	{
		int c = 0;
		for (loc l <- countPerLoc)
		{
			if (countPerLoc[l] == i)
			{
				c += 1;
			}
		}

		counts[i] = c;
	}

	return counts;
}

@doc{
	Count the number of declarations that are matched to each use.
}
public map[loc, int] countNumPossibleDeclarations(rel[loc, loc] useDecl)
{
	// calculation written for efficiency
	set[loc] uses = domain(useDecl);
	map[loc, int] countPerLoc = toMapUnique(uses * {0});

	for (<u,d> <- useDecl)
	{
		if (d != unknownLocation)
		{
			countPerLoc[u] ? 0 += 1;
		}
	}

	return countPerLoc;
}

private str ppVar(node ast) {
	//println("ast: <ast>");
	str pretty = "";
	visit (ast) {
		case name(str name): pretty = name;
	}
	//println(pretty);
	return pretty;
}