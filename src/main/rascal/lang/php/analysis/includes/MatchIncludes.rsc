@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::MatchIncludes

import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;
import lang::php::stats::Stats;
import lang::php::util::Utils;
import lang::php::ast::System;
import lang::php::pp::PrettyPrinter;
import lang::php::util::LocUtils;
import lang::php::analysis::includes::IncludeGraph;

import IO;
import List;
import String;
import Set;
import util::Math;

data FNBits = lit(str s) | fnBit();

private map[str, set[loc]] lookupCacheRE = ( );

public void clearLookupCache() { lookupCacheRE = ( ); }

private list[FNBits] fnModel(Expr e) {
	if (binaryOperation(l,r,concat()) := e) {
		return [ *fnModel(l), *fnModel(r) ];
	} else if (scalar(encapsed(el)) := e) {
		return [ *fnModel(eli) | eli <- el ];
	} else if (scalar(string(s)) := e) {
		if (trim(s) == "") return [ lit(s) ];
		list[str] parts = split("/",s);
		if(size(parts)==0) return [ lit("/") | _ <- [0..size(s)]];
		if (s[0] == "/" && trim(parts[0]) == "") parts = tail(parts);
		res = [ lit("/"), lit(p) | p <- parts ];
		if (parts[0] != "") res = tail(res);
		if (s[-1] == "/") res = res + lit("/"); 
		return res;
	} else {
		return [ fnBit() ];
	}
}

private str escaped(str c) {
	if (c notin {".","\\","/"}) return c;
	return "[<escape(c,("/" : "\\/"))>]";
}

private str fnMatch(Expr e) {
	list[FNBits] res = fnModel(e);
	lastFnBit = lastIndexOf(res, fnBit());
	if (lastFnBit != -1) res = res[lastFnBit..];
	
	solve(res) {
		while([lit(".."),lit("/"),*a] := res) res = [*a];
		while([lit("."),lit("/"),*a] := res) res = [*a];
		while([lit(".."),*a] := res) res = [*a];
		while([lit("."), *a] := res) res = [*a];
		while([*a,lit("/"),lit("/"),*b] := res)
			res = [*a,lit("/"),*b];
		while([*a,lit("/"),lit(c),lit("/"),lit("."),lit("/"),*d] := res)
			res = [*a,lit("/"),lit(c),lit("/"),*d];
		while([*a,lit("/"),lit(_),lit("/"),lit(".."),lit("/"),*d] := res)
			res = [*a,lit("/"),*d];
	}
	list[str] toMatch = [];
	for (ri <- res)
		if (lit(s) := ri)
			toMatch = toMatch + [ "<escaped(c)>" | c <- tail(split("",s)) ];
		else
			toMatch = toMatch + "\\S*";
	return intercalate("",toMatch);
}

public str showGeneratedRegex(str s) {
	return fnMatch(parsePHPExpression(s));
}

// TODO: Add support for library includes. This is only an issue were we
// to match an include that was both a library include and an include in
// our own system.
public IncludeGraphEdge matchIncludes(System _, IncludeGraph ig, IncludeGraphEdge e, bool _, list[str] _) {
	Expr attemptToMatch = e.includeExpr.expr;
	
	// If this is a literal, we can try to match it; if it is an fbBit, it is some
	// file name piece that we can't use in matching
	//if (lit(s) := matchItem) {
	// Create  regular expression for s, this is just s with special characters escaped
	str re = "^\\S*" + fnMatch(attemptToMatch) + "$";
	set[loc] filteredIncludes = { };
	if (re in lookupCacheRE) {
		filteredIncludes = lookupCacheRE[re];
	} else {	
		// Find any locations that match the regular expression
		filteredIncludes = { l | l <- ig.nodes<0>, rexpMatch(l.path,re) };
		lookupCacheRE[re] = filteredIncludes;
	}
		
	if (size(filteredIncludes) == 1) {
		return igEdge(e.source, ig.nodes[getOneFrom(filteredIncludes)], e.includeExpr);
	} else if (size(filteredIncludes) > 1 && size(filteredIncludes) < size(ig.nodes<0>)) {
		return igEdge(e.source, multiNode({ig.nodes[l] | l <- filteredIncludes}), e.includeExpr);
	} else {
		return igEdge(e.source, unknownNode(), e.includeExpr);
	}
}

// TODO: Along with the system, we should also include known libraries here
public set[loc] matchIncludes(System sys, Expr includeExpr, loc _, set[loc] libs = { }) {
	// Create the regular expression representing the include expression
	str re = "^\\S*" + fnMatch(includeExpr.expr) + "$";

	// Filter the includes to just return those that match the regular expression
	set[loc] filteredIncludes = { };
	try {
		filteredIncludes = { l | l <- (sys.files<0> + libs), rexpMatch(l.path,re) };
	} catch _ : {
		println("Error with regular expression");
	} 

	// Just return the result of applying the regexp match, we may want to do
	// some caching, etc here in the future	
	return filteredIncludes;	
}
