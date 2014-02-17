module lang::php::analysis::includes::ScriptResolve

import lang::php::ast::AbstractSyntax;
import lang::php::util::Utils;
import lang::php::util::LocUtils;
import lang::php::util::System;
import lang::php::analysis::includes::IncludesInfo;
import lang::php::analysis::includes::MatchIncludes;

import Set;
import Relation;
import String;

private Expr replaceConstants(Expr e, IncludesInfo iinfo) {
	return bottom-up visit(e) {
		case fc:fetchConst(name(cn)) => (iinfo.constMap[cn])[@at=fc@at]
			when cn in iinfo.constMap
			
		case fcc:fetchClassConst(name(name(cln)),cn) => (iinfo.classConstMap[cln][cn])[@at=fcc@at]
			when cln in iinfo.classConstMap && cn in iinfo.classConstMap[cln]
	}
}

public rel[loc,loc] grabScript(System sys, str p, str v, IncludesInfo iinfo, loc toResolve, loc baseLoc) =
	quickResolve(sys, p, v, iinfo, toResolve, baseLoc);
	
public rel[loc,loc] scriptResolve(System sys, str p, str v, loc toResolve, loc baseLoc) {
	rel[loc,loc] resolved = { };
	set[loc] unresolvable = { };
	
	Script scr = sys[toResolve];
	includes = { < i@at, i > | /i:include(_,_) := scr };
	if (size(includes) == 0) return resolved;
		
	// Step 1: run the quick includes over the script. This will fully
	// resolve some of the includes, partially resolve some others (maybe),
	// and perform simplifications
	IncludesInfo iinfo = loadIncludesInfo(p, v);
	quickResolved = grabScript(sys, p, v, iinfo, toResolve, baseLoc);
	
	// Step 2: The quick resolve tells us what is reachable. If we were
	// able to resolve everything to a unique file, bring each of these
	// in recursively.
	unresolvable += { l | l <- includes<0>, l notin quickResolved<0> };
	  
	for (l <- includes<0>, l notin unresolvable) {
		if (size(quickResolved[l]) == 1) {
			;
		} else {
			;
		}
	}
	

	return resolved;
}