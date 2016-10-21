module lang::php::analysis::cfg::Util

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::BasicBlocks;
import lang::php::analysis::NamePaths;
import analysis::graphs::Graph;
import Relation;
import Set;

public set[CFGNode] pred(CFG cfg, CFGNode n) {
	predlabels = { e.from | e <- cfg.edges, e.to == n@lab };
	return { nd | nd <- cfg.nodes, nd@lab in predlabels };
}

public set[CFGNode] pred(Graph[CFGNode] g, CFGNode n) = invert(g)[n];

public set[CFGNode] succ(CFG cfg, CFGNode n) {
	succlabels = { e.to | e <- cfg.edges, e.from == n@lab };
	return { nd | nd <- cfg.nodes, nd@lab in succlabels };
}

public set[CFGNode] succ(Graph[CFGNode] g, CFGNode n) = g[n];

public set[CFGNode] reachable(Graph[CFGNode] g, CFGNode n) = g+[n];

public set[CFGNode] reaches(Graph[CFGNode] g, CFGNode n) = (invert(g)+)[n];

@doc{Given an existing expression, find the node that represents this expression}
public CFGNode findNodeForExpr(CFG cfg, Expr expr) {
	possibleMatches = { n | n:exprNode(e) <- cfg.nodes, e == expr, (e@at)?, (expr@at)?, e@at == expr@at };
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching expressions found";
	} else {
		throw "Unexpected error: no matching expressions found";
	}
}

@doc{Given a location, find the node that represents the expression at this location}
public CFGNode findNodeForExpr(CFG cfg, loc l) {
	possibleMatches = { n | n:exprNode(e) <- cfg.nodes, (e@at)?, e@at == l };
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching expressions found";
	} else {
		throw "Unexpected error: no matching expressions found";
	}
}

@doc{Given an existing statement, find the node that represents this statement}
public CFGNode findNodeForStmt(CFG cfg, Stmt stmt) {
	possibleMatches = { n | n:stmtNode(s) <- cfg.nodes, s == stmt, (s@at)?, (stmt@at)?, s@at == stmt@at };	
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching statements found";
	} else {
		throw "Unexpected error: no matching statements found";
	}
}

@doc{Given a location, find the node that represents the statement at this location}
public CFGNode findNodeForStmt(CFG cfg, loc l) {
	possibleMatches = { n | n:stmtNode(s) <- cfg.nodes, (s@at)?, s@at == l };	
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching statements found";
	} else {
		throw "Unexpected error: no matching statements found";
	}
}

@doc{Given the location, find the node at this location}
public CFGNode findNodeForLocation(CFG cfg, loc l) {
	possibleMatches = { n | n <- cfg.nodes, (n has stmt && (n.stmt@at)? && n.stmt@at == l) || (n has expr && (n.expr@at)? && n.expr@at == l) };
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching nodes found";
	} else {
		throw "Unexpected error: no matching nodes found";
	}
}

@doc{Given a starting node and the graph, see if the predicate is true on any successor nodes.}
public bool trueOnAReachedPath(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred) {
	for (n <- (g+)[startNode], pred(n)) {
		return true;
	}
	return false;
}

@doc{Given a starting node and the graph, see if the predicate is true on any predecessor nodes.}
public bool trueOnAReachingPath(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred) {
	return trueOnAReachedPath(invert(g), startNode, pred);
}

@doc{Return the CFG for the node at the given location}
public CFG findContainingCFG(Script s, map[NamePath,CFG] cfgs, loc l) {
	
	for (/c:class(cname,_,_,_,mbrs) := s) {
		for (m:method(mname,_,_,params,body) <- mbrs, l < m@at) {
			return cfgs[methodPath(cname,mname)];
		}
	}
	
	for (/f:function(fname,_,params,body) := s, l < f@at) {
		return cfgs[functionPath(fname)];
	}
	
	return cfgs[scriptPath()];
}

@doc{Check to see if the predicate can be satisfied on all paths from the start node.}
public bool trueOnAllReachedPaths(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred, bool includeStartNode = false) {
	set[CFGNode] seenBefore = { };
	
	bool traverser(CFGNode currentNode) {
		// If we get this far, we are at the end of the path and haven't satisfied the predicate.
		// So, we will return false (we assume the predicate isn't looking for entry or exit nodes.
		if (isEntryNode(currentNode) || isExitNode(currentNode)) {
			return false;
		}
		
		// Assuming this is a normal node, check the predicate. If it is true, we return.
		if (pred(currentNode)) {
			return true;
		}
		
		// Get the nodes that we need to check
		nodesToCheck = { n | n <- currentNode, n notin seenBefore };
		seenBefore = seenBefore + nodesToCheck;
		
		// Traverse all the paths through the reachable nodes
		traversalResult = { traverser(n) | n <- nodesToCheck };
		
		// If any of the paths returned false, return false, else return true;
		return false notin traversalResult;		
	}
	
	if (includeStartNode) {
		return traverser(startNode);
	} else {
		return false notin { traverser(n) | n <- g[startNode] };
	}
}

@doc{Check to see if the predicate can be satisfied on all paths that reach the start node.}
public bool trueOnAllReachingPaths(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred, bool includeStartNode = false) {
	return trueOnAllReachedPaths(invert(g), startNode, pred, includeStartNode = includeStartNode);
}