module lang::php::m3::Types

import lang::php::m3::Core;
import lang::php::ast::AbstractSyntax;
import lang::php::pp::PrettyPrinter;
import lang::php::\syntax::Names;

import Prelude;
import Traversal;

// in this first version
// only calculate the assign expressions
public M3 calculateTypesFlowInsensitive(M3 m3, node ast)
{
	visit (ast)
	{
		case _: ;
	}
	
	return m3;
}