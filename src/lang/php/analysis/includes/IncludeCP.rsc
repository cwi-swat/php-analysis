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
import vis::Figure;
import vis::Render; 
import Relation;
import Graph;
import util::Math;

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

public IncludeGraph extractIncludeGraph(rel[loc fileloc, Script scr] corpus, str productRoot) {
	int sizeToRemove = size(productRoot);
	map[loc,IncludeGraphNode] nodeMap = ( l:igNode(substring(l.path,sizeToRemove),l) | l <- corpus<0> );
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

public IncludeGraph computeGraph(rel[str product, str version, loc fileloc, Script scr] prod, str p, str v) {
	println("Solving scalars");
	prod2 = evalAllScalars(prod,p,v);
	println("Resolving includes using path pattern matching");
	prod3 = resolveIncludes(prod2,p,v);
	println("Extracting include graph");
	return extractIncludeGraph(prod3<2,3>,getCorpusItem(p,v).path);
}

public rel[str,str,IncludeGraph] computeGraphs() {
	rel[str,str,IncludeGraph] res = { };
	
	for (p <- getProducts(), v <- getVersions(p)) {
		println("Loading <p> version <v>");
		prod = loadProduct(p,v);
		println("Solving scalars");
		prod2 = evalAllScalars(prod,p,v);
		println("Resolving includes using path pattern matching");
		prod3 = resolveIncludes(prod2,p,v);
		println("Extracting include graph");
		res += < p, v, extractIncludeGraph(prod3<2,3>,getCorpusItem(p,v).path) >;
	}
	
	return res;
}

public void renderIncludeGraph(IncludeGraph ig) {
	nodes = [ box(text(fileName), id(fileName), size(40)) | igNode(fileName, fileLoc) <- ig.nodes ];
	edges = [ edge(fn1,fn2) | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges ];
	render(graph(nodes,edges,gap(40)));
}

public void renderIncludeGraphAsDot(IncludeGraph ig, str product, str version, loc writeTo) {
	nodes = [ "\"<fileName>\";" | igNode(fileName, fileLoc) <- ig.nodes ];
	edges = [ "\"<fn1>\" -\> \"<fn2>\";" | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges ];
	str dotGraph = "digraph \"includeGraph\" {
				   '	graph [ label = \"Include Graph for <product> version <version>\" ];
				   '	node [ color = white ];
				   '	<intercalate("\n", nodes)>
				   '	<intercalate("\n",edges)>
				   '}";
	writeFile(writeTo,dotGraph);
}

public Graph[str] collapseToGraph(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return collapseToGraph(getOneFrom(graphs[product,version]));
}

public Graph[str] collapseToGraph(IncludeGraph ig) {
	return { < fn1, fn2 > | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges };
}

public rel[str name, int direct, int indirect] calculateOutflow(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return calculateOutflow(getOneFrom(graphs[product,version]));
}

public rel[str name, int direct, int indirect] calculateOutflow(IncludeGraph ig) {
	rel[str name, int direct, int indirect] res = { };
	g = collapseToGraph(ig);
	for (igNode(fn,l) <- ig.nodes) {
		direct = (fn in g<0>) ? size(g[fn]) : 0;
		indirect = (fn in g<0>) ? size((g+)[fn]) : 0;
		res += < fn, direct, indirect >;
	}
	return res;
}

public rel[str name, int direct, int indirect] calculateInflow(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return calculateInflow(getOneFrom(graphs[product,version]));
}

public rel[str name, int direct, int indirect] calculateInflow(IncludeGraph ig) {
	rel[str name, int direct, int indirect] res = { };
	g = invert(collapseToGraph(ig));
	for (igNode(fn,l) <- ig.nodes) {
		direct = (fn in g<0>) ? size(g[fn]) : 0;
		indirect = (fn in g<0>) ? size((g+)[fn]) : 0;
		res += < fn, direct, indirect >;
	}
	return res;
}

public real listMean(list[int] l) = (( 0 | it + n | n <- l) * 1.0) / size(l) when size(l) > 0;
public real listMean(list[int] l) = 0 when size(l) == 0;

public real listMedian(list[int] l) = (ls[size(l)/2-1] + ls[size(l)/2]) * 1.0 / 2 when size(l) % 2 == 0 && ls := sort(l);
public real listMedian(list[int] l) = ls[size(l)/2] * 1.0 when size(l) % 2 == 1 && ls := sort(l);

data InOutStats = ios(real meanDirectInflow, real meanIndirectInflow, real meanDirectOutflow, real meanIndirectOutflow,
					  real medianDirectInflow, real medianIndirectInflow, real medianDirectOutflow, real medianIndirectOutflow);
					  
public InOutStats calculateStats(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return calculateStats(getOneFrom(graphs[product,version]));
}

public InOutStats calculateStats(IncludeGraph ig) {
	real round2(real r) = round(r*100)/100.0;
	
	outflow = calculateOutflow(ig);
	inflow = calculateInflow(ig);
	
	directOutflow = [ i | < n,i,_> <- outflow ];
	indirectOutflow = [ i | < n,_,i> <- outflow ];
	directInflow = [ i | <n,i,_> <- inflow ];
	indirectInflow = [ i | < n,_,i > <- inflow ];
	
	return ios(round2(listMean(directInflow)), round2(listMean(indirectInflow)), 
			   round2(listMean(directOutflow)), round2(listMean(indirectOutflow)),
	           round2(listMedian(directInflow)), round2(listMedian(indirectInflow)), 
	           round2(listMedian(directOutflow)), round2(listMedian(indirectOutflow)));
}

public map[int,int] directOutflowDist(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return directOutflowDist(getOneFrom(graphs[product,version]));
}

public map[int,int] directOutflowDist(IncludeGraph ig) {
	map[int,int] res = ( );
	g = collapseToGraph(ig);
	for (igNode(nn,_) <- ig.nodes) {
		edgeCount = size(g[nn]);
		if (edgeCount in res) res[edgeCount] += 1; else res[edgeCount] = 1;
	}
	return res;
}

public map[int,int] indirectOutflowDist(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return indirectOutflowDist(getOneFrom(graphs[product,version]));
}

public map[int,int] indirectOutflowDist(IncludeGraph ig) {	
	map[int,int] res = ( );
	g = collapseToGraph(ig);
	for (igNode(nn,_) <- ig.nodes) {
		edgeCount = size((g+)[nn]);
		if (edgeCount in res) res[edgeCount] += 1; else res[edgeCount] = 1;
	}
	return res;
}

public int directOutflowUnknownCount(rel[str,str,IncludeGraph] graphs, str product, str version) {
	return directOutflowUnknownCount(getOneFrom(graphs[product,version]));
}

public int directOutflowUnknownCount(IncludeGraph ig) {
	return size( { nn | igNode(nn,_) <- ig.nodes, igEdge(igNode(nn,_),igNode("UNCOMPUTABLE",_),_) <- ig.edges } );
}

