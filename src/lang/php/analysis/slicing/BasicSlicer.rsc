module lang::php::analysis::slicing::BasicSlicer

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::usedef::UseDef;
import lang::php::analysis::cfg::Util;
import lang::php::analysis::cfg::Visualize;
import lang::php::util::Utils;

import Relation;
import IO;
import Set;
import List;

public CFG basicSlice(CFG inputCFG, CFGNode n, set[Name] names, Defs d = { }, Uses u = { }) {
	// This performs a basic slice, just using the CFG. A more precise slice,
	// using an SDG, should replace this at some point.
	
	// Get all definitions for the graph
	if (isEmpty(d)) {
		d = definitions(inputCFG);
	}
	
	// And, get all uses
	if (isEmpty(u)) {
		u = uses(inputCFG, d);
	}
	
	// Convert the CFG into a standard graph (binary relation). We invert
	// it since we are taking a backwards slice.
	forwardg = cfgAsGraph(inputCFG);
	g = invert(forwardg);

	// Which nodes in the CFG are reachable from the node where we are starting
	// the slice?	
	reachableFromN = (g*)[n];
	
	// Which uses do we initially care about? The slicing criteria include both the node
	// where we start the slice and the names we are interested in; we take uses of those
	// names, which indicate the definitions that are important to the slice. 
	rel[Name name, Lab definedAt] importantUses = { ui | tuple[Name name, Lab definedAt] ui <- u[n.l], ui.name in names };
	logMessage("Found <size(importantUses)> important uses:\n<importantUses>", 2);
	solve(importantUses) {
		// Now, we compute a fixpoint, extending the set with the uses which contributed to the
		// uses we already know about. When this terminates, we will have the uses, indicating
		// the important definitions, for all the names that contribute to the query. 
		importantUses = importantUses + { ui | l <- importantUses.definedAt, tuple[Name name, Lab definedAt] ui <- u[l] };
		logMessage("Found <size(importantUses)> important uses:\n<importantUses>", 2);
	}
	
	// The important uses indicate the labels of the nodes that define each use. We need to keep each of these
	// nodes in the control flow graph (step 1), plus all nodes contained inside these nodes (step 2), and then
	// predicates/conditionals that contain these nodes (step 3).
	definingLabels = importantUses.definedAt;
	definingNodes = { gn | gn <- reachableFromN, gn.l in definingLabels };
	logMessage("Found <size(definingNodes)> nodes based on needed definitions", 2);
	
	llr = getLabelLocationRel(inputCFG);
	for (l <- llr[{gn.l | gn <- definingNodes}]) {
		logMessage("<l>", 2);
	}
	
	// Find all containing predicate nodes.
	ifNodes = { < ni, s > | ni:stmtNode(s:\if(_,_,_,_),_) <- inputCFG.nodes };
	doNodes = { < ni, s > | ni:stmtNode(s:do(_,_),_) <- inputCFG.nodes };
	whileNodes = { < ni, s > | ni:stmtNode(s:\while(_,_),_) <- inputCFG.nodes };
	forNodes = { < ni, s > | ni:stmtNode(s:\for(_,_,_,_),_) <- inputCFG.nodes };
	forEachNodes = { < ni, s > | ni:stmtNode(s:\foreach(_,_,_,_,_),_) <- inputCFG.nodes };
	// TODO: Add switch, which also means adding the related case...
	// TODO: Add try/catch and try/catch/finally
	ternaryNodes = { < ni, e > | ni:exprNode(e:ternary(_,_,_),_) <- inputCFG.nodes };
	
	headersForStmts = { < ni, s > | ni:headerNode(Stmt s,_,_) <- inputCFG.nodes };
	footersForStmts = { < ni, s > | ni:footerNode(Stmt s,_,_) <- inputCFG.nodes };
	headersForExprs = { < ni, e > | ni:headerNode(Expr e,_,_) <- inputCFG.nodes };
	footersForExprs = { < ni, e > | ni:footerNode(Expr e,_,_) <- inputCFG.nodes };

	predStmtNodes = ifNodes + doNodes + whileNodes + forNodes + forEachNodes + headersForStmts;
	predExprNodes = ternaryNodes + headersForExprs;
	
	containedLocations = { gn.expr@at | gn <- definingNodes, gn is exprNode, (gn.expr@at)? } +
						 { gn.stmt@at | gn <- definingNodes, gn is stmtNode, (gn.stmt@at)? };
						 
	if (n is exprNode && (n.expr@at)?) {
		containedLocations = containedLocations + n.expr@at;
	} else if (n is stmtNode && (n.stmt@at)?) {
		containedLocations = containedLocations + n.stmt@at;
	}
	
	for (< ni, s > <- predStmtNodes) {
		logMessage("Stmt: <s@at>", 2);
	}
	
	logMessage("<containedLocations>", 2);
	 
	rel[CFGNode, Stmt] containingStmts = { };
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
	
	logMessage("Found <size(containingStmts)> containing pred statements", 2);
	logMessage("Found <size(containingExprs)> containing pred exprs", 2);

	nodesToKeep = n + definingNodes + getEntryNode(inputCFG) + getExitNode(inputCFG);
	if (size(containingStmts) > 0) {
		nodesToKeep = nodesToKeep + 
			containingStmts<0> + 
			invert(headersForStmts)[containingStmts<1>] +
			invert(footersForStmts)[containingStmts<1>];
	}
	if (size(containingExprs) > 0) {
		nodesToKeep = nodesToKeep +
			 containingExprs<0> +
			 invert(headersForExprs)[containingExprs<1>] + 
			 invert(footersForExprs)[containingExprs<1>];
	}
	
	// Also keep all nodes that are reachable in the backwards slice that are decision points
	otherNodesToKeep = { rn | rn <- reachableFromN, size(forwardg[rn]) > 1 };
			
	nodesToRemove = inputCFG.nodes - (nodesToKeep + otherNodesToKeep);
	
	inputCFG = transformUnlinkedConditions(inputCFG, alsoCheck=nodesToRemove);

	for (n2r <- nodesToRemove) {
		inputCFG = removeNode(inputCFG, n2r);
	}
		
	inputCFG = transformUnlinkedConditions(inputCFG);
	
	return inputCFG;
}

public void visualizeSlice(CFG slicedCFG, loc l) {
	renderCFGAsDot(slicedCFG, l, title="Sliced CFG");
}