module lang::php::analysis::includes::QuickResolve

import lang::php::ast::AbstractSyntax;
import lang::php::util::Utils;
import lang::php::util::LocUtils;
import lang::php::ast::System;
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

public rel[loc,loc] quickResolve(System sys, str p, str v, loc toResolve, loc baseLoc, set[loc] libs = { }) {
	IncludesInfo iinfo = loadIncludesInfo(p, v);
	return quickResolve(sys, iinfo, toResolve, baseLoc, libs=libs);
}

public rel[loc,Expr,loc] quickResolveExpr(System sys, IncludesInfo iinfo, loc toResolve, loc baseLoc, set[loc] libs = { }) {
	rel[loc,Expr,loc] resolved = { };

	Script scr = sys[toResolve];
	includes = { < i@at, i > | /i:include(_,_) := scr };
	if (size(includes) == 0) return resolved;
		
	// Step 1: simplify the include expression using a variety of techniques,
	// such as simulating function calls, replacing magic constants, and
	// performing string concatenations
	includes = { < l, normalizeExpr(replaceConstants(i,iinfo), baseLoc) > | < l, i > <- includes };
	
	// Step 2: if we have a scalar expression that is an absolute path, meaning
	// it starts with \ or /, then see if we can match it to a file, it should
	// be something in the set of files that make up the system; in this case we
	// should be able to match it to a unique file
	unresolved = includes;
	for (iitem:< _, i > <- includes, scalar(string(s)) := i.expr, size(s) > 0, s[0] in { "\\", "/"}) {
		try {
			iloc = calculateLoc(sys<0>,toResolve,baseLoc,s);
			resolved = resolved + <i@at, i, iloc >;
			unresolved = domainX(unresolved, {i@at});  
		} catch UnavailableLoc(_) : {
			;
		}
	}
	
	// Step 3: if we have a non-scalar expression, try matching to see if we can
	// match the include to one or more potential files; if this matches multiple
	// possible files, that's fine, this is a conservative estimation so we may
	// find files that will never actually be included in practice
	for (iitem:< _, i > <- unresolved) {
		possibleMatches = matchIncludes(sys, i, baseLoc, libs=libs);
		resolved = resolved + { < i@at, i, l > | l <- possibleMatches }; 
	}
	
	return resolved;
}

public rel[loc,loc] quickResolve(System sys, IncludesInfo iinfo, loc toResolve, loc baseLoc, set[loc] libs = { }) {
	return (quickResolveExpr(sys, iinfo, toResolve, baseLoc, libs=libs))<0,2>;
}