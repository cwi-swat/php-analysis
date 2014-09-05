module lang::php::m3::Calls
extend lang::php::m3::Core;

import lang::php::m3::Uses;

public str unknownMethodScheme = "php+unknown+method"; 
public str unknownFieldScheme = "php+unknown+field"; 

public M3 gatherMethodCallsAndFieldAccesses(M3 m3, node ast)
{
	visit (ast)
    {
    	case c:call(name(functionNameNode), _):
    		m3@calls += { <c@scope, fn> | fn <- m3@uses[functionNameNode@at] };
    
		case m:methodCall(_, name(name(n)), _):
			m3@calls += { <m@scope, |<unknownMethodScheme>:///<n>|> };
		
		case s:staticCall(name(classNameNode), name(name(n)), _):
			m3@calls += { <s@scope, appendName(n, "method", cn)> | cn <- m3@uses[classNameNode@at] };
			
		case n:new(name(classNameNode), _):
			m3@calls += { <n@scope, appendName("__construct", "method", cn)> | cn <- m3@uses[classNameNode@at] };
/*    }
    
    return m3;
}


public M3 gatherFieldAccesses(M3 m3, ast)
{
	visit(ast)
	{*/
		case f:fetchClassConst(name(classNameNode), name(c)):
			m3@accesses += { <f@scope, appendName(c, "classConst", cn)> | cn <- m3@uses[classNameNode@at] };
			
		case p:propertyFetch(_, name(name(q))):
			m3@accesses += { <p@scope, |<unknownFieldScheme>:///<q>|> };
		
		case s:staticPropertyFetch(name(classNameNode), name(name(p))):
		 	m3@accesses += { <s@scope, appendName(p, "field", cn)> | cn <- m3@uses[classNameNode@at] };
	}
	
	// TODO $this
	
	return m3;
}

rel[loc, loc] resolveUnknownMethodCalls(M3 m3) = resolveUnknownMemberAccesses(m3, m3@calls, isMethod, unknownMethodScheme);

rel[loc, loc] resolveUnknownFieldAccesses(M3 m3) = resolveUnknownMemberAccesses(m3, m3@accesses, isField, unknownFieldScheme);


rel[loc, loc] resolveUnknownMemberAccesses(M3 m3, rel[loc, loc] accesses, bool(loc) isMember, str unknownMemberScheme)
{
	//qualifiedCalls = { <m, c> | <m, c> <- m3@calls, isMethod(m), isMethod(c) };
	//unqualifiedCalls = { <m, c> | <m, c> <- m3@calls, isMethod(m), c.scheme == "php+unknown+method" };
	
	unknownMembers = { c | c <- range(accesses), c.scheme == unknownMemberScheme };
	
	possibleMembers = { <m, p> | m <- unknownMembers, p <- m3@names[toLowerCase(m.file)], isMember(p) };	

	possibleMembers += (unknownMembers - domain(possibleMembers)) * {unknownLocation}; 

	return possibleMembers;
}



map[int, int] memberResolutionHistogram(rel[loc, loc] possibleMembers, M3 m3) {
	// group members of classes with the same base class

	descendants = (invert(m3@extends + m3@implements))+;
	
	LUBs = set[loc] (set[loc] types) {	
		return (types - descendants[types]);
	};

	rel[loc, loc] corrected = {};
	
	for (m <- domain(possibleMembers)) {		
		calledTypes = { *getMemberParents(p, m3) | p <- possibleMembers[m] };
		corrected += { <m,t> | t <- LUBs(calledTypes) };
	}
	
	return calculateResolutionHistogram(corrected);
}

