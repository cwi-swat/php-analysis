module lang::php::analysis::cfg::Util

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::BasicBlocks;
import lang::php::analysis::NamePaths;
import analysis::graphs::Graph;
import Relation;
import Set;
import List;

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
	possibleMatches = { n | n:exprNode(e,_) <- cfg.nodes, e == expr, (e@at)?, (expr@at)?, e@at == expr@at };
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching expressions found";
	} else {
		throw "Unexpected error: no matching expressions found, <expr@at>";
	}
}

@doc{Given a location, find the node that represents the expression at this location}
public CFGNode findNodeForExpr(CFG cfg, loc l) {
	possibleMatches = { n | n:exprNode(e,_) <- cfg.nodes, (e@at)?, e@at == l };
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
	possibleMatches = { n | n:stmtNode(s,_) <- cfg.nodes, s == stmt, (s@at)?, (stmt@at)?, s@at == stmt@at };	
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
	possibleMatches = { n | n:stmtNode(s,_) <- cfg.nodes, (s@at)?, s@at == l };	
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

@doc{Return the location/path of the CFG for the node at the given location}
public loc findContainingCFGLoc(Script s, map[loc,CFG] cfgs, loc l) {
	
	for (/c:class(cname,_,_,_,mbrs) := s) {
		for (m:method(mname,_,_,params,body) <- mbrs, l < m@at) {
			return methodPath(cname,mname);
		}
	}
	
	for (/f:function(fname,_,params,body) := s, l < f@at) {
		return functionPath(fname);
	}
	
	return scriptPath();
}

@doc{Return the CFG for the node at the given location}
public CFG findContainingCFG(Script s, map[loc,CFG] cfgs, loc l) {
	return cfgs[findContainingCFGLoc(s, cfgs, l)];
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
		nodesToCheck = { n | n <- g[currentNode], n notin seenBefore };
		seenBefore = seenBefore + nodesToCheck;
		
		// Traverse all the paths through the reachable nodes
		traversalResult = { traverser(n) | n <- nodesToCheck };
		
		// If any of the paths returned false, return false, else return true
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

alias GatherResult[&T] = tuple[bool trueOnAllPaths, set[&T] results];

public GatherResult[&T] gatherOnAllReachedPaths(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred, bool(CFGNode cn) stop, &T (CFGNode cn) gather, bool includeStartNode = false) {
	GatherResult[&T] traverser(CFGNode currentNode) = traverser({currentNode});
	
	GatherResult[&T] traverser(set[CFGNode] currentNodes) {
		GatherResult[&T] res = < true, { } >;
		set[CFGNode] seenBefore = currentNodes;
		set[CFGNode] frontier = currentNodes;
		
		solve(res, frontier) {
			workingFrontier = frontier;
			// For any nodes on the frontier that meet the predicate, gather the info from those nodes
			for (n <- frontier) {
				if (isEntryNode(n) || isExitNode(n)) {
					return < false, { } >;
				} else if (pred(n)) {
					res.results = res.results + gather(n);
					// If this node satisfied the pred, we don't want to traverse through it
					workingFrontier = workingFrontier - n;
				} else if (stop(n)) {
					// TODO: See if we can merge this with check above...
					return < false, { } >;
				}
			}
			// Find the new frontier, which is the nodes reachable from the current frontier that we haven't seen before
			frontier = g[workingFrontier] - seenBefore;
			// Add the new frontier into the set of nodes we've already seen 
			seenBefore += frontier;
		}
		
		return res;
	}

//	GatherResult[&T] traverser(CFGNode currentNode) {
//		// If we get this far, we are at the end of the path and haven't satisfied the predicate.
//		// So, we will return false (we assume the predicate isn't looking for entry or exit nodes.
//		if (isEntryNode(currentNode) || isExitNode(currentNode)) {
//			return < false, {} >;
//		}
//		
//		// Assuming this is a normal node, check the predicate. If it is true, we return.
//		if (pred(currentNode)) {
//			return < true, { gather(currentNode) } >;
//		}
//		
//		if (stop(currentNode)) {
//			return < false, { } >;
//		}
//		
//		// Get the nodes that we need to check
//		nodesToCheck = { n | n <- g[currentNode], n notin seenBefore };
//		seenBefore = seenBefore + nodesToCheck;
//		
//		// Traverse all the paths through the reachable nodes
//		traversalResult = { traverser(n) | n <- nodesToCheck };
//
//		// If any of the paths returned false, return false, else return true with the gathered results
//		gr = < false notin { gr.trueOnAllPaths | gr <- traversalResult }, { *gr.results | gr <- traversalResult } >;
//		return gr;		
//	}
	
	if (includeStartNode) {
		return traverser(startNode);
	} else {
		return traverser(g[startNode]);
	}
}

@doc{Check to see if the predicate can be satisfied on all paths that reach the start node.}
public GatherResult[&T] gatherOnAllReachingPaths(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred, bool(CFGNode cn) stop, &T (CFGNode cn) gather, bool includeStartNode = false) {
	return gatherOnAllReachedPaths(invert(g), startNode, pred, stop, gather, includeStartNode = includeStartNode);
}

@doc{Find all matching cases on all reached paths.}
public set[&T] findAllReachedUntil(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred, bool(CFGNode cn) stop, &T (CFGNode cn) gather, bool includeStartNode = false) {
	set[&T] traverser(CFGNode currentNode) = traverser({currentNode});
	
	set[&T] traverser(set[CFGNode] currentNodes) {
		set[&T] res = { };
		set[CFGNode] seenBefore = currentNodes;
		set[CFGNode] frontier = currentNodes;
		
		solve(res, frontier) {
			// For any nodes on the frontier that meet the predicate, gather the info from those nodes
			for (n <- frontier, pred(n)) res = res + gather(n);
			// Narrow the frontier down to only those nodes that we can traverse through
			frontier = { n | n <- frontier, !isEntryNode(n), !isExitNode(n), !stop(n) };
			// Find the new frontier, which is the nodes reachable from the current frontier that we haven't seen before
			frontier = g[frontier] - seenBefore;
			// Add the new frontier into the set of nodes we've already seen 
			seenBefore += frontier;
		}
		
		return res;
	}
	
	if (includeStartNode) {
		return traverser(startNode);
	} else {
		return traverser(g[startNode]);
	}
}

@doc{Find all matched cases on all reaching paths.}
public set[&T] findAllReachingUntil(Graph[CFGNode] g, CFGNode startNode, bool(CFGNode cn) pred, bool(CFGNode cn) stop, &T (CFGNode cn) gather, bool includeStartNode = false) {
	return findAllReachedUntil(invert(g), startNode, pred, stop, gather, includeStartNode = includeStartNode);
}

public CFG removeNode(CFG inputCFG, CFGNode n) {
	// Get the edges into this node
	edgesInto = { e | e <- inputCFG.edges, e.to == n.l };
	
	// Get the edges from this node
	edgesFrom = { e | e <- inputCFG.edges, e.from == n.l };
	
	// Now, link up the nodes at each endpoint
	newEdges = { mergeEdges(e1,e2) | e1 <- edgesInto, e2 <- edgesFrom };
	
	return inputCFG[edges=inputCFG.edges - edgesInto - edgesFrom + newEdges ][nodes = inputCFG.nodes - n];
}

public FlowEdge mergeEdges(FlowEdge e1, FlowEdge e2) {
	// TODO: This just returns a normal edge, but we may want to return other edges
	// if one or both input edge are jump edges, conditionalEdges, etc
	return flowEdge(e1.from, e2.to);
}

// TODO: This uses a heuristic to optimize this, but does not take into
// account numbers of incoming edges, etc, just a forward layered flow through
// the CFG.
public list[CFGNode] buildForwardWorklist(CFG inputCFG) {
	startingNode = getEntryNode(inputCFG);
	list[CFGNode] res = [ startingNode ];
	g = cfgAsGraph(inputCFG);
	nextLayer = g[startingNode];
	while (!isEmpty(nextLayer)) {
		res = res + toList(nextLayer);
		nextLayer = g[nextLayer] - toSet(res);
	}
	return res; 
}