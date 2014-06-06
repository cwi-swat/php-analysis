module lang::php::m3::Types
extend lang::php::m3::Core;

import lang::php::m3::TypeSymbol;

// in this first version always return mixed.
// only calculate the assign expressions
public M3 calculateTypesFlowInsensitive(M3 m3, Script ast)
{
	bottom-up visit (ast)
	{
		case e:expr(_):
			m3@types += { <e@at, mixed()> };
	
	    // method call and fetch	
		case methodCall(e,_,_):
			m3@types += { <e@at, mixed()> };
		
		case propertyFetch(Expr e, _):
			m3@types += { <e@at, mixed()> };
			
		// static call and fetch
		case staticCall(e:expr(_),_,_):
			m3@types += { <e@at, mixed()> };
		
	    case staticPropertyFetch(e:expr(_), _): {
			m3@types += { <e@at, mixed()> };
			fail;
		}
		
	    case staticPropertyFetch(_, e:expr(_)):
			m3@types += { <e@at, mixed()> };
		
	}
	
	return m3;
}