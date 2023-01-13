@license{
  Copyright (c) 2009-2013 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::Visualize

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::FlowEdge;
import lang::php::analysis::cfg::CFG;
import lang::php::pp::PrettyPrinter;
import lang::php::analysis::cfg::BasicBlocks;
import IO;
import List;
import String;
import vis::Figure;
import vis::Render; 

//public void renderCFG(CFG c) {
//	str getID(CFGNode n) = "<n@lab>";
//	nodes = [ box(text("<escapeForDot(printCFGNode(n))>"), id(getID(n)), size(40)) | n <- c.nodes ];
//	edges = [ edge("<e.from>","<e.to>") | e <- c.edges ];
//	render(graph(nodes,edges,gap(40)));
//}

public str escapeForDot(str s) {
	return escape(s, ("\n" : "\\n", "\"" : "\\\""));
}

public void renderCFGAsDot(CFG c, loc writeTo, str title = "") {
	str getID(CFGNode n) = "<n@lab>";
	c = visit(c) { case inlineHTML(_) => inlineHTML("HTMLCode") }
	
	nodes = [ "\"<getID(n)>\" [ label = \"<getID(n)>:<escapeForDot(printCFGNode(n))>\", labeljust=\"l\" ];" | n <- c.nodes ];
	edges = [ "\"<e.from>\" -\> \"<e.to>\" [ label = \"<printFlowEdgeLabel(e)>\"];" | e <- c.edges ];
	str dotGraph = "digraph \"CFG\" {
				   '	graph [ label = \"Control Flow Graph<size(title)>0?" for <title>":"">\" ];
				   '	node [ shape = box ];
				   '	<intercalate("\n", nodes)>
				   '	<intercalate("\n",edges)>
				   '}";
	writeFile(writeTo,dotGraph);
}
