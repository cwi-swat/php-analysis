@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::BasicBlocks

import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::NamePaths;

import Relation;
import List;
import String;
import Set;
import IO;
import analysis::graphs::Graph;

data CFGNode = 	basicBlock(list[CFGNode] nodes);
data Lab = blockLabel(int id);

public str printCFGNode(basicBlock(list[CFGNode] nodes)) 
	= intercalate("\n", ["[<idx>] : <printCFGNode(nodes[idx])>"|idx<-index(nodes)]);

public CFG createBasicBlocks(CFG g) {
	entryNode = getEntryNode(g);
	exitNode = getExitNode(g);
	forwards = cfgAsGraph(g);
	backwards = invert(forwards);
	set[CFGNode] basicBlocks = { };
	blockId = 1;
	
	// First, identify all the basic block "headers". The headers are either merge points
	// (the first line), jump targets from split points (the second line), or the entry
	// node for the function/method/script (last line). We also treat all join nodes
	// as headers, since these tend to be jump targets (this is a judgement call, since
	// in some cases there is only one incoming edge). 
	headerNodes = { n | n <- (g.nodes - entryNode), size(backwards[n]) > 1 } + 
				  { n | n <- (g.nodes - entryNode), size(backwards[n]) == 1, size(forwards[backwards[n]]) > 1 } +
				  { n | n <- (g.nodes - entryNode), n is footerNode } +
				  forwards[entryNode] +
				  exitNode +
				  entryNode;
	
	// Now, for each header node, add in all the reachable nodes until we find
	// a) another header node, or b) a node with multiple out edges.
	for (hn <- headerNodes) {
		nodeList = [ hn ];
		currentNode = hn;
		while (size(forwards[currentNode]) == 1) {
			currentNode = getOneFrom(forwards[currentNode]);
			if (currentNode in headerNodes) break;
			nodeList += currentNode;
		}
		basicBlocks += basicBlock(nodeList)[lab=blockLabel(blockId)];
		blockId += 1;	
	}

	// Now we have all the nodes as basic blocks, so rebuild the edges
	bool blocksConnected(CFGNode n1, CFGNode n2) {
		n1Exit = last(n1.nodes);
		n2Entry = head(n2.nodes);
		return n2Entry in forwards[n1Exit];
	}
	
	FlowEdge getBlockEdge(CFGNode n1, CFGNode n2) {
		n1Exit = last(n1.nodes);
		n2Entry = head(n2.nodes);
		edges = { e | e <- g.edges, n1Exit.lab == e.from, n2Entry.lab == e.to };
		if (size(edges) > 1) {
			for (e <- edges)
				println("In <g.item>, found flow edge <e>"); 
			throw "We should not have multiple edges between the same nodes";
		}
		e = getOneFrom(edges);
		return e[from=n1.lab][to=n2.lab];
	}
	
	CFGNode blockEntryNode() {
		entryNodes = { n | n <- basicBlocks, isEntryNode(head(n.nodes)) };
		if (size(entryNodes) == 1) return getOneFrom(entryNodes);
		throw "Error, found multiple entry nodes";
	}
	
	CFGNode blockExitNode() {
		exitNodes = { n | n <- basicBlocks, isExitNode(last(n.nodes)) };
		if (size(exitNodes) == 1) return getOneFrom(exitNodes);
		println("In <g.item>, found <size(exitNodes)> exit nodes out of a total of <size(g.nodes)> nodes with <size(basicBlocks)> blocks");
		throw "blocksSoFar"(g.nodes,basicBlocks); //"Error, found multiple exit nodes";
	}
	
	blockEdges = { getBlockEdge(n1,n2) | n1 <- basicBlocks, n2 <- basicBlocks, blocksConnected(n1,n2) };
	
	// sanity check -- this shouldn't have caused us to lose nodes
	if (size(g.nodes) != size({n | b <- basicBlocks, n <- b.nodes })) {
		blockNodes = {n | b <- basicBlocks, n <- b.nodes };
		missingNodes = g.nodes - blockNodes;
		for (n <- missingNodes)
			println("Missing node for <g.item>: <n>");
		// NOTE: no longer throwing, this can happen when we have code that isn't actually reachable
		//throw "Error in conversion to basic blocks, expected <size(g.nodes)> nodes but only found <size(blockNodes)> nodes";
	}
		
	if (g has at) {
		return cfg(g.item, basicBlocks, blockEdges, g.at, blockEntryNode(), blockExitNode());
	} else {
		return cfg(g.item, basicBlocks, blockEdges, blockEntryNode(), blockExitNode());
	}
}
