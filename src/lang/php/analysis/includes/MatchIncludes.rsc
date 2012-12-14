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
import lang::php::analysis::includes::IncludeGraph;
import lang::php::pp::PrettyPrinter;
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
	return ( l : matchIncludes(scripts<0>,scripts[l]) | l <- scripts );
}

// Attempt to resolve includes in the file by first building a pattern, based on the
// literal and variable parts of the file name, and then trying to find which files
// could match. We resolve if we only get one hit. Otherwise, we don't resolve, but
// we could at least reduce the number of possibilities to a more reasonable number.
//
//
// NOTE: The assumption in this code is that other steps to try to simplify the
// include have already been taken, e.g., constant substitution or algebraic
// simplification of string concatenations.
//
// TODO: Add code to do the latter. For now, if we don't resolve this, we just
// leave it alone.
public Script matchIncludes(set[loc] possibleIncludes, Script scr) {
	list[FNBits] flattenExpr(Expr e) {
		if (binaryOperation(l,r,concat()) := e) {
			return flattenExpr(l) + flattenExpr(r);
		} else if (scalar(string(s)) := e) {
			list[str] parts = split("/",s);
			while([a*,b,"..",c*] := parts) parts = [*a,*c];
			while([a*,".",c*] := parts) parts = [*a,*c];		
			return [ (p == "..") ? fnBit() : FNBits::lit(p) | p <- parts ];
		} else {
			return [ fnBit() ];
		}
	}
	
	str fnBits2Str(FNBits fnb) {
		str escaped(str c) = escape(c,("/" : "\\/"));
		switch(fnb) {
			case lit(s) : return intercalate("",[ "[<escaped(c)>]" | c <- tail(split("",s)) ]);
			case fnBit() : return "\\S+";
		}
	}
	
	// Assumption: we have already done the various scalar transformations, so we have made
	// the includes "as literal as possible". Now, using the information in any string literals
	// present in the include, we will match against the file names we have in the total
	// list of includable files.
	list[Expr] varIncludes = fetchIncludeUsesVarPaths(scr);
	map[Expr,Expr] replacementMap = ( );
	
	for (i:include(iexp,_) <- varIncludes) {
		list[FNBits] bits = flattenExpr(iexp);
		while([a*,fnBit(),fnBit(),b*] := bits) bits = [*a,fnBit(),*b];
		while([a*,lit(s1),lit(s2),b*] := bits) bits = [*a,lit("<s1>/<s2>"),*b];
		list[str] reList = [ fnBits2Str(b) | b <- bits ];
		str re = "^\\S*" + intercalate("",reList) + "$";
		//println("Trying regular expression <re>");
		filteredIncludes = [ l | l <- possibleIncludes, rexpMatch(l.path,re) ];
		//println("Found <size(filteredIncludes)> possible includes");
		if (size(filteredIncludes) == 1) {
			replacementMap[i] = scalar(string(filteredIncludes[0].path))[@at=iexp@at];
		} else {
			println("Could not replace <pp(iexp)> at <iexp@at>, found <size(filteredIncludes)> hits with rexp <re>");
		}	
	}
	
	scr = visit(scr) {
		case i:include(iexp,itype) => include(replacementMap[i],itype)[@at=i@at] when i in replacementMap
	}
	return scr;
}

public void blah(Script scr) {
	// First, develop the signature for what is needed; this can tell us what needs
	// to be (directly or indirectly) imported
	// NOTE: This is the problem with this technique -- the needed constants, etc could
	// be coming in indirectly...
	// So, do we just resolve them to try to resolve more constants, or do we use this
	// with the other matching info?
	
	// fetchClassConst(NameOrExpr className, str constName)
	
	// fetchConst(Name name)
	
	usedConstants = { n | /fetchConst(name(n)) := scr };
	usedClassConstants = { < cn, n > | /fetchClassConst(name(name(cn)), n) := scr };
	//usedClasses = 	
}
