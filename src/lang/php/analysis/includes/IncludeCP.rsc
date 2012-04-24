@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::includes::IncludeCP

import lang::php::ast::AbstractSyntax;
import lang::php::util::Corpus;
import lang::php::analysis::evaluators::ScalarEval;
import lang::php::stats::Stats;
import lang::php::util::Utils;
import Exception;
import IO;
import List;
import String;
import Set;

data RuntimeException = CannotEval(Expr expr);

anno int Expr@includeId;

data FNBits = lit(str s) | fnBit();

public rel[str product, str version, loc fileloc, Script scr] resolveIncludes(rel[str product, str version, loc fileloc, Script scr] corpus, str p, str v) {
	return { < p, v, l, resolveIncludes(corpus<2>,s) > | < p,v,l,s> <- corpus };
}

@doc{Perform light-weight constant propagation and evaluation to attempt to resolve any
     expressions used in includes.}
public Script resolveIncludes(set[loc] possibleIncludes, Script scr) {
	list[FNBits] flattenExpr(Expr e) {
		if (binaryOperation(l,r,concat()) := e) {
			return flattenExpr(l) + flattenExpr(r);
		} else if (scalar(string(s)) := e) {
			list[str] parts = split("/",s);
			while([a*,b,"..",c*] := parts) parts = [*a,*c];
			while([a*,".",c*] := parts) parts = [*a,*c];		
			return [ (p == "..") ? fnBit() : lit(p) | p <- parts ];
		} else {
			return [ fnBit() ];
		}
	}
	
	str fnBits2Str(FNBits fnb) {
		switch(fnb) {
			case lit(s) : return intercalate("",[ "[<c>]" | c <- tail(split("",s)) ]);
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
		while([a*,lit(s1),lit(s2),b*] := bits) bits = [*a,lit(s1+s2),*b];
		list[str] reList = [ fnBits2Str(b) | b <- bits ];
		str re = "^\\S*" + intercalate("",reList) + "$";
		//println("Trying regular expression <re>");
		filteredIncludes = [ l | l <- possibleIncludes, rexpMatch(l.path,re) ];
		//println("Found <size(filteredIncludes)> possible includes");
		if (size(filteredIncludes) == 1) {
			replacementMap[i] = scalar(string(filteredIncludes[0].path))[@at=iexp@at];
		}	
	}
	
	scr = visit(scr) {
		case i:include(iexp,itype) => include(replacementMap[i],itype)[@at=i@at] when i in replacementMap
	}
	return scr;
}

public rel[str,str,loc,Expr] solveAndGather() {
	rel[str,str,loc,Expr] res = { };
	
	for (p <- getProducts(), v <- getVersions(p)) {
		println("Loading <p> version <v>");
		prod = loadProduct(p,v);
		println("Unresolved includes: <size(gatherIncludesWithVarPaths(prod,p,v))>");
		println("Solving scalars");
		prod2 = evalAllScalars(prod,p,v);
		println("Unresolved includes: <size(gatherIncludesWithVarPaths(prod2,p,v))>");
		println("Resolving includes using path pattern matching");
		prod3 = resolveIncludes(prod2,p,v);
		println("Unresolved includes: <size(gatherIncludesWithVarPaths(prod3,p,v))>");
		res += gatherIncludesWithVarPaths(prod3,p,v);
	}
	
	return res;
}

data IncludeGraphNode = igNode(str fileName, loc fileLoc);
data IncludeGraphEdge = igEdge(IncludeGraphNode source, IncludeGraphNode target, Expr includeExpr);
data IncludeGraph = igGraph(set[IncludeGraphNode] nodes, set[IncludeGraphEdge] edges);

public IncludeGraph extractIncludeGraph(rel[loc fileloc, Script scr] corpus) {
	map[loc,IncludeGraphNode] nodeMap = ( l:igNode(l.file,l) | l <- corpus<0> );
	loc unk = |file:///unknown|;
	nodeMap[unk] = igNode("UNCOMPUTABLE",unk);
	set[IncludeGraphEdge] edgeSet = { };
	
	for (<l,s> <- corpus) {
		includes = fetchIncludeUses(s);
		for (iexp:include(e,itype) <- includes) {
			if (scalar(string(sp)) := e) {
				try {
					iloc = calculateLoc(corpus<0>,l,sp);
					edgeSet += igEdge(nodeMap[l],nodeMap[iloc],iexp);					
				} catch UnavailableLoc(_) : {
					edgeSet += igEdge(nodeMap[l],nodeMap[unk],iexp);
				}
			} else {
				edgeSet += igEdge(nodeMap[l],nodeMap[unk],iexp);
			}
		}
	}
	
	return igGraph(nodeMap<1>,edgeSet);
}