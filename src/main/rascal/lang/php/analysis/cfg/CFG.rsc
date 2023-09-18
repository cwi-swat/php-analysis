@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::CFG

import lang::php::ast::AbstractSyntax;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import analysis::graphs::Graph;
import Set;
import Node;

@doc{Representations of the control flow graph}
public data CFG 
	= cfg(loc item, set[CFGNode] nodes, FlowEdges edges)
	| cfg(loc item, set[CFGNode] nodes, FlowEdges edges, CFGNode entryNode, CFGNode exitNode)
	| cfg(loc item, set[CFGNode] nodes, FlowEdges edges, loc at)
	| cfg(loc item, set[CFGNode] nodes, FlowEdges edges, loc at, CFGNode entryNode, CFGNode exitNode)
	;

@doc{Control flow graph nodes}
data CFGNode
	= functionEntry(str functionName, Lab lab)
	| functionExit(str functionName, Lab lab)
	| methodEntry(str className, str methodName, Lab lab)
	| methodExit(str className, str methodName, Lab lab)
	| closureEntry(str fileName, int offset, int length, Lab lab)
	| closureExit(str fileName, int offset, int length, Lab lab)
	| scriptEntry(Lab lab)
	| scriptExit(Lab lab)
	| stmtNode(Stmt stmt, Lab lab)
	| exprNode(Expr expr, Lab lab)
	| foreachTest(Expr expr, Lab lab)
	| foreachAssignKey(Expr expr, Expr keyExpr, Lab lab)
	| foreachAssignValue(Expr expr, Expr valExpr, Lab lab)
	| headerNode(Stmt stmt, Lab footer, Lab lab)
	| headerNode(Expr expr, Lab footer, Lab lab)
	| footerNode(Stmt stmt, Lab header, Lab lab)
	| footerNode(Expr expr, Lab header, Lab lab)
	| actualProvided(str paramName, bool refAssign, Lab lab)
	| actualNotProvided(str paramName, Expr expr, bool refAssign, Lab lab)
	;

public alias CFGNodes = set[CFGNode];

@doc{Pretty-print CFG nodes}
public str printCFGNode(functionEntry(str fn ,_)) = "Entry: <fn>";
public str printCFGNode(functionExit(str fn, _)) = "Exit: <fn>";
public str printCFGNode(methodEntry(str cn, str mn, _)) = "Entry: <cn>::<mn>";
public str printCFGNode(methodExit(str cn, str mn, _)) = "Exit: <cn>::<mn>";
public str printCFGNode(closureEntry(str fn, int offset, int len, _)) = "Entry: <fn>,<offset>,<len>";
public str printCFGNode(closureExit(str fn, int offset, int len, _)) = "Exit: <fn>,<offset>,<len>";
public str printCFGNode(scriptEntry(_)) = "Entry";
public str printCFGNode(scriptExit(_)) = "Exit";
public str printCFGNode(foreachTest(Expr expr, Lab l)) = "Iteration Test";
public str printCFGNode(foreachAssignKey(Expr expr, Expr keyExpr, Lab l)) = "Assign Foreach Key <pp(keyExpr)>";
public str printCFGNode(foreachAssignValue(Expr expr, Expr valExpr, Lab l)) = "Assign Foreach Value <pp(valExpr)>";
public str printCFGNode(headerNode(Expr e,_,Lab lab)) = "header: <getName(e)>";
public str printCFGNode(headerNode(Stmt s,_,Lab lab)) = "header: <getName(s)>";
public str printCFGNode(footerNode(Expr e,_,Lab lab)) = "footer: <getName(e)>";
public str printCFGNode(footerNode(Stmt s,_,Lab lab)) = "footer: <getName(s)>";
public str printCFGNode(stmtNode(Stmt s, Lab lab)) {
	switch(s) {
		case classDef(ClassDef cd) : return cd has className ? "Class <cd.className>" : "Class ANONYMOUS";
		case function(fn,_,_,_,_,_) : return "Function <fn>";
		default: return "Stmt: <pp(s)>";
	}
}
public str printCFGNode(exprNode(Expr e, Lab lab)) = "Expr: <pp(e)>";
public str printCFGNode(actualProvided(str paramName, bool refAssign, Lab lab)) = "Arbitrary Value <paramName> <refAssign ? "?" : "">= unknown";
public str printCFGNode(actualNotProvided(str paramName, Expr expr, bool refAssign, Lab lab)) = "Default Value <paramName> <refAssign ? "?" : "">= <pp(expr)>";

@doc{Convert the CFG into a Rascal Graph, based on flow edge information}
public Graph[CFGNode] cfgAsGraph(CFG cfg) {
	nodeMap = ( n.lab : n | n <- cfg.nodes );
	return { < nodeMap[e.from], nodeMap[e.to] > | e <- cfg.edges, e.from in nodeMap, e.to in nodeMap };
}

@doc{Given a node, determine if it is an entry node.}
public bool isEntryNode(CFGNode n) = (n is functionEntry) || (n is methodEntry) || (n is scriptEntry) || (n is closureEntry);

@doc{Get the unique entry node for the CFG.}
public CFGNode getEntryNode(CFG g) {
	if (g has entryNode) return g.entryNode;
	entryNodes = { n | n <- g.nodes, isEntryNode(n) };
	if (size(entryNodes) == 1)
		return getOneFrom(entryNodes);
	throw "Could not find a unique entry node";
}

@doc{Given a node, determine if it is an exit node.}
public bool isExitNode(CFGNode n) = (n is functionExit) || (n is methodExit) || (n is scriptExit) || (n is closureExit);

@doc{Get the unique exit node for the CFG.}
public CFGNode getExitNode(CFG g) {
	if (g has exitNode) return g.exitNode;
	exitNodes = { n | n <- g.nodes, isExitNode(n) };
	if (size(exitNodes) == 1)
		return getOneFrom(exitNodes);
	throw "Could not find a unique exit node";
}

@doc{Get a map from labels to locations.}
rel[Lab label, loc at] getLabelLocationRel(CFG g) {
	exprs = { < n.lab, n.expr.at > | n <- g.nodes, n is exprNode, (n.expr.at.scheme != "unknown") };
	stmts = { < n.lab, n.stmt.at > | n <- g.nodes, n is stmtNode, (n.stmt.at.scheme != "unknown") };
	return exprs + stmts;
}