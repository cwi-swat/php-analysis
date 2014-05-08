@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::MatchIncludes

import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::stats::Stats;
import lang::php::util::Utils;
import lang::php::ast::System;
import lang::php::analysis::includes::IncludeGraph;
import lang::php::pp::PrettyPrinter;
import lang::php::util::LocUtils;
import Exception;
import IO;
import List;
import String;
import Set;
import Relation;
import util::Math;

data FNBits = lit(str s) | fnBit();

// This function just calls the next function on each script in the map. The bulk of
// what happens is done in the function below.
public map[loc fileloc, Script scr] matchIncludes(System sys, loc baseLoc) {
	println("MATCHING INCLUDE FILE PATTERNS");
	sys = ( l : matchIncludes(sys<0>,sys[l],baseLoc,[]) | l <- sys );
	println("MATCHING INCLUDE FILE PATTERNS FINISHED");
	return sys;	
}

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
		if(size(parts)==0) return [ lit("/") | idx <- [0..size(s)]];
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
		while([lit(".."),lit("/"),a*] := res) res = [*a];
		while([lit("."),lit("/"),a*] := res) res = [*a];
		while([lit(".."),a*] := res) res = [*a];
		while([lit("."), a*] := res) res = [*a];
		while([a*,lit("/"),lit("/"),b*] := res)
			res = [*a,lit("/"),*b];
		while([a*,lit("/"),lit(c),lit("/"),lit("."),lit("/"),d*] := res)
			res = [*a,lit("/"),lit(c),lit("/"),*d];
		while([a*,lit("/"),lit(c),lit("/"),lit(".."),lit("/"),d*] := res)
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

// TODO: Add support for library includes. This is only an issue were we
// to match an include that was both a library include and an include in
// our own system.
public IncludeGraphEdge matchIncludes(System sys, IncludeGraph ig, IncludeGraphEdge e, bool ipMayBeSet, list[str] ipath) {
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
	
	return e;
}

// TODO: Along with the system, we should also include known libraries here
public set[loc] matchIncludes(System sys, Expr includeExpr, loc baseLoc, set[loc] libs = { }) {
	// Create the regular expression representing the include expression
	str re = "^\\S*" + fnMatch(includeExpr.expr) + "$";

	// Filter the includes to just return those that match the regular expression
	set[loc] filteredIncludes = { l | l <- (sys<0> + libs), rexpMatch(l.path,re) }; 

	// Just return the result of applying the regexp match, we may want to do
	// some caching, etc here in the future	
	return filteredIncludes;	
}
