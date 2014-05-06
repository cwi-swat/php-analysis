module lang::php::ast::Scopes

import lang::php::ast::AbstractSyntax;

import Node;

@doc{
	Propagate the @decl annotations on nodes to the @scope of their children.
}
public &T <: node annotateWithDeclScopes(&T <: node t, loc scope)
{
	t@scope = scope;
	
	if ((t@decl)?)
	{
		scope = t@decl;
	}
	
	// alternative: makeNode(getName(t),[ top-down-break visit(c) { case ... } | c <- getChildren(t) ]) 
	for (i <- [0..arity(t)])
	{
		t[i] = top-down-break visit (t[i])
		{
			case node n => annotateWithDeclScopes(n, scope)
		}
	}
	
	return t;
}
