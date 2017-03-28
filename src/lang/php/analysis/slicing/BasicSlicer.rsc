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
	reachableFromN = g*[n];
	
	// Which uses do we initially care about? We start with uses that reach the start
	// node and are for one of the names we care about.
	importantUses = { ui | ui <- u[n.l], ui.name in names };

	// Now, we find the nodes that define these uses, then we add their uses,
	// then we find the nodes that define those uses, etc, until we stabilize
	importantDefs = { di | di <- d, di.definedAt in importantUses.definedAt };
	solve(importantUses, importantDefs) {
		importantUses = importantUses + { ui | ui <- u, ui.definedAt in d.definedAt };
		importantDefs = importantDefs + { di | di <- d, di.definedAt in importantUses.definedAt };
	}
	
	// The defs will give us all the nodes we need to keep, except for control flow
	// nodes. First, we identify the defining nodes to keep from the graph, then we
	// use containment to see which other nodes to keep.
	definingLabels = importantDefs.definedAt;
	definingNodes = { gn | gn <- reachableFromN, n.l in definedAt };
	
	return CFG;
}