module lang::php::analysis::includes::IncludeGraph

import lang::php::ast::AbstractSyntax;
import lang::php::stats::Stats;
import analysis::graphs::Graph;
import lang::php::util::LocUtils;
import String;
import Set;
import Relation;

data IncludeGraphNode = igNode(str fileName, loc fileLoc) | unknownNode();
data IncludeGraphEdge = igEdge(IncludeGraphNode source, IncludeGraphNode target, Expr includeExpr);
data IncludeGraph = igGraph(set[IncludeGraphNode] nodes, set[IncludeGraphEdge] edges);

public IncludeGraph extractIncludeGraph(map[loc fileloc, Script scr] scripts, str productRoot) {
	int sizeToRemove = size(productRoot);
	map[loc,IncludeGraphNode] nodeMap = ( l:igNode(substring(l.path,sizeToRemove),l) | l <- scripts );
	set[IncludeGraphEdge] edgeSet = { };
	
	for (l <- scripts) {
		includes = fetchIncludeUses(scripts[l]);
		for (iexp:include(e,itype) <- includes) {
			if (scalar(string(sp)) := e) {
				try {
					iloc = calculateLoc(scripts<0>,l,sp);
					edgeSet += igEdge(nodeMap[l],nodeMap[iloc],iexp);					
				} catch UnavailableLoc(_) : {
					edgeSet += igEdge(nodeMap[l],unknownNode(),iexp);
				}
			} else {
				edgeSet += igEdge(nodeMap[l],unknownNode(),iexp);
			}
		}
	}
	
	return igGraph(nodeMap<1>,edgeSet);
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
