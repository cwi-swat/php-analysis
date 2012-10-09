module lang::php::analysis::includes::IncludeGraph

import lang::php::ast::AbstractSyntax;
import lang::php::stats::Stats;
import analysis::graphs::Graph;

data IncludeGraphNode = igNode(str fileName, loc fileLoc);
data IncludeGraphEdge = igEdge(IncludeGraphNode source, IncludeGraphNode target, Expr includeExpr);
data IncludeGraph = igGraph(set[IncludeGraphNode] nodes, set[IncludeGraphEdge] edges);

public IncludeGraph extractIncludeGraph(map[loc fileloc, Script scr] scripts, str productRoot) {
	int sizeToRemove = size(productRoot);
	map[loc,IncludeGraphNode] nodeMap = ( l:igNode(substring(l.path,sizeToRemove),l) | l <- scripts );
	loc unk = |file:///unknown|;
	nodeMap[unk] = igNode("UNCOMPUTABLE",unk);
	set[IncludeGraphEdge] edgeSet = { };
	
	for (l <- scripts) {
		includes = fetchIncludeUses(scripts[l]);
		for (iexp:include(e,itype) <- includes) {
			if (scalar(string(sp)) := e) {
				try {
					iloc = calculateLoc(scripts<0>,l,sp);
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

public Graph[str] collapseToGraph(IncludeGraph ig) {
	return { < fn1, fn2 > | igEdge(igNode(fn1,_),igNode(fn2,_),_) <- ig.edges };
}

