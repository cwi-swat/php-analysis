module lang::php::analysis::includes::IncludeGraph

import lang::php::ast::AbstractSyntax;
import lang::php::stats::Stats;
import lang::php::util::LocUtils;
import lang::php::analysis::evaluators::AlgebraicSimplification;
import lang::php::analysis::evaluators::SimulateCalls;
import lang::php::analysis::includes::LibraryIncludes;

import analysis::graphs::Graph;
import String;
import Set;
import Relation;

data IncludeGraphNode = igNode(str fileName, loc fileLoc) | libNode(str libName, str libPath) | unknownNode() | multiNode(set[IncludeGraphNode] alts);
data IncludeGraphEdge = igEdge(IncludeGraphNode source, IncludeGraphNode target, Expr includeExpr);
data IncludeGraph = igGraph(map[loc,IncludeGraphNode] nodes, set[IncludeGraphEdge] edges);

public IncludeGraph extractIncludeGraph(map[loc fileloc, Script scr] scripts, loc productRoot, set[LibItem] libraries) {
	int sizeToRemove = size(productRoot.path);
	map[loc,IncludeGraphNode] nodeMap = ( l:igNode(substring(l.path,sizeToRemove),l) | l <- scripts ) + (|file:///synthesizedLoc/<lib.path>| : libNode(lib.name,lib.path) | lib <- libraries);
	set[IncludeGraphEdge] edgeSet = { };
	
	for (l <- scripts) {
		includes = fetchIncludeUses(scripts[l]);
		for (iexp:include(e,itype) <- includes) {
			solve(e) {
				e = algebraicSimplification(simulateCalls(e));
			}
			if (scalar(string(sp)) := e) {
				try {
					iloc = calculateLoc(scripts<0>,l,productRoot,sp,true,[]);
					edgeSet += igEdge(nodeMap[l],nodeMap[iloc],iexp[expr=e]);					
				} catch UnavailableLoc(_) : {
					edgeSet += igEdge(nodeMap[l],unknownNode(),iexp[expr=e]);
				}
			} else {
				edgeSet += igEdge(nodeMap[l],unknownNode(),iexp[expr=e]);
			}
		}
	}
	
	return igGraph(nodeMap,edgeSet);
}

public Graph[str] collapseToGraph(IncludeGraph ig) {
	return { < fn1, fn2 > | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges };
}

public Graph[loc] collapseToLocGraph(IncludeGraph ig) {
	return { < fl1, fl2 > | igEdge(igNode(_,fl1),igNode(_,fl2),_) <- ig.edges };
}

public Graph[IncludeGraphNode] collapseToNodeGraph(IncludeGraph ig) {
	return { < n1, n2 > | igEdge(n1,n2,_) <- ig.edges };
}

public IncludeGraphNode nodeForLoc(IncludeGraph ig, loc l) {
	matches = { n | n:igNode(_,l) <- ig.nodes };
	if (size(matches) > 1) throw "WARNING: We should only have one node for each location";
	if (size(matches) == 0) throw "WARNING: We should have at least one node for each location";
	return getOneFrom(matches);
}
