module lang::php::analysis::cfg::Util

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::BasicBlocks;
import analysis::graphs::Graph;
import Relation;

public set[CFGNode] pred(CFG cfg, CFGNode n) {
	predlabels = { e.from | e <- cfg.edges, e.to == n@lab };
	return { nd | nd <- cfg.nodes, nd@lab in predlabels };
}

public set[CFGNode] pred(Graph[CFGNode] g, CFGNode n) {
	return invert(g)[n];
}

public set[CFGNode] succ(CFG cfg, CFGNode n) {
	succlabels = { e.to | e <- cfg.edges, e.from == n@lab };
	return { nd | nd <- cfg.nodes, nd@lab in succlabels };
}

public set[CFGNode] succ(Graph[CFGNode] g, CFGNode n) {
	return g[n];
}