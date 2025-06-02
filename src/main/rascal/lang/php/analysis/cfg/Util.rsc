@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::cfg::Util

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::BasicBlocks;
import lang::php::analysis::NamePaths;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;

import analysis::graphs::Graph;
import Relation;
import Set;
import List;
import Node;
import Map;

public set[CFGNode] pred(CFG cfg, CFGNode n) {
	predlabels = { e.from | e <- cfg.edges, e.to == n.lab };
	return { nd | nd <- cfg.nodes, nd.lab in predlabels };
}

public set[CFGNode] pred(Graph[CFGNode] g, CFGNode n) = invert(g)[n];

public set[CFGNode] succ(CFG cfg, CFGNode n) {
	succlabels = { e.to | e <- cfg.edges, e.from == n.lab };
	return { nd | nd <- cfg.nodes, nd.lab in succlabels };
}

public set[CFGNode] succ(Graph[CFGNode] g, CFGNode n) = g[n];

public set[CFGNode] reachable(Graph[CFGNode] g, CFGNode n) = (g+)[n];

public set[CFGNode] reaches(Graph[CFGNode] g, CFGNode n) = (invert(g)+)[n];

@doc{Given an existing expression, find the node that represents this expression}
public CFGNode findNodeForExpr(CFG cfg, Expr expr) {
	possibleMatches = { n | n:exprNode(e,_) <- cfg.nodes, e == expr, (e.at.scheme != "unknown"), (expr.at.scheme != "unknown"), e.at == expr.at };
	if (size(possibleMatches) == 1) {
		return getOneFrom(possibleMatches);
	} else if (size(possibleMatches) > 1) {
		throw "Unexpected error: multiple matching expressions found";
	} else {
		throw "Unexpected error: no matching expressions found, <expr.at>";
	}
}

