@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::includes::QuickResolve

import lang::php::ast::AbstractSyntax;
import lang::php::util::Utils;
import lang::php::util::LocUtils;
import lang::php::ast::System;
import lang::php::analysis::includes::IncludesInfo;
import lang::php::analysis::includes::MatchIncludes;
import lang::php::analysis::evaluators::Simplify;

import Set;
import Relation;
import String;

public Expr replaceConstants(Expr e, IncludesInfo iinfo) {
	return bottom-up visit(e) {
		case fc:fetchConst(name(cn)) => (iinfo.constMap[cn])[at=fc.at]
			when cn in iinfo.constMap
			
		case fcc:fetchClassConst(name(name(cln)),str cn) => (iinfo.classConstMap[cln][cn])[at=fcc.at]
			when cln in iinfo.classConstMap && cn in iinfo.classConstMap[cln]
	}
}

public rel[loc,loc] quickResolve(System sys, loc toResolve, set[loc] libs = { }, bool checkFS=false) {
	if (sys has name && sys has version && sys has baseLoc) {
		return quickResolve(sys, sys.name, sys.version, toResolve, sys.baseLoc, libs=libs, checkFS=checkFS);
	}
	throw "Provided system must have name, version, and baseLoc fields set";
}

public rel[loc,loc] quickResolve(System sys, str p, str v, loc toResolve, loc baseLoc, set[loc] libs = { }, bool checkFS=false) {
	IncludesInfo iinfo = loadIncludesInfo(p, v);
	return quickResolve(sys, iinfo, toResolve, baseLoc, libs=libs, checkFS=checkFS);
}

public rel[loc,Expr,loc] quickResolveExpr(System sys, IncludesInfo iinfo, loc toResolve, loc baseLoc, set[loc] libs = { }, bool checkFS=false) {
	rel[loc,Expr,loc] resolved = { };

	Script scr = sys.files[toResolve];
	rel[loc,Expr] includes = { < i.at, i > | /i:include(_,_) := scr };
	if (size(includes) == 0) return resolved;
		
	// Step 1: simplify the include expression using a variety of techniques,
	// such as simulating function calls, replacing magic constants, and
	// performing string concatenations
	includes = { < l, simplifyExpr(replaceConstants(i,iinfo), baseLoc) > | < l, i > <- includes };
	
	// Step 2: if we have a scalar expression that is an absolute path, meaning
	// it starts with \ or /, then see if we can match it to a file, it should
	// be something in the set of files that make up the system; in this case we
	// should be able to match it to a unique file
	unresolved = includes;
	for (< _, i > <- includes, scalar(string(s)) := i.expr, size(s) > 0, s[0] in { "\\", "/"}) {
		try {
			iloc = calculateLoc(sys.files<0>,toResolve,baseLoc,s,checkFS=checkFS);
			resolved = resolved + <i.at, i, iloc >;
			unresolved = domainX(unresolved, {i.at});  
		} catch UnavailableLoc(_) : {
			;
		}
	}
	
	// Step 3: if we have a non-scalar expression, try matching to see if we can
	// match the include to one or more potential files; if this matches multiple
	// possible files, that's fine, this is a conservative estimation so we may
	// find files that will never actually be included in practice
	for (< _, i > <- unresolved) {
		possibleMatches = matchIncludes(sys, i, baseLoc, libs=libs);
		resolved = resolved + { < i.at, i, l > | l <- possibleMatches }; 
	}
	
	return resolved;
}

public rel[loc,loc] quickResolve(System sys, IncludesInfo iinfo, loc toResolve, loc baseLoc, set[loc] libs = { }, bool checkFS=false) {
	return (quickResolveExpr(sys, iinfo, toResolve, baseLoc, libs=libs, checkFS=checkFS))<0,2>;
}