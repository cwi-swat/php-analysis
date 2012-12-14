@license{

  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::CFG

import lang::php::ast::AbstractSyntax;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::NamePaths;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::cfg::FlowEdge;
import analysis::graphs::Graph;

public data CFG = cfg(NamePath item, set[CFGNode] nodes, FlowEdges edges);

data CFGNode
	= functionEntry(str functionName)
	| functionExit(str functionName)
	| methodEntry(str className, str methodName)
	| methodExit(str className, str methodName)
	| scriptEntry()
	| scriptExit()
	| stmtNode(Stmt stmt, Lab l)
	| exprNode(Expr expr, Lab l)
	| foreachTest(Expr expr, Lab l)
	| joinNode(Stmt stmt, Lab l)
	;

public anno Lab CFGNode@lab;

public alias CFGNodes = set[CFGNode];

public str printCFGNode(CFGNode n) {
	switch(n) {
		case functionEntry(fn) : return "Entry: <fn>";
		case functionExit(fn) : return "Exit: <fn>";
		case methodEntry(cn,mn) : return "Entry: <cn>::<mn>";
		case methodExit(cn,mn) : return "Exit: <cn>::<mn>";
		case scriptEntry() : return "Entry";
		case scriptExit() : return "Exit";
		case stmtNode(s,l) : {
			switch(s) {
				case classDef(ClassDef cd) : return "Class <cd.className>";
				case function(fn,_,_,_) : return "Function <fn>";
				default: return pp(s);
			}
		}
		case exprNode(e,l) : {
			switch(e) {
				default: return pp(e);
			}
		}
		case foreachTest(e,l) : return "Iteration Test";
		case joinNode(s,l) : return "join";	
	}
}

public Graph[CFGNode] cfgAsGraph(CFG cfg) {
	nodeMap = ( n@lab : n | n <- cfg.nodes );
	return { < nodeMap[e.from], nodeMap[e.to] > | e <- cfg.edges };
}

