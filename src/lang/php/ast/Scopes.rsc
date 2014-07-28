module lang::php::ast::Scopes

import lang::php::ast::AbstractSyntax;

import Set;
import List;
import String;
import Node;

@doc{
	Propagate the @decl annotations on nodes to the @scope of their children.
	Only propagate a decl if its type is in allowedScopeTypes.
}
public &T <: node annotateWithDeclScopes(&T <: node t, loc scope, set[str] allowedScopeTypes)
{
	t@scope = scope;
	
	if (t@decl? && isAllowedScope(t@decl.scheme, allowedScopeTypes))
	{
		scope = t@decl;
	}
	
	// alternative: makeNode(getName(t),[ top-down-break visit(c) { case ... } | c <- getChildren(t) ]) 
	for (i <- [0..arity(t)])
	{
		t[i] = top-down-break visit (t[i])
		{
			case node n => annotateWithDeclScopes(n, scope, allowedScopeTypes)
		}
	}
	
	return t;
}

@memo private bool isAllowedScope(str scheme, set[str] allowedScopeTypes) = !isEmpty(schemeToSet(scheme) & allowedScopeTypes);
@memo private set[str] schemeToSet(str scheme) = toSet(split("+", scheme));