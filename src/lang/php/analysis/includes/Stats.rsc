module lang::php::analysis::includes::Stats

import lang::php::analysis::includes::IncludeGraph;

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

public map[int,int] directOutflowDist(IncludeGraph ig) {
	map[int,int] res = ( );
	g = collapseToGraph(ig);
	for (igNode(nn,_) <- ig.nodes) {
		edgeCount = size(g[nn]);
		if (edgeCount in res) res[edgeCount] += 1; else res[edgeCount] = 1;
	}
	return res;
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

public int directOutflowUnknownCount(IncludeGraph ig) {
	return size( { nn | igNode(nn,_) <- ig.nodes, igEdge(igNode(nn,_),igNode("UNCOMPUTABLE",_),_) <- ig.edges } );
}