@doc{Given a location, find the node that represents the expression at this location}
public CFGNode findNodeForExpr(CFG cfg, loc l) {
	possibleMatches = { n | n:exprNode(e,_) <- cfg.nodes, (e.at.scheme != "unknown"), e.at == l };
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
	possibleMatches = { n | n:stmtNode(s,_) <- cfg.nodes, s == stmt, (s.at.scheme != "unknown"), (stmt.at.scheme != "unknown"), s.at == stmt.at };	
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
	possibleMatches = { n | n:stmtNode(s,_) <- cfg.nodes, (s.at.scheme != "unknown"), s.at == l };	
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
	possibleMatches = { n | n <- cfg.nodes, (n has stmt && (n.stmt.at.scheme != "unknown") && n.stmt.at == l) || (n has expr && (n.expr.at.scheme != "unknown") && n.expr.at == l) };
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
public loc findContainingCFGLoc(Script s, loc l) {
	
	// TODO: Add support for anonymous classes
	for (/class(cname,_,_,_,mbrs,_) := s) {
		for (m:method(mname,_,_,_,_,_,_) <- mbrs, l < m.at) {
			return methodPath(cname,mname);
		}
	}
	
	for (/f:function(fname,_,_,_,_,_) := s, l < f.at) {
		return functionPath(fname);
	}
	
	return scriptPath("");
}

@doc{Return the CFG for the node at the given location}
public CFG findContainingCFG(Script s, map[loc,CFG] cfgs, loc l) {
	return cfgs[findContainingCFGLoc(s, l)];
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

@doc{Remove a node from the CFG, relinking edges as necessary}
public CFG removeNode(CFG inputCFG, CFGNode n) {
	// Get the edges into this node
	edgesInto = { e | e <- inputCFG.edges, e.to == n.lab };
	
	// Get the edges from this node
	edgesFrom = { e | e <- inputCFG.edges, e.from == n.lab };
	
	// Now, link up the nodes at each endpoint
	newEdges = { mergeEdges(e1,e2) | e1 <- edgesInto, e2 <- edgesFrom };
	
	return inputCFG[edges=inputCFG.edges - edgesInto - edgesFrom + newEdges ][nodes = inputCFG.nodes - n];
}

public CFG removeNodes(CFG inputCFG, set[CFGNode] ns) {
	// Turn the edge relation into two maps: one with edges into nodes, one
	// with edges from nodes.
	map[Lab, FlowEdges] edgesIntoAllNodes = ( n.lab : { } | n <- inputCFG.nodes ); 
	map[Lab, FlowEdges] edgesFromAllNodes = ( n.lab : { } | n <- inputCFG.nodes );

	// Populate the edge maps
	for (e <- inputCFG.edges) {
		edgesFromAllNodes[e.from] += e;
		edgesIntoAllNodes[e.to] += e;
	}
	
	// Now, for each node that we will remove, link up their edges appropriately
	for (n <- ns) {
		// For node n, get the edges into this node
		FlowEdges edgesInto = edgesIntoAllNodes[n.lab];

		// For node n, get the edges from this node
		FlowEdges edgesFrom = edgesFromAllNodes[n.lab];
		
		// Compute the new edges we want to add; skip those that are self-loops
		FlowEdges newEdges = { mergeEdges(e1,e2) | e1 <- edgesInto, e1.from != n.lab, e2 <- edgesFrom, e2.to != n.lab };

		// Add the new edges into the appropriate maps
		for (ne <- newEdges) {
			edgesFromAllNodes[ne.from] += ne;
			edgesIntoAllNodes[ne.to] += ne;
		}
		
		// Remove the old edges from the appropriate maps. This is needed since we
		// have two references to each edge: one in the from map, one in the two.
		// So, all the "from" edges need to be removed from the appropriate "to"
		// map items, and all the "to" edges need to be removed from the appropriate
		// "from" map items. The only references will be left in the map elements
		// indexed by n, which will be removed eventually.
		for (e <- edgesInto) {
			edgesFromAllNodes[e.from] -= e;
		}
		for (e <- edgesFrom) {
			edgesIntoAllNodes[e.to] -= e;
		}
	}
	
	// Finally, remove the node from the into and from maps and update the nodes set
	edgesFromAllNodes = domainX(edgesFromAllNodes, { n.lab | n <- ns } );
	edgesIntoAllNodes = domainX(edgesIntoAllNodes, { n.lab | n <- ns } );
	inputCFG.nodes = inputCFG.nodes - ns;
	
	// Then updates the edges as well
	consolidatedFrom = { *ef | ef <- edgesFromAllNodes<1> };
	consolidatedTo = { *et | et <- edgesIntoAllNodes<1> };
	inputCFG.edges = consolidatedFrom + consolidatedTo;

	return inputCFG;
}

@doc{Turn condition edges into regular edges if the header for the associated condition is no longer present}
public CFG transformUnlinkedConditions(CFG inputCFG, set[CFGNode] alsoCheck = { }) {
	newEdges = { };
	presentHeaders = { n.lab | n <- inputCFG.nodes, n is headerNode };
	
	if (!isEmpty(alsoCheck)) {
		presentHeaders = presentHeaders - { n.lab | n <- alsoCheck };
	}
	
	for (e <- inputCFG.edges) {
		if (e is conditionTrueFlowEdge && e.header notin presentHeaders) {
			newEdges += flowEdge(e.from, e.to);
		} else if (e is conditionFalseFlowEdge && e.header notin presentHeaders) {
			newEdges += flowEdge(e.from, e.to);
		} else {
			newEdges += e;
		}
	}
	return inputCFG[edges=newEdges];
}

@doc{Merge two edges into a single edge from the source of the first to the target of the second}
public FlowEdge mergeEdges(FlowEdge e1, FlowEdge e2) {
	// TODO: Handle other cases if needed, we may need to merge
	// other conditions or handle combos of true and false edges...
	if (e1 is conditionTrueFlowEdge && e2 is flowEdge) {
		return e1[to = e2.to];
	}

	if (e2 is conditionTrueFlowEdge && e1 is flowEdge) {
		return e2[from = e1.from];
	}
	
	if (e1 is conditionFalseFlowEdge && e2 is flowEdge) {
		return e1[to = e2.to];
	}

	if (e2 is conditionFalseFlowEdge && e1 is flowEdge) {
		return e2[from = e1.from];
	}
	
	if (e1 is backEdge) {
		return e1[to = e2.to];
	}
	
	if (e2 is backEdge) {
		return e2[from = e1.from];
	}
	
	return flowEdge(e1.from, e2.to);
}

@doc{Remove any backedges from the CFG}
public CFG removeBackEdges(CFG inputCFG) {
	set[str] toRemove = { "backEdge", "jumpEdge", "conditionTrueBackEdge", "escapingBreakEdge", "escapingContinueEdge", "escapingGotoEdge" };
	newEdges = { e | e <- inputCFG.edges, getName(e) notin toRemove };
	return inputCFG[edges = newEdges];
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