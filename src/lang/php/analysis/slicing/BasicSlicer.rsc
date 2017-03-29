module lang::php::analysis::slicing::BasicSlicer

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::usedef::UseDef;

import Relation;
import IO;
import Set;

public CFG basicSlice(CFG inputCFG, CFGNode n, set[Name] names) {
	// This performs a basic slice, just using the CFG. A more precise slice,
	// using an SDG, should replace this at some point.
	
	// Get all definitions for the graph
	d = definitions(inputCFG);
	
	// And, get all uses
	u = uses(inputCFG, d);
	
	// Convert the CFG into a standard graph (binary relation). We invert
	// it since we are taking a backwards slice.
	g = invert(cfgAsGraph(inputCFG));

	// Which nodes in the CFG are reachable from the node where we are starting
	// the slice?	
	reachableFromN = (g*)[n];
	
	// Which uses do we initially care about? The slicing criteria include both the node
	// where we start the slice and the names we are interested in; we take uses of those
	// names, which indicate the definitions that are important to the slice. 
	rel[Name name, Lab definedAt] importantUses = { ui | tuple[Name name, Lab definedAt] ui <- u[n.l], ui.name in names };
	println("Found <size(importantUses)> important uses:\n<importantUses>");
	solve(importantUses) {
		// Now, we compute a fixpoint, extending the set with the uses which contributed to the
		// uses we already know about. When this terminates, we will have the uses, indicating
		// the important definitions, for all the names that contribute to the query. 
		importantUses = importantUses + { ui | l <- importantUses.definedAt, tuple[Name name, Lab definedAt] ui <- u[l] };
		println("Found <size(importantUses)> important uses:\n<importantUses>");
	}
	
	// The important uses indicate the labels of the nodes that define each use. We need to keep each of these
	// nodes in the control flow graph (step 1), plus all nodes contained inside these nodes (step 2), and then
	// predicates/conditionals that contain these nodes (step 3).
	definingLabels = importantUses.definedAt;
	definingNodes = { gn | gn <- reachableFromN, gn.l in definingLabels };
	println("Found <size(definingNodes)> nodes based on needed definitions");
	
	llr = getLabelLocationRel(inputCFG);
	for (l <- llr[{gn.l | gn <- definingNodes}]) {
		println(l);
	}
	
	// Find all containing predicate nodes.
	ifNodes = { < ni, s > | ni:stmtNode(s:\if(_,_,_,_),_) <- inputCFG.nodes };
	doNodes = { < ni, s > | ni:stmtNode(s:do(_,_),_) <- inputCFG.nodes };
	whileNodes = { < ni, s > | ni:stmtNode(s:\while(_,_),_) <- inputCFG.nodes };
	forNodes = { < ni, s > | ni:stmtNode(s:\for(_,_,_,_),_) <- inputCFG.nodes };
	forEachNodes = { < ni, s > | ni:stmtNode(s:\forEach(_,_,_,_,_),_) <- inputCFG.nodes };
	// TODO: Add switch, which also means adding the related case...
	// TODO: Add try/catch and try/catch/finally
	ternaryNodes = { < ni, e > | ni:exprNode(e:ternary(_,_,_),_) <- inputCFG.nodes };
	predStmtNodes = ifNodes + doNodes + whileNodes + forNodes + forEachNodes;
	predExprNodes = ternaryNodes;
	
	headersForStmts = { < s, ni > | ni:headerNode(s,_,_) <- inputCFG.nodes, s in predStmtNodes<1> };
	footersForStmts = { < s, ni > | ni:footerNode(s,_,_) <- inputCFG.nodes, s in predStmtNodes<1> };
	headersForExprs = { < e, ni > | ni:headerNode(e,_,_) <- inputCFG.nodes, s in predExprNodes<1> };
	footersForExprs = { < e, ni > | ni:footerNode(e,_,_) <- inputCFG.nodes, s in predExprNodes<1> };
	
	containedLocations = { gn.expr@at | gn <- definingNodes, gn is exprNode, (gn.expr@at)? } +
						 { gn.stmt@at | gn <- definingNodes, gn is stmtNode, (gn.stmt@at)? };

	containingStmts = { };
	for (< ni, s > <- predStmtNodes) {
		if (size({ l | l <- containedLocations, l < s@at }) > 0) {
			containingStmts = containingStmts + < ni, s >;
		}
	}

	containingExprs = { };
	for (< ni, e > <- predExprNodes) {
		if (size({ l | l <- containedLocations, l < e@at }) > 0) {
			containingExprs = containingExprs + < ni, e >;
		}
	}
	
	println("Found <size(containingStmts)> containing pred statements");
	println("Found <size(containingExprs)> containing pred exprs");

	resultingCFG = inputCFG;
	// TODO: Add start and end nodes!
	resultingCFG.nodes = definingNodes + containingStmts<0> + containingExprs<0> + headersForStmts[containingStmts<1>] + footersForStmts[containingStmts<1>] + headersForExprs[containingExprs<1>] + footersForExprs[containingExprs<1>];
	labels = { n.l | n <- resultingCFG.nodes };
	edges = resultingCFG.edges;
	solve(newEdges) {
		edges = { };
		for (e <- newEdges) {
			if (e.from == e.to && e.from in labels) {
				edges = edges + e;
			} else {
				; // Add code for other cases...
			} 
		}
	}
	return inputCFG;
}