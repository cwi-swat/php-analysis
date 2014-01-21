@license{
  Copyright (c) 2009-2011 CWI
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
import lang::php::util::System;
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
public map[loc fileloc, Script scr] matchIncludes(map[loc fileloc, Script scr] scripts) {
	println("MATCHING INCLUDE FILE PATTERNS");
	scripts = ( l : matchIncludes(scripts<0>,scripts[l]) | l <- scripts );
	println("MATCHING INCLUDE FILE PATTERNS FINISHED");
	return scripts;	
}

private FNBits lastLiteralPart(Expr e) {
	if (binaryOperation(l,r,concat()) := e) {
		return lastLiteralPart(r);
	} else if (scalar(encapsed(el)) := e) {
		return lastLiteralPart(last(el));
	} else if (scalar(string("/")) := e) {
		return fnBit();
	} else if (scalar(string(s)) := e) {
		if (trim(s) == "") return fnBit();
		
		list[str] parts = split("/",trim(s));
		lastDotDot = lastIndexOf(parts,"..");
		lastDot = lastIndexOf(parts,".");
		lastToUse = max(lastDotDot,lastDot);

		if (lastToUse == -1)
			return lit(s);
		else if (lastToUse >= 0 && (lastToUse+1) < size(parts))
			return lit(intercalate("/",drop(lastToUse+1,parts)));
		else
			return fnBit();
	} else {
		return fnBit();
	}
}

private str escaped(str c) = escape(c,("/" : "\\/"));

// TODO: Add support for library includes. This is only an issue were we
// to match an include that was both a library include and an include in
// our own system.
public IncludeGraphEdge matchIncludes(System sys, IncludeGraph ig, IncludeGraphEdge e) {
	Expr attemptToMatch = e.includeExpr.expr;

	// If the result is a scalar, just try to match it to an actual file; if we
	// cannot, continue with the more general matching attempt
	if (scalar(string(sp)) := attemptToMatch && size(sp) > 0 && sp[0] in { ".","\\","/"}) {
		try {
			iloc = calculateLoc(sys<0>,e.source.fileLoc,sp);
			return e[target=ig.nodes[iloc]];					
		} catch UnavailableLoc(_) : {
			;
		}
	} 

	// Find the part of the include expression that we may be able to match; this is
	// the last literal part of the string, after any . or .. path characters (we don't
	// use them to adjust to path because, in cases like $x../path/to/file, we don't
	// know what $x is, so we don't know if we can just "walk back" a step, so this
	// makes the match more conservative)
	matchItem = lastLiteralPart(attemptToMatch);
	
	// If this is a literal, we can try to match it; if it is an fbBit, it is some
	// file name piece that we can't use in matching
	if (lit(s) := matchItem) {
		// Create  regular expression for s, this is just s with special characters escaped
		str re = "^\\S*" + intercalate("",[ "[<escaped(c)>]" | c <- tail(split("",s)) ]) + "$";

		// Find any locations that match the regular expression
		filteredIncludes = { l | l <- ig.nodes<0>, rexpMatch(l.path,re) };
		
		if (size(filteredIncludes) == 1) {
			return igEdge(e.source, ig.nodes[getOneFrom(filteredIncludes)], e.includeExpr);
		} else if (size(filteredIncludes) > 1 && size(filteredIncludes) < size(ig.nodes<0>)) {
			return igEdge(e.source, multiNode({ig.nodes[l] | l <- filteredIncludes}), e.includeExpr);
		} else {
			return igEdge(e.source, unknownNode(), e.includeExpr);
		}
	}
	
	return e;
}
